import 'package:equatable/equatable.dart';

class LieuEntity extends Equatable {
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

  const LieuEntity({
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
    return 'LieuEntity(id: $id, nom: $nom, categorie: $categorie, '
        'latitude: $latitude, longitude: $longitude, '
        'nombreEvenements: $nombreEvenements, moyenneAvis: $moyenneAvis)';
  }
}