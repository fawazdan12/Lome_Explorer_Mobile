import 'dart:async';
import 'package:event_flow/config/websocket_config.dart';
import 'package:event_flow/core/services/websocket_service.dart';
import 'package:event_flow/domains/entities/websocket_entity.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Provider pour gérer les notifications WebSocket
class NotificationProvider extends ChangeNotifier {
  final WebSocketService _service;
  final Logger _logger;

  // État de connexion
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;

  // Liste des notifications reçues
  final List<WebSocketNotificationEntity> _notifications = [];

  // Compteur de notifications non lues
  int _unreadCount = 0;

  // Subscriptions
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _errorSubscription;

  // Dernière erreur
  String? _lastError;

  NotificationProvider({
    required WebSocketService service,
    required Logger logger,
  })  : _service = service,
        _logger = logger {
    _init();
  }

  // ==================== GETTERS ====================

  WebSocketConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState.isConnected;
  List<WebSocketNotificationEntity> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  String? get lastError => _lastError;

  // Filtrer les notifications par type
  List<WebSocketNotificationEntity> get eventNotifications =>
      _notifications.where((n) => WebSocketConfig.isEventNotification(n.type)).toList();

  List<WebSocketNotificationEntity> get placeNotifications =>
      _notifications.where((n) => WebSocketConfig.isPlaceNotification(n.type)).toList();

  List<WebSocketNotificationEntity> get personalNotifications =>
      _notifications.where((n) => WebSocketConfig.isPersonalNotification(n.type)).toList();

  // ==================== INITIALISATION ====================

  void _init() {
    // Écouter l'état de connexion
    _connectionStateSubscription = _service.connectionStateStream.listen((state) {
      _connectionState = state;
      _logger.d('État connexion: ${state.description}');
      notifyListeners();
    });

    // Écouter les notifications
    _notificationSubscription = _service.allNotifications.listen((notification) {
      _handleNotification(notification);
    });

    // Écouter les erreurs
    _errorSubscription = _service.errors.listen((error) {
      _lastError = error;
      _logger.e('Erreur WebSocket: $error');
      notifyListeners();
    });
  }

  void _handleNotification(WebSocketNotificationEntity notification) {
    _notifications.insert(0, notification); // Ajouter au début
    _unreadCount++;

    // Limiter à 100 notifications en mémoire
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }

    _logger.i('Nouvelle notification: ${notification.type}');
    notifyListeners();
  }

  // ==================== CONNEXION ====================

  Future<void> connectToGeneral() async {
    await _service.connectToGeneralNotifications();
  }

  Future<void> connectToPersonal(String token) async {
    await _service.connectToPersonalNotifications(token);
  }

  Future<void> connectToLocation({
    required double latitude,
    required double longitude,
    int radius = 10,
  }) async {
    await _service.connectToLocationNotifications(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  Future<void> disconnect() async {
    await _service.disconnect();
  }

  Future<void> reconnect() async {
    await _service.reconnect();
  }

  // ==================== ABONNEMENTS ====================

  void subscribeToLocation({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) {
    _service.subscribeToLocationEvents(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  void subscribeToCategories(List<String> categories) {
    _service.subscribeToCategories(categories);
  }

  // ==================== GESTION DES NOTIFICATIONS ====================

  /// Marquer une notification comme lue
  void markAsRead(WebSocketNotificationEntity notification) {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  /// Marquer toutes les notifications comme lues
  void markAllAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// Effacer toutes les notifications
  void clearAllNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  /// Effacer une notification spécifique
  void removeNotification(WebSocketNotificationEntity notification) {
    _notifications.remove(notification);
    if (_unreadCount > 0) {
      _unreadCount--;
    }
    notifyListeners();
  }

  /// Effacer l'erreur
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // ==================== NETTOYAGE ====================

  @override
  void dispose() {
    _logger.i('Nettoyage NotificationProvider');

    _connectionStateSubscription?.cancel();
    _notificationSubscription?.cancel();
    _errorSubscription?.cancel();

    _service.dispose();

    super.dispose();
  }
}