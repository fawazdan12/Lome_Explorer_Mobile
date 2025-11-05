import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/core/providers/geo_provider.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/domains/repositories/avis_repository.dart';
import 'package:event_flow/domains/repositories/auth_repository.dart';
import 'package:event_flow/domains/repositories/geo_repository.dart';
import 'package:event_flow/domains/repositories/lieu_evenement_repository.dart';
import 'package:event_flow/core/providers/notification_provider.dart';
import 'package:event_flow/core/services/websocket_service.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

final getIt = GetIt.instance;

/// Fournir tous les providers à MultiProvider
/// Utilisé dans main.dart
List<SingleChildWidget> getAppProviders() {
  return [
    // ==================== AUTH PROVIDERS ====================
    ChangeNotifierProvider<AuthNotifier>(
      create: (_) => AuthNotifier(
        repo: getIt<AuthenticationRepository>(),
        logger: getIt<Logger>(),
      ),
    ),

    // ==================== WEBSOCKET NOTIFICATION PROVIDER ====================
    ChangeNotifierProvider<NotificationProvider>(
      create: (_) => NotificationProvider(
        service: getIt<WebSocketService>(),
        logger: getIt<Logger>(),
      ),
    ),

    // ==================== GEO PROVIDERS ====================
    // NOTE: Tous ces Notifiers dépendent uniquement de GetIt, le ChangeNotifierProvider simple suffit.
    ChangeNotifierProvider<UserLocationNotifier>(
      create: (_) => UserLocationNotifier(
        repo: getIt<GeolocationRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<QuartiersNotifier>(
      create: (_) => QuartiersNotifier(
        repo: getIt<GeolocationRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<IsInLomeNotifier>(
      create: (_) => IsInLomeNotifier(
        repo: getIt<GeolocationRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<GeocodeAddressNotifier>(
      create: (_) => GeocodeAddressNotifier(
        repo: getIt<GeolocationRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<PositionWatcherNotifier>(
      create: (_) => PositionWatcherNotifier(
        repo: getIt<GeolocationRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<LocationServiceNotifier>(
      create: (_) => LocationServiceNotifier(
        repo: getIt<GeolocationRepository>(),
        logger: getIt<Logger>(),
      ),
    ),

    // ==================== SEARCH NOTIFIERS (Dépendances pour les Notifiers de Liste) ====================
    // Ils doivent être déclarés avant les Notifiers de Liste
    ChangeNotifierProvider<LieuSearchNotifier>(
      create: (_) => LieuSearchNotifier(),
    ),
    ChangeNotifierProvider<EvenementSearchNotifier>(
      create: (_) => EvenementSearchNotifier(),
    ),
    ChangeNotifierProvider<ProximitySearchNotifier>(
      create: (_) => ProximitySearchNotifier(),
    ),

    // ==================== LIEU EVENEMENT PROVIDERS (Simplification des Proxy) ====================

    // Lieu Detail : SUPPRIMÉ de la liste globale (voir createLieuDetailProvider ci-dessous)
    // Evenement Detail : SUPPRIMÉ de la liste globale (voir createEvenementDetailProvider ci-dessous)

    // Simplification : LieuxNotifier utilise context.read() pour obtenir LieuSearchNotifier
    ChangeNotifierProvider<LieuxNotifier>(
      create: (context) => LieuxNotifier(
        repo: getIt<LieuEvenementRepository>(),
        logger: getIt<Logger>(),
        searchNotifier: context
            .read<LieuSearchNotifier>(), // Utilisation simplifiée
      ),
    ),

    // Simplification : EvenementsNotifier utilise context.read() pour obtenir EvenementSearchNotifier
    ChangeNotifierProvider<EvenementsNotifier>(
      create: (context) => EvenementsNotifier(
        repo: getIt<LieuEvenementRepository>(),
        logger: getIt<Logger>(),
        searchNotifier: context
            .read<EvenementSearchNotifier>(), // Utilisation simplifiée
      ),
    ),

    // Simplification : NearbyPlacesNotifier utilise context.read() pour obtenir ProximitySearchNotifier
    ChangeNotifierProvider<NearbyPlacesNotifier>(
      create: (context) => NearbyPlacesNotifier(
        repo: getIt<LieuEvenementRepository>(),
        logger: getIt<Logger>(),
        proximityNotifier: context
            .read<ProximitySearchNotifier>(), // Utilisation simplifiée
      ),
    ),

    // Simplification : NearbyEventsNotifier utilise context.read() pour obtenir ProximitySearchNotifier
    ChangeNotifierProvider<NearbyEventsNotifier>(
      create: (context) => NearbyEventsNotifier(
        repo: getIt<LieuEvenementRepository>(),
        logger: getIt<Logger>(),
        proximityNotifier: context
            .read<ProximitySearchNotifier>(), // Utilisation simplifiée
      ),
    ),

    ChangeNotifierProvider<CacheNotifier>(
      create: (_) => CacheNotifier(
        repo: getIt<LieuEvenementRepository>(),
        logger: getIt<Logger>(),
      ),
    ),

    // ==================== AVIS PROVIDERS ====================
    // Les providers d'opérations (Create/Update/Delete) n'ont pas besoin d'ID
    ChangeNotifierProvider<CreateAvisLieuNotifier>(
      create: (_) => CreateAvisLieuNotifier(
        repo: getIt<AvisRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<UpdateAvisLieuNotifier>(
      create: (_) => UpdateAvisLieuNotifier(
        repo: getIt<AvisRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<DeleteAvisLieuNotifier>(
      create: (_) => DeleteAvisLieuNotifier(
        repo: getIt<AvisRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<CreateAvisEvenementNotifier>(
      create: (_) => CreateAvisEvenementNotifier(
        repo: getIt<AvisRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<UpdateAvisEvenementNotifier>(
      create: (_) => UpdateAvisEvenementNotifier(
        repo: getIt<AvisRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
    ChangeNotifierProvider<DeleteAvisEvenementNotifier>(
      create: (_) => DeleteAvisEvenementNotifier(
        repo: getIt<AvisRepository>(),
        logger: getIt<Logger>(),
      ),
    ),
  ];
}

// ==================== FACTORIES POUR PROVIDERS DÉTAIL (Nécessitent un ID) ====================

/// Créer dynamiquement un provider AvisLieuNotifier pour un lieuId spécifique (comme vous l'aviez fait)
ChangeNotifierProvider<AvisLieuNotifier> createAvisLieuProvider(String lieuId) {
  return ChangeNotifierProvider<AvisLieuNotifier>(
    create: (_) => AvisLieuNotifier(
      repo: getIt<AvisRepository>(),
      logger: getIt<Logger>(),
      lieuId: lieuId,
    ),
  );
}

/// Créer dynamiquement un provider AvisEvenementNotifier pour un evenementId spécifique (comme vous l'aviez fait)
ChangeNotifierProvider<AvisEvenementNotifier> createAvisEvenementProvider(
  String evenementId,
) {
  return ChangeNotifierProvider<AvisEvenementNotifier>(
    create: (_) => AvisEvenementNotifier(
      repo: getIt<AvisRepository>(),
      logger: getIt<Logger>(),
      evenementId: evenementId,
    ),
  );
}

/// NOUVEAU : Factory pour le détail d'un lieu (remplace la déclaration globale)
ChangeNotifierProvider<LieuDetailNotifier> createLieuDetailProvider(
  String lieuId,
) {
  return ChangeNotifierProvider<LieuDetailNotifier>(
    create: (_) => LieuDetailNotifier(
      repo: getIt<LieuEvenementRepository>(),
      logger: getIt<Logger>(),
      lieuId: lieuId,
    ),
  );
}

/// NOUVEAU : Factory pour le détail d'un événement (remplace la déclaration globale)
ChangeNotifierProvider<EvenementDetailNotifier> createEvenementDetailProvider(
  String evenementId,
) {
  return ChangeNotifierProvider<EvenementDetailNotifier>(
    create: (_) => EvenementDetailNotifier(
      repo: getIt<LieuEvenementRepository>(),
      logger: getIt<Logger>(),
      evenementId: evenementId,
    ),
  );
}
