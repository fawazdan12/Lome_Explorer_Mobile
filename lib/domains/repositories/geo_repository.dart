import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:geolocator/geolocator.dart';

/// Contrat du repository de géolocalisation
abstract class GeolocationRepository {
  // ==================== DÉTECTION ====================

  /// Détecter la localisation de l'utilisateur
  Future<Either<Failure, LocationEntity>> detectLocation();

  /// Obtenir la localisation en cache
  Future<Either<Failure, LocationEntity?>> getCachedLocation();

  // ==================== GÉOCODAGE ====================

  /// Convertir une adresse en coordonnées
  Future<Either<Failure, LocationEntity>> geocodeAddress(String address);

  // ==================== QUARTIERS ====================

  /// Obtenir la liste des quartiers de Lomé
  Future<Either<Failure, List<QuartierEntity>>> getQuartiers();

  /// Valider si une localisation est à Lomé
  Future<Either<Failure, bool>> validateLomeLocation({
    required double latitude,
    required double longitude,
  });

  // ==================== DISTANCE ====================

  /// Calculer la distance entre deux points
  double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  });

  // ==================== SURVEILLANCE ====================

  /// Surveiller les changements de position
  Stream<Position> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    Duration timeInterval = const Duration(seconds: 5),
  });

  // ==================== SERVICES ====================

  /// Vérifier si le service de localisation est activé sur l'appareil
  Future<Either<Failure, bool>> isLocationServiceEnabled();

  /// Ouvrir les paramètres de localisation du système
  Future<Either<Failure, bool>> openLocationSettings();

  /// Ouvrir les paramètres de permissions de l'application
  Future<Either<Failure, bool>> openAppSettings();
}