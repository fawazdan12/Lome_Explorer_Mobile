import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/auth_entity.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/utilisateur_entity.dart';
import 'package:event_flow/domains/repositories/auth_repository.dart';


// ==================== REGISTER ====================

class RegisterUseCase {
  final AuthenticationRepository _repository;

  RegisterUseCase(this._repository);

  Future<Either<Failure, AuthenticationEntity>> call({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? tel,
  }) {
    return _repository.register(
      username: username,
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      tel: tel,
    );
  }
}

// ==================== LOGIN ====================

class LoginUseCase {
  final AuthenticationRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<Failure, AuthenticationEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(
      email: email,
      password: password,
    );
  }
}

// ==================== LOGOUT ====================

class LogoutUseCase {
  final AuthenticationRepository _repository;

  LogoutUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}

// ==================== GET PROFILE ====================

class GetProfileUseCase {
  final AuthenticationRepository _repository;

  GetProfileUseCase(this._repository);

  Future<Either<Failure, UtilisateurEntity>> call() {
    return _repository.getProfile();
  }
}

// ==================== GET CACHED USER ====================

class GetCachedUtilisateurUseCase {
  final AuthenticationRepository _repository;

  GetCachedUtilisateurUseCase(this._repository);

  Future<Either<Failure, UtilisateurEntity?>> call() {
    return _repository.getCachedUtilisateur();
  }
}

// ==================== CHECK AUTHENTICATION ====================

class CheckAuthenticationUseCase {
  final AuthenticationRepository _repository;

  CheckAuthenticationUseCase(this._repository);

  bool call() {
    return _repository.isAuthenticated;
  }
}

// ==================== GET TOKEN ====================

class GetTokenUseCase {
  final AuthenticationRepository _repository;

  GetTokenUseCase(this._repository);

  String? call() {
    return _repository.token;
  }
}