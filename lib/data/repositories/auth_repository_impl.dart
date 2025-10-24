import 'package:dartz/dartz.dart';
import 'package:event_flow/config/api_execption.dart';
import 'package:event_flow/core/services/auth_service.dart';
import 'package:event_flow/domains/entities/auth_entity.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';
import 'package:event_flow/domains/entities/utilisateur_entity.dart';
import 'package:event_flow/domains/repositories/auth_repository.dart';
import 'package:logger/logger.dart';


class AuthenticationRepositoryImpl implements AuthenticationRepository {
  final AuthenticationService _authService;
  final Logger _logger;

  AuthenticationRepositoryImpl({
    required AuthenticationService authService,
    required Logger logger,
  })  : _authService = authService,
        _logger = logger;

  @override
  Future<Either<Failure, AuthenticationEntity>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? tel,
  }) async {
    try {
      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        tel: tel,
      );

      return Right(
        AuthenticationEntity(
          utilisateur: UtilisateurAuthEntity(
            id: result.utilisateur.id,
            username: result.utilisateur.username,
            email: result.utilisateur.email,
            tel: result.utilisateur.tel,
            dateCreation: result.utilisateur.dateCreation,
            isActive: result.utilisateur.isActive,
          ),
          token: result.token,
        ),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, AuthenticationEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      return Right(
        AuthenticationEntity(
          utilisateur: UtilisateurAuthEntity(
            id: result.utilisateur.id,
            username: result.utilisateur.username,
            email: result.utilisateur.email,
            tel: result.utilisateur.tel,
            dateCreation: result.utilisateur.dateCreation,
            isActive: result.utilisateur.isActive,
          ),
          token: result.token,
        ),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _authService.logout();
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, UtilisateurEntity>> getProfile() async {
    try {
      final utilisateur = await _authService.getProfile();

      return Right(
        UtilisateurEntity(
          id: utilisateur.id,
          username: utilisateur.username,
          email: utilisateur.email,
          tel: utilisateur.tel,
          dateCreation: utilisateur.dateCreation,
          isActive: utilisateur.isActive,
          nombreLieux: utilisateur.nombreLieux,
          nombreEvenements: utilisateur.nombreEvenements,
        ),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, UtilisateurEntity?>> getCachedUtilisateur() async {
    try {
      final utilisateur = await _authService.getCachedUtilisateur();

      if (utilisateur == null) {
        return const Right(null);
      }

      return Right(
        UtilisateurEntity(
          id: utilisateur.id,
          username: utilisateur.username,
          email: utilisateur.email,
          tel: utilisateur.tel,
          dateCreation: utilisateur.dateCreation,
          isActive: utilisateur.isActive,
          nombreLieux: utilisateur.nombreLieux,
          nombreEvenements: utilisateur.nombreEvenements,
        ),
      );
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  bool get isAuthenticated => _authService.isAuthenticated;

  @override
  String? get token => _authService.token;

  // ==================== HELPERS ====================

  Failure _mapException(dynamic exception) {
    _logger.e('Erreur authentification: $exception');

    if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message);
    } else if (exception is ApiException) {
      if (exception.statusCode == 401 || exception.statusCode == 403) {
        return AuthenticationFailure(exception.message);
      }
      return ServerFailure(exception.message);
    } else {
      return UnknownFailure(exception.toString());
    }
  }
}