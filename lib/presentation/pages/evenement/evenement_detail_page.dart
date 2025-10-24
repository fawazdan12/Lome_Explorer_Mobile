import 'package:event_flow/config/app_routers.dart';
import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as getit;
import 'package:event_flow/presentation/pages/auth/guard_lieu_evenement.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EvenementDetailPage extends StatefulWidget {
  final String evenementId;

  const EvenementDetailPage({super.key, required this.evenementId});

  @override
  State<EvenementDetailPage> createState() => _EvenementDetailPageState();
}

class _EvenementDetailPageState extends State<EvenementDetailPage> {
  bool _hasTriedFetch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEvenement();
    });
  }

  Future<void> _fetchEvenement() async {
    if (!mounted) return;

    final notifier = context.read<EvenementDetailNotifier>();
    await notifier.fetchEvenement(widget.evenementId);

    if (mounted) {
      setState(() => _hasTriedFetch = true);

      // Afficher un message d'erreur si nécessaire
      if (notifier.error != null) {
        SnackBarHelper.showError(
          context,
          'Impossible de charger l\'événement: ${notifier.error}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails de l\'événement',
        actions: [
          Consumer<EvenementDetailNotifier>(
            builder: (context, notifier, _) {
              final evenement = notifier.cache[widget.evenementId];
              if (evenement == null) return const SizedBox.shrink();

              return Row(
                children: [
                  // ✅ Bouton édition avec vérification de propriété
                  OwnershipEditButton(
                    evenement: evenement,
                    onPressed: () async {
                      final result = await AppRoutes.navigateTo(
                        context,
                        AppRoutes.evenementEdit,
                        arguments: {'evenement': evenement},
                      );

                      if (result == true && mounted) {
                        setState(() => _hasTriedFetch = false);
                        _fetchEvenement();
                      }
                    },
                  ),

                  // Menu avec actions conditionnelles
                  OwnerOnly(
                    evenement: evenement,
                    
                    fallback: IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        SnackBarHelper.showInfo(
                          context,
                          'Fonctionnalité de partage à venir',
                        );
                      },
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOwnerMenu(context, evenement),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<EvenementDetailNotifier>(
        builder: (context, detailNotifier, _) {
          // État de chargement
          if (detailNotifier.isLoading && !_hasTriedFetch) {
            return const LoadingWidget(message: 'Chargement des détails...');
          }

          // Erreur
          if (detailNotifier.error != null) {
            return AppErrorWidget(
              message: _getErrorMessage(detailNotifier.error!),
              icon: _getErrorIcon(detailNotifier.error!),
              onRetry: () {
                setState(() => _hasTriedFetch = false);
                _fetchEvenement();
              },
            );
          }

          // Événement non trouvé
          final evenement = detailNotifier.cache[widget.evenementId];
          if (evenement == null) {
            return EmptyStateWidget(
              title: 'Événement introuvable',
              message: 'L\'événement demandé n\'existe pas ou a été supprimé',
              icon: Icons.event_busy,
              onAction: () => Navigator.pop(context),
              actionLabel: 'Retour',
            );
          }

          // Affichage des détails
          return _buildEventDetails(context, evenement);
        },
      ),
      floatingActionButton: Consumer<EvenementDetailNotifier>(
        builder: (context, notifier, _) {
          final evenement = notifier.cache[widget.evenementId];
          if (evenement == null) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              AppRoutes.navigateTo(
                context,
                AppRoutes.avisEvenementCreate,
                arguments: {
                  'evenementId': widget.evenementId,
                  'evenementNom': evenement.nom,
                },
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

  Widget _buildEventDetails(BuildContext context, dynamic evenement) {
    final dateFormat = DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR');
    final now = DateTime.now();
    final isUpcoming = evenement.dateDebut.isAfter(now);
    final isPast = evenement.dateFin.isBefore(now);
    final isOngoing = !isUpcoming && !isPast;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _hasTriedFetch = false);
        await _fetchEvenement();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec statut
            _buildHeader(context, evenement, isUpcoming, isPast, isOngoing),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  _buildSection(
                    context,
                    title: 'Description',
                    child: Text(
                      evenement.description ?? 'Pas de description disponible.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dates et horaires
                  _buildSection(
                    context,
                    title: 'Dates et horaires',
                    child: Column(
                      children: [
                        _buildInfoCard(
                          icon: Icons.event,
                          color: AppColors.primaryBlue,
                          title: 'Début',
                          subtitle: dateFormat.format(evenement.dateDebut),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoCard(
                          icon: Icons.event_available,
                          color: AppColors.primaryGreen,
                          title: 'Fin',
                          subtitle: dateFormat.format(evenement.dateFin),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoCard(
                          icon: Icons.access_time,
                          color: AppColors.primaryOrange,
                          title: 'Durée',
                          subtitle: _getDuration(
                            evenement.dateDebut,
                            evenement.dateFin,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lieu
                  _buildSection(
                    context,
                    title: 'Localisation',
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.place,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        title: Text(evenement.lieuNom),
                        subtitle:
                            evenement.lieuLatitude != null &&
                                evenement.lieuLongitude != null
                            ? Text(
                                'Lat: ${evenement.lieuLatitude!.toStringAsFixed(4)}, '
                                'Lng: ${evenement.lieuLongitude!.toStringAsFixed(4)}',
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.navigation),
                          onPressed: () {
                            // Ouvrir dans Google Maps
                            SnackBarHelper.showInfo(
                              context,
                              'Navigation à venir',
                            );
                          },
                        ),
                        onTap: () {
                          if (evenement.lieuId != null) {
                            AppRoutes.navigateTo(
                              context,
                              AppRoutes.lieuDetail,
                              arguments: evenement.lieuId,
                            );
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Organisateur
                  _buildSection(
                    context,
                    title: 'Organisateur',
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryOrange,
                          child: Text(
                            evenement.organisateurNom[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(evenement.organisateurNom),
                        subtitle: const Text('Organisateur'),
                        trailing: IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () {
                            SnackBarHelper.showInfo(
                              context,
                              'Messagerie à venir',
                            );
                          },
                        ),
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
                              evenement.moyenneAvis?.toStringAsFixed(1) ??
                              'N/A',
                          label: 'Note moyenne',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.comment,
                          color: AppColors.info,
                          value: '${evenement.nombreAvis}',
                          label: 'Avis',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bouton voir les avis
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AppRoutes.navigateTo(
                          context,
                          AppRoutes.avisEvenementList,
                          arguments: {
                            'evenementId': widget.evenementId,
                            'evenementNom': evenement.nom,
                          },
                        );
                      },
                      icon: const Icon(Icons.reviews),
                      label: const Text('Voir tous les avis'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic evenement,
    bool isUpcoming,
    bool isPast,
    bool isOngoing,
  ) {
    Color statusColor;
    String statusText;

    if (isPast) {
      statusColor = AppColors.mediumGrey;
      statusText = 'Terminé';
    } else if (isOngoing) {
      statusColor = AppColors.success;
      statusText = 'En cours';
    } else {
      statusColor = AppColors.primaryBlue;
      statusText = 'À venir';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            evenement.nom,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  evenement.lieuNom,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Card(
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

  String _getDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inDays > 0) {
      return '${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('500')) {
      return 'Le serveur a rencontré une erreur.\n'
          'Veuillez réessayer dans quelques instants.';
    } else if (error.contains('404')) {
      return 'Événement introuvable.';
    } else if (error.contains('Network')) {
      return 'Erreur de connexion.\n'
          'Vérifiez votre connexion Internet.';
    }
    return error;
  }

  IconData _getErrorIcon(String error) {
    if (error.contains('500')) {
      return Icons.cloud_off;
    } else if (error.contains('404')) {
      return Icons.event_busy;
    } else if (error.contains('Network')) {
      return Icons.wifi_off;
    }
    return Icons.error_outline;
  }

  // Méthode pour le menu du propriétaire
void _showOwnerMenu(BuildContext context, EvenementEntity evenement) {
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
              final canEdit = await context.canEditEvenement(evenement);
              if (canEdit && context.mounted) {
                final result = await AppRoutes.navigateTo(
                  context,
                  AppRoutes.evenementEdit,
                  arguments: {'evenement': evenement},
                );
                if (result == true && context.mounted) {
                  setState(() => _hasTriedFetch = false);
                  _fetchEvenement();
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final canDelete = await context.canDeleteEvenement(evenement);
              if (canDelete && context.mounted) {
                _showDeleteDialog(context, evenement);
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
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Voir les participants'),
            onTap: () {
              Navigator.pop(context);
              SnackBarHelper.showInfo(context, 'Liste des participants à venir');
            },
          ),
        ],
      ),
    ),
  );
}

void _showDeleteDialog(BuildContext context, EvenementEntity evenement) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          const Text('Supprimer l\'événement'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir supprimer cet événement ?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evenement.nom,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'Cette action est irréversible',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await getit.getIt<LieuEvenementService>().deleteEvenement(evenement.id);
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Événement supprimé avec succès',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }
}
}
