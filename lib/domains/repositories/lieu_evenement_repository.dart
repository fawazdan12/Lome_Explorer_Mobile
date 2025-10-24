import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';

/// Contrat du repository pour les lieux et événements
abstract class LieuEvenementRepository {
  // ==================== LIEUX ====================

  /// Récupérer la liste des lieux
  Future<Either<Failure, List<LieuEntity>>> getLieux({
    int page = 1,
    String? search,
    String? categorie,
  });

  /// Récupérer un lieu par son ID
  Future<Either<Failure, LieuEntity>> getLieuById(String id);

  /// Créer un nouveau lieu
  Future<Either<Failure, LieuEntity>> createLieu({
    required String nom,
    required String description,
    required String categorie,
    required double latitude,
    required double longitude,
  });

  /// Récupérer les lieux à proximité
  Future<Either<Failure, List<NearbyPlaceEntity>>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    required double radius,
  });

  // ==================== ÉVÉNEMENTS ====================

  /// Récupérer la liste des événements
  Future<Either<Failure, List<EvenementEntity>>> getEvenements({
    int page = 1,
    String? search,
    bool? aVenir,
  });

  /// Récupérer un événement par son ID
  Future<Either<Failure, EvenementEntity>> getEvenementById(String id);

  /// Récupérer les événements à proximité
  Future<Either<Failure, List<EvenementEntity>>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required double radius,
  });

  // ==================== CACHE ====================

  /// Rafraîchir tous les caches
  Future<Either<Failure, void>> refreshAllCache();

  /// Vider les caches
  Future<Either<Failure, void>> clearAllCache();
}