import 'dart:async';
import 'dart:convert';
import 'package:event_flow/config/websocket_config.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// DataSource pour gérer les connexions WebSocket
class WebSocketDataSource {
  final Logger _logger;
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  int _reconnectAttempts = 0;
  String? _currentEndpoint;
  
  // StreamControllers pour broadcaster les événements
  final _connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  WebSocketDataSource({required Logger logger}) : _logger = logger;

  // ==================== GETTERS ====================
  
  WebSocketConnectionState get connectionState => _connectionState;
  Stream<WebSocketConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;

  // ==================== CONNEXION ====================

  /// Se connecter à un endpoint WebSocket
  Future<void> connect(String endpoint, {String? token}) async {
    if (_connectionState == WebSocketConnectionState.connected) {
      _logger.w('WebSocket déjà connecté à $_currentEndpoint');
      return;
    }

    _currentEndpoint = endpoint;
    _updateConnectionState(WebSocketConnectionState.connecting);
    
    try {
      _logger.i('🔌 Connexion WebSocket à $endpoint');
      
      // Parser l'URL et s'assurer que le scheme est bien 'ws' ou 'wss'
      Uri wsUri = Uri.parse(endpoint);
      
      // Vérifier et forcer le scheme WebSocket
      if (wsUri.scheme != 'ws' && wsUri.scheme != 'wss') {
        _logger.e('❌ Scheme invalide: ${wsUri.scheme}');
        throw Exception('URL doit commencer par ws:// ou wss://');
      }
      
      // Ajouter le token si fourni (pour les notifications personnelles)
      if (token != null) {
        wsUri = wsUri.replace(queryParameters: {'token': token});
      }
      
      _logger.d('📍 URI finale: $wsUri');
      _logger.d('📍 Scheme: ${wsUri.scheme}');
      _logger.d('📍 Host: ${wsUri.host}');
      _logger.d('📍 Port: ${wsUri.port}');
      _logger.d('📍 Path: ${wsUri.path}');
      
      // Créer le WebSocketChannel avec l'URI correcte
      _channel = WebSocketChannel.connect(wsUri);
      
      // Attendre que la connexion soit établie
      await _channel!.ready.timeout(
        WebSocketConfig.connectionTimeout,
        onTimeout: () {
          throw TimeoutException('Connexion WebSocket timeout après ${WebSocketConfig.connectionTimeout.inSeconds}s');
        },
      );
      
      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      
      _logger.i('✅ WebSocket connecté avec succès');
      
      // Écouter les messages
      _listenToMessages();
      
      // Démarrer le ping automatique
      _startPingTimer();
      
    } on TimeoutException catch (e) {
      _logger.e('⏱️ Timeout connexion WebSocket: $e');
      _updateConnectionState(WebSocketConnectionState.error);
      _errorController.add('Timeout de connexion: ${e.message}');
      _scheduleReconnect();
    } on WebSocketChannelException catch (e) {
      _logger.e('❌ Erreur WebSocketChannel: $e');
      _updateConnectionState(WebSocketConnectionState.error);
      _errorController.add('Erreur WebSocket: ${e.message}');
      _scheduleReconnect();
    } catch (e, stackTrace) {
      _logger.e('❌ Erreur connexion WebSocket: $e');
      _logger.e('❌ Stack trace: $stackTrace');
      _updateConnectionState(WebSocketConnectionState.error);
      _errorController.add('Erreur de connexion: $e');
      _scheduleReconnect();
    }
  }

  /// Écouter les messages du WebSocket
  void _listenToMessages() {
    _subscription?.cancel(); // Annuler l'ancienne subscription
    
    _subscription = _channel?.stream.listen(
      (dynamic message) {
        try {
          _logger.d('📦 Message brut reçu: $message'); // ✅ LOG BRUT
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _logger.d('📩 Message WebSocket reçu: ${data['type']}');
          _logger.d('📩 Contenu complet: $data'); // ✅ LOG COMPLET
          _messageController.add(data);
          
          // Répondre aux pings
          if (data['type'] == WebSocketConfig.pingMessage) {
            sendMessage({'type': WebSocketConfig.pongMessage});
          }
        } catch (e) {
          _logger.e('❌ Erreur parsing message WebSocket: $e');
          _errorController.add('Erreur de parsing: $e');
        }
      },
      onError: (error) {
        _logger.e('❌ Erreur WebSocket stream: $error');
        _updateConnectionState(WebSocketConnectionState.error);
        _errorController.add('Erreur de stream: $error');
        _scheduleReconnect();
      },
      onDone: () {
        _logger.w('⚠️ WebSocket fermé par le serveur');
        _updateConnectionState(WebSocketConnectionState.disconnected);
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  /// Démarrer le timer de ping pour maintenir la connexion active
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(WebSocketConfig.pingInterval, (_) {
      if (isConnected) {
        sendMessage({'type': WebSocketConfig.pingMessage});
        _logger.d('📤 Ping envoyé');
      }
    });
  }

  // ==================== DÉCONNEXION ====================

  /// Se déconnecter du WebSocket
  Future<void> disconnect() async {
    _logger.i('🔌 Déconnexion WebSocket');
    
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _currentEndpoint = null;
    _reconnectAttempts = 0;
    
    _logger.i('✅ WebSocket déconnecté');
  }

  // ==================== RECONNEXION ====================

  /// Planifier une tentative de reconnexion
  void _scheduleReconnect() {
    if (_reconnectAttempts >= WebSocketConfig.maxReconnectAttempts) {
      _logger.e('❌ Nombre maximum de tentatives de reconnexion atteint');
      _updateConnectionState(WebSocketConnectionState.error);
      _errorController.add('Impossible de se reconnecter après ${WebSocketConfig.maxReconnectAttempts} tentatives');
      return;
    }

    _reconnectAttempts++;
    final delay = WebSocketConfig.reconnectDelay(_reconnectAttempts);
    
    _logger.w('🔄 Tentative de reconnexion $_reconnectAttempts/${WebSocketConfig.maxReconnectAttempts} dans ${delay.inSeconds}s');
    _updateConnectionState(WebSocketConnectionState.reconnecting);
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_currentEndpoint != null) {
        connect(_currentEndpoint!);
      }
    });
  }

  /// Forcer une reconnexion immédiate
  Future<void> reconnect() async {
    _logger.i('🔄 Reconnexion manuelle');
    _reconnectAttempts = 0;
    
    if (_currentEndpoint != null) {
      await disconnect();
      await connect(_currentEndpoint!);
    } else {
      _logger.w('⚠️ Aucun endpoint enregistré pour la reconnexion');
    }
  }

  // ==================== ENVOI DE MESSAGES ====================

  /// Envoyer un message au serveur WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (!isConnected) {
      _logger.w('⚠️ Tentative d\'envoi de message alors que WebSocket n\'est pas connecté');
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel?.sink.add(jsonMessage);
      _logger.d('📤 Message envoyé: ${message['type']}');
    } catch (e) {
      _logger.e('❌ Erreur envoi message WebSocket: $e');
      _errorController.add('Erreur d\'envoi: $e');
    }
  }

  // ==================== ABONNEMENTS ====================

  /// S'abonner aux événements d'une localisation
  void subscribeToLocation({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) {
    sendMessage({
      'type': WebSocketConfig.subscribeLocation,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    });
    _logger.i('📍 Abonnement localisation: ($latitude, $longitude) - ${radius}km');
  }

  /// S'abonner aux événements de catégories spécifiques
  void subscribeToCategories(List<String> categories) {
    sendMessage({
      'type': WebSocketConfig.subscribeCategory,
      'categories': categories,
    });
    _logger.i('🏷️ Abonnement catégories: ${categories.join(', ')}');
  }

  // ==================== HELPERS PRIVÉS ====================

  /// Mettre à jour l'état de connexion
  void _updateConnectionState(WebSocketConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
      _logger.d('🔄 État WebSocket: ${state.description}');
    }
  }

  // ==================== NETTOYAGE ====================

  /// Nettoyer les ressources
  Future<void> dispose() async {
    _logger.i('🧹 Nettoyage WebSocketDataSource');
    
    await disconnect();
    
    await _connectionStateController.close();
    await _messageController.close();
    await _errorController.close();
    
    _logger.i('✅ WebSocketDataSource nettoyé');
  }
}