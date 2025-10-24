import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:event_flow/domains/repositories/geo_repository.dart';
import 'package:geolocator/geolocator.dart';

// ==================== DÉTECTION ====================

class DetectLocationUseCase {
  final GeolocationRepository _repository;

  DetectLocationUseCase(this._repository);

  Future<Either<Failure, LocationEntity>> call() {
    return _repository.detectLocation();
  }
}

class GetCachedLocationUseCase {
  final GeolocationRepository _repository;

  GetCachedLocationUseCase(this._repository);

  Future<Either<Failure, LocationEntity?>> call() {
    return _repository.getCachedLocation();
  }
}

// ==================== GÉOCODAGE ====================

class GeocodeAddressUseCase {
  final GeolocationRepository _repository;

  GeocodeAddressUseCase(this._repository);

  Future<Either<Failure, LocationEntity>> call(String address) {
    return _repository.geocodeAddress(address);
  }
}

// ==================== QUARTIERS ====================

class GetQuartiersUseCase {
  final GeolocationRepository _repository;

  GetQuartiersUseCase(this._repository);

  Future<Either<Failure, List<QuartierEntity>>> call() {
    return _repository.getQuartiers();
  }
}

class ValidateLomeLocationUseCase {
  final GeolocationRepository _repository;

  ValidateLomeLocationUseCase(this._repository);

  Future<Either<Failure, bool>> call({
    required double latitude,
    required double longitude,
  }) {
    return _repository.validateLomeLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }
}

// ==================== DISTANCE ====================

class CalculateDistanceUseCase {
  final GeolocationRepository _repository;

  CalculateDistanceUseCase(this._repository);

  double call({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    return _repository.calculateDistance(
      lat1: lat1,
      lng1: lng1,
      lat2: lat2,
      lng2: lng2,
    );
  }
}

// ==================== SURVEILLANCE ====================

class WatchPositionUseCase {
  final GeolocationRepository _repository;

  WatchPositionUseCase(this._repository);

  Stream<Position> call({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    Duration timeInterval = const Duration(seconds: 5),
  }) {
    return _repository.watchPosition(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeInterval: timeInterval,
    );
  }
}

// ==================== SERVICES ====================

class IsLocationServiceEnabledUseCase {
  final GeolocationRepository _repository;

  IsLocationServiceEnabledUseCase(this._repository);

  Future<Either<Failure, bool>> call() {
    return _repository.isLocationServiceEnabled();
  }
}

class OpenLocationSettingsUseCase {
  final GeolocationRepository _repository;

  OpenLocationSettingsUseCase(this._repository);

  Future<Either<Failure, bool>> call() {
    return _repository.openLocationSettings();
  }
}

class OpenAppSettingsUseCase {
  final GeolocationRepository _repository;

  OpenAppSettingsUseCase(this._repository);

  Future<Either<Failure, bool>> call() {
    return _repository.openAppSettings();
  }
}