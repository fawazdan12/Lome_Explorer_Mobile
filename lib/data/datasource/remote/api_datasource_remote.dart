import 'dart:math';

import 'package:dio/dio.dart';
import 'package:event_flow/config/api_execption.dart';
import 'package:event_flow/config/app_config.dart';
import 'package:event_flow/data/models/avis_lieu_event_geo_model.dart';
import 'package:event_flow/data/models/lieu_evenement_model.dart';
import 'package:event_flow/data/models/statistic_model.dart';
import 'package:event_flow/data/models/utilisateur_model.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteDataSource {
  final Dio _dio;
  final Logger _logger;
  String? _token;
  final SharedPreferences _preferences;

  RemoteDataSource({
    required Dio dio,
    required Logger logger,
    required SharedPreferences preferences,
  }) : _dio = dio,
       _logger = logger,
       _preferences = preferences {
    _setupDio();
  }

  void _setupDio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TOUJOURS vérifier SharedPreferences en priorité
          final tokenFromPrefs = _preferences.getString(LocalStorageKeys.token);
          final token = tokenFromPrefs ?? _token;

          _logger.d('Token from _token: ${_token != null ? "YES" : "NO"}');
          _logger.d(
            'Token from SharedPreferences: ${tokenFromPrefs != null ? "YES" : "NO"}',
          );

          if (token != null && token.isNotEmpty) {
            options.headers[ApiConstants.authorization] = 'Token $token';
            _logger.d('Token ajouté: ${token.substring(0, 20)}...');
          } else {
            _logger.w('Aucun token disponible');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('Réponse: ${response.statusCode} ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Erreur HTTP: ${error.message}');
          _logger.e('Status Code: ${error.response?.statusCode}');
          _logger.e('Response Data: ${error.response?.data}');
          _logger.e('Request Data: ${error.requestOptions.data}');
          _logger.e('Request Headers: ${error.requestOptions.headers}');
          if (error.response?.statusCode == 401) {
            _logger.e(
              'Token utilisé: ${_token != null ? "Oui (${_token!.substring(0, 20)}...)" : "Non"}',
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setToken(String token) {
    _token = token;
    _logger.i(
      'Token défini dans RemoteDataSource: ${token.substring(0, 20)}...',
    );
  }

  void clearToken() {
    _token = null;
    _logger.i('Token nettoyé dans RemoteDataSource');
  }

  // NOUVELLE MÉTHODE : Vérifier si le token est défini
  bool hasToken() {
    final hasInMemory = _token != null && _token!.isNotEmpty;
    final hasInPrefs = _preferences.getString(LocalStorageKeys.token) != null;
    return hasInMemory || hasInPrefs;
  }

  // NOUVELLE MÉTHODE : Obtenir le token (pour debug uniquement)
  String? getToken() {
    return _token ?? _preferences.getString(LocalStorageKeys.token);
  }

  // ==================== AUTHENTIFICATION ====================

  Future<AuthenticationModel> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? tel,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.authRegister,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          'tel': tel,
        },
      );

      if (response.statusCode == 201) {
        return AuthenticationModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur lors de l\'inscription',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<AuthenticationModel> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Envoi requête login pour: $email');
      final response = await _dio.post(
        ApiConstants.authLogin,
        data: {'email': email, 'password': password},
      );

      _logger.i('Réponse login - Status: ${response.statusCode}');
      _logger.i('Réponse login - Data: ${response.data}');

      if (response.statusCode == 200) {
        // VÉRIFIER que le token est dans la réponse
        final data = response.data as Map<String, dynamic>;

        if (!data.containsKey('token')) {
          _logger.e('ERREUR : Pas de token dans la réponse !');
          _logger.e('Clés disponibles: ${data.keys.toList()}');
          throw ApiException(
            message: 'Pas de token dans la réponse du serveur',
            statusCode: response.statusCode,
          );
        }

        final token = data['token'] as String;
        _logger.i('Token extrait: ${token.substring(0, 20)}...');

        final auth = AuthenticationModel.fromJson(response.data);

        //Définir le token IMMÉDIATEMENT
        setToken(auth.token);
        _logger.i('Token défini dans RemoteDataSource');

        return auth;
      }

      throw ApiException(
        message: 'Email ou mot de passe incorrect',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _logger.e('DioException lors du login: ${e.message}');
      throw _handleDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.authLogout);
      clearToken();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<UtilisateurModel> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.authProfile);
      if (response.statusCode == 200) {
        return UtilisateurModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Impossible de récupérer le profil',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ==================== LIEUX ====================

  Future<List<LieuModel>> getLieux({
    int page = 1,
    String? search,
    String? categorie,
  }) async {
    try {
      final queryParams = {
        'page': page,
        if (search != null) 'search': search,
        if (categorie != null) 'categorie': categorie,
      };

      final response = await _dio.get(
        ApiConstants.lieux,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        return (results ?? [])
            .map((json) => LieuModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<LieuModel> getLieuById(String id) async {
    try {
      final response = await _dio.get(
        ApiConstants.lieuDetail.replaceFirst('{id}', id),
      );

      if (response.statusCode == 200) {
        return LieuModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Lieu non trouvé',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<LieuModel> createLieu({
    required String nom,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.lieux,
        data: {
          'nom': nom,
          'description': description,
          'categorie': categorie,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 201) {
        return LieuModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur lors de la création du lieu',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Mettre à jour un lieu existant
  Future<LieuModel> updateLieu({
    required String id,
    required String nom,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.lieuDetail.replaceFirst('{id}', id),
        data: {
          'nom': nom,
          'description': description,
          'categorie': categorie,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        return LieuModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur lors de la mise à jour du lieu',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Supprimer un lieu par son ID
  Future<void> deleteLieu(String id) async {
    try {
      final response = await _dio.delete(
        ApiConstants.lieuDetail.replaceFirst('{id}', id),
      );

      if (response.statusCode != 204) {
        throw ApiException(
          message: 'Erreur lors de la suppression du lieu',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<NearbyPlaceModel>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.geoLieuxProximite,
        queryParameters: {'lat': latitude, 'lng': longitude, 'radius': radius},
      );

      if (response.statusCode == 200) {
        final lieux = response.data['lieux'] as List?;
        return (lieux ?? [])
            .map(
              (json) => NearbyPlaceModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ==================== ÉVÉNEMENTS ====================

  Future<List<EvenementModel>> getEvenements({
    int page = 1,
    String? search,
    bool? aVenir,
  }) async {
    try {
      final queryParams = {
        'page': page,
        if (search != null) 'search': search,
        if (aVenir != null) 'a_venir': aVenir,
      };

      final response = await _dio.get(
        ApiConstants.evenements,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        return (results ?? [])
            .map(
              (json) => EvenementModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // crée un événement
  Future<EvenementModel> createEvenement({
    required String nom,
    required String description,
    required String lieuId,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.evenements,
        data: {
          'nom': nom,
          'description': description,
          'lieu': lieuId,
          'date_debut': dateDebut.toIso8601String(),
          'date_fin': dateFin.toIso8601String(),
        },
      );

      if (response.statusCode == 201) {
        return EvenementModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur lors de la création de l\'événement',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Met à jour un événement existant
  Future<EvenementModel> updateEvenement({
    required String id,
    required String nom,
    required String description,
    required String lieuId,
    required DateTime dateDebut, 
    required DateTime dateFin,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.evenementDetail.replaceFirst('{id}', id),
        data: {
          'nom': nom,
          'description': description,
          'lieu': lieuId,
          'date_debut': dateDebut.toIso8601String(),
          'date_fin': dateFin.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return EvenementModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur lors de la mise à jour de l\'événement',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Supprime un événement par son ID
  Future<void> deleteEvenement(String id) async {
    try {
      final response = await _dio.delete(
        ApiConstants.evenementDetail.replaceFirst('{id}', id),
      );

      if (response.statusCode != 204) {
        throw ApiException(
          message: 'Erreur lors de la suppression de l\'événement',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<EvenementModel> getEvenementById(String id) async {
    try {
      final response = await _dio.get(
        ApiConstants.evenementDetail.replaceFirst('{id}', id),
      );

      if (response.statusCode == 200) {
        return EvenementModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Événement non trouvé',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<EvenementModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.geoEvenementsProximite,
        queryParameters: {'lat': latitude, 'lng': longitude, 'radius': radius},
      );

      if (response.statusCode == 200) {
        final evenements = response.data['evenements'] as List?;
        return (evenements ?? [])
            .map(
              (json) => EvenementModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ==================== GÉOLOCALISATION ====================

  Future<LocationModel> detectLocation() async {
    try {
      final response = await _dio.get(ApiConstants.geoDetectLocation);

      if (response.statusCode == 200) {
        return LocationModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Impossible de détecter la localisation',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<LocationModel> geocodeAddress(String address) async {
    try {
      final response = await _dio.post(
        ApiConstants.geoGeocode,
        data: {'address': address},
      );

      if (response.statusCode == 200) {
        return LocationModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Adresse non trouvée',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<QuartierModel>> getQuartiers() async {
    try {
      final response = await _dio.get(ApiConstants.geoQuartiers);

      if (response.statusCode == 200) {
        final quartiers = response.data['quartiers'] as List?;
        return (quartiers ?? [])
            .map((json) => QuartierModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<bool> validateLomeLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.geoValidateLome,
        data: {'latitude': latitude, 'longitude': longitude},
      );

      if (response.statusCode == 200) {
        return response.data['is_in_lome'] as bool? ?? false;
      }
      return false;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ==================== AVIS ====================

  // ==================== AVIS LIEUX ====================

  Future<AvisLieuModel> createAvisLieu({
    required String lieuId,
    required int note,
    required String texte,
  }) async {
    try {
      _logger.i('Création avis lieu:');
      _logger.i('lieuId: $lieuId');
      _logger.i('note: $note');
      _logger.i('texte: ${texte.substring(0, min(50, texte.length))}...');
      final response = await _dio.post(
        ApiConstants.avisLieux,
        data: {'lieu': lieuId, 'note': note, 'texte': texte},
      );

      if (response.statusCode == 201) {
        return AvisLieuModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur lors de la création de l\'avis',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<AvisLieuModel>> getAvisLieu(String lieuId) async {
    try {
      final response = await _dio.get(
        ApiConstants.lieuAvis.replaceFirst('{id}', lieuId),
      );

      if (response.statusCode == 200) {
        final avis = response.data as List?;
        return (avis ?? [])
            .map((json) => AvisLieuModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<AvisLieuModel> updateAvisLieu({
    required String avisId,
    required int note,
    required String texte,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.avisLieux}$avisId/',
        data: {'note': note, 'texte': texte},
      );

      if (response.statusCode == 200) {
        return AvisLieuModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur modification avis',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<void> deleteAvisLieu(String avisId) async {
    try {
      final response = await _dio.delete('${ApiConstants.avisLieux}$avisId/');

      if (response.statusCode != 204) {
        throw ApiException(
          message: 'Erreur suppression avis',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ==================== AVIS ÉVÉNEMENTS ====================

  Future<List<AvisEvenementModel>> getAvisEvenement(String evenementId) async {
    try {
      final response = await _dio.get(
        ApiConstants.evenementAvis.replaceFirst('{id}', evenementId),
      );

      if (response.statusCode == 200) {
        final avis = response.data as List?;
        return (avis ?? [])
            .map(
              (json) =>
                  AvisEvenementModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<AvisEvenementModel> createAvisEvenement({
    required String evenementId,
    required int note,
    required String texte,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.avisEvenements,
        data: {'evenement': evenementId, 'note': note, 'texte': texte},
      );

      if (response.statusCode == 201) {
        return AvisEvenementModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur création avis',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<AvisEvenementModel> updateAvisEvenement({
    required String avisId,
    required int note,
    required String texte,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.avisEvenements}$avisId/',
        data: {'note': note, 'texte': texte},
      );

      if (response.statusCode == 200) {
        return AvisEvenementModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Erreur modification avis',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<void> deleteAvisEvenement(String avisId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.avisEvenements}$avisId/',
      );

      if (response.statusCode != 204) {
        throw ApiException(
          message: 'Erreur suppression avis',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ==================== STATISTIQUES ====================

  Future<StatistiquesModel> getStatistiques() async {
    try {
      final response = await _dio.get(ApiConstants.stats);

      if (response.statusCode == 200) {
        return StatistiquesModel.fromJson(response.data);
      }
      throw ApiException(
        message: 'Impossible de récupérer les statistiques',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ==================== GESTION DES ERREURS ====================

  Object _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          message: 'Délai d\'attente dépassé',
          originalError: e,
        );
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Délai d\'attente dépassé',
          originalError: e,
        );
      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Délai d\'attente dépassé',
          originalError: e,
        );
      case DioExceptionType.badResponse:
        return _handleBadResponse(e);
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Certificat invalide',
          originalError: e,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Erreur de connexion',
          originalError: e,
        );
      case DioExceptionType.unknown:
        return ApiException(
          message: e.message ?? 'Erreur inconnue',
          originalError: e,
        );
      default:
        return ApiException(message: 'Erreur API', originalError: e);
    }
  }

  Object _handleBadResponse(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // LOGGER DÉTAILLÉ
    _logger.e('_handleBadResponse appelée');
    _logger.e('Status: $statusCode');
    _logger.e('Data type: ${data.runtimeType}');
    _logger.e('Data: $data');

    String message = 'Erreur serveur';
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      _logger.e('Data est un Map, clés: ${data.keys.toList()}');

      // Extraire le message d'erreur
      if (data['error'] != null) {
        message = data['error'].toString();
      } else if (data['detail'] != null) {
        message = data['detail'].toString();
      } else if (data['message'] != null) {
        message = data['message'].toString();
      } else {
        // Chercher dans les erreurs de validation
        final errorKeys = data.keys
            .where((k) => k != 'non_field_errors')
            .toList();
        if (errorKeys.isNotEmpty) {
          final firstKey = errorKeys.first;
          final errorValue = data[firstKey];

          if (errorValue is List && errorValue.isNotEmpty) {
            message = '$firstKey: ${errorValue.first}';
          } else {
            message = '$firstKey: $errorValue';
          }
        }
      }

      errors = data;
    } else if (data is String) {
      _logger.e('Data est un String: $data');
      message = data;
    }

    _logger.e('Message final: $message');

    switch (statusCode) {
      case 400:
        return ValidationException(message: message, errors: errors);
      case 401:
      case 403:
        return AuthenticationException(message);
      case 404:
        return NotFoundFailure(message);
      default:
        return ApiException(
          message: message,
          statusCode: statusCode,
          originalError: e,
        );
    }
  }
}
