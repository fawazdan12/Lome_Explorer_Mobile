import 'package:event_flow/config/app_routers.dart';
import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as getit;
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:event_flow/presentation/pages/auth/guard_lieu_evenement.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

final _logger = Logger();

class LieuDetailPage extends StatefulWidget {
  final String lieuId;

  const LieuDetailPage({super.key, required this.lieuId});

  @override
  State<LieuDetailPage> createState() => _LieuDetailPageState();
}

class _LieuDetailPageState extends State<LieuDetailPage> {
  bool _hasTriedFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLieu();
    });
  }

  Future<void> _fetchLieu() async {
    if (!mounted) return;

    final notifier = context.read<LieuDetailNotifier>();
    await notifier.fetchLieu(widget.lieuId);

    if (mounted) {
      setState(() => _hasTriedFetch = true);

      // Afficher un message d'erreur si nécessaire
      if (notifier.error != null) {
        SnackBarHelper.showError(
          context,
          'Erreur de chargement: ${notifier.error}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails du lieu',
        actions: [
          Consumer<LieuDetailNotifier>(
            builder: (context, notifier, _) {
              final lieu = notifier.cache[widget.lieuId];
              if (lieu == null) return const SizedBox.shrink();

              return Row(
                children: [
                  // Bouton édition avec vérification de propriété
                  OwnershipEditButton(
                    lieu: lieu,
                    onPressed: () async {
                      final result = await AppRoutes.navigateTo(
                        context,
                        AppRoutes.lieuEdit,
                        arguments: {'lieu': lieu},
                      );

                      if (result == true && mounted) {
                        setState(() => _hasTriedFetch = false);
                        _fetchLieu();
                      }
                    },
                  ),

                  // Menu avec suppression protégée
                  OwnerOnly(
                    lieu: lieu,
                    fallback: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showPublicMenu(context, lieu),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOwnerMenu(context, lieu),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<LieuDetailNotifier>(
        builder: (context, detailNotifier, _) {
          // État de chargement
          if (detailNotifier.isLoading && !_hasTriedFetch) {
            return const LoadingWidget(message: 'Chargement des détails...');
          }

          // Erreur
          if (detailNotifier.error != null) {
            return AppErrorWidget(
              message: detailNotifier.error!,
              onRetry: () {
                setState(() => _hasTriedFetch = false);
                _fetchLieu();
              },
            );
          }

          // Lieu non trouvé
          final lieu = detailNotifier.cache[widget.lieuId];
          if (lieu == null) {
            return EmptyStateWidget(
              title: 'Lieu non trouvé',
              message: 'Le lieu demandé n\'existe pas ou a été supprimé',
              icon: Icons.location_off,
              onAction: () => Navigator.pop(context),
              actionLabel: 'Retour',
            );
          }

          // Afficher les données du lieu
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<LieuDetailNotifier>().cache.forEach((key, value) {
              if (value != null) {
                _logger.i('Lieu en cache: ${value.nom}');
                _logger.i(
                  'Description: "${value.description}" (${value.description.length} caractères)',
                );
              }
            });
          });

          // Affichage des détails
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _hasTriedFetch = false);
              await _fetchLieu();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec info principale
                  _buildHeader(context, lieu),

                  // Détails
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        _buildSection(
                          context,
                          title: 'Description',
                          child: Builder(
                            builder: (context) {
                              _logger.d(
                                'Affichage description du lieu "${lieu.nom}":',
                              );
                              _logger.d('Valeur: "${lieu.description}"');
                              _logger.d('Longueur: ${lieu.description.length}');
                              _logger.d('isEmpty: ${lieu.description.isEmpty}');

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  lieu.description.isNotEmpty
                                      ? lieu.description
                                      : 'Pas de description disponible.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Localisation
                        _buildSection(
                          context,
                          title: 'Localisation',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: AppColors.primaryGreen,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Coordonnées GPS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lat: ${lieu.latitude.toStringAsFixed(6)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Lng: ${lieu.longitude.toStringAsFixed(6)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // ouvrir l'application de navigation
                                    AppRoutes.navigateTo(
                                      context,
                                      AppRoutes.map,
                                      arguments: {
                                        'latitude': lieu.latitude,
                                        'longitude': lieu.longitude,
                                        'lieuNom': lieu.nom,
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.navigation),
                                  label: const Text('Naviguer vers ce lieu'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Propriétaire
                        _buildSection(
                          context,
                          title: 'Propriétaire',
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryBlue,
                                child: Text(
                                  lieu.proprietaireNom.isNotEmpty
                                      ? lieu.proprietaireNom[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                lieu.proprietaireNom.isNotEmpty
                                    ? lieu.proprietaireNom
                                    : 'Inconnu',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text('Propriétaire du lieu'),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Date de création
                        _buildSection(
                          context,
                          title: 'Informations',
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha((255 * 0.1).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: AppColors.info,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date de création',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(lieu.dateCreation),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Statistiques
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.star,
                                color: AppColors.ratingColor,
                                value:
                                    lieu.moyenneAvis?.toStringAsFixed(1) ??
                                    'N/A',
                                label: 'Note moyenne',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.event,
                                color: AppColors.primaryBlue,
                                value: '${lieu.nombreEvenements}',
                                label: 'Événements',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Événements du lieu (Section simplifiée pour l'instant)
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Événements à ce lieu',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (lieu.nombreEvenements > 0)
                          TextButton(
                            onPressed: () {
                              // Naviguer vers la liste des événements filtrée par lieu
                              SnackBarHelper.showInfo(
                                context,
                                'Liste des événements à venir',
                              );
                            },
                            child: const Text('Voir tout'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (lieu.nombreEvenements == 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: EmptyStateWidget(
                        title: 'Aucun événement',
                        message:
                            'Il n\'y a pas encore d\'événements pour ce lieu',
                        icon: Icons.event_busy,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${lieu.nombreEvenements} événement${lieu.nombreEvenements > 1 ? 's' : ''} organisé${lieu.nombreEvenements > 1 ? 's' : ''} à ce lieu',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),

                  // Avis - Section complète avec bouton
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Avis des visiteurs',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                AppRoutes.navigateTo(
                                  context,
                                  AppRoutes.avisLieuList,
                                  arguments: {
                                    'lieuId': widget.lieuId,
                                    'lieuNom': lieu.nom,
                                  },
                                );
                              },
                              child: const Text('Voir tout'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        //  Statistiques des avis
                        if (lieu.moyenneAvis != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.ratingColor.withAlpha((255 * 0.1).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: AppColors.ratingColor,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  lieu.moyenneAvis!.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ratingColor,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/ 5',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: AppColors.mediumGrey),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        //  Bouton pour voir/donner un avis
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AppRoutes.navigateTo(
                                context,
                                AppRoutes.avisLieuList,
                                arguments: {
                                  'lieuId': widget.lieuId,
                                  'lieuNom': lieu.nom,
                                },
                              );
                            },
                            icon: const Icon(Icons.reviews),
                            label: const Text('Voir tous les avis'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<LieuDetailNotifier>(
        builder: (context, notifier, _) {
          final lieu = notifier.cache[widget.lieuId];
          if (lieu == null) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              AppRoutes.navigateTo(
                context,
                AppRoutes.avisLieuCreate,
                arguments: {'lieuId': lieu.id, 'lieuNom': lieu.nom},
              );
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Donner mon avis'),
            backgroundColor: AppColors.primaryOrange,
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic lieu) {
    return Container(
      width: double.infinity,
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
          Text(
            lieu.nom,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lieu.categorie,
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (lieu.moyenneAvis != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${lieu.moyenneAvis!.toStringAsFixed(1)} / 5',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${lieu.nombreEvenements} événement${lieu.nombreEvenements > 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour le menu du propriétaire
  void _showOwnerMenu(BuildContext context, LieuEntity lieu) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () async {
                Navigator.pop(context);
                final canEdit = await context.canEditLieu(lieu);
                if (canEdit && context.mounted) {
                  AppRoutes.navigateTo(
                    context,
                    AppRoutes.lieuEdit,
                    arguments: {'lieu': lieu},
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                final canDelete = await context.canDeleteLieu(lieu);
                if (canDelete && context.mounted) {
                  // Afficher dialogue de confirmation
                  _showDeleteDialog(context, lieu);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager'),
              onTap: () {
                Navigator.pop(context);
                SnackBarHelper.showInfo(context, 'Partage à venir');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour le menu public (non-propriétaire)
  void _showPublicMenu(BuildContext context, LieuEntity lieu) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager'),
              onTap: () {
                Navigator.pop(context);
                SnackBarHelper.showInfo(context, 'Partage à venir');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Ajouter aux favoris'),
              onTap: () {
                Navigator.pop(context);
                SnackBarHelper.showInfo(context, 'Favoris à venir');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                SnackBarHelper.showInfo(context, 'Signalement à venir');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Afficher le dialogue de confirmation de suppression
  void _showDeleteDialog(BuildContext context, LieuEntity lieu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Supprimer le lieu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir supprimer ce lieu ?',
              style: Theme.of(dialogContext).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha((255 * 0.3).round())),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lieu.nom,
                          style: Theme.of(dialogContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cette action est irréversible',
                          style: Theme.of(dialogContext).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tous les événements associés à ce lieu seront également affectés.',
              style: Theme.of(
                dialogContext,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Supprimer le lieu
        await getit.getIt<LieuEvenementService>().deleteLieu(lieu.id);

        // Fermer le dialogue de chargement
        if (context.mounted) Navigator.pop(context);

        // Succès
        if (context.mounted) {
          SnackBarHelper.showSuccess(
            context,
            '${lieu.nom} a été supprimé avec succès',
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        // Fermer le dialogue de chargement
        if (context.mounted) Navigator.pop(context);

        // Gérer l'erreur
        if (context.mounted) {
          String errorMessage = 'Erreur lors de la suppression: ';

          if (e.toString().contains('401')) {
            errorMessage = 'Session expirée. Veuillez vous reconnecter.';
            await context.read<AuthNotifier>().logout();
            if (context.mounted) {
              await Navigator.pushNamed(context, '/login');
              Navigator.pop(context);
            }
          } else if (e.toString().contains('403')) {
            errorMessage =
                'Vous n\'avez pas la permission de supprimer ce lieu.';
          } else {
            errorMessage += e.toString();
          }

          SnackBarHelper.showError(context, errorMessage);
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy', 'fr_FR');
    return formatter.format(date);
  }
}
