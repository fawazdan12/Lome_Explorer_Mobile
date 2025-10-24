import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:event_flow/domains/repositories/lieu_evenement_repository.dart';


// ==================== LIEUX ====================

class GetLieuxUseCase {
  final LieuEvenementRepository _repository;

  GetLieuxUseCase(this._repository);

  Future<Either<Failure, List<LieuEntity>>> call({
    int page = 1,
    String? search,
    String? categorie,
  }) {
    return _repository.getLieux(
      page: page,
      search: search,
      categorie: categorie,
    );
  }
}

class GetLieuByIdUseCase {
  final LieuEvenementRepository _repository;

  GetLieuByIdUseCase(this._repository);

  Future<Either<Failure, LieuEntity>> call(String id) {
    return _repository.getLieuById(id);
  }
}

class CreateLieuUseCase {
  final LieuEvenementRepository _repository;

  CreateLieuUseCase(this._repository);

  Future<Either<Failure, LieuEntity>> call({
    required String nom,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
  }) {
    return _repository.createLieu(
      nom: nom,
      description: description,
      categorie: categorie,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class GetNearbyPlacesUseCase {
  final LieuEvenementRepository _repository;

  GetNearbyPlacesUseCase(this._repository);

  Future<Either<Failure, List<NearbyPlaceEntity>>> call({
    required double latitude,
    required double longitude,
    required double radius,
  }) {
    return _repository.getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }
}

// ==================== ÉVÉNEMENTS ====================

class GetEvenementsUseCase {
  final LieuEvenementRepository _repository;

  GetEvenementsUseCase(this._repository);

  Future<Either<Failure, List<EvenementEntity>>> call({
    int page = 1,
    String? search,
    bool? aVenir,
  }) {
    return _repository.getEvenements(
      page: page,
      search: search,
      aVenir: aVenir,
    );
  }
}

class GetEvenementByIdUseCase {
  final LieuEvenementRepository _repository;

  GetEvenementByIdUseCase(this._repository);

  Future<Either<Failure, EvenementEntity>> call(String id) {
    return _repository.getEvenementById(id);
  }
}

class GetNearbyEventsUseCase {
  final LieuEvenementRepository _repository;

  GetNearbyEventsUseCase(this._repository);

  Future<Either<Failure, List<EvenementEntity>>> call({
    required double latitude,
    required double longitude,
    required double radius,
  }) {
    return _repository.getNearbyEvents(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }
}

// ==================== CACHE ====================

class RefreshAllCacheUseCase {
  final LieuEvenementRepository _repository;

  RefreshAllCacheUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.refreshAllCache();
  }
}

class ClearAllCacheUseCase {
  final LieuEvenementRepository _repository;

  ClearAllCacheUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.clearAllCache();
  }
}