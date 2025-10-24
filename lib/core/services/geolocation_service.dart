import 'package:event_flow/data/datasource/local/cache_hive_datasource.dart';
import 'package:event_flow/data/datasource/remote/api_datasource_remote.dart';
import 'package:event_flow/data/models/avis_lieu_event_geo_model.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  final Logger _logger;

  GeolocationService({
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _logger = logger;

  // ==================== DÉTECTION DE LOCALISATION ====================

  /// Détecter la localisation de l'utilisateur
  Future<LocationModel> detectLocation() async {
    try {
      _logger.i('Détection de la localisation');

      // Essayer d'obtenir la position GPS
      try {
        final position = await _getCurrentPosition();
        if (position != null) {
          _logger.i('Position GPS obtenue: ${position.latitude}, ${position.longitude}');

          final location = LocationModel(
            latitude: position.latitude,
            longitude: position.longitude,
            source: 'gps',
          );

          // Mettre en cache
          await _localDataSource.cacheLocation(location);

          return location;
        }
      } catch (e) {
        _logger.w('Impossible d\'obtenir la position GPS: $e');
      }

      // Fallback: détecter via l'API
      final location = await _remoteDataSource.detectLocation();
      await _localDataSource.cacheLocation(location);

      _logger.i('Localisation détectée: ${location.latitude}, ${location.longitude}');
      return location;
    } catch (e) {
      _logger.e('Erreur lors de la détection de localisation: $e');
      rethrow;
    }
  }

  /// Obtenir la localisation en cache
  Future<LocationModel?> getCachedLocation() async {
    try {
      return await _localDataSource.getCachedLocation();
    } catch (e) {
      _logger.e('Erreur lors de la récupération du cache de localisation: $e');
      return null;
    }
  }

  /// Obtenir la position GPS actuelle
  Future<Position?> _getCurrentPosition() async {
    try {
      // Vérifier d'abord si le service de localisation est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Service de localisation désactivé');
        return null;
      }

      // Vérifier les permissions
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        _logger.w('Permission de localisation refusée');
        return null;
      }

      // ✅ CORRECTION : Augmenter le timeout et améliorer la précision
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Moins exigeant
        timeLimit: const Duration(seconds: 30), // Timeout augmenté
      ).timeout(
        const Duration(seconds: 35), // Timeout de secours
        onTimeout: () async{
          _logger.w('Timeout GPS - utilisation de lastKnownPosition');
          final lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            _logger.i('Utilisation de la dernière position connue après timeout');
            return lastPosition;
          }
          throw 'Aucune position GPS disponible'; 
        },
      );

      return position;
    } catch (e) {
      _logger.e('Erreur lors de la récupération de la position GPS: $e');
      // ✅ Essayer d'obtenir la dernière position connue
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          _logger.i('Utilisation de la dernière position connue');
          return lastPosition;
        }
      } catch (_) {}
      return null;
    }
  }

  /// Vérifier et demander la permission de localisation
  Future<bool> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Permission de localisation refusée');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Permission de localisation refusée définitivement');
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      _logger.e('Erreur lors de la vérification de permission: $e');
      return false;
    }
  }

  // ==================== GÉOCODAGE ====================

  /// Convertir une adresse en coordonnées
  Future<LocationModel> geocodeAddress(String address) async {
    try {
      _logger.i('Géocodage de l\'adresse: $address');

      final location = await _remoteDataSource.geocodeAddress(address);

      _logger.i('Adresse géocodée: ${location.latitude}, ${location.longitude}');
      return location;
    } catch (e) {
      _logger.e('Erreur lors du géocodage: $e');
      rethrow;
    }
  }

  // ==================== QUARTIERS ====================

  /// Obtenir la liste des quartiers de Lomé
  Future<List<QuartierModel>> getQuartiers() async {
    try {
      _logger.i('Récupération des quartiers');

      final quartiers = await _remoteDataSource.getQuartiers();

      _logger.i('${quartiers.length} quartiers récupérés');
      return quartiers;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des quartiers: $e');
      rethrow;
    }
  }

  /// Valider si une localisation est à Lomé
  Future<bool> validateLomeLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      _logger.i('Validation de la localisation Lomé');

      final isInLome = await _remoteDataSource.validateLomeLocation(
        latitude: latitude,
        longitude: longitude,
      );

      _logger.i('Localisation Lomé valide: $isInLome');
      return isInLome;
    } catch (e) {
      _logger.e('Erreur lors de la validation: $e');
      rethrow;
    }
  }

  // ==================== DISTANCE ====================

  /// Calculer la distance entre deux points
  double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    try {
      final distance = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
      final distanceKm = distance / 1000;

      _logger.d('Distance calculée: ${distanceKm.toStringAsFixed(2)} km');
      return double.parse(distanceKm.toStringAsFixed(2));
    } catch (e) {
      _logger.e('Erreur lors du calcul de distance: $e');
      return 0.0;
    }
  }

  // ==================== SURVEILLANCE DE POSITION ====================

  /// Écouter les changements de position
  Stream<Position> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    Duration timeInterval = const Duration(seconds: 5),
  }) {
    _logger.i('Début de la surveillance de la position');

    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      // ✅ Suppression du timeLimit qui cause des timeouts
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }

  /// Vérifier si les services de localisation sont activés
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      _logger.e('Erreur lors de la vérification du service: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres de localisation
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      _logger.e('Erreur lors de l\'ouverture des paramètres: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres d'application
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      _logger.e('Erreur lors de l\'ouverture des paramètres d\'app: $e');
      return false;
    }
  }
}