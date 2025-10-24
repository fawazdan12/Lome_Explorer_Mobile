import 'dart:async';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:event_flow/domains/repositories/geo_repository.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

final getIt = GetIt.instance;

// ==================== LOCATION NOTIFIER ====================

/// Notifier pour la localisation actuelle de l'utilisateur
class UserLocationNotifier extends ChangeNotifier {
  final GeolocationRepository _repo;
  final Logger _logger;

  LocationEntity? _location;
  bool _isLoading = false;
  String? _error;

  UserLocationNotifier({
    required GeolocationRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  LocationEntity? get location => _location;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ CORRECTION : Utiliser scheduleMicrotask pour éviter notifyListeners pendant build
  Future<void> detectLocation() async {
    _isLoading = true;
    _error = null;
    
    // Planifier la notification après le build actuel
    scheduleMicrotask(() {
      if (!_isDisposed) notifyListeners();
    });

    try {
      final result = await _repo.detectLocation();

      result.fold(
        (failure) {
          _logger.e('Erreur détection: ${failure.message}');
          _error = failure.message;
          _location = null;
        },
        (location) {
          _location = location;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _location = null;
    } finally {
      _isLoading = false;
      // Utiliser scheduleMicrotask ici aussi
      scheduleMicrotask(() {
        if (!_isDisposed) notifyListeners();
      });
    }
  }

  Future<void> getCachedLocation() async {
    try {
      final result = await _repo.getCachedLocation();

      result.fold(
        (failure) => _location = null,
        (location) => _location = location,
      );
      
      scheduleMicrotask(() {
        if (!_isDisposed) notifyListeners();
      });
    } catch (e) {
      _logger.e('Erreur cache: $e');
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

// ==================== QUARTIERS NOTIFIER ====================

/// Notifier pour les quartiers
class QuartiersNotifier extends ChangeNotifier {
  final GeolocationRepository _repo;
  final Logger _logger;

  List<QuartierEntity> _quartiers = [];
  bool _isLoading = false;
  String? _error;

  QuartiersNotifier({
    required GeolocationRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  List<QuartierEntity> get quartiers => _quartiers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchQuartiers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getQuartiers();

      result.fold(
        (failure) {
          _logger.e('Erreur quartiers: ${failure.message}');
          _error = failure.message;
          _quartiers = [];
        },
        (quartiers) {
          _quartiers = quartiers;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _quartiers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ==================== IS IN LOME NOTIFIER ====================

/// Notifier pour la vérification de localisation à Lomé
class IsInLomeNotifier extends ChangeNotifier {
  final GeolocationRepository _repo;
  final Logger _logger;

  bool? _isInLome;
  bool _isLoading = false;
  String? _error;

  IsInLomeNotifier({
    required GeolocationRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool? get isInLome => _isInLome;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> validateLocation(LocationEntity location) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.validateLomeLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      result.fold(
        (failure) {
          _logger.e('Erreur validation: ${failure.message}');
          _error = failure.message;
          _isInLome = false;
        },
        (isInLome) {
          _isInLome = isInLome;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _isInLome = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ==================== GEOCODE ADDRESS NOTIFIER ====================

/// Notifier pour le géocodage d'adresse
class GeocodeAddressNotifier extends ChangeNotifier {
  final GeolocationRepository _repo;
  final Logger _logger;

  final Map<String, LocationEntity?> _cache = {};
  bool _isLoading = false;
  String? _error;

  GeocodeAddressNotifier({
    required GeolocationRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<LocationEntity?> geocodeAddress(String address) async {
    if (address.isEmpty) return null;

    if (_cache.containsKey(address)) {
      return _cache[address];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.geocodeAddress(address);

      LocationEntity? location;
      result.fold(
        (failure) {
          _logger.e('Erreur géocodage: ${failure.message}');
          _error = failure.message;
          location = null;
        },
        (loc) {
          location = loc;
          _error = null;
        },
      );

      _cache[address] = location;
      return location;
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _cache.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _cache.clear();
    super.dispose();
  }
}

// ==================== POSITION WATCHER NOTIFIER ====================

/// Notifier pour la position en temps réel
class PositionWatcherNotifier extends ChangeNotifier {
  final GeolocationRepository _repo;
  final Logger _logger;

  Position? _currentPosition;
  bool _isWatching = false;
  String? _error;
  StreamSubscription<Position>? _positionSubscription;

  PositionWatcherNotifier({
    required GeolocationRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  Position? get currentPosition => _currentPosition;
  bool get isWatching => _isWatching;
  String? get error => _error;

  void startWatching({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
    Duration timeInterval = const Duration(seconds: 5),
  }) {
    if (_isWatching) return;

    _isWatching = true;
    _error = null;
    notifyListeners();

    _positionSubscription = _repo.watchPosition(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeInterval: timeInterval,
    ).listen(
      (position) {
        _currentPosition = position;
        notifyListeners();
      },
      onError: (e) {
        _logger.e('Erreur surveillance position: $e');
        _error = e.toString();
        _isWatching = false;
        notifyListeners();
      },
      onDone: () {
        _isWatching = false;
        notifyListeners();
      },
    );
  }

  Future<void> stopWatching() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isWatching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

// ==================== LOCATION SERVICE NOTIFIER ====================

/// Notifier pour vérifier l'état du service de localisation
class LocationServiceNotifier extends ChangeNotifier {
  final GeolocationRepository _repo;
  final Logger _logger;

  bool _isEnabled = false;
  bool _isChecking = false;

  LocationServiceNotifier({
    required GeolocationRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isEnabled => _isEnabled;
  bool get isChecking => _isChecking;

  Future<void> checkService() async {
    _isChecking = true;
    notifyListeners();

    try {
      final result = await _repo.isLocationServiceEnabled();

      result.fold(
        (failure) {
          _logger.e('Erreur vérification service: ${failure.message}');
          _isEnabled = false;
        },
        (enabled) {
          _isEnabled = enabled;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _isEnabled = false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> openSettings() async {
    try {
      final result = await _repo.openLocationSettings();

      return result.fold(
        (failure) {
          _logger.e('Erreur ouverture paramètres: ${failure.message}');
          return false;
        },
        (opened) => opened,
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      final result = await _repo.openAppSettings();

      return result.fold(
        (failure) {
          _logger.e('Erreur ouverture paramètres app: ${failure.message}');
          return false;
        },
        (opened) => opened,
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}