import 'package:equatable/equatable.dart';

class UtilisateurEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? tel;
  final DateTime dateCreation;
  final bool isActive;
  final int nombreLieux;
  final int nombreEvenements;

  const UtilisateurEntity({
    required this.id,
    required this.username,
    required this.email,
    this.tel,
    required this.dateCreation,
    required this.isActive,
    required this.nombreLieux,
    required this.nombreEvenements,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    tel,
    dateCreation,
    isActive,
    nombreLieux,
    nombreEvenements,
  ];
}