import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/auth_entity.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/utilisateur_entity.dart';


/// Contrat du repository d'authentification
abstract class AuthenticationRepository {
  /// Enregistrer un nouvel utilisateur
  Future<Either<Failure, AuthenticationEntity>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? tel,
  });

  /// Connecter un utilisateur
  Future<Either<Failure, AuthenticationEntity>> login({
    required String email,
    required String password,
  });

  /// Déconnecter l'utilisateur
  Future<Either<Failure, void>> logout();

  /// Obtenir le profil de l'utilisateur
  Future<Either<Failure, UtilisateurEntity>> getProfile();

  /// Obtenir l'utilisateur en cache
  Future<Either<Failure, UtilisateurEntity?>> getCachedUtilisateur();

  /// Vérifier si l'utilisateur est authentifié
  bool get isAuthenticated;

  /// Obtenir le token actuel
  String? get token;
}