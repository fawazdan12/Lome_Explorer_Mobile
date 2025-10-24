import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as di;
import 'package:event_flow/domains/repositories/avis_repository.dart';
import 'package:event_flow/domains/repositories/lieu_evenement_repository.dart';
import 'package:event_flow/presentation/pages/auth/login_page.dart';
import 'package:event_flow/presentation/pages/auth/register_page.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:event_flow/presentation/pages/avis/evenement/avis_evenement_create_page.dart' as avis_evenement_create_page;
import 'package:event_flow/presentation/pages/avis/evenement/avis_evenement_detail_page.dart';
import 'package:event_flow/presentation/pages/avis/evenement/avis_evenement_edit_page.dart';
import 'package:event_flow/presentation/pages/avis/evenement/avis_evenement_list_page.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_create_page.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_detail_page.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_edit_page.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_list_page.dart';
import 'package:event_flow/presentation/pages/evenement/creation_evenement_page.dart';
import 'package:event_flow/presentation/pages/evenement/evenement_detail_page.dart';
import 'package:event_flow/presentation/pages/evenement/evenement_list_page.dart';
import 'package:event_flow/presentation/pages/evenement/modif_evenement_page.dart';
import 'package:event_flow/presentation/pages/home_page.dart';
import 'package:event_flow/presentation/pages/lieu/creation_lieu_page.dart';
import 'package:event_flow/presentation/pages/lieu/lieu_detail_page.dart';
import 'package:event_flow/presentation/pages/lieu/lieu_list_page.dart';
import 'package:event_flow/presentation/pages/lieu/modif_lieu_page.dart';
import 'package:event_flow/presentation/pages/map/map_page.dart';
import 'package:event_flow/presentation/pages/profile_page.dart';

/// Classe pour gérer toutes les routes de l'application
class AppRoutes {
  // Noms des routes
  static const String home = '/';
  static const String map = '/map';
  static const String profile = '/profile';
  
  // Auth
  static const String login = '/login';
  static const String register = '/register';
  
  // Lieux
  static const String lieuList = '/lieux';
  static const String lieuDetail = '/lieu/detail';
  static const String lieuCreate = '/lieu/create';
  static const String lieuEdit = '/lieu/edit';
  
  // Événements
  static const String evenementList = '/evenements';
  static const String evenementDetail = '/evenement/detail';
  static const String evenementCreate = '/evenement/create';
  static const String evenementEdit = '/evenement/edit';
  
  // Avis Lieux
  static const String avisLieuList = '/avis-lieu/list';
  static const String avisLieuDetail = '/avis-lieu/detail';
  static const String avisLieuCreate = '/avis-lieu/create';
  static const String avisLieuEdit = '/avis-lieu/edit';
  
  // Avis Événements
  static const String avisEvenementList = '/avis-evenement/list';
  static const String avisEvenementDetail = '/avis-evenement/detail';
  static const String avisEvenementCreate = '/avis-evenement/create';
  static const String avisEvenementEdit = '/avis-evenement/edit';

  /// Génère les routes de l'application
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomePage(),
      map: (context) => const MapPage(),
      profile: (context) => const ProfilePage(),
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      lieuList: (context) => const LieuListPage(),
      lieuCreate: (context) => const LieuCreatePage(),
      evenementList: (context) => const EvenementListPage(),
      evenementCreate: (context) => const EvenementCreatePage(),
    };
  }

  /// Génère une route avec paramètres
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Extraire les arguments
    final args = settings.arguments;

    switch (settings.name) {
      // Lieu Detail
      case lieuDetail:
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => LieuDetailNotifier(
                repo: di.getIt<LieuEvenementRepository>(),
                logger: di.getIt<Logger>(),
                lieuId: args,
              ),
              child: LieuDetailPage(lieuId: args),
            ),
            settings: settings,
          );
        }
        break;

      // Lieu Edit
      case lieuEdit:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => LieuEditPage(lieu: args['lieu']),
            settings: settings,
          );
        }
        break;

      // ✅ Événement Detail - CORRECTION ICI
      case evenementDetail:
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => EvenementDetailNotifier(
                repo: di.getIt<LieuEvenementRepository>(),
                logger: di.getIt<Logger>(),
                evenementId: args,
              ),
              child: EvenementDetailPage(evenementId: args),
            ),
            settings: settings,
          );
        }
        break;

      // Événement Edit
      case evenementEdit:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => EvenementEditPage(evenement: args['evenement']),
            settings: settings,
          );
        }
        break;

      // Avis Lieu List
      case avisLieuList:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => AvisLieuNotifier(
                repo: di.getIt<AvisRepository>(),
                logger: di.getIt<Logger>(),
                lieuId: args['lieuId'],
              ),
              child: AvisLieuListPage(
                lieuId: args['lieuId'],
                lieuNom: args['lieuNom'],
              ),
            ),
            settings: settings,
          );
        }
        break;

      // Avis Lieu Detail
      case avisLieuDetail:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => AvisLieuDetailPage(
              lieuId: args['lieuId'],
              avisId: args['avisId'],
            ),
            settings: settings,
          );
        }
        break;

      // Avis Lieu Create
      case avisLieuCreate:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => AvisLieuCreatePage(
              lieuId: args['lieuId'],
              lieuNom: args['lieuNom'],
            ),
            settings: settings,
          );
        }
        break;

      // Avis Lieu Edit
      case avisLieuEdit:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => AvisLieuEditPage(avis: args['avis']),
            settings: settings,
          );
        }
        break;

      // Avis Événement List
      case avisEvenementList:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => AvisEvenementNotifier(
                repo: di.getIt<AvisRepository>(),
                logger: di.getIt<Logger>(),
                evenementId: args['evenementId'],
              ),
              child: AvisEvenementListPage(
                evenementId: args['evenementId'],
                evenementNom: args['evenementNom'],
              ),
            ),
            settings: settings,
          );
        }
        break;

      // Avis Événement Detail
      case avisEvenementDetail:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => AvisEvenementDetailPage(avis: args['avis']),
            settings: settings,
          );
        }
        break;

      // Avis Événement Create
      case avisEvenementCreate:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => avis_evenement_create_page.AvisEvenementCreatePage(
              evenementId: args['evenementId'],
              evenementNom: args['evenementNom'],
            ),
            settings: settings,
          );
        }
        break;

      // Avis Événement Edit
      case avisEvenementEdit:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => AvisEvenementEditPage(avis: args['avis']),
            settings: settings,
          );
        }
        break;
    }

    // Route non trouvée
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Text('Route "${settings.name}" non trouvée'),
        ),
      ),
    );
  }

  /// Méthodes helper pour naviguer
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> navigateAndReplace<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, void>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}