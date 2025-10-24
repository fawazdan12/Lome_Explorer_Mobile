import 'package:equatable/equatable.dart';
import 'package:event_flow/domains/entities/avis_lieu_evenement_entity.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';


// ==================== MODELS AVIS LIEU ====================

class AvisLieuModel extends Equatable {
  final String id;
  final int note;
  final String texte;
  final DateTime date;
  final String utilisateurId;
  final String utilisateurNom;
  final String lieuId;
  final String lieuNom;

  const AvisLieuModel({
    required this.id,
    required this.note,
    required this.texte,
    required this.date,
    required this.utilisateurId,
    required this.utilisateurNom,
    required this.lieuId,
    required this.lieuNom,
  });

  factory AvisLieuModel.fromJson(Map<String, dynamic> json) {
    return AvisLieuModel(
      id: json['id'] as String,
      note: json['note'] as int,
      texte: json['texte'] as String,
      date: DateTime.parse(json['date'] as String),
      utilisateurId: json['utilisateur'] as String? ?? '',
      utilisateurNom: json['utilisateur_nom'] as String,
      lieuId: json['lieu'] as String? ?? '',
      lieuNom: json['lieu_nom'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'texte': texte,
      'date': date.toIso8601String(),
      'utilisateur': utilisateurId,
      'utilisateur_nom': utilisateurNom,
      'lieu': lieuId,
      'lieu_nom': lieuNom,
    };
  }

  AvisLieuEntity toEntity() {
    return AvisLieuEntity(
      id: id,
      note: note,
      texte: texte,
      date: date,
      utilisateurId: utilisateurId,
      utilisateurNom: utilisateurNom,
      lieuId: lieuId,
      lieuNom: lieuNom,
    );
  }

  @override
  List<Object?> get props => [
    id,
    note,
    texte,
    date,
    utilisateurId,
    utilisateurNom,
    lieuId,
    lieuNom,
  ];
}

// ==================== MODELS AVIS ÉVÉNEMENT ====================

class AvisEvenementModel extends Equatable {
  final String id;
  final int note;
  final String texte;
  final DateTime date;
  final String utilisateurId;
  final String utilisateurNom;
  final String evenementId;
  final String evenementNom;

  const AvisEvenementModel({
    required this.id,
    required this.note,
    required this.texte,
    required this.date,
    required this.utilisateurId,
    required this.utilisateurNom,
    required this.evenementId,
    required this.evenementNom,
  });

  factory AvisEvenementModel.fromJson(Map<String, dynamic> json) {
    return AvisEvenementModel(
      id: json['id'] as String,
      note: json['note'] as int,
      texte: json['texte'] as String,
      date: DateTime.parse(json['date'] as String),
      utilisateurId: json['utilisateur'] as String? ?? '',
      utilisateurNom: json['utilisateur_nom'] as String,
      evenementId: json['evenement'] as String? ?? '',
      evenementNom: json['evenement_nom'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'texte': texte,
      'date': date.toIso8601String(),
      'utilisateur': utilisateurId,
      'utilisateur_nom': utilisateurNom,
      'evenement': evenementId,
      'evenement_nom': evenementNom,
    };
  }

  AvisEvenementEntity toEntity() {
    return AvisEvenementEntity(
      id: id,
      note: note,
      texte: texte,
      date: date,
      utilisateurId: utilisateurId,
      utilisateurNom: utilisateurNom,
      evenementId: evenementId,
      evenementNom: evenementNom,
    );
  }

  @override
  List<Object?> get props => [
    id,
    note,
    texte,
    date,
    utilisateurId,
    utilisateurNom,
    evenementId,
    evenementNom,
  ];
}

// ==================== MODELS GÉOLOCALISATION ====================

class LocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? quartier;
  final String source;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.quartier,
    required this.source,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address'] as String?,
      city: json['city'] as String? ?? json['ville'] as String?,
      quartier: json['quartier'] as String?,
      source: json['source'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'quartier': quartier,
      'source': source,
    };
  }

  LocationEntity toEntity() {
    return LocationEntity(
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      quartier: quartier,
      source: source,
    );
  }

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

class NearbyPlaceModel extends Equatable {
  final String lieuId;
  final String lieuNom;
  final String categorie;
  final double latitude;
  final double longitude;
  final double distance;
  final int nombreEvenements;

  const NearbyPlaceModel({
    required this.lieuId,
    required this.lieuNom,
    required this.categorie,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.nombreEvenements,
  });

  factory NearbyPlaceModel.fromJson(Map<String, dynamic> json) {
    return NearbyPlaceModel(
      lieuId: json['id'] as String,
      lieuNom: json['nom'] as String,
      categorie: json['categorie'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      distance: double.parse(json['distance'].toString()),
      nombreEvenements: json['nombre_evenements'] as int? ?? 0,
    );
  }

  NearbyPlaceEntity toEntity() {
    return NearbyPlaceEntity(
      lieuId: lieuId,
      lieuNom: lieuNom,
      categorie: categorie,
      latitude: latitude,
      longitude: longitude,
      distance: distance,
      nombreEvenements: nombreEvenements,
    );
  }

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

class QuartierModel extends Equatable {
  final String key;
  final String nom;
  final double latitude;
  final double longitude;

  const QuartierModel({
    required this.key,
    required this.nom,
    required this.latitude,
    required this.longitude,
  });

  factory QuartierModel.fromJson(Map<String, dynamic> json) {
    return QuartierModel(
      key: json['key'] as String,
      nom: json['nom'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }

  QuartierEntity toEntity() {
    return QuartierEntity(
      key: key,
      nom: nom,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  List<Object?> get props => [key, nom, latitude, longitude];
}