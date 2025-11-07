import 'package:event_flow/domains/entities/avis_lieu_evenement_entity.dart';
import 'package:event_flow/domains/repositories/avis_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

final getIt = GetIt.instance;

// ==================== AVIS LIEUX NOTIFIER ====================

/// Notifier pour les avis d'un lieu
class AvisLieuNotifier extends ChangeNotifier {
  final AvisRepository _repo;
  final Logger _logger;
  final String lieuId;

  List<AvisLieuEntity> _avis = [];
  bool _isLoading = false;
  String? _error;

  AvisLieuNotifier({
    required AvisRepository repo,
    required Logger logger,
    required this.lieuId,
  })  : _repo = repo,
        _logger = logger {
    fetchAvis();
  }

  List<AvisLieuEntity> get avis => _avis;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAvis() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getAvisLieu(lieuId);

      result.fold(
        (failure) {
          _logger.e('Erreur avis lieu: ${failure.message}');
          _error = failure.message;
          _avis = [];
        },
        (avis) {
          _avis = avis;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _avis = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAvis() async {
    await fetchAvis();
  }

}

// ==================== CREATE AVIS LIEU NOTIFIER ====================

/// Notifier pour créer un avis pour un lieu
class CreateAvisLieuNotifier extends ChangeNotifier {
  final AvisRepository _repo;
  final Logger _logger;

  bool _isLoading = false;
  String? _error;
  AvisLieuEntity? _lastCreatedAvis;

  CreateAvisLieuNotifier({
    required AvisRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;
  AvisLieuEntity? get lastCreatedAvis => _lastCreatedAvis;

  Future<AvisLieuEntity?> createAvis({
    required String lieuId,
    required int note,
    required String texte,
  }) async {
    _isLoading = true;
    _error = null;
    _lastCreatedAvis = null;
    notifyListeners();

    try {
      final result = await _repo.createAvisLieu(
        lieuId: lieuId,
        note: note,
        texte: texte,
      );

      return result.fold(
        (failure) {
          _logger.e('Erreur création avis lieu: ${failure.message}');
          _error = failure.message;
          return null;
        },
        (avis) {
          _lastCreatedAvis = avis;
          _logger.i('Avis lieu créé');
          return avis;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}

// ==================== UPDATE AVIS LIEU NOTIFIER ====================

/// Notifier pour modifier un avis de lieu
class UpdateAvisLieuNotifier extends ChangeNotifier {
  final AvisRepository _repo;
  final Logger _logger;

  bool _isLoading = false;
  String? _error;
  AvisLieuEntity? _lastUpdatedAvis;

  UpdateAvisLieuNotifier({
    required AvisRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;
  AvisLieuEntity? get lastUpdatedAvis => _lastUpdatedAvis;

  Future<AvisLieuEntity?> updateAvis({
    required String avisId,
    required int note,
    required String texte,
  }) async {
    _isLoading = true;
    _error = null;
    _lastUpdatedAvis = null;
    notifyListeners();

    try {
      final result = await _repo.updateAvisLieu(
        avisId: avisId,
        note: note,
        texte: texte,
      );

      return result.fold(
        (failure) {
          _logger.e('Erreur modification avis lieu: ${failure.message}');
          _error = failure.message;
          return null;
        },
        (avis) {
          _lastUpdatedAvis = avis;
          _logger.i('Avis lieu modifié');
          return avis;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}

// ==================== DELETE AVIS LIEU NOTIFIER ====================

/// Notifier pour supprimer un avis de lieu
class DeleteAvisLieuNotifier extends ChangeNotifier {
  final AvisRepository _repo;
  final Logger _logger;

  bool _isLoading = false;
  String? _error;
  bool _lastDeleteSuccess = false;

  DeleteAvisLieuNotifier({
    required AvisRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get lastDeleteSuccess => _lastDeleteSuccess;

  Future<bool> deleteAvis(String avisId) async {
    _isLoading = true;
    _error = null;
    _lastDeleteSuccess = false;
    notifyListeners();

    try {
      final result = await _repo.deleteAvisLieu(avisId);

      return result.fold(
        (failure) {
          _logger.e('Erreur suppression avis lieu: ${failure.message}');
          _error = failure.message;
          _lastDeleteSuccess = false;
          return false;
        },
        (_) {
          _logger.i('Avis lieu supprimé');
          _lastDeleteSuccess = true;
          _error = null;
          return true;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _lastDeleteSuccess = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}

// ==================== AVIS ÉVÉNEMENTS NOTIFIER ====================

/// Notifier pour les avis d'un événement
class AvisEvenementNotifier extends ChangeNotifier {
  final AvisRepository _repo;
  final Logger _logger;
  final String evenementId;

  List<AvisEvenementEntity> _avis = [];
  bool _isLoading = false;
  String? _error;

  AvisEvenementNotifier({
    required AvisRepository repo,
    required Logger logger,
    required this.evenementId,
  })  : _repo = repo,
        _logger = logger {
    fetchAvis();
  }

  List<AvisEvenementEntity> get avis => _avis;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAvis() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.getAvisEvenement(evenementId);

      result.fold(
        (failure) {
          _logger.e('Erreur avis événement: ${failure.message}');
          _error = failure.message;
          _avis = [];
        },
        (avis) {
          _avis = avis;
          _error = null;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _avis = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // crée un avis
  Future<AvisEvenementEntity?> createAvis({
    required String evenementId,
    required int note,
    required String texte,
  }) async {
    return await _repo.createAvisEvenement(
      evenementId: evenementId,
      note: note,
      texte: texte,
    ).then((result) => result.fold(
          (failure) {
            _logger.e('Erreur création avis événement: ${failure.message}');
            _error = failure.message;
            return null;
          },
          (avis) {
            _logger.i('Avis événement créé');
            fetchAvis(); // rafraîchir la liste des avis après création
            return avis;
          },
        ));
  }

  Future<void> refreshAvis() async {
    await fetchAvis();
  }

}

// Factory pour créer AvisEvenementNotifier avec les dépendances injectées
class AvisEvenementNotifierFactory {
  static AvisEvenementNotifier create(
      BuildContext context, String evenementId) {
    final repo = getIt<AvisRepository>();
    final logger = getIt<Logger>();

    return AvisEvenementNotifier(
      repo: repo,
      logger: logger,
      evenementId: evenementId,
    );
  }
}

// ==================== CREATE AVIS ÉVÉNEMENT NOTIFIER ====================

/// Notifier pour créer un avis pour un événement
class CreateAvisEvenementNotifier extends ChangeNotifier {
  final AvisRepository _repo;
  final Logger _logger;

  bool _isLoading = false;
  String? _error;
  AvisEvenementEntity? _lastCreatedAvis;

  CreateAvisEvenementNotifier({
    required AvisRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;
  AvisEvenementEntity? get lastCreatedAvis => _lastCreatedAvis;

  Future<AvisEvenementEntity?> createAvis({
    required String evenementId,
    required int note,
    required String texte,
  }) async {
    _isLoading = true;
    _error = null;
    _lastCreatedAvis = null;
    notifyListeners();

    try {
      final result = await _repo.createAvisEvenement(
        evenementId: evenementId,
        note: note,
        texte: texte,
      );

      return result.fold(
        (failure) {
          _logger.e('Erreur création avis événement: ${failure.message}');
          _error = failure.message;
          return null;
        },
        (avis) {
          _lastCreatedAvis = avis;
          _logger.i('Avis événement créé');
          return avis;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}

// ==================== UPDATE AVIS ÉVÉNEMENT NOTIFIER ====================

/// Notifier pour modifier un avis d'événement
class UpdateAvisEvenementNotifier extends ChangeNotifier {
  final AvisRepository _repo;
  final Logger _logger;

  bool _isLoading = false;
  String? _error;
  AvisEvenementEntity? _lastUpdatedAvis;

  UpdateAvisEvenementNotifier({
    required AvisRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;
  AvisEvenementEntity? get lastUpdatedAvis => _lastUpdatedAvis;

  Future<AvisEvenementEntity?> updateAvis({
    required String avisId,
    required int note,
    required String texte,
  }) async {
    _isLoading = true;
    _error = null;
    _lastUpdatedAvis = null;
    notifyListeners();

    try {
      final result = await _repo.updateAvisEvenement(
        avisId: avisId,
        note: note,
        texte: texte,
      );

      return result.fold(
        (failure) {
          _logger.e('Erreur modification avis événement: ${failure.message}');
          _error = failure.message;
          return null;
        },
        (avis) {
          _lastUpdatedAvis = avis;
          _logger.i('Avis événement modifié');
          return avis;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}

// ==================== DELETE AVIS ÉVÉNEMENT NOTIFIER ====================

/// Notifier pour supprimer un avis d'événement
class DeleteAvisEvenementNotifier extends ChangeNotifier {
  final AvisRepository _repo;
  final Logger _logger;

  bool _isLoading = false;
  String? _error;
  bool _lastDeleteSuccess = false;

  DeleteAvisEvenementNotifier({
    required AvisRepository repo,
    required Logger logger,
  })  : _repo = repo,
        _logger = logger;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get lastDeleteSuccess => _lastDeleteSuccess;

  Future<bool> deleteAvis(String avisId) async {
    _isLoading = true;
    _error = null;
    _lastDeleteSuccess = false;
    notifyListeners();

    try {
      final result = await _repo.deleteAvisEvenement(avisId);

      return result.fold(
        (failure) {
          _logger.e('Erreur suppression avis événement: ${failure.message}');
          _error = failure.message;
          _lastDeleteSuccess = false;
          return false;
        },
        (_) {
          _logger.i('Avis événement supprimé');
          _lastDeleteSuccess = true;
          _error = null;
          return true;
        },
      );
    } catch (e) {
      _logger.e('Erreur: $e');
      _error = e.toString();
      _lastDeleteSuccess = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}