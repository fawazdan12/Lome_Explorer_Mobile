import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? quartier;
  final String source; // 'gps', 'ip', 'default'

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.quartier,
    required this.source,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    address,
    city,
    quartier,
    source,
  ];
}

class NearbyPlaceEntity extends Equatable {
  final String lieuId;
  final String lieuNom;
  final String categorie;
  final double latitude;
  final double longitude;
  final double distance; // en km
  final int nombreEvenements;

  const NearbyPlaceEntity({
    required this.lieuId,
    required this.lieuNom,
    required this.categorie,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.nombreEvenements,
  });

  @override
  List<Object?> get props => [
    lieuId,
    lieuNom,
    categorie,
    latitude,
    longitude,
    distance,
    nombreEvenements,
  ];
}

class QuartierEntity extends Equatable {
  final String key;
  final String nom;
  final double latitude;
  final double longitude;

  const QuartierEntity({
    required this.key,
    required this.nom,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [key, nom, latitude, longitude];
}