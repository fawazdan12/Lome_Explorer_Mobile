// ==================== PROFILE PAGE ====================

import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/presentation/pages/auth/login_page.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Charger le profil au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    
    final authNotifier = context.read<AuthNotifier>();
    
    // Si authentifié, rafraîchir le profil depuis l'API
    if (authNotifier.isAuthenticated) {
      await authNotifier.refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profil',
        showBackButton: false,
        actions: [
          // Bouton de rafraîchissement manuel
          Consumer<AuthNotifier>(
            builder: (context, authNotifier, _) {
              if (!authNotifier.isAuthenticated) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: authNotifier.isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
                onPressed: authNotifier.isLoading 
                  ? null 
                  : () => authNotifier.refreshProfile(),
                tooltip: 'Actualiser le profil',
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthNotifier>(
        builder: (context, authNotifier, _) {
          // Afficher un loader pendant le chargement initial
          if (authNotifier.isLoading && authNotifier.currentUser == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!authNotifier.isAuthenticated) {
            return _buildUnauthenticatedProfile(context);
          }

          return RefreshIndicator(
            onRefresh: () => authNotifier.refreshProfile(),
            child: _buildAuthenticatedProfile(context, authNotifier),
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 100,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 24),
            Text(
              'Vous n\'êtes pas connecté',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Connectez-vous pour accéder à votre profil et gérer vos lieux et événements',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Naviguer vers l'inscription
              },
              icon: const Icon(Icons.app_registration),
              label: const Text('Créer un compte'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),

            // Mode visiteur
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Continuer en tant que visiteur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedProfile(
    BuildContext context,
    AuthNotifier authNotifier,
  ) {
    final user = authNotifier.currentUser;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), 
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primaryOrange,
            child: Text(
              user?.username[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.username ?? 'Utilisateur',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mediumGrey,
                ),
          ),
          const SizedBox(height: 24),

          // Statistiques
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                context,
                icon: Icons.location_on,
                value: '${user?.nombreLieux ?? 0}',
                label: 'Lieux',
              ),
              _buildStatCard(
                context,
                icon: Icons.event,
                value: '${user?.nombreEvenements ?? 0}',
                label: 'Événements',
              ),
            ],
          ),
          const SizedBox(height: 24),

          //  Afficher la date d'inscription
          if (user?.dateCreation != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Membre depuis ${_formatDate(user!.dateCreation)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Modifier le profil'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Naviguer vers édition profil
                    SnackBarHelper.showInfo(
                      context,
                      'Fonctionnalité à venir',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Paramètres'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Naviguer vers paramètres
                    SnackBarHelper.showInfo(
                      context,
                      'Fonctionnalité à venir',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: AppColors.error),
                  title: Text(
                    'Se déconnecter',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Se déconnecter'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      await authNotifier.logout();
                      if (mounted) {
                        SnackBarHelper.showSuccess(
                          context,
                          'Déconnexion réussie',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Card(
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primaryOrange),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // Helper pour formater la date
  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}