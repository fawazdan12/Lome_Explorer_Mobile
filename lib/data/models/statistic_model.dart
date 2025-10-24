import 'package:equatable/equatable.dart';
import 'package:event_flow/domains/entities/statistic_entity.dart';


class StatistiquesModel extends Equatable {
  final int nombreLieux;
  final int nombreEvenements;
  final int nombreUtilisateurs;
  final int nombreAvisLieux;
  final int nombreAvisEvenements;
  final int evenementsAVenir;

  const StatistiquesModel({
    required this.nombreLieux,
    required this.nombreEvenements,
    required this.nombreUtilisateurs,
    required this.nombreAvisLieux,
    required this.nombreAvisEvenements,
    required this.evenementsAVenir,
  });

  factory StatistiquesModel.fromJson(Map<String, dynamic> json) {
    return StatistiquesModel(
      nombreLieux: json['nombre_lieux'] as int? ?? 0,
      nombreEvenements: json['nombre_evenements'] as int? ?? 0,
      nombreUtilisateurs: json['nombre_utilisateurs'] as int? ?? 0,
      nombreAvisLieux: json['nombre_avis_lieux'] as int? ?? 0,
      nombreAvisEvenements: json['nombre_avis_evenements'] as int? ?? 0,
      evenementsAVenir: json['evenements_a_venir'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_lieux': nombreLieux,
      'nombre_evenements': nombreEvenements,
      'nombre_utilisateurs': nombreUtilisateurs,
      'nombre_avis_lieux': nombreAvisLieux,
      'nombre_avis_evenements': nombreAvisEvenements,
      'evenements_a_venir': evenementsAVenir,
    };
  }

  StatistiquesEntity toEntity() {
    return StatistiquesEntity(
      nombreLieux: nombreLieux,
      nombreEvenements: nombreEvenements,
      nombreUtilisateurs: nombreUtilisateurs,
      nombreAvisLieux: nombreAvisLieux,
      nombreAvisEvenements: nombreAvisEvenements,
      evenementsAVenir: evenementsAVenir,
    );
  }

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