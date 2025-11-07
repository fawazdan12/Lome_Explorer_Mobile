import 'package:dartz/dartz.dart';
import 'package:event_flow/config/api_execption.dart';
import 'package:event_flow/core/services/avis_service.dart';
import 'package:event_flow/domains/entities/avis_lieu_evenement_entity.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/repositories/avis_repository.dart';
import 'package:logger/logger.dart';

class AvisRepositoryImpl implements AvisRepository {
  final AvisService _service;
  final Logger _logger;

  AvisRepositoryImpl({required AvisService service, required Logger logger})
    : _service = service,
      _logger = logger;

  @override
  Future<Either<Failure, List<AvisLieuEntity>>> getAvisLieu(
    String lieuId,
  ) async {
    try {
      final avis = await _service.getAvisLieu(lieuId);
      return Right(avis.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, AvisLieuEntity>> createAvisLieu({
    required String lieuId,
    required int note,
    required String texte,
  }) async {
    try {
      _logger.i('[REPO] createAvisLieu appelé');
      _logger.i('lieuId: $lieuId (length: ${lieuId.length})');
      _logger.i('note: $note');
      _logger.i('texte length: ${texte.length}');
      final avis = await _service.createAvisLieu(
        lieuId: lieuId,
        note: note,
        texte: texte,
      );
      return Right(avis.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, AvisLieuEntity>> updateAvisLieu({
    required String avisId,
    required int note,
    required String texte,
  }) async {
    try {
      final avis = await _service.updateAvisLieu(
        avisId: avisId,
        note: note,
        texte: texte,
      );
      return Right(avis.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAvisLieu(String avisId) async {
    try {
      await _service.deleteAvisLieu(avisId);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<AvisEvenementEntity>>> getAvisEvenement(
    String evenementId,
  ) async {
    try {
      final avis = await _service.getAvisEvenement(evenementId);
      return Right(avis.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, AvisEvenementEntity>> createAvisEvenement({
    required String evenementId,
    required int note,
    required String texte,
  }) async {
    try {
      final avis = await _service.createAvisEvenement(
        evenementId: evenementId,
        note: note,
        texte: texte,
      );
      return Right(avis.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, AvisEvenementEntity>> updateAvisEvenement({
    required String avisId,
    required int note,
    required String texte,
  }) async {
    try {
      final avis = await _service.updateAvisEvenement(
        avisId: avisId,
        note: note,
        texte: texte,
      );
      return Right(avis.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAvisEvenement(String avisId) async {
    try {
      await _service.deleteAvisEvenement(avisId);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  Failure _mapException(dynamic exception) {
    _logger.e('Erreur Avis: $exception');

    if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is ApiException) {
      return ServerFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message);
    } else {
      return UnknownFailure(exception.toString());
    }
  }
}
