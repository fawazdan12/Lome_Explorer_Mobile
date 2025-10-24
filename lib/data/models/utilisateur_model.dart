import 'package:equatable/equatable.dart';
import 'package:event_flow/domains/entities/utilisateur_entity.dart';


class UtilisateurModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? tel;
  final DateTime dateCreation;
  final bool isActive;
  final int nombreLieux;
  final int nombreEvenements;

  const UtilisateurModel({
    required this.id,
    required this.username,
    required this.email,
    this.tel,
    required this.dateCreation,
    required this.isActive,
    required this.nombreLieux,
    required this.nombreEvenements,
  });

  /// Convertir JSON en Model
  factory UtilisateurModel.fromJson(Map<String, dynamic> json) {
    return UtilisateurModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      tel: json['tel'] as String?,
      dateCreation: DateTime.parse(json['date_creation'] as String),
      isActive: json['is_active'] as bool? ?? true,
      nombreLieux: json['nombre_lieux'] as int? ?? 0,
      nombreEvenements: json['nombre_evenements'] as int? ?? 0,
    );
  }

  /// Convertir Model en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'tel': tel,
      'date_creation': dateCreation.toIso8601String(),
      'is_active': isActive,
      'nombre_lieux': nombreLieux,
      'nombre_evenements': nombreEvenements,
    };
  }

  /// Convertir Model en Entity
  UtilisateurEntity toEntity() {
    return UtilisateurEntity(
      id: id,
      username: username,
      email: email,
      tel: tel,
      dateCreation: dateCreation,
      isActive: isActive,
      nombreLieux: nombreLieux,
      nombreEvenements: nombreEvenements,
    );
  }

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

class AuthenticationModel extends Equatable {
  final UtilisateurModel utilisateur;
  final String token;

  const AuthenticationModel({
    required this.utilisateur,
    required this.token,
  });

  factory AuthenticationModel.fromJson(Map<String, dynamic> json) {
    return AuthenticationModel(
      utilisateur: UtilisateurModel.fromJson(
        json['user'] as Map<String, dynamic>,
      ),
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': utilisateur.toJson(),
      'token': token,
    };
  }

  @override
  List<Object?> get props => [utilisateur, token];
}