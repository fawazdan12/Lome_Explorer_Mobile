import 'package:equatable/equatable.dart';

class AvisLieuEntity extends Equatable {
  final String id;
  final int note;
  final String texte;
  final DateTime date;
  final String utilisateurId;
  final String utilisateurNom;
  final String lieuId;
  final String lieuNom;

  const AvisLieuEntity({
    required this.id,
    required this.note,
    required this.texte,
    required this.date,
    required this.utilisateurId,
    required this.utilisateurNom,
    required this.lieuId,
    required this.lieuNom,
  });

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

class AvisEvenementEntity extends Equatable {
  final String id;
  final int note;
  final String texte;
  final DateTime date;
  final String utilisateurId;
  final String utilisateurNom;
  final String evenementId;
  final String evenementNom;

  const AvisEvenementEntity({
    required this.id,
    required this.note,
    required this.texte,
    required this.date,
    required this.utilisateurId,
    required this.utilisateurNom,
    required this.evenementId,
    required this.evenementNom,
  });

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