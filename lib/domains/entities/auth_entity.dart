import 'package:equatable/equatable.dart';

class AuthenticationEntity extends Equatable {
  final UtilisateurAuthEntity utilisateur;
  final String token;

  const AuthenticationEntity({
    required this.utilisateur,
    required this.token,
  });

  @override
  List<Object?> get props => [utilisateur, token];
}

class UtilisateurAuthEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? tel;
  final DateTime dateCreation;
  final bool isActive;

  const UtilisateurAuthEntity({
    required this.id,
    required this.username,
    required this.email,
    this.tel,
    required this.dateCreation,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    tel,
    dateCreation,
    isActive,
  ];
}