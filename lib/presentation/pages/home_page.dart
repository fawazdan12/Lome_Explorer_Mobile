import 'package:event_flow/config/app_routers.dart';
import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/presentation/pages/evenement/evenement_list_page.dart';
import 'package:event_flow/presentation/pages/lieu/lieu_list_page.dart';
import 'package:event_flow/presentation/pages/map/map_page.dart';
import 'package:event_flow/presentation/pages/profile_page.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:event_flow/data/datasource/local/cache_hive_datasource.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as getit;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_flow/core/providers/notification_provider.dart';
import 'package:event_flow/presentation/widgets/notification_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Essayer de récupérer l'utilisateur en cache
      context.read<AuthNotifier>().getCachedUser();

      // Charger les données initiales
      context.read<LieuxNotifier>().fetchLieux();
      context.read<EvenementsNotifier>().fetchEvenements();

      _initializeWebSocket();
    });
  }

  Future<void> _initializeWebSocket() async {
    final notifProvider = context.read<NotificationProvider>();

    // Se connecter aux notifications générales
    if (!notifProvider.isConnected) {
      await notifProvider.connectToGeneral();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeContentPage(),
      const MapPage(), 
      const LieuListPage(),
      const EvenementListPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Lieux',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Événements',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ==================== HOME CONTENT PAGE ====================

class HomeContentPage extends StatelessWidget {
  const HomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lomé Explorer'),
        backgroundColor: AppColors.primaryOrange,
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.red),
            onPressed: () {
              Navigator.pushNamed(context, '/debug');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Vider cache complet',
            onPressed: () async {
              final localDataSource = getit.getIt<LocalDataSource>();
              await localDataSource.clearAllCache();

              // Vider aussi SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('cache_cleared_v2');

              SnackBarHelper.showSuccess(
                context,
                'Cache vidé ! Redémarrez l\'app',
              );
            },
          ),
          // Bouton carte en haut
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Voir la carte',
            onPressed: () {
              AppRoutes.navigateTo(context, AppRoutes.map);
            },
          ),
          // Afficher bouton login/logout selon l'état
          Consumer<AuthNotifier>(
            builder: (context, authNotifier, _) {
              if (authNotifier.isAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Se déconnecter',
                  onPressed: () => _showLogoutDialog(context, authNotifier),
                );
              } else {
                return TextButton.icon(
                  onPressed: () {
                    AppRoutes.navigateTo(context, AppRoutes.login);
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Connexion',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildHeader(context),
            ),
            const SizedBox(height: 16),

            // Carte rapide
            _buildQuickMapAccess(context),
            const SizedBox(height: 24),

            // Section Lieux populaires
            _buildLieuxSection(context),
            const SizedBox(height: 24),

            // Section Événements à venir
            _buildEvenementsSection(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryOrange,
              AppColors.primaryOrange.withAlpha((255 * 0.7).round()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AuthNotifier>(
              builder: (context, authNotifier, _) {
                if (authNotifier.isAuthenticated) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue,',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      Text(
                        authNotifier.currentUser?.username ?? 'Utilisateur',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Découvrez Lomé',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Explorez les lieux et événements',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha((255 * 0.9).round()),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMapAccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: () {
            AppRoutes.navigateTo(context, AppRoutes.map);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withAlpha((255 * 0.7).round()),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explorer la carte',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Voir tous les lieux et événements autour de vous',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha((255 * 0.9).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Remplacez la section _buildLieuxSection dans home_page.dart par ceci :

  Widget _buildLieuxSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lieux populaires',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  AppRoutes.navigateTo(context, AppRoutes.lieuList);
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<LieuxNotifier>(
          builder: (context, lieuxNotifier, _) {
            if (lieuxNotifier.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (lieuxNotifier.lieux.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun lieu disponible'),
              );
            }

            

            return SizedBox(
              height: 200, // Augmenté pour avoir plus d'espace
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: lieuxNotifier.lieux.take(5).length,
                itemBuilder: (context, index) {
                  final lieu = lieuxNotifier.lieux[index];

                  return Container(
                    width: 200, // Augmenté pour avoir plus d'espace
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          AppRoutes.navigateTo(
                            context,
                            AppRoutes.lieuDetail,
                            arguments: lieu.id,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nom
                              Text(
                                lieu.nom,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Catégorie
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lieu.categorie,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Description (NOUVEAU)
                              if (lieu.description.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    lieu.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                      height: 1.3,
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),

                              const SizedBox(height: 8),

                              // Note
                              if (lieu.moyenneAvis != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: AppColors.ratingColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      lieu.moyenneAvis!.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEvenementsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Événements à venir',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  AppRoutes.navigateTo(context, AppRoutes.evenementList);
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<EvenementsNotifier>(
          builder: (context, evenementsNotifier, _) {
            if (evenementsNotifier.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (evenementsNotifier.evenements.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun événement à venir'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: evenementsNotifier.evenements.take(3).length,
              itemBuilder: (context, index) {
                final evt = evenementsNotifier.evenements[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withAlpha((255 * 0.2).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.event, color: AppColors.primaryBlue),
                    ),
                    title: Text(evt.nom),
                    subtitle: Text(evt.lieuNom),
                    trailing: Text(
                      '${evt.dateDebut.day}/${evt.dateDebut.month}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      AppRoutes.navigateTo(
                        context,
                        AppRoutes.evenementDetail,
                        arguments: evt.id,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthNotifier authNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authNotifier.logout();
              if (context.mounted) {
                Navigator.pop(context);
                SnackBarHelper.showSuccess(context, 'Déconnexion réussie');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
