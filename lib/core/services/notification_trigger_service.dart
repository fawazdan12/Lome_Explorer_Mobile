import 'package:event_flow/core/providers/notification_provider.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:logger/logger.dart';

/// Service pour déclencher automatiquement les connexions WebSocket
/// lors des opérations CRUD sur les entités
class NotificationTriggerService {
  final NotificationProvider _notificationProvider;
  final Logger _logger;

  NotificationTriggerService({
    required NotificationProvider notificationProvider,
    required Logger logger,
  })  : _notificationProvider = notificationProvider,
        _logger = logger;

  // ==================== INITIALISATION ====================

  /// Initialiser et connecter aux notifications générales
  Future<void> initialize() async {
    _logger.i('🔔 Initialisation des notifications automatiques');

    if (!_notificationProvider.isConnected) {
      await _notificationProvider.connectToGeneral();
      _logger.i('✅ Connecté aux notifications générales');
    }
  }

  // ==================== NOTIFICATIONS LIEU ====================

  /// Déclencher après création d'un lieu
  void onLieuCreated(LieuEntity lieu) {
    _logger.i('📍 Lieu créé: ${lieu.nom}');
    _ensureGeneralConnectionActive();
    // Le serveur Django enverra automatiquement la notification
    // via le signal post_save dans signals.py
  }

  /// Déclencher après modification d'un lieu
  void onLieuUpdated(LieuEntity lieu) {
    _logger.i('📍 Lieu modifié: ${lieu.nom}');
    _ensureGeneralConnectionActive();
    // Le serveur Django enverra automatiquement la notification
  }

  /// Déclencher après suppression d'un lieu
  void onLieuDeleted(String lieuId, String lieuNom) {
    _logger.i('📍 Lieu supprimé: $lieuNom');
    _ensureGeneralConnectionActive();
    // Le serveur Django enverra automatiquement la notification
  }

  // ==================== NOTIFICATIONS ÉVÉNEMENT ====================

  /// Déclencher après création d'un événement
  void onEvenementCreated(EvenementEntity evenement) {
    _logger.i('📅 Événement créé: ${evenement.nom}');
    _ensureGeneralConnectionActive();

    // Si géolocalisation disponible, s'abonner à la zone
    if (evenement.lieuLatitude != null && evenement.lieuLongitude != null) {
      _notificationProvider.subscribeToLocation(
        latitude: evenement.lieuLatitude!,
        longitude: evenement.lieuLongitude!,
        radius: 10,
      );
    }
  }

  /// Déclencher après modification d'un événement
  void onEvenementUpdated(EvenementEntity evenement) {
    _logger.i('📅 Événement modifié: ${evenement.nom}');
    _ensureGeneralConnectionActive();
  }

  /// Déclencher après suppression d'un événement
  void onEvenementDeleted(String evenementId, String evenementNom) {
    _logger.i('📅 Événement supprimé: $evenementNom');
    _ensureGeneralConnectionActive();
  }

  // ==================== NOTIFICATIONS AVIS ====================

  /// Déclencher après création d'un avis (propriétaire uniquement)
  void onAvisCreated({
    required String proprietaireId,
    required String entityNom,
    required int note,
  }) {
    _logger.i('⭐ Avis créé sur: $entityNom (Note: $note/5)');
    
    // Les avis sont envoyés au propriétaire via WebSocket personnel
    // Le serveur Django gère cela dans signals.py
    _ensurePersonalConnectionActive(proprietaireId);
  }

  // ==================== HELPERS PRIVÉS ====================

  /// Vérifier que la connexion générale est active
  void _ensureGeneralConnectionActive() {
    if (!_notificationProvider.isConnected) {
      _logger.w('⚠️ WebSocket non connecté, tentative de connexion...');
      _notificationProvider.connectToGeneral();
    }
  }

  /// Vérifier que la connexion personnelle est active (pour avis)
  void _ensurePersonalConnectionActive(String userId) {
    // Note: La connexion personnelle nécessite un token
    // Elle est gérée séparément dans les pages d'authentification
    _logger.d('🔐 Notification personnelle pour user: $userId');
  }

  /// Se connecter aux notifications basées sur la localisation
  Future<void> connectToLocationNotifications({
    required double latitude,
    required double longitude,
    int radius = 10,
  }) async {
    _logger.i('📍 Connexion aux notifications de localisation');
    await _notificationProvider.connectToLocation(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  /// Déconnecter proprement
  void dispose() {
    _logger.i('🧹 Nettoyage NotificationTriggerService');
  }
}