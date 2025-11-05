import 'package:event_flow/config/websocket_config.dart';
import 'package:event_flow/domains/entities/websocket_entity.dart';
import 'package:event_flow/domains/repositories/websocket_repository.dart';
import 'package:logger/logger.dart';

/// Service métier pour gérer les WebSockets
class WebSocketService {
  final WebSocketRepository _repository;
  final Logger _logger;

  WebSocketService({
    required WebSocketRepository repository,
    required Logger logger,
  })  : _repository = repository,
        _logger = logger;

  // ==================== CONNEXION ====================

  /// Se connecter aux notifications générales
  Future<void> connectToGeneralNotifications() async {
    try {
      _logger.i('🔌 Connexion aux notifications générales');
      final result = await _repository.connectToEvents();

      result.fold(
        (failure) => _logger.e('❌ Erreur connexion: ${failure.message}'),
        (_) => _logger.i('✅ Connecté aux notifications générales'),
      );
    } catch (e) {
      _logger.e('❌ Erreur: $e');
    }
  }

  /// Se connecter aux notifications personnelles
  Future<void> connectToPersonalNotifications(String token) async {
    try {
      _logger.i('🔌 Connexion aux notifications personnelles');
      final result = await _repository.connectToPersonal(token);

      result.fold(
        (failure) => _logger.e('❌ Erreur connexion: ${failure.message}'),
        (_) => _logger.i('✅ Connecté aux notifications personnelles'),
      );
    } catch (e) {
      _logger.e('❌ Erreur: $e');
    }
  }

  /// Se connecter aux notifications basées sur la localisation
  Future<void> connectToLocationNotifications({
    required double latitude,
    required double longitude,
    int radius = 10,
  }) async {
    try {
      _logger.i('🔌 Connexion aux notifications de localisation');
      final result = await _repository.connectToLocation(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      result.fold(
        (failure) => _logger.e('❌ Erreur connexion: ${failure.message}'),
        (_) => _logger.i('✅ Connecté aux notifications de localisation'),
      );
    } catch (e) {
      _logger.e('❌ Erreur: $e');
    }
  }

  /// Se déconnecter
  Future<void> disconnect() async {
    try {
      _logger.i('🔌 Déconnexion WebSocket');
      final result = await _repository.disconnect();

      result.fold(
        (failure) => _logger.e('❌ Erreur déconnexion: ${failure.message}'),
        (_) => _logger.i('✅ Déconnecté'),
      );
    } catch (e) {
      _logger.e('❌ Erreur: $e');
    }
  }

  /// Reconnecter
  Future<void> reconnect() async {
    try {
      _logger.i('🔄 Reconnexion WebSocket');
      final result = await _repository.reconnect();

      result.fold(
        (failure) => _logger.e('❌ Erreur reconnexion: ${failure.message}'),
        (_) => _logger.i('✅ Reconnecté'),
      );
    } catch (e) {
      _logger.e('❌ Erreur: $e');
    }
  }

  // ==================== ABONNEMENTS ====================

  /// S'abonner aux événements d'une zone
  void subscribeToLocationEvents({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) {
    final result = _repository.subscribeToLocation(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    result.fold(
      (failure) => _logger.e('❌ Erreur abonnement: ${failure.message}'),
      (_) => _logger.i('✅ Abonné à la zone ($latitude, $longitude)'),
    );
  }

  /// S'abonner aux événements de catégories
  void subscribeToCategories(List<String> categories) {
    final result = _repository.subscribeToCategories(categories);

    result.fold(
      (failure) => _logger.e('❌ Erreur abonnement: ${failure.message}'),
      (_) => _logger.i('✅ Abonné aux catégories: ${categories.join(', ')}'),
    );
  }

  // ==================== ÉTAT ====================

  WebSocketConnectionState get connectionState => _repository.connectionState;
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _repository.connectionStateStream;
  bool get isConnected => _repository.isConnected;

  // ==================== NOTIFICATIONS ====================

  Stream<WebSocketNotificationEntity> get allNotifications =>
      _repository.notificationStream;

  Stream<WebSocketNotificationEntity> get eventNotifications =>
      _repository.eventNotificationStream;

  Stream<WebSocketNotificationEntity> get placeNotifications =>
      _repository.placeNotificationStream;

  Stream<WebSocketNotificationEntity> get personalNotifications =>
      _repository.personalNotificationStream;

  Stream<String> get errors => _repository.errorStream;

  // ==================== NETTOYAGE ====================

  Future<void> dispose() async {
    await _repository.dispose();
  }
}