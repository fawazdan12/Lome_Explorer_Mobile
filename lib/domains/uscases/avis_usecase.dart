import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/avis_lieu_evenement_entity.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/repositories/avis_repository.dart';


// ==================== AVIS LIEUX ====================

class GetAvisLieuUseCase {
  final AvisRepository _repository;

  GetAvisLieuUseCase(this._repository);

  Future<Either<Failure, List<AvisLieuEntity>>> call(String lieuId) {
    return _repository.getAvisLieu(lieuId);
  }
}

class CreateAvisLieuUseCase {
  final AvisRepository _repository;

  CreateAvisLieuUseCase(this._repository);

  Future<Either<Failure, AvisLieuEntity>> call({
    required String lieuId,
    required int note,
    required String texte,
  }) {
    return _repository.createAvisLieu(
      lieuId: lieuId,
      note: note,
      texte: texte,
    );
  }
}

class UpdateAvisLieuUseCase {
  final AvisRepository _repository;

  UpdateAvisLieuUseCase(this._repository);

  Future<Either<Failure, AvisLieuEntity>> call({
    required String avisId,
    required int note,
    required String texte,
  }) {
    return _repository.updateAvisLieu(
      avisId: avisId,
      note: note,
      texte: texte,
    );
  }
}

class DeleteAvisLieuUseCase {
  final AvisRepository _repository;

  DeleteAvisLieuUseCase(this._repository);

  Future<Either<Failure, void>> call(String avisId) {
    return _repository.deleteAvisLieu(avisId);
  }
}

// ==================== AVIS ÉVÉNEMENTS ====================

class GetAvisEvenementUseCase {
  final AvisRepository _repository;

  GetAvisEvenementUseCase(this._repository);

  Future<Either<Failure, List<AvisEvenementEntity>>> call(String evenementId) {
    return _repository.getAvisEvenement(evenementId);
  }
}

class CreateAvisEvenementUseCase {
  final AvisRepository _repository;

  CreateAvisEvenementUseCase(this._repository);

  Future<Either<Failure, AvisEvenementEntity>> call({
    required String evenementId,
    required int note,
    required String texte,
  }) {
    return _repository.createAvisEvenement(
      evenementId: evenementId,
      note: note,
      texte: texte,
    );
  }
}

class UpdateAvisEvenementUseCase {
  final AvisRepository _repository;

  UpdateAvisEvenementUseCase(this._repository);

  Future<Either<Failure, AvisEvenementEntity>> call({
    required String avisId,
    required int note,
    required String texte,
  }) {
    return _repository.updateAvisEvenement(
      avisId: avisId,
      note: note,
      texte: texte,
    );
  }
}

class DeleteAvisEvenementUseCase {
  final AvisRepository _repository;

  DeleteAvisEvenementUseCase(this._repository);

  Future<Either<Failure, void>> call(String avisId) {
    return _repository.deleteAvisEvenement(avisId);
  }
}