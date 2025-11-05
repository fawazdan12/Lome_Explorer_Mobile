import 'package:event_flow/config/app_routers.dart';
import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/presentation/pages/auth/guard_lieu_evenement.dart';
import 'package:event_flow/presentation/pages/evenement/creation_evenement_page.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as getit;
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EvenementListPage extends StatefulWidget {
  const EvenementListPage({super.key});

  @override
  State<EvenementListPage> createState() => _EvenementListPageState();
}

class _EvenementListPageState extends State<EvenementListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvenementsNotifier>().fetchEvenements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Événements',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EvenementCreatePage()),
              );
              
              if (result == true && mounted) {
                context.read<EvenementsNotifier>().fetchEvenements();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBarWidget(
              hint: 'Rechercher un événement...',
              icon: Icons.event_note,
              onChanged: (value) {
                context.read<EvenementSearchNotifier>().setSearch(value);
              },
              onClear: () {
                context.read<EvenementSearchNotifier>().reset();
              },
            ),
          ),

          // Filtre à venir / passés
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<EvenementSearchNotifier>(
              builder: (context, searchNotifier, _) {
                return Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('À venir'),
                        selected: searchNotifier.aVenir,
                        onSelected: (selected) {
                          searchNotifier.setAVenir(true);
                        },
                        selectedColor: AppColors.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Passés'),
                        selected: !searchNotifier.aVenir,
                        onSelected: (selected) {
                          searchNotifier.setAVenir(false);
                        },
                        selectedColor: AppColors.mediumGrey.withOpacity(0.3),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Liste des événements
          Expanded(
            child: Consumer<EvenementsNotifier>(
              builder: (context, evenementsNotifier, _) {
                if (evenementsNotifier.isLoading) {
                  return const LoadingWidget(
                    message: 'Chargement des événements...',
                  );
                }

                if (evenementsNotifier.error != null) {
                  return AppErrorWidget(
                    message: evenementsNotifier.error!,
                    onRetry: () => evenementsNotifier.fetchEvenements(),
                  );
                }

                if (evenementsNotifier.evenements.isEmpty) {
                  return EmptyStateWidget(
                    title: 'Aucun événement',
                    message: 'Il n\'y a aucun événement pour le moment',
                    icon: Icons.event_busy,
                    onAction: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EvenementCreatePage(),
                        ),
                      );
                      
                      if (result == true && mounted) {
                        context.read<EvenementsNotifier>().fetchEvenements();
                      }
                    },
                    actionLabel: 'Créer un événement',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => evenementsNotifier.fetchEvenements(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: evenementsNotifier.evenements.length,
                    itemBuilder: (context, index) {
                      final evenement = evenementsNotifier.evenements[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SecuredEvenementCard(
                          evenement: evenement,
                          onTap: () async {
                            final result = await AppRoutes.navigateTo(
                              context,
                              AppRoutes.evenementDetail,
                              arguments: evenement.id,
                            );

                            if (result == true && mounted) {
                              context.read<EvenementsNotifier>().fetchEvenements();
                            }
                          },
                          onRefresh: () {
                            context.read<EvenementsNotifier>().fetchEvenements();
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGET SÉCURISÉ POUR LES CARTES D'ÉVÉNEMENT ====================

class _SecuredEvenementCard extends StatelessWidget {
  final EvenementEntity evenement;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _SecuredEvenementCard({
    required this.evenement,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isUpcoming = evenement.dateDebut.isAfter(DateTime.now());
    final isOwner = OwnershipGuard.isEvenementOwner(context, evenement);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom avec badge propriétaire
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                evenement.nom,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // ✅ Badge "Moi" si organisateur
                            if (isOwner)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 12,
                                      color: AppColors.primaryOrange,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Moi',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primaryOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Lieu
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                evenement.lieuNom,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.primaryGreen),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // ✅ Menu contextuel SEULEMENT pour l'organisateur
                  if (isOwner)
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: AppColors.darkGrey),
                      tooltip: 'Options',
                      itemBuilder: (context) => [
                        // Option Modifier
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: AppColors.primaryBlue),
                              const SizedBox(width: 8),
                              const Text('Modifier'),
                            ],
                          ),
                          onTap: () async {
                            await Future.delayed(const Duration(milliseconds: 100));
                            if (context.mounted) {
                              final canEdit = await context.canEditEvenement(evenement);
                              if (canEdit && context.mounted) {
                                final result = await AppRoutes.navigateTo(
                                  context,
                                  AppRoutes.evenementEdit,
                                  arguments: {'evenement': evenement},
                                );
                                if (result == true && context.mounted) {
                                  onRefresh();
                                }
                              }
                            }
                          },
                        ),
                        
                        // Option Supprimer
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Future.delayed(const Duration(milliseconds: 100));
                            if (context.mounted) {
                              final canDelete = await context.canDeleteEvenement(evenement);
                              if (canDelete && context.mounted) {
                                _showDeleteDialog(context, evenement, onRefresh);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Dates
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : AppColors.mediumGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 16,
                          color: isUpcoming
                              ? AppColors.primaryBlue
                              : AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Début: ${dateFormat.format(evenement.dateDebut)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 16,
                          color: isUpcoming
                              ? AppColors.primaryBlue
                              : AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Fin: ${dateFormat.format(evenement.dateFin)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Note et nombre d'avis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (evenement.moyenneAvis != null)
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: AppColors.ratingColor),
                        const SizedBox(width: 4),
                        Text(
                          evenement.moyenneAvis!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  Text(
                    '${evenement.nombreAvis} avis',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== DIALOGUE DE SUPPRESSION ====================

void _showDeleteDialog(
  BuildContext context,
  EvenementEntity evenement,
  VoidCallback onRefresh,
) async {
  final isUpcoming = evenement.dateDebut.isAfter(DateTime.now());
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          const Expanded(child: Text('Supprimer l\'événement')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir supprimer cet événement ?',
            style: Theme.of(dialogContext).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        evenement.nom,
                        style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(evenement.dateDebut)}',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                if (isUpcoming) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Événement à venir',
                      style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cette action est irréversible',
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 8),
            Text(
              'Les participants inscrits seront notifiés de l\'annulation.',
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
      // Afficher indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Supprimer l'événement
      await getit.getIt<LieuEvenementService>().deleteEvenement(evenement.id);

      // Fermer le dialogue de chargement
      if (context.mounted) Navigator.pop(context);

      // Succès
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          '${evenement.nom} supprimé avec succès',
        );
        onRefresh();
      }
    } catch (e) {
      // Fermer le dialogue de chargement
      if (context.mounted) Navigator.pop(context);

      // Afficher l'erreur
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors de la suppression: $e',
        );
      }
    }
  }
}

// ==================== EVENEMENT CARD WIDGET ====================

class EvenementCardWidget extends StatelessWidget {
  final String nom;
  final String lieuNom;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double? moyenneAvis;
  final int nombreAvis;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EvenementCardWidget({
    super.key,
    required this.nom,
    required this.lieuNom,
    required this.dateDebut,
    required this.dateFin,
    this.moyenneAvis,
    required this.nombreAvis,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isUpcoming = dateDebut.isAfter(DateTime.now());

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lieuNom,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.primaryGreen),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            onTap: onEdit,
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            onTap: onDelete,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Supprimer',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Dates
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : AppColors.mediumGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 16,
                          color: isUpcoming
                              ? AppColors.primaryBlue
                              : AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Début: ${dateFormat.format(dateDebut)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 16,
                          color: isUpcoming
                              ? AppColors.primaryBlue
                              : AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Fin: ${dateFormat.format(dateFin)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Note et nombre d'avis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (moyenneAvis != null)
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.ratingColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          moyenneAvis!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  Text(
                    '$nombreAvis avis',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
