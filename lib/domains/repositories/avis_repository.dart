import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/avis_lieu_evenement_entity.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';


/// Contrat du repository pour les avis
abstract class AvisRepository {
  // ==================== AVIS LIEUX ====================

  /// Obtenir tous les avis d'un lieu
  Future<Either<Failure, List<AvisLieuEntity>>> getAvisLieu(String lieuId);

  /// Créer un avis pour un lieu
  Future<Either<Failure, AvisLieuEntity>> createAvisLieu({
    required String lieuId,
    required int note,
    required String texte,
  });

  /// Modifier un avis de lieu
  Future<Either<Failure, AvisLieuEntity>> updateAvisLieu({
    required String avisId,
    required int note,
    required String texte,
  });

  /// Supprimer un avis de lieu
  Future<Either<Failure, void>> deleteAvisLieu(String avisId);

  // ==================== AVIS ÉVÉNEMENTS ====================

  /// Obtenir tous les avis d'un événement
  Future<Either<Failure, List<AvisEvenementEntity>>> getAvisEvenement(
    String evenementId,
  );

  /// Créer un avis pour un événement
  Future<Either<Failure, AvisEvenementEntity>> createAvisEvenement({
    required String evenementId,
    required int note,
    required String texte,
  });

  /// Modifier un avis d'événement
  Future<Either<Failure, AvisEvenementEntity>> updateAvisEvenement({
    required String avisId,
    required int note,
    required String texte,
  });

  /// Supprimer un avis d'événement
  Future<Either<Failure, void>> deleteAvisEvenement(String avisId);
}