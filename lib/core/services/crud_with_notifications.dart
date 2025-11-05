import 'package:event_flow/core/providers/notification_provider.dart';
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/data/models/lieu_evenement_model.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

/// Service wrapper qui déclenche les notifications WebSocket
/// après chaque opération CRUD
class CrudWithNotifications {
  final LieuEvenementService _service;
  final Logger _logger;

  CrudWithNotifications({
    required LieuEvenementService service,
    required Logger logger,
  })  : _service = service,
        _logger = logger;

  // ==================== LIEUX ====================

  /// Créer un lieu avec notification
  Future<LieuModel> createLieu({
    required BuildContext context,
    required String nom,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
  }) async {
    _logger.i('🏗️ Création lieu avec notifications: $nom');

    // 1. Créer le lieu
    final lieu = await _service.createLieu(
      nom: nom,
      description: description,
      categorie: categorie,
      latitude: latitude,
      longitude: longitude,
    );

    // 2. Déclencher la notification (le serveur Django s'en charge)
    _logger.i('✅ Lieu créé, notification envoyée par Django');
    
    // 3. Vérifier la connexion WebSocket
    if (context.mounted) {
      final notifProvider = context.read<NotificationProvider>();
      if (!notifProvider.isConnected) {
        _logger.w('⚠️ WebSocket non connecté, connexion...');
        await notifProvider.connectToGeneral();
      }
    }

    return lieu;
  }

  /// Modifier un lieu avec notification
  Future<LieuModel> updateLieu({
    required BuildContext context,
    required String id,
    required String nom,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
  }) async {
    _logger.i('✏️ Modification lieu avec notifications: $nom');

    final lieu = await _service.updateLieu(
      id: id,
      nom: nom,
      description: description,
      categorie: categorie,
      latitude: latitude,
      longitude: longitude,
    );

    _logger.i('✅ Lieu modifié, notification envoyée par Django');
    return lieu;
  }

  /// Supprimer un lieu avec notification
  Future<void> deleteLieu({
    required BuildContext context,
    required String id,
  }) async {
    _logger.i('🗑️ Suppression lieu avec notifications: $id');

    await _service.deleteLieu(id);

    _logger.i('✅ Lieu supprimé, notification envoyée par Django');
  }

  // ==================== ÉVÉNEMENTS ====================

  /// Créer un événement avec notification
  Future<EvenementModel> createEvenement({
    required BuildContext context,
    required String nom,
    required String description,
    required DateTime dateDebut,  
    required DateTime dateFin,
    required String lieuId,
  }) async {
    _logger.i('🏗️ Création événement avec notifications: $nom');

    final evenement = await _service.createEvenement(
      nom: nom,
      description: description,
      dateDebut: dateDebut,  
      dateFin: dateFin,
      lieuId: lieuId,
    );

    _logger.i('✅ Événement créé, notification envoyée par Django');

    // Vérifier la connexion WebSocket
    if (context.mounted) {
      final notifProvider = context.read<NotificationProvider>();
      if (!notifProvider.isConnected) {
        await notifProvider.connectToGeneral();
      }
    }

    return evenement;
  }

  /// Modifier un événement avec notification
  Future<EvenementModel> updateEvenement({
    required BuildContext context,
    required String id,
    required String nom,
    required String description,
    required DateTime dateDebut,
    required DateTime dateFin,
    required String lieuId,
  }) async {
    _logger.i('✏️ Modification événement avec notifications: $nom');

    final evenement = await _service.updateEvenement(
      id: id,
      nom: nom,
      description: description,
      dateDebut: dateDebut,  
      dateFin: dateFin,
      lieuId: lieuId,
    );

    _logger.i('✅ Événement modifié, notification envoyée par Django');
    return evenement;
  }

  /// Supprimer un événement avec notification
  Future<void> deleteEvenement({
    required BuildContext context,
    required String id,
  }) async {
    _logger.i('🗑️ Suppression événement avec notifications: $id');

    await _service.deleteEvenement(id);

    _logger.i('✅ Événement supprimé, notification envoyée par Django');
  }
}