import 'package:dartz/dartz.dart';
import 'package:event_flow/domains/entities/erreur_entity.dart';


// Typedefs pour simplifier le code avec Either
typedef ResultVoid = Future<Either<Failure, void>>;
typedef ResultEntity<T> = Future<Either<Failure, T>>;
typedef ResultList<T> = Future<Either<Failure, List<T>>>;
typedef ResultMap = Future<Either<Failure, Map<String, dynamic>>>;

// Typedefs pour les callbacks
typedef OnSuccess<T> = void Function(T result);
typedef OnError = void Function(String error);
typedef OnLoading = void Function();

// Typedefs pour les transformations
typedef JsonToEntity<T> = T Function(Map<String, dynamic> json);
typedef EntityToJson<T> = Map<String, dynamic> Function(T entity);

// Typedefs pour les pagination
typedef FuturePagedResult<T> = Future<Either<Failure, List<T>>>;

// Typedef pour les query parameters
typedef QueryParams = Map<String, dynamic>;