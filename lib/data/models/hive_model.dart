import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class HiveUtilisateur {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String? tel;

  @HiveField(4)
  final DateTime dateCreation;

  @HiveField(5)
  final bool isActive;

  @HiveField(6)
  final int nombreLieux;

  @HiveField(7)
  final int nombreEvenements;

  HiveUtilisateur({
    required this.id,
    required this.username,
    required this.email,
    this.tel,
    required this.dateCreation,
    required this.isActive,
    required this.nombreLieux,
    required this.nombreEvenements,
  });
}

@HiveType(typeId: 1)
class HiveLieu {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nom;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String categorie;

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final DateTime dateCreation;

  @HiveField(7)
  final String proprietaireNom;

  @HiveField(8)
  final String proprietaireId;

  @HiveField(9)
  final int nombreEvenements;

  @HiveField(10)
  final double? moyenneAvis;

  HiveLieu({
    required this.id,
    required this.nom,
    required this.description,
    required this.categorie,
    required this.latitude,
    required this.longitude,
    required this.dateCreation,
    required this.proprietaireNom,
    required this.proprietaireId,
    required this.nombreEvenements,
    this.moyenneAvis,
  });
}

@HiveType(typeId: 2)
class HiveEvenement {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nom;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime dateDebut;

  @HiveField(4)
  final DateTime dateFin;

  @HiveField(5)
  final String lieuId;

  @HiveField(6)
  final String lieuNom;

  @HiveField(7)
  final double? lieuLatitude;

  @HiveField(8)
  final double? lieuLongitude;

  @HiveField(9)
  final String organisateurId;

  @HiveField(10)
  final String organisateurNom;

  @HiveField(11)
  final double? moyenneAvis;

  @HiveField(12)
  final int nombreAvis;

  @HiveField(13)
  final double? distance;

  HiveEvenement({
    required this.id,
    required this.nom,
    required this.description,
    required this.dateDebut,
    required this.dateFin,
    required this.lieuId,
    required this.lieuNom,
    this.lieuLatitude,
    this.lieuLongitude,
    required this.organisateurId,
    required this.organisateurNom,
    this.moyenneAvis,
    required this.nombreAvis,
    this.distance,
  });
}

@HiveType(typeId: 3)
class HiveLocation {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final String? address;

  @HiveField(3)
  final String? city;

  @HiveField(4)
  final String? quartier;

  @HiveField(5)
  final String source;

  @HiveField(6)
  final DateTime cachedAt;

  HiveLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.quartier,
    required this.source,
    required this.cachedAt,
  });
}