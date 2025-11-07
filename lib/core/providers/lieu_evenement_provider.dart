import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:event_flow/domains/repositories/lieu_evenement_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

final getIt = GetIt.instance;

// ==================== SEARCH STATE NOTIFIERS ====================

/// Notifier pour les paramètres de recherche des lieux
class LieuSearchNotifier extends ChangeNotifier {
  String _search = '';
  String? _categorie;

  String get search => _search;
  String? get categorie => _categorie;

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setCategorie(String? value) {
    _categorie = value;
    notifyListeners();
  }

  void reset() {
    _search = '';
    _categorie = null;
    notifyListeners();
  }

}

/// Notifier pour les paramètres de recherche des événements
class EvenementSearchNotifier extends ChangeNotifier {
  String _search = '';
  bool _aVenir = true;

  String get search => _search;
  bool get aVenir => _aVenir;

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setAVenir(bool value) {
    _aVenir = value;
    notifyListeners();
  }

  void reset() {
    _search = '';
    _aVenir = true;
    notifyListeners();
  }

}

// ==================== LIEUX NOTIFIER ====================

/// Notifier pour la liste des lieux
class LieuxNotifier extends ChangeNotifier {
  final LieuEvenementRepository _repo;
  final Logger _logger;
  final LieuSearchNotifier _searchNotifier;

  List<LieuEntity> _lieux = [];
  bool _isLoading = false;
  String? _error;

  LieuxNotifier({
    required LieuEvenementRepository repo,
    required Logger logger,
    required LieuSearchNotifier searchNotifier,
  })  : _repo = repo,
        _logger = logger,
        _searchNotifier = searchNotifier {
    _searchNotifier.addListener(_onSearchChanged);
  }

  List<LieuEntity> get lieux => _lieux;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onSearchChanged() {
    fetchLieux();
  }

  Future<void> fetchLieux() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getLieux(
        search: _searchNotifier.search.isEmpty ? null : _searchNotifier.search,
        categorie: _searchNotifier.categorie,
      );

      result.fold(
        (failure) {
          _logger.e('Erreur lieux: ${failure.message}');
          _error = failure.message;
          _lieux = [];
        },
        (lieux) {
          _lieux = lieux;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _lieux = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchNotifier.removeListener(_onSearchChanged);
    super.dispose();
  }
}

/// Notifier pour le détail d'un lieu
class LieuDetailNotifier extends ChangeNotifier {
  final LieuEvenementRepository _repo;
  final Logger _logger;
  final String lieuId;

  final Map<String, LieuEntity?> cache = {};
  bool _isLoading = false;
  String? _error;

  LieuDetailNotifier({
    required LieuEvenementRepository repo,
    required this.lieuId,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<LieuEntity?> fetchLieu(String lieuId) async {
    if (cache.containsKey(lieuId)) {
      return cache[lieuId];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getLieuById(lieuId);

      return result.fold(
        (failure) {
          _logger.e('Erreur détail lieu: ${failure.message}');
          _error = failure.message;
          cache[lieuId] = null;
          return null;
        },
        (lieu) {
          cache[lieuId] = lieu;
          _error = null;
          return lieu;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      cache[lieuId] = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    cache.clear();
    super.dispose();
  }
}

// ==================== ÉVÉNEMENTS NOTIFIER ====================

/// Notifier pour la liste des événements
class EvenementsNotifier extends ChangeNotifier {
  final LieuEvenementRepository _repo;
  final Logger _logger;
  final EvenementSearchNotifier _searchNotifier;

  List<EvenementEntity> _evenements = [];
  bool _isLoading = false;
  String? _error;

  EvenementsNotifier({
    required LieuEvenementRepository repo,
    required Logger logger,
    required EvenementSearchNotifier searchNotifier,
  })  : _repo = repo,
        _logger = logger,
        _searchNotifier = searchNotifier {
    _searchNotifier.addListener(_onSearchChanged);
  }

  List<EvenementEntity> get evenements => _evenements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onSearchChanged() {
    fetchEvenements();
  }

  Future<void> fetchEvenements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getEvenements(
        search: _searchNotifier.search.isEmpty ? null : _searchNotifier.search,
        aVenir: _searchNotifier.aVenir,
      );

      result.fold(
        (failure) {
          _logger.e('Erreur événements: ${failure.message}');
          _error = failure.message;
          _evenements = [];
        },
        (evenements) {
          _evenements = evenements;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _evenements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchNotifier.removeListener(_onSearchChanged);
    super.dispose();
  }
}

/// Notifier pour le détail d'un événement
class EvenementDetailNotifier extends ChangeNotifier {
  final LieuEvenementRepository _repo;
  final Logger _logger;
  final String evenementId;

  final Map<String, EvenementEntity?> cache = {};
  bool _isLoading = false;
  String? _error;

  EvenementDetailNotifier({
    required LieuEvenementRepository repo,
    required this.evenementId,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<EvenementEntity?> fetchEvenement(String evenementId) async {
    if (cache.containsKey(evenementId)) {
      return cache[evenementId];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getEvenementById(evenementId);

      return result.fold(
        (failure) {
          _logger.e('Erreur détail événement: ${failure.message}');
          _error = failure.message;
          cache[evenementId] = null;
          return null;
        },
        (evenement) {
          cache[evenementId] = evenement;
          _error = null;
          return evenement;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      cache[evenementId] = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    cache.clear();
    super.dispose();
  }
}

// ==================== PROXIMITY NOTIFIER ====================

/// Notifier pour la recherche de proximité
class ProximitySearchNotifier extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  double? _radius;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  double? get radius => _radius;

  void setSearch({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    _radius = radius;
    notifyListeners();
  }

  void reset() {
    _latitude = null;
    _longitude = null;
    _radius = null;
    notifyListeners();
  }

}

/// Notifier pour les lieux à proximité
class NearbyPlacesNotifier extends ChangeNotifier {
  final LieuEvenementRepository _repo;
  final Logger _logger;
  final ProximitySearchNotifier _proximityNotifier;

  List<NearbyPlaceEntity> _places = [];
  bool _isLoading = false;
  String? _error;

  NearbyPlacesNotifier({
    required LieuEvenementRepository repo,
    required Logger logger,
    required ProximitySearchNotifier proximityNotifier,
  })  : _repo = repo,
        _logger = logger,
        _proximityNotifier = proximityNotifier {
    _proximityNotifier.addListener(_onProximityChanged);
  }

  List<NearbyPlaceEntity> get places => _places;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onProximityChanged() {
    if (_proximityNotifier.latitude != null &&
        _proximityNotifier.longitude != null) {
      fetchNearbyPlaces();
    } else {
      _places = [];
      notifyListeners();
    }
  }

  Future<void> fetchNearbyPlaces() async {
    if (_proximityNotifier.latitude == null ||
        _proximityNotifier.longitude == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getNearbyPlaces(
        latitude: _proximityNotifier.latitude!,
        longitude: _proximityNotifier.longitude!,
        radius: _proximityNotifier.radius ?? 10,
      );

      result.fold(
        (failure) {
          _logger.e('Erreur lieux proximité: ${failure.message}');
          _error = failure.message;
          _places = [];
        },
        (places) {
          _places = places;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _proximityNotifier.removeListener(_onProximityChanged);
    super.dispose();
  }
}

/// Notifier pour les événements à proximité
class NearbyEventsNotifier extends ChangeNotifier {
  final LieuEvenementRepository _repo;
  final Logger _logger;
  final ProximitySearchNotifier _proximityNotifier;

  List<EvenementEntity> _events = [];
  bool _isLoading = false;
  String? _error;

  NearbyEventsNotifier({
    required LieuEvenementRepository repo,
    required Logger logger,
    required ProximitySearchNotifier proximityNotifier,
  })  : _repo = repo,
        _logger = logger,
        _proximityNotifier = proximityNotifier {
    _proximityNotifier.addListener(_onProximityChanged);
  }

  List<EvenementEntity> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onProximityChanged() {
    if (_proximityNotifier.latitude != null &&
        _proximityNotifier.longitude != null) {
      fetchNearbyEvents();
    } else {
      _events = [];
      notifyListeners();
    }
  }

  Future<void> fetchNearbyEvents() async {
    if (_proximityNotifier.latitude == null ||
        _proximityNotifier.longitude == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getNearbyEvents(
        latitude: _proximityNotifier.latitude!,
        longitude: _proximityNotifier.longitude!,
        radius: _proximityNotifier.radius ?? 10,
      );

      result.fold(
        (failure) {
          _logger.e('Erreur événements proximité: ${failure.message}');
          _error = failure.message;
          _events = [];
        },
        (events) {
          _events = events;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _proximityNotifier.removeListener(_onProximityChanged);
    super.dispose();
  }
}

// ==================== CACHE NOTIFIER ====================

/// Notifier pour gérer le cache
class CacheNotifier extends ChangeNotifier {
  final LieuEvenementRepository _repo;
  final Logger _logger;

  bool _isLoading = false;
  String? _error;

  CacheNotifier({
    required LieuEvenementRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refreshCache() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.refreshAllCache();

      result.fold(
        (failure) {
          _logger.e('Erreur rafraîchissement: ${failure.message}');
          _error = failure.message;
        },
        (_) {
          _logger.i('Cache rafraîchi');
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.clearAllCache();

      result.fold(
        (failure) {
          _logger.e('Erreur suppression: ${failure.message}');
          _error = failure.message;
        },
        (_) {
          _logger.i('Cache supprimé');
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}