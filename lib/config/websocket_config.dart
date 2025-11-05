/// Configuration pour les WebSockets
class WebSocketConfig {
  // ==================== ENDPOINTS WEBSOCKET ====================
  
  /// WebSocket pour les notifications générales d'événements
  static const String wsEvents = 'ws://10.0.2.2:8000/ws/events/';
  
  /// WebSocket pour les notifications personnelles (utilisateur authentifié)
  static const String wsPersonal = 'ws://10.0.2.2:8000/ws/personal/';
  
  /// WebSocket basé sur la localisation
  /// Usage: wsLocation(latitude, longitude, radius)
  static String wsLocation(double lat, double lng, {int radius = 10}) {
    return 'ws://10.0.2.2:8000/ws/location/$lat/$lng/$radius/';
  }

  // ==================== CONFIGURATION ====================
  
  /// Durée avant de considérer une connexion comme timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  
  /// Intervalle de ping pour maintenir la connexion active
  static const Duration pingInterval = Duration(seconds: 30);
  
  /// Nombre maximum de tentatives de reconnexion
  static const int maxReconnectAttempts = 5;
  
  /// Délai entre chaque tentative de reconnexion (progression exponentielle)
  static Duration reconnectDelay(int attempt) {
    // 2s, 4s, 8s, 16s, 32s
    return Duration(seconds: 2 * (1 << attempt.clamp(0, 5)));
  }

  // ==================== TYPES DE MESSAGES ====================
  
  /// Types de messages envoyés par le client
  static const String pingMessage = 'ping';
  static const String subscribeLocation = 'subscribe_location';
  static const String subscribeCategory = 'subscribe_category';
  
  /// Types de notifications reçues du serveur
  static const String pongMessage = 'pong';
  static const String connectionEstablished = 'connection_established';
  static const String subscriptionConfirmed = 'subscription_confirmed';
  
  // Événements
  static const String newEvent = 'new_event';
  static const String eventUpdated = 'event_updated';
  static const String eventCancelled = 'event_cancelled';
  static const String proximityEvent = 'proximity_event';
  static const String eventReminder = 'event_reminder';
  
  // Lieux
  static const String newPlace = 'new_place';
  
  // Notifications personnelles
  static const String personalNotification = 'personal_notification';
  static const String unreadNotifications = 'unread_notifications';
  
  // Erreurs
  static const String errorMessage = 'error';

  // ==================== HELPERS ====================
  
  /// Vérifier si un type de message est une notification d'événement
  static bool isEventNotification(String type) {
    return [
      newEvent,
      eventUpdated,
      eventCancelled,
      proximityEvent,
      eventReminder,
    ].contains(type);
  }
  
  /// Vérifier si un type de message est une notification de lieu
  static bool isPlaceNotification(String type) {
    return type == newPlace;
  }
  
  /// Vérifier si un type de message est une notification personnelle
  static bool isPersonalNotification(String type) {
    return [
      personalNotification,
      unreadNotifications,
    ].contains(type);
  }
}

/// États de connexion WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Extension pour obtenir une description lisible de l'état
extension WebSocketConnectionStateExtension on WebSocketConnectionState {
  String get description {
    switch (this) {
      case WebSocketConnectionState.disconnected:
        return 'Déconnecté';
      case WebSocketConnectionState.connecting:
        return 'Connexion...';
      case WebSocketConnectionState.connected:
        return 'Connecté';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnexion...';
      case WebSocketConnectionState.error:
        return 'Erreur de connexion';
    }
  }
  
  bool get isConnected => this == WebSocketConnectionState.connected;
  bool get canReconnect => this == WebSocketConnectionState.disconnected || 
                           this == WebSocketConnectionState.error;
}