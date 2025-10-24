import 'package:event_flow/config/app_routers.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:event_flow/presentation/pages/auth/guard_lieu_evenement.dart';
import 'package:event_flow/presentation/pages/lieu/creation_lieu_page.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as getit;
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:provider/provider.dart';

class LieuListPage extends StatefulWidget {
  const LieuListPage({super.key});

  @override
  State<LieuListPage> createState() => _LieuListPageState();
}

class _LieuListPageState extends State<LieuListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LieuxNotifier>().fetchLieux();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Lieux',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LieuCreatePage()),
              );
              
              if (result == true && mounted) {
                context.read<LieuxNotifier>().fetchLieux();
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
              hint: 'Rechercher un lieu...',
              onChanged: (value) {
                context.read<LieuSearchNotifier>().setSearch(value);
              },
              onClear: () {
                context.read<LieuSearchNotifier>().reset();
              },
            ),
          ),
          
          // Liste des lieux
          Expanded(
            child: Consumer<LieuxNotifier>(
              builder: (context, lieuxNotifier, _) {
                if (lieuxNotifier.isLoading) {
                  return const LoadingWidget(
                    message: 'Chargement des lieux...',
                  );
                }

                if (lieuxNotifier.error != null) {
                  return AppErrorWidget(
                    message: lieuxNotifier.error!,
                    onRetry: () => lieuxNotifier.fetchLieux(),
                  );
                }

                if (lieuxNotifier.lieux.isEmpty) {
                  return EmptyStateWidget(
                    title: 'Aucun lieu',
                    message: 'Il n\'y a aucun lieu pour le moment',
                    icon: Icons.location_off,
                    onAction: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LieuCreatePage(),
                        ),
                      );
                      
                      if (result == true && mounted) {
                        context.read<LieuxNotifier>().fetchLieux();
                      }
                    },
                    actionLabel: 'Créer un lieu',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => lieuxNotifier.fetchLieux(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: lieuxNotifier.lieux.length,
                    itemBuilder: (context, index) {
                      final lieu = lieuxNotifier.lieux[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SecuredLieuCard(
                          lieu: lieu,
                          onTap: () async {
                            final result = await AppRoutes.navigateTo(
                              context,
                              AppRoutes.lieuDetail,
                              arguments: lieu.id,
                            );

                            if (result == true && mounted) {
                              context.read<LieuxNotifier>().fetchLieux();
                            }
                          },
                          onRefresh: () {
                            context.read<LieuxNotifier>().fetchLieux();
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

// ==================== WIDGET SÉCURISÉ POUR LES CARTES DE LIEU ====================

class _SecuredLieuCard extends StatelessWidget {
  final LieuEntity lieu;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _SecuredLieuCard({
    required this.lieu,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = OwnershipGuard.isLieuOwner(context, lieu);

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
                                lieu.nom,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // ✅ Badge "Moi" si propriétaire
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
                        
                        // Catégorie
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lieu.categorie,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // ✅ Menu contextuel SEULEMENT pour le propriétaire
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
                              final canEdit = await context.canEditLieu(lieu);
                              if (canEdit && context.mounted) {
                                final result = await AppRoutes.navigateTo(
                                  context,
                                  AppRoutes.lieuEdit,
                                  arguments: {'lieu': lieu},
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
                              final canDelete = await context.canDeleteLieu(lieu);
                              if (canDelete && context.mounted) {
                                _showDeleteDialog(context, lieu, onRefresh);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Statistiques
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (lieu.moyenneAvis != null)
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: AppColors.ratingColor),
                        const SizedBox(width: 4),
                        Text(
                          lieu.moyenneAvis!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${lieu.nombreEvenements} événement${lieu.nombreEvenements > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
  LieuEntity lieu,
  VoidCallback onRefresh,
) async {
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
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                        style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                        style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
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
            'Les événements associés seront également affectés.',
            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
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
      // Afficher indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Supprimer le lieu
      await getit.getIt<LieuEvenementService>().deleteLieu(lieu.id);

      // Fermer le dialogue de chargement
      if (context.mounted) Navigator.pop(context);

      // Succès
      if (context.mounted) {
        SnackBarHelper.showSuccess(context, '${lieu.nom} supprimé avec succès');
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