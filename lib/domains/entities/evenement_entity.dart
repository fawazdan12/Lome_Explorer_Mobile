import 'package:equatable/equatable.dart';

class EvenementEntity extends Equatable {
  final String id;
  final String nom;
  final String? description;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? lieuId;
  final String lieuNom;
  final double? lieuLatitude;
  final double? lieuLongitude;
  final String? organisateurId;
  final String organisateurNom;
  final double? moyenneAvis;
  final int nombreAvis;
  final double? distance; 

  const EvenementEntity({
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
}