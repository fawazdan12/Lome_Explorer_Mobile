import 'package:dartz/dartz.dart';
import 'package:event_flow/config/api_execption.dart';
import 'package:event_flow/core/services/geolocation_service.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:event_flow/domains/repositories/geo_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

class GeolocationRepositoryImpl implements GeolocationRepository {
  final GeolocationService _service;
  final Logger _logger;

  GeolocationRepositoryImpl({
    required GeolocationService service,
    required Logger logger,
  })  : _service = service,
        _logger = logger;

  @override
  Future<Either<Failure, LocationEntity>> detectLocation() async {
    try {
      final location = await _service.detectLocation();
      return Right(location.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, LocationEntity?>> getCachedLocation() async {
    try {
      final location = await _service.getCachedLocation();
      return Right(location?.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, LocationEntity>> geocodeAddress(String address) async {
    try {
      final location = await _service.geocodeAddress(address);
      return Right(location.toEntity());
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<QuartierEntity>>> getQuartiers() async {
    try {
      final quartiers = await _service.getQuartiers();
      return Right(
        quartiers.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> validateLomeLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final isValid = await _service.validateLomeLocation(
        latitude: latitude,
        longitude: longitude,
      );
      return Right(isValid);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return _service.calculateDistance(
      lat1: lat1,
      lng1: lng1,
      lat2: lat2,
      lng2: lng2,
    );
  }

  @override
  Stream<Position> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    Duration timeInterval = const Duration(seconds: 5),
  }) {
    return _service.watchPosition(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeInterval: timeInterval,
    );
  }

  @override
  Future<Either<Failure, bool>> isLocationServiceEnabled() async {
    try {
      final isEnabled = await _service.isLocationServiceEnabled();
      return Right(isEnabled);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> openLocationSettings() async {
    try {
      final opened = await _service.openLocationSettings();
      return Right(opened);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> openAppSettings() async {
    try {
      final opened = await _service.openAppSettings();
      return Right(opened);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ==================== HELPERS ====================

  Failure _mapException(dynamic exception) {
    _logger.e('Erreur géolocalisation: $exception');

    if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is ApiException) {
      return ServerFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else {
      return UnknownFailure(exception.toString());
    }
  }
}