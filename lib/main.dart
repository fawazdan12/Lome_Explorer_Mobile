import 'package:event_flow/domains/injections/hive_setup.dart';
import 'package:event_flow/domains/injections/providers.dart';
import 'package:event_flow/domains/injections/service_locator.dart';
import 'package:event_flow/presentation/widgets/my_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;


void main() async {
  // Assurez-vous que les widgets Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration timeago pour le français
  timeago.setLocaleMessages('fr', timeago.FrMessages());


  // Configuration de l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    // Initialiser Hive
    await setupHive();

    // Initialiser le Service Locator (GetIt)
    await setupServiceLocator();

    // Initialiser les dates en français
    await initializeDateFormatting('fr_FR', null);

    // Lancer l'application
    runApp(
      MultiProvider(
        providers: getAppProviders(),
        child: MyApp(),
      ),
    );
  } catch (e) {
    // Afficher une erreur si l'initialisation échoue
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
