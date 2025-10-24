import 'package:dio/dio.dart';
import 'package:event_flow/config/app_config.dart';
import 'package:event_flow/core/services/avis_service.dart';
import 'package:event_flow/core/services/auth_service.dart';
import 'package:event_flow/core/services/geolocation_service.dart';
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/data/datasource/local/cache_hive_datasource.dart';
import 'package:event_flow/data/datasource/remote/api_datasource_remote.dart';
import 'package:event_flow/domains/repositories/avis_repository.dart';
import 'package:event_flow/domains/repositories/auth_repository.dart';
import 'package:event_flow/domains/repositories/geo_repository.dart';
import 'package:event_flow/domains/repositories/lieu_evenement_repository.dart';
import 'package:event_flow/data/repositories/auth_repository_impl.dart';
import 'package:event_flow/data/repositories/avis_repository_impl.dart';
import 'package:event_flow/data/repositories/geo_repository_impl.dart';
import 'package:event_flow/data/repositories/lieu_evenement_repository_impl.dart';
import 'package:event_flow/domains/uscases/auth_uscase.dart';
import 'package:event_flow/domains/uscases/avis_usecase.dart';
import 'package:event_flow/domains/uscases/geo_usecase.dart';
import 'package:event_flow/domains/uscases/lieu_evenement_uscase.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

/// Initialiser tous les services et dépendances
Future<void> setupServiceLocator() async {
  // ==================== LOGGER ====================
  _setupLogger();

  // ==================== SHARED PREFERENCES ====================
  await _setupSharedPreferences();

  // ==================== LOCAL DATA SOURCE (HIVE) ====================
  await _setupLocalDataSource();

  // ==================== DIO ====================
  _setupDio();

  // ==================== REMOTE DATA SOURCE ====================
  _setupRemoteDataSource();

  // ==================== SERVICES ====================
  _setupServices();

  // ==================== REPOSITORIES ====================
  _setupRepositories();

  // ==================== USE CASES ====================
  _setupUseCases();
}

// ==================== LOGGER ====================

void _setupLogger() {
  getIt.registerSingleton<Logger>(
    Logger(),
  );
}

// ==================== SHARED PREFERENCES ====================

Future<void> _setupSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
}

// ==================== LOCAL DATA SOURCE ====================

Future<void> _setupLocalDataSource() async {
  final localDataSource = LocalDataSource(logger: getIt<Logger>());
  await localDataSource.initialize();
  getIt.registerSingleton<LocalDataSource>(localDataSource);
}

// ==================== DIO ====================

void _setupDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectionTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      contentType: ApiConstants.contentTypeJson,
    ),
  );

  getIt.registerSingleton<Dio>(dio);
}

// ==================== REMOTE DATA SOURCE ====================

void _setupRemoteDataSource() {
  getIt.registerSingleton<RemoteDataSource>(
    RemoteDataSource(
      dio: getIt<Dio>(),
      logger: getIt<Logger>(),
      preferences: getIt<SharedPreferences>(), // AJOUT
    ),
  );
}

// ==================== SERVICES ====================

void _setupServices() {
  // Auth Service
    final authService = AuthenticationService(
      remoteDataSource: getIt<RemoteDataSource>(),
      localDataSource: getIt<LocalDataSource>(),
      preferences: getIt<SharedPreferences>(),
      logger: getIt<Logger>(),
  
  );

  authService.initializeTokenFromCache();
  getIt.registerSingleton<AuthenticationService>(authService);

  // Avis Service
  getIt.registerSingleton<AvisService>(
    AvisService(
      remoteDataSource: getIt<RemoteDataSource>(),
      logger: getIt<Logger>(),
    ),
  );

  // Geolocation Service
  getIt.registerSingleton<GeolocationService>(
    GeolocationService(
      remoteDataSource: getIt<RemoteDataSource>(),
      localDataSource: getIt<LocalDataSource>(),
      logger: getIt<Logger>(),
    ),
  );

  // Lieu Evenement Service
  getIt.registerSingleton<LieuEvenementService>(
    LieuEvenementService(
      remoteDataSource: getIt<RemoteDataSource>(),
      localDataSource: getIt<LocalDataSource>(),
      logger: getIt<Logger>(),
    ),
  );
}

// ==================== REPOSITORIES ====================

void _setupRepositories() {
  // Auth Repository
  getIt.registerSingleton<AuthenticationRepository>(
    AuthenticationRepositoryImpl(
      authService: getIt<AuthenticationService>(),
      logger: getIt<Logger>(),
    ),
  );

  // Avis Repository
  getIt.registerSingleton<AvisRepository>(
    AvisRepositoryImpl(
      service: getIt<AvisService>(),
      logger: getIt<Logger>(),
    ),
  );

  // Geolocation Repository
  getIt.registerSingleton<GeolocationRepository>(
    GeolocationRepositoryImpl(
      service: getIt<GeolocationService>(),
      logger: getIt<Logger>(),
    ),
  );

  // Lieu Evenement Repository
  getIt.registerSingleton<LieuEvenementRepository>(
    LieuEvenementRepositoryImpl(
      service: getIt<LieuEvenementService>(),
      logger: getIt<Logger>(),
    ),
  );
}

// ==================== USE CASES ====================

void _setupUseCases() {
  // Auth Use Cases
  getIt.registerSingleton<RegisterUseCase>(
    RegisterUseCase(getIt<AuthenticationRepository>()),
  );
  getIt.registerSingleton<LoginUseCase>(
    LoginUseCase(getIt<AuthenticationRepository>()),
  );
  getIt.registerSingleton<LogoutUseCase>(
    LogoutUseCase(getIt<AuthenticationRepository>()),
  );
  getIt.registerSingleton<GetProfileUseCase>(
    GetProfileUseCase(getIt<AuthenticationRepository>()),
  );
  getIt.registerSingleton<GetCachedUtilisateurUseCase>(
    GetCachedUtilisateurUseCase(getIt<AuthenticationRepository>()),
  );
  getIt.registerSingleton<CheckAuthenticationUseCase>(
    CheckAuthenticationUseCase(getIt<AuthenticationRepository>()),
  );
  getIt.registerSingleton<GetTokenUseCase>(
    GetTokenUseCase(getIt<AuthenticationRepository>()),
  );

  // Avis Use Cases
  getIt.registerSingleton<GetAvisLieuUseCase>(
    GetAvisLieuUseCase(getIt<AvisRepository>()),
  );
  getIt.registerSingleton<CreateAvisLieuUseCase>(
    CreateAvisLieuUseCase(getIt<AvisRepository>()),
  );
  getIt.registerSingleton<UpdateAvisLieuUseCase>(
    UpdateAvisLieuUseCase(getIt<AvisRepository>()),
  );
  getIt.registerSingleton<DeleteAvisLieuUseCase>(
    DeleteAvisLieuUseCase(getIt<AvisRepository>()),
  );
  getIt.registerSingleton<GetAvisEvenementUseCase>(
    GetAvisEvenementUseCase(getIt<AvisRepository>()),
  );
  getIt.registerSingleton<CreateAvisEvenementUseCase>(
    CreateAvisEvenementUseCase(getIt<AvisRepository>()),
  );
  getIt.registerSingleton<UpdateAvisEvenementUseCase>(
    UpdateAvisEvenementUseCase(getIt<AvisRepository>()),
  );
  getIt.registerSingleton<DeleteAvisEvenementUseCase>(
    DeleteAvisEvenementUseCase(getIt<AvisRepository>()),
  );

  // Geolocation Use Cases
  getIt.registerSingleton<DetectLocationUseCase>(
    DetectLocationUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<GetCachedLocationUseCase>(
    GetCachedLocationUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<GeocodeAddressUseCase>(
    GeocodeAddressUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<GetQuartiersUseCase>(
    GetQuartiersUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<ValidateLomeLocationUseCase>(
    ValidateLomeLocationUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<CalculateDistanceUseCase>(
    CalculateDistanceUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<WatchPositionUseCase>(
    WatchPositionUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<IsLocationServiceEnabledUseCase>(
    IsLocationServiceEnabledUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<OpenLocationSettingsUseCase>(
    OpenLocationSettingsUseCase(getIt<GeolocationRepository>()),
  );
  getIt.registerSingleton<OpenAppSettingsUseCase>(
    OpenAppSettingsUseCase(getIt<GeolocationRepository>()),
  );

  // Lieu Evenement Use Cases
  getIt.registerSingleton<GetLieuxUseCase>(
    GetLieuxUseCase(getIt<LieuEvenementRepository>()),
  );
  getIt.registerSingleton<GetLieuByIdUseCase>(
    GetLieuByIdUseCase(getIt<LieuEvenementRepository>()),
  );
  getIt.registerSingleton<CreateLieuUseCase>(
    CreateLieuUseCase(getIt<LieuEvenementRepository>()),
  );
  getIt.registerSingleton<GetNearbyPlacesUseCase>(
    GetNearbyPlacesUseCase(getIt<LieuEvenementRepository>()),
  );
  getIt.registerSingleton<GetEvenementsUseCase>(
    GetEvenementsUseCase(getIt<LieuEvenementRepository>()),
  );
  getIt.registerSingleton<GetEvenementByIdUseCase>(
    GetEvenementByIdUseCase(getIt<LieuEvenementRepository>()),
  );
  getIt.registerSingleton<GetNearbyEventsUseCase>(
    GetNearbyEventsUseCase(getIt<LieuEvenementRepository>()),
  );
  getIt.registerSingleton<RefreshAllCacheUseCase>(
    RefreshAllCacheUseCase(getIt<LieuEvenementRepository>()),
  );
  getIt.registerSingleton<ClearAllCacheUseCase>(
    ClearAllCacheUseCase(getIt<LieuEvenementRepository>()),
  );
}