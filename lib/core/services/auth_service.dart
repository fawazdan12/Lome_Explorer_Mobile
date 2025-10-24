import 'package:event_flow/config/app_config.dart';
import 'package:event_flow/data/datasource/local/cache_hive_datasource.dart';
import 'package:event_flow/data/datasource/remote/api_datasource_remote.dart';
import 'package:event_flow/data/models/utilisateur_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  final SharedPreferences _preferences;
  final Logger _logger;

  AuthenticationService({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
    required SharedPreferences preferences,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _preferences = preferences,
       _logger = logger {
    // ✅ CORRECTION : Initialiser le token au démarrage
    initializeTokenFromCache();
  }

  /// Vérifier si l'utilisateur est connecté
  bool get isAuthenticated {
    return _preferences.containsKey(LocalStorageKeys.token) &&
        _preferences.getString(LocalStorageKeys.token)?.isNotEmpty == true;
  }

  /// Obtenir le token actuel
  String? get token {
    return _preferences.getString(LocalStorageKeys.token);
  }

  /// Enregistrer un nouvel utilisateur
  Future<AuthenticationModel> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? tel,
  }) async {
    try {
      _logger.i('Inscription en cours pour: $email');

      final auth = await _remoteDataSource.register(
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        tel: tel,
      );

      // Sauvegarder le token et les données
      await _saveAuthData(auth);

      _logger.i('✅ Inscription réussie pour: $email');
      _logger.i('✅ Token sauvegardé: ${auth.token.substring(0, 20)}...');

      return auth;
    } catch (e) {
      _logger.e('Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  /// Connecter un utilisateur
  Future<AuthenticationModel> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Connexion en cours pour: $email');

      final auth = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      _logger.i('📥 Token reçu de l\'API: ${auth.token}');
      _logger.i('📏 Longueur du token: ${auth.token.length}');

      if (auth.token.isEmpty) {
        _logger.e('❌ ERREUR : Token vide reçu de l\'API !');
        throw Exception('Token vide reçu du serveur');
      }

      // Sauvegarder le token et les données
      await _saveAuthData(auth);

      _logger.i('✅ Connexion réussie pour: $email');

      return auth;
    } catch (e) {
      _logger.e('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// Déconnecter l'utilisateur
  Future<void> logout() async {
    try {
      _logger.i('Déconnexion en cours');

      // 1. Appeler l'API de déconnexion AVEC le token
      try {
        await _remoteDataSource.logout();
        _logger.i('API de déconnexion appelée avec succès');
      } catch (e) {
        _logger.w('Erreur API lors de la déconnexion (continuant...): $e');
      }

      // 2. Nettoyer les données locales
      await _clearAuthData();

      _logger.i('Déconnexion réussie');
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion: $e');
      // En cas d'erreur, nettoyer quand même les données locales
      await _clearAuthData();
      rethrow;
    }
  }

  /// Obtenir le profil de l'utilisateur connecté
  Future<UtilisateurModel> getProfile() async {
    try {
      _logger.i('Récupération du profil');

      final utilisateur = await _remoteDataSource.getProfile();

      // Mettre en cache
      await _localDataSource.cacheUtilisateur(utilisateur);

      _logger.i('Profil récupéré: ${utilisateur.username}');
      return utilisateur;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du profil: $e');
      rethrow;
    }
  }

  /// Obtenir l'utilisateur en cache
  Future<UtilisateurModel?> getCachedUtilisateur() async {
    try {
      return await _localDataSource.getCachedUtilisateur();
    } catch (e) {
      _logger.e('Erreur lors de la lecture du cache utilisateur: $e');
      return null;
    }
  }

  // ==================== HELPERS PRIVÉS ====================

  /// Sauvegarder les données d'authentification
  Future<void> _saveAuthData(AuthenticationModel auth) async {
    try {
      _logger.d('💾 Sauvegarde des données d\'authentification...');

      // 1. Sauvegarder le token dans SharedPreferences
      await _preferences.setString(LocalStorageKeys.token, auth.token);
      _logger.d('✅ Token sauvegardé dans SharedPreferences');

      // 2. ⚠️ CRITIQUE : Mettre à jour RemoteDataSource avec le token
      _remoteDataSource.setToken(auth.token);
      _logger.d('✅ Token défini dans RemoteDataSource');

      // 3. Mettre en cache l'utilisateur
      await _localDataSource.cacheUtilisateur(auth.utilisateur);
      _logger.d('✅ Utilisateur mis en cache');

      // 4. Marquer comme connecté
      await _preferences.setBool(LocalStorageKeys.isLoggedIn, true);
      _logger.d('✅ Marqué comme connecté');

      _logger.i('✅ Données d\'authentification sauvegardées avec succès');
    } catch (e) {
      _logger.e('❌ Erreur lors de la sauvegarde des données auth: $e');
      rethrow;
    }
  }

  /// Nettoyer les données d'authentification
  Future<void> _clearAuthData() async {
    try {
      _logger.d('🧹 Nettoyage des données d\'authentification...');

      // 1. Nettoyer SharedPreferences
      await _preferences.remove(LocalStorageKeys.token);
      await _preferences.remove(LocalStorageKeys.isLoggedIn);
      await _preferences.remove(LocalStorageKeys.utilisateur);
      _logger.d('✅ SharedPreferences nettoyé');

      // 2. Nettoyer le token dans RemoteDataSource
      _remoteDataSource.clearToken();
      _logger.d('✅ Token nettoyé dans RemoteDataSource');

      // 3. Nettoyer le cache Hive
      await _localDataSource.clearUtilisateur();
      _logger.d('✅ Cache Hive nettoyé');

      _logger.i('✅ Données d\'authentification nettoyées');
    } catch (e) {
      _logger.e('❌ Erreur lors du nettoyage des données auth: $e');
    }
  }

  /// Initialiser le token depuis le cache au démarrage
  void initializeTokenFromCache() {
    try {
      final token = _preferences.getString(LocalStorageKeys.token);
      if (token != null && token.isNotEmpty) {
        _remoteDataSource.setToken(token);
        _logger.i(
          '✅ Token initialisé depuis le cache: ${token.substring(0, 20)}...',
        );
      } else {
        _logger.w('⚠️ Aucun token trouvé dans le cache');
      }
    } catch (e) {
      _logger.e('❌ Erreur lors de l\'initialisation du token: $e');
    }
  }
}
