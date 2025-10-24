import 'package:dartz/dartz.dart';
import 'package:event_flow/config/api_execption.dart';
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:event_flow/domains/repositories/lieu_evenement_repository.dart';
import 'package:logger/logger.dart';


class LieuEvenementRepositoryImpl implements LieuEvenementRepository {
  final LieuEvenementService _service;
  final Logger _logger;

  LieuEvenementRepositoryImpl({
    required LieuEvenementService service,
    required Logger logger,
  })  : _service = service,
        _logger = logger;

  @override
  Future<Either<Failure, List<LieuEntity>>> getLieux({
    int page = 1,
    String? search,
    String? categorie,
  }) async {
    try {
      final lieux = await _service.getLieux(
        page: page,
        search: search,
        categorie: categorie,
      );

      return Right(
        lieux.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, LieuEntity>> getLieuById(String id) async {
    try {
      final lieu = await _service.getLieuById(id);
      return Right(lieu.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, LieuEntity>> createLieu({
    required String nom,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final lieu = await _service.createLieu(
        nom: nom,
        description: description,
        categorie: categorie,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(lieu.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<NearbyPlaceEntity>>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final places = await _service.getNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      return Right(
        places.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<EvenementEntity>>> getEvenements({
    int page = 1,
    String? search,
    bool? aVenir,
  }) async {
    try {
      final evenements = await _service.getEvenements(
        page: page,
        search: search,
        aVenir: aVenir,
      );

      return Right(
        evenements.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, EvenementEntity>> getEvenementById(String id) async {
    try {
      final evenement = await _service.getEvenementById(id);
      return Right(evenement.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<EvenementEntity>>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final evenements = await _service.getNearbyEvents(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      return Right(
        evenements.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> refreshAllCache() async {
    try {
      await _service.refreshAllCache();
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllCache() async {
    try {
      await _service.clearAllCache();
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ==================== HELPERS ====================

  Failure _mapException(dynamic exception) {
    _logger.e('Erreur Lieu/Événement: $exception');

    if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is ApiException) {
      return ServerFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message);
    } else {
      return UnknownFailure(exception.toString());
    }
  }
}