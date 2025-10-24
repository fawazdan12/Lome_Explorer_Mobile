import 'package:equatable/equatable.dart';

class StatistiquesEntity extends Equatable {
  final int nombreLieux;
  final int nombreEvenements;
  final int nombreUtilisateurs;
  final int nombreAvisLieux;
  final int nombreAvisEvenements;
  final int evenementsAVenir;

  const StatistiquesEntity({
    required this.nombreLieux,
    required this.nombreEvenements,
    required this.nombreUtilisateurs,
    required this.nombreAvisLieux,
    required this.nombreAvisEvenements,
    required this.evenementsAVenir,
  });

  @override
  List<Object?> get props => [
    nombreLieux,
    nombreEvenements,
    nombreUtilisateurs,
    nombreAvisLieux,
    nombreAvisEvenements,
    evenementsAVenir,
  ];
}