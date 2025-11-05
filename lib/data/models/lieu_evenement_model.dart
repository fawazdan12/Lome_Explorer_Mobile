import 'package:equatable/equatable.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:logger/logger.dart';

// Logger global pour les models
final _logger = Logger();

// ==================== MODELS LIEU ====================

class LieuModel extends Equatable {
  final String id;
  final String nom;
  final String description;
  final String categorie;
  final double latitude;
  final double longitude;
  final DateTime dateCreation;
  final String proprietaireNom;
  final String proprietaireId;
  final int nombreEvenements;
  final double? moyenneAvis;

  const LieuModel({
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

  factory LieuModel.fromJson(Map<String, dynamic> json) {
    _logger.d('🔍 === DIAGNOSTIC COMPLET LIEU ===');
    _logger.d('📦 JSON BRUT COMPLET:');
    _logger.d(json.toString());
    _logger.d('');
    
    _logger.d('🔑 Clés disponibles: ${json.keys.toList()}');
    _logger.d('');
    
    // Diagnostic proprietaire
    _logger.d('👤 PROPRIÉTAIRE:');
    _logger.d('  ├─ json["proprietaire"] = ${json['proprietaire']}');
    _logger.d('  ├─ Type: ${json['proprietaire'].runtimeType}');
    _logger.d('  ├─ json["proprietaire_id"] = ${json['proprietaire_id']}');
    _logger.d('  ├─ Type: ${json['proprietaire_id'].runtimeType}');
    _logger.d('  └─ json["proprietaire_nom"] = ${json['proprietaire_nom']}');
    _logger.d('');

    String proprietaireId = '';
    
    // ✅ PRIORITÉ 1 : Vérifier proprietaire_id en premier
    if (json['proprietaire_id'] != null && json['proprietaire_id'].toString().isNotEmpty) {
      proprietaireId = json['proprietaire_id'].toString();
      _logger.d('✅ proprietaire_id trouvé: "$proprietaireId"');
    }
    // PRIORITÉ 2 : Essayer proprietaire
    else if (json['proprietaire'] != null) {
      if (json['proprietaire'] is String) {
        proprietaireId = json['proprietaire'] as String;
        _logger.d('✅ proprietaire (string) trouvé: "$proprietaireId"');
      } else if (json['proprietaire'] is Map) {
        final propMap = json['proprietaire'] as Map<String, dynamic>;
        proprietaireId = propMap['id']?.toString() ?? '';
        _logger.d('✅ proprietaire.id (map) trouvé: "$proprietaireId"');
      }
    }
    
    _logger.d('🎯 RÉSULTAT FINAL: proprietaireId = "$proprietaireId"');
    _logger.d('================================\n');

    // Extraction sécurisée de la description
    String description = '';
    if (json['description'] != null) {
      description = json['description'].toString().trim();
    }

    return LieuModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: description,
      categorie: json['categorie'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'] as String)
          : DateTime.now(),
      proprietaireNom: json['proprietaire_nom'] as String? ?? 'Inconnu',
      proprietaireId: proprietaireId,
      nombreEvenements: json['nombre_evenements'] as int? ?? 0,
      moyenneAvis: json['moyenne_avis'] != null
          ? double.parse(json['moyenne_avis'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'categorie': categorie,
      'latitude': latitude,
      'longitude': longitude,
      'date_creation': dateCreation.toIso8601String(),
      'proprietaire_nom': proprietaireNom,
      'proprietaire_id': proprietaireId,  // ✅ Utiliser proprietaire_id
      'nombre_evenements': nombreEvenements,
      'moyenne_avis': moyenneAvis,
    };
  }

  LieuEntity toEntity() {
    _logger.d('LieuModel.toEntity - "$nom"');
    _logger.d(' proprietaireId: "$proprietaireId"');
    _logger.d(' description: "${description.length > 0 ? description.substring(0, description.length > 50 ? 50 : description.length) : '(vide)'}"...');

    return LieuEntity(
      id: id,
      nom: nom,
      description: description,
      categorie: categorie,
      latitude: latitude,
      longitude: longitude,
      dateCreation: dateCreation,
      proprietaireNom: proprietaireNom,
      proprietaireId: proprietaireId,
      nombreEvenements: nombreEvenements,
      moyenneAvis: moyenneAvis,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nom,
    description,
    categorie,
    latitude,
    longitude,
    dateCreation,
    proprietaireNom,
    proprietaireId,
    nombreEvenements,
    moyenneAvis,
  ];

  @override
  String toString() {
    return 'LieuModel(id: $id, nom: $nom, proprietaireId: $proprietaireId, categorie: $categorie)';
  }
}

// ==================== MODELS ÉVÉNEMENT ====================

class EvenementModel extends Equatable {
  final String id;
  final String nom;
  final String description;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String lieuId;
  final String lieuNom;
  final double? lieuLatitude;
  final double? lieuLongitude;
  final String organisateurId;
  final String organisateurNom;
  final double? moyenneAvis;
  final int nombreAvis;
  final double? distance;

  const EvenementModel({
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

  factory EvenementModel.fromJson(Map<String, dynamic> json) {
    _logger.d('📦 EvenementModel.fromJson - Parsing événement: ${json['nom']}');
    
    // Debug organisateur
    _logger.d('👤 ORGANISATEUR:');
    _logger.d('  ├─ json["organisateur"] = ${json['organisateur']}');
    _logger.d('  ├─ json["organisateur_id"] = ${json['organisateur_id']}');
    _logger.d('  └─ json["organisateur_nom"] = ${json['organisateur_nom']}');

    // Extraction organisateur_id
    String organisateurId = '';
    if (json['organisateur_id'] != null && json['organisateur_id'].toString().isNotEmpty) {
      organisateurId = json['organisateur_id'].toString();
      _logger.d('✅ organisateur_id trouvé: "$organisateurId"');
    } else if (json['organisateur'] != null) {
      if (json['organisateur'] is String) {
        organisateurId = json['organisateur'] as String;
      } else if (json['organisateur'] is Map) {
        organisateurId = (json['organisateur'] as Map)['id']?.toString() ?? '';
      }
    }

    // Extraction sécurisée de la description
    String description = '';
    if (json['description'] != null) {
      description = json['description'].toString().trim();
    }

    return EvenementModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: description,
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      lieuId: json['lieu'] as String? ?? '',
      lieuNom: json['lieu_nom'] as String,
      lieuLatitude: json['lieu_latitude'] != null
          ? double.parse(json['lieu_latitude'].toString())
          : null,
      lieuLongitude: json['lieu_longitude'] != null
          ? double.parse(json['lieu_longitude'].toString())
          : null,
      organisateurId: organisateurId,
      organisateurNom: json['organisateur_nom'] as String,
      moyenneAvis: json['moyenne_avis'] != null
          ? double.parse(json['moyenne_avis'].toString())
          : null,
      nombreAvis: json['nombre_avis'] as int? ?? 0,
      distance: json['distance'] != null
          ? double.parse(json['distance'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin.toIso8601String(),
      'lieu': lieuId,
      'lieu_nom': lieuNom,
      'lieu_latitude': lieuLatitude,
      'lieu_longitude': lieuLongitude,
      'organisateur_id': organisateurId,  // ✅ Utiliser organisateur_id
      'organisateur_nom': organisateurNom,
      'moyenne_avis': moyenneAvis,
      'nombre_avis': nombreAvis,
      'distance': distance,
    };
  }

  EvenementEntity toEntity() {
    return EvenementEntity(
      id: id,
      nom: nom,
      description: description,
      dateDebut: dateDebut,
      dateFin: dateFin,
      lieuId: lieuId,
      lieuNom: lieuNom,
      lieuLatitude: lieuLatitude,
      lieuLongitude: lieuLongitude,
      organisateurId: organisateurId,
      organisateurNom: organisateurNom,
      moyenneAvis: moyenneAvis,
      nombreAvis: nombreAvis,
      distance: distance,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nom,
    description,
    dateDebut,
    dateFin,
    lieuId,
    lieuNom,
    lieuLatitude,
    lieuLongitude,
    organisateurId,
    organisateurNom,
    moyenneAvis,
    nombreAvis,
    distance,
  ];

  @override
  String toString() {
    return 'EvenementModel(id: $id, nom: $nom, organisateurId: $organisateurId, lieu: $lieuNom)';
  }
}