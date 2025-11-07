import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:event_flow/config/api_execption.dart';
import 'package:event_flow/config/websocket_config.dart';
import 'package:event_flow/data/datasource/remote/websocket_datasource.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/websocket_entity.dart';
import 'package:event_flow/domains/repositories/websocket_repository.dart';
import 'package:logger/logger.dart';

class WebSocketRepositoryImpl implements WebSocketRepository {
  final WebSocketDataSource _dataSource;
  final Logger _logger;

  // StreamControllers pour les différents types de notifications
  final _notificationController =
      StreamController<WebSocketNotificationEntity>.broadcast();
  final _eventNotificationController =
      StreamController<WebSocketNotificationEntity>.broadcast();
  final _placeNotificationController =
      StreamController<WebSocketNotificationEntity>.broadcast();
  final _personalNotificationController =
      StreamController<WebSocketNotificationEntity>.broadcast();

  StreamSubscription? _messageSubscription;

  WebSocketRepositoryImpl({
    required WebSocketDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger {
    _listenToMessages();
  }

  // ==================== CONNEXION ====================

  @override
  Future<Either<Failure, void>> connectToEvents() async {
    try {
      await _dataSource.connect(WebSocketConfig.wsEvents);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> connectToPersonal(String token) async {
    try {
      await _dataSource.connect(WebSocketConfig.wsPersonal, token: token);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> connectToLocation({
    required double latitude,
    required double longitude,
    int radius = 10,
  }) async {
    try {
      final endpoint = WebSocketConfig.wsLocation(latitude, longitude, radius: radius);
      await _dataSource.connect(endpoint);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await _dataSource.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> reconnect() async {
    try {
      await _dataSource.reconnect();
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ==================== ÉTAT ====================

  @override
  WebSocketConnectionState get connectionState => _dataSource.connectionState;

  @override
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _dataSource.connectionStateStream;

  @override
  bool get isConnected => _dataSource.isConnected;

  // ==================== NOTIFICATIONS ====================

  @override
  Stream<WebSocketNotificationEntity> get notificationStream =>
      _notificationController.stream;

  @override
  Stream<WebSocketNotificationEntity> get eventNotificationStream =>
      _eventNotificationController.stream;

  @override
  Stream<WebSocketNotificationEntity> get placeNotificationStream =>
      _placeNotificationController.stream;

  @override
  Stream<WebSocketNotificationEntity> get personalNotificationStream =>
      _personalNotificationController.stream;

  @override
  Stream<String> get errorStream => _dataSource.errorStream;

  // ==================== ABONNEMENTS ====================

  @override
  Either<Failure, void> subscribeToLocation({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) {
    try {
      if (!isConnected) {
        return const Left(NetworkFailure('WebSocket non connecté'));
      }

      _dataSource.subscribeToLocation(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Either<Failure, void> subscribeToCategories(List<String> categories) {
    try {
      if (!isConnected) {
        return const Left(NetworkFailure('WebSocket non connecté'));
      }

      _dataSource.subscribeToCategories(categories);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ==================== ÉCOUTE DES MESSAGES ====================

  void _listenToMessages() {
    _messageSubscription = _dataSource.messageStream.listen((message) {
      _handleMessage(message);
    });
  }

  void _handleMessage(Map<String, dynamic> message) {
    try {
      final type = message['type'] as String?;

      _logger.d('Traitement message type: $type'); 

      // Ignorer les messages système (pong, connection_established, etc.)
      if (type == 'pong' ||
          type == 'connection_established' ||
          type == 'subscription_confirmed') {
        return;
      }

      // Parser les notifications
      final notification = WebSocketEntityFactory.fromJson(message);

      if (notification != null) {
        _logger.i('Notification parsée: $type'); 
        // Ajouter à tous les streams
        _notificationController.add(notification);

        // Dispatcher vers les streams spécifiques
        if (WebSocketConfig.isEventNotification(type!)) {
          _logger.i('Notification d\'événement détectée');
          _eventNotificationController.add(notification);
        } else if (WebSocketConfig.isPlaceNotification(type)) {
          _logger.i('Notification de lieu détectée');
          _placeNotificationController.add(notification);
        } else if (WebSocketConfig.isPersonalNotification(type)) {
          _logger.i('Notification personnelle détectée');
          _personalNotificationController.add(notification);
        }

        _logger.d('Notification traitée: $type');
      } else {
        _logger.w('Type de notification inconnu: $type');
      }
    } catch (e) {
      _logger.e('Erreur traitement message: $e');
    }
  }

  // ==================== NETTOYAGE ====================

  @override
  Future<void> dispose() async {
    _logger.i('Nettoyage WebSocketRepository');

    await _messageSubscription?.cancel();

    await _notificationController.close();
    await _eventNotificationController.close();
    await _placeNotificationController.close();
    await _personalNotificationController.close();

    await _dataSource.dispose();

    _logger.i('WebSocketRepository nettoyé');
  }

  // ==================== HELPERS ====================

  Failure _mapException(dynamic exception) {
    _logger.e('Erreur WebSocket: $exception');

    if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is TimeoutException) {
      return NetworkFailure('Timeout de connexion WebSocket');
    } else {
      return UnknownFailure(exception.toString());
    }
  }
}