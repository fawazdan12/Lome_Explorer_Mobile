import 'package:event_flow/data/datasource/local/cache_hive_datasource.dart';
import 'package:event_flow/data/datasource/remote/api_datasource_remote.dart';
import 'package:event_flow/data/models/avis_lieu_event_geo_model.dart';
import 'package:event_flow/data/models/lieu_evenement_model.dart';
import 'package:logger/logger.dart';


class LieuEvenementService {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  final Logger _logger;

  LieuEvenementService({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _logger = logger;

  // ==================== LIEUX ====================

  /// Récupérer la liste des lieux
  Future<List<LieuModel>> getLieux({
    int page = 1,
    String? search,
    String? categorie,
    bool useCache = true,
  }) async {
    try {
      _logger.i('Récupération des lieux - page: $page');

      // Essayer le cache d'abord
      if (useCache && page == 1) {
        final cachedLieux = await _localDataSource.getCachedLieux();
        if (cachedLieux.isNotEmpty) {
          _logger.d('${cachedLieux.length} lieux récupérés du cache');
          return cachedLieux;
        }
      }

      // Récupérer du serveur
      final lieux = await _remoteDataSource.getLieux(
        page: page,
        search: search,
        categorie: categorie,
      );

      // Mettre en cache
      if (page == 1) {
        await _localDataSource.cacheLieux(lieux);
      }

      _logger.i('${lieux.length} lieux récupérés du serveur');
      return lieux;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des lieux: $e');
      rethrow;
    }
  }

  /// Récupérer un lieu par son ID
  Future<LieuModel> getLieuById(String id) async {
    try {
      _logger.i('Récupération du lieu: $id');

      // Essayer le cache
      final cached = await _localDataSource.getCachedLieuById(id);
      if (cached != null) {
        _logger.d('Lieu récupéré du cache: $id');
        return cached;
      }

      // Récupérer du serveur
      final lieu = await _remoteDataSource.getLieuById(id);

      _logger.i('Lieu récupéré du serveur: $id');
      return lieu;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du lieu: $e');
      rethrow;
    }
  }

  /// Créer un nouveau lieu
  Future<LieuModel> createLieu({
    required String nom,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
  }) async {
    try {
      _logger.i('Création d\'un lieu: $nom');

      final lieu = await _remoteDataSource.createLieu(
        nom: nom,
        description: description,
        categorie: categorie,
        latitude: latitude,
        longitude: longitude,
      );

      // Vider le cache pour forcer le rafraîchissement
      await _localDataSource.clearLieux();

      _logger.i('Lieu créé avec succès: ${lieu.id}');
      return lieu;
    } catch (e) {
      _logger.e('Erreur lors de la création du lieu: $e');
      rethrow;
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
    final updatedLieu = await _remoteDataSource.updateLieu(
      id: id,
      nom: nom,
      description: description,
      categorie: categorie,
      latitude: latitude,
      longitude: longitude,
    );
    
    // Mettre à jour l'élément dans le cache au lieu de tout vider
    final cachedLieux = await _localDataSource.getCachedLieux();
    final index = cachedLieux.indexWhere((l) => l.id == id);
    if (index != -1) {
      cachedLieux[index] = updatedLieu;
      await _localDataSource.cacheLieux(cachedLieux);
    }
    
    return updatedLieu;
  } catch (e) {
    _logger.e('Erreur mise à jour lieu: $e');
    rethrow;
  }
  }

  /// Supprimer un lieu par son ID
  Future<void> deleteLieu(String id) async {
    try {
      _logger.i('Suppression du lieu: $id');

      await _remoteDataSource.deleteLieu(id);

      // Vider le cache pour forcer le rafraîchissement
      await _localDataSource.clearLieux();

      _logger.i('Lieu supprimé avec succès: $id');
    } catch (e) {
      _logger.e('Erreur lors de la suppression du lieu: $e');
      rethrow;
    }
  }

  /// Récupérer les lieux à proximité
  Future<List<NearbyPlaceModel>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      _logger.i('Recherche de lieux à proximité: $latitude, $longitude, $radius km');

      final places = await _remoteDataSource.getNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      _logger.i('${places.length} lieux trouvés à proximité');
      return places;
    } catch (e) {
      _logger.e('Erreur lors de la recherche de lieux: $e');
      rethrow;
    }
  }

  // ==================== ÉVÉNEMENTS ====================

  /// Récupérer la liste des événements
  Future<List<EvenementModel>> getEvenements({
    int page = 1,
    String? search,
    bool? aVenir,
    bool useCache = true,
  }) async {
    try {
      _logger.i('Récupération des événements - page: $page');

      // Essayer le cache d'abord
      if (useCache && page == 1 && aVenir != false) {
        final cached = await _localDataSource.getCachedEvenements();
        if (cached.isNotEmpty) {
          _logger.d('${cached.length} événements récupérés du cache');
          return cached;
        }
      }

      // Récupérer du serveur
      final evenements = await _remoteDataSource.getEvenements(
        page: page,
        search: search,
        aVenir: aVenir,
      );

      // Mettre en cache
      if (page == 1 && aVenir != false) {
        await _localDataSource.cacheEvenements(evenements);
      }

      _logger.i('${evenements.length} événements récupérés du serveur');
      return evenements;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des événements: $e');
      rethrow;
    }
  }

  /// Créer un nouvel événement
  Future<EvenementModel> createEvenement({
    required String nom,
    required String description,
    required DateTime dateDebut,  
    required DateTime dateFin,
    required String lieuId,
  }) async {
    try {
      _logger.i('Création d\'un événement: $nom');

      final evenement = await _remoteDataSource.createEvenement(
        nom: nom,
        description: description,
        dateDebut: dateDebut, 
        dateFin: dateFin,
        lieuId: lieuId,
      );

      _logger.i('🔔 Événement créé: ${evenement.id}');
      _logger.i('🔔 Le serveur Django devrait envoyer une notification maintenant');
      // Vider le cache pour forcer le rafraîchissement
      await _localDataSource.clearEvenements();

      _logger.i('Événement créé avec succès: ${evenement.id}');
      return evenement;
    } catch (e) {
      _logger.e('Erreur lors de la création de l\'événement: $e');
      rethrow;
    }
  }

  /// Mettre à jour un événement existant
  Future<EvenementModel> updateEvenement({
    required String id,
    required String nom,
    required String description,
    required DateTime dateDebut,  
    required DateTime dateFin,
    required String lieuId,
  }) async {
    try {
      _logger.i('Mise à jour de l\'événement: $id');

      final updatedEvenement = await _remoteDataSource.updateEvenement(
        id: id,
        nom: nom,
        description: description,
        dateDebut: dateDebut,  
        dateFin: dateFin,
        lieuId: lieuId,
      );

      // Vider le cache pour forcer le rafraîchissement
      await _localDataSource.clearEvenements();

      _logger.i('Événement mis à jour avec succès: $id');
      return updatedEvenement;
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour de l\'événement: $e');
      rethrow;
    }
  }

  // supprimer un événement
  Future<void> deleteEvenement(String id) async {
    try {
      _logger.i('Suppression de l\'événement: $id');

      await _remoteDataSource.deleteEvenement(id);

      // Vider le cache pour forcer le rafraîchissement
      await _localDataSource.clearEvenements();

      _logger.i('Événement supprimé avec succès: $id');
    } catch (e) {
      _logger.e('Erreur lors de la suppression de l\'événement: $e');
      rethrow;
    }
  }

  /// Récupérer un événement par son ID
  Future<EvenementModel> getEvenementById(String id) async {
    try {
      _logger.i('Récupération de l\'événement: $id');

      final evenement = await _remoteDataSource.getEvenementById(id);

      _logger.i('Événement récupéré: $id');
      return evenement;
    } catch (e) {
      _logger.e('Erreur lors de la récupération de l\'événement: $e');
      rethrow;
    }
  }

  /// Récupérer les événements à proximité
  Future<List<EvenementModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      _logger.i('Recherche d\'événements à proximité: $latitude, $longitude, $radius km');

      final evenements = await _remoteDataSource.getNearbyEvents(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      _logger.i('${evenements.length} événements trouvés à proximité');
      return evenements;
    } catch (e) {
      _logger.e('Erreur lors de la recherche d\'événements: $e');
      rethrow;
    }
  }

  // ==================== CACHE ====================

  /// Rafraîchir tous les caches
  Future<void> refreshAllCache() async {
    try {
      _logger.i('Rafraîchissement de tous les caches');

      await Future.wait([
        _localDataSource.clearLieux(),
        _localDataSource.clearEvenements(),
      ]);

      await getLieux(useCache: false);
      await getEvenements(useCache: false);

      _logger.i('Tous les caches rafraîchis');
    } catch (e) {
      _logger.e('Erreur lors du rafraîchissement des caches: $e');
    }
  }

  /// Vider les caches
  Future<void> clearAllCache() async {
    try {
      _logger.i('Suppression de tous les caches');
      await _localDataSource.clearLieux();
      await _localDataSource.clearEvenements();
      _logger.i('Tous les caches supprimés');
    } catch (e) {
      _logger.e('Erreur lors de la suppression des caches: $e');
    }
  }
}