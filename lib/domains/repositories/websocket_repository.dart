import 'package:dartz/dartz.dart';
import 'package:event_flow/config/websocket_config.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/websocket_entity.dart';

/// Contrat du repository WebSocket
abstract class WebSocketRepository {
  // ==================== CONNEXION ====================

  /// Se connecter au WebSocket général des événements
  Future<Either<Failure, void>> connectToEvents();

  /// Se connecter au WebSocket personnel (nécessite authentification)
  Future<Either<Failure, void>> connectToPersonal(String token);

  /// Se connecter au WebSocket basé sur la localisation
  Future<Either<Failure, void>> connectToLocation({
    required double latitude,
    required double longitude,
    int radius = 10,
  });

  /// Se déconnecter
  Future<Either<Failure, void>> disconnect();

  /// Reconnecter
  Future<Either<Failure, void>> reconnect();

  // ==================== ÉTAT ====================

  /// Obtenir l'état actuel de connexion
  WebSocketConnectionState get connectionState;

  /// Stream de l'état de connexion
  Stream<WebSocketConnectionState> get connectionStateStream;

  /// Vérifier si connecté
  bool get isConnected;

  // ==================== NOTIFICATIONS ====================

  /// Stream de toutes les notifications
  Stream<WebSocketNotificationEntity> get notificationStream;

  /// Stream des notifications d'événements
  Stream<WebSocketNotificationEntity> get eventNotificationStream;

  /// Stream des notifications de lieux
  Stream<WebSocketNotificationEntity> get placeNotificationStream;

  /// Stream des notifications personnelles
  Stream<WebSocketNotificationEntity> get personalNotificationStream;

  /// Stream des erreurs
  Stream<String> get errorStream;

  // ==================== ABONNEMENTS ====================

  /// S'abonner aux notifications d'une localisation
  Either<Failure, void> subscribeToLocation({
    required double latitude,
    required double longitude,
    double radius = 10,
  });

  /// S'abonner aux notifications de catégories
  Either<Failure, void> subscribeToCategories(List<String> categories);

  // ==================== NETTOYAGE ====================

  /// Nettoyer les ressources
  Future<void> dispose();
}