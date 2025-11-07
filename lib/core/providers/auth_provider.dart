import 'dart:async';
import 'package:event_flow/config/app_config.dart';
import 'package:event_flow/data/datasource/remote/api_datasource_remote.dart';
import 'package:event_flow/domains/entities/utilisateur_entity.dart';
import 'package:event_flow/domains/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

/// Notifier principal pour l'authentification
class AuthNotifier extends ChangeNotifier {
  final AuthenticationRepository _repo;
  final Logger _logger;

  UtilisateurEntity? _utilisateur;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  AuthNotifier({
    required AuthenticationRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger {
    _initAuth();
  }

  UtilisateurEntity? get utilisateur => _utilisateur;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  // Alias pour compatibilité
  UtilisateurEntity? get currentUser => _utilisateur;

  // ==================== INITIALISATION ====================

  Future<void> _initAuth() async {
    try {
      
      _isAuthenticated = _repo.isAuthenticated;
      
      if (_isAuthenticated) {
        await _loadCachedUser();
      }
      
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur init auth: $e');
    }
  }

  Future<void> _loadCachedUser() async {
    try {
      final result = await _repo.getCachedUtilisateur();
      result.fold(
        (failure) => _utilisateur = null,
        (user) => _utilisateur = user,
      );
      notifyListeners();
    } catch (e) {
      _logger.e('Erreur chargement utilisateur: $e');
    }
  }

  // Méthode publique pour recharger l'utilisateur en cache
  Future<void> getCachedUser() async {
    await _loadCachedUser();
  }

  // ==================== INSCRIPTION ====================

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? tel,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.register(
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        tel: tel,
      );

      return result.fold(
        (failure) {
          _logger.e('Erreur inscription: ${failure.message}');
          _error = failure.message;
          _isAuthenticated = false;
          _utilisateur = null;
          return false;
        },
        (authEntity) {
          // Extraire l'utilisateur de AuthenticationEntity
          _utilisateur = UtilisateurEntity(
            id: authEntity.utilisateur.id,
            username: authEntity.utilisateur.username,
            email: authEntity.utilisateur.email,
            tel: authEntity.utilisateur.tel,
            dateCreation: authEntity.utilisateur.dateCreation,
            isActive: authEntity.utilisateur.isActive,
            nombreLieux: 0,
            nombreEvenements: 0,
          );
          _isAuthenticated = true;
          _error = null;
          _logger.i('Inscription réussie: ${_utilisateur!.username}');
          return true;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== CONNEXION ====================

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.i('Tentative de connexion pour: $email');
      final result = await _repo.login(
        email: email,
        password: password,
      );

      return result.fold(
        (failure) {
          _logger.e('Erreur connexion: ${failure.message}');
          _error = failure.message;
          _isAuthenticated = false;
          _utilisateur = null;
          return false;
        },
        (authEntity) {
          // Extraire l'utilisateur de AuthenticationEntity
          _utilisateur = UtilisateurEntity(
            id: authEntity.utilisateur.id,
            username: authEntity.utilisateur.username,
            email: authEntity.utilisateur.email,
            tel: authEntity.utilisateur.tel,
            dateCreation: authEntity.utilisateur.dateCreation,
            isActive: authEntity.utilisateur.isActive,
            nombreLieux: 0,
            nombreEvenements: 0,
          );
          _isAuthenticated = true;
          _error = null;
          _logger.i('Connexion réussie: ${_utilisateur!.username}');

          _logger.i('Token reçu: ${authEntity.token.substring(0, 20)}...');
        
        // VÉRIFIER que le token est dans SharedPreferences
        final prefs = GetIt.instance<SharedPreferences>();
        final savedToken = prefs.getString(LocalStorageKeys.token);
        _logger.i('Token dans SharedPreferences: ${savedToken != null ? "${savedToken.substring(0, 20)}..." : "NULL"}');
        
        // VÉRIFIER que RemoteDataSource a le token (avec la nouvelle méthode)
        final remoteDs = GetIt.instance<RemoteDataSource>();
        final hasToken = remoteDs.hasToken();
        final token = remoteDs.getToken();
        _logger.i('RemoteDataSource.hasToken(): $hasToken');
        if (token != null) {
          _logger.i('RemoteDataSource.getToken(): ${token.substring(0, 20)}...');
        }
          return true;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== DÉCONNEXION ====================

  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.logout();

      // Que l'API réussisse ou échoue, on nettoie l'état local
      _utilisateur = null;
      _isAuthenticated = false;
      _error = null;
      
      result.fold(
        (failure) {
          _logger.w('Erreur déconnexion API (ignorée): ${failure.message}');
        },
        (_) {
          _logger.i('Déconnexion réussie');
        },
      );
    } catch (e) {
      // Même en cas d'exception, on déconnecte l'utilisateur
      _logger.w('Exception déconnexion (ignorée): $e');
      _utilisateur = null;
      _isAuthenticated = false;
      _error = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== PROFIL ====================

  Future<void> refreshProfile() async {
    if (!_isAuthenticated) {
      _logger.w('Tentative de refresh sans authentification');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getProfile();

      result.fold(
        (failure) {
          _logger.e('Erreur profil: ${failure.message}');
          _error = failure.message;
        },
        (user) {
          _utilisateur = user;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== VÉRIFICATION ====================

  Future<void> checkAuthentication() async {
    try {
      _isAuthenticated = _repo.isAuthenticated;

      if (_isAuthenticated) {
        await _loadCachedUser();
      } else {
        _utilisateur = null;
      }

      notifyListeners();
    } catch (e) {
      _logger.e('Erreur vérification: $e');
      _isAuthenticated = false;
      _utilisateur = null;
      notifyListeners();
    }
  }

  /// Réinitialiser les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }

}