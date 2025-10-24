import 'package:event_flow/data/datasource/remote/api_datasource_remote.dart';
import 'package:event_flow/data/models/avis_lieu_event_geo_model.dart';
import 'package:logger/logger.dart';

class AvisService {
  final RemoteDataSource _remoteDataSource;
  final Logger _logger;

  AvisService({
    required RemoteDataSource remoteDataSource,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _logger = logger;

  // ==================== AVIS LIEUX ====================

  Future<List<AvisLieuModel>> getAvisLieu(String lieuId) async {
    try {
      _logger.i('Récupération des avis du lieu: $lieuId');

      final avis = await _remoteDataSource.getAvisLieu(lieuId);

      _logger.i('${avis.length} avis récupérés');
      return avis;
    } catch (e) {
      _logger.e('Erreur récupération avis lieu: $e');
      rethrow;
    }
  }

  Future<AvisLieuModel> createAvisLieu({
    required String lieuId,
    required int note,
    required String texte,
  }) async {
    try {
      _logger.i('Création d\'un avis pour le lieu: $lieuId');

      final avis = await _remoteDataSource.createAvisLieu(
        lieuId: lieuId,
        note: note,
        texte: texte,
      );

      _logger.i('Avis créé avec succès');
      return avis;
    } catch (e) {
      _logger.e('Erreur création avis lieu: $e');
      rethrow;
    }
  }

  Future<AvisLieuModel> updateAvisLieu({
    required String avisId,
    required int note,
    required String texte,
  }) async {
    try {
      _logger.i('Modification de l\'avis: $avisId');

      final avis = await _remoteDataSource.updateAvisLieu(
        avisId: avisId,
        note: note,
        texte: texte,
      );

      _logger.i('Avis modifié');
      return avis;
    } catch (e) {
      _logger.e('Erreur modification avis: $e');
      rethrow;
    }
  }

  Future<void> deleteAvisLieu(String avisId) async {
    try {
      _logger.i('Suppression de l\'avis: $avisId');

      await _remoteDataSource.deleteAvisLieu(avisId);

      _logger.i('Avis supprimé');
    } catch (e) {
      _logger.e('Erreur suppression avis: $e');
      rethrow;
    }
  }

  // ==================== AVIS ÉVÉNEMENTS ====================

  Future<List<AvisEvenementModel>> getAvisEvenement(String evenementId) async {
    try {
      _logger.i('Récupération des avis de l\'événement: $evenementId');

      final avis = await _remoteDataSource.getAvisEvenement(evenementId);

      _logger.i('${avis.length} avis récupérés');
      return avis;
    } catch (e) {
      _logger.e('Erreur récupération avis événement: $e');
      rethrow;
    }
  }

  Future<AvisEvenementModel> createAvisEvenement({
    required String evenementId,
    required int note,
    required String texte,
  }) async {
    try {
      _logger.i('Création d\'un avis pour l\'événement: $evenementId');

      final avis = await _remoteDataSource.createAvisEvenement(
        evenementId: evenementId,
        note: note,
        texte: texte,
      );

      _logger.i('Avis créé avec succès');
      return avis;
    } catch (e) {
      _logger.e('Erreur création avis événement: $e');
      rethrow;
    }
  }

  Future<AvisEvenementModel> updateAvisEvenement({
    required String avisId,
    required int note,
    required String texte,
  }) async {
    try {
      _logger.i('Modification de l\'avis: $avisId');

      final avis = await _remoteDataSource.updateAvisEvenement(
        avisId: avisId,
        note: note,
        texte: texte,
      );

      _logger.i('Avis modifié');
      return avis;
    } catch (e) {
      _logger.e('Erreur modification avis: $e');
      rethrow;
    }
  }

  Future<void> deleteAvisEvenement(String avisId) async {
    try {
      _logger.i('Suppression de l\'avis: $avisId');

      await _remoteDataSource.deleteAvisEvenement(avisId);

      _logger.i('Avis supprimé');
    } catch (e) {
      _logger.e('Erreur suppression avis: $e');
      rethrow;
    }
  }
}