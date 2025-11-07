import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_create_page.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_delete_page.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_detail_page.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_edit_page.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as di;

class AvisLieuListPage extends StatefulWidget {
  final String lieuId;
  final String lieuNom;

  const AvisLieuListPage({
    super.key,
    required this.lieuId,
    required this.lieuNom,
  });

  @override
  State<AvisLieuListPage> createState() => _AvisLieuListPageState();
}

class _AvisLieuListPageState extends State<AvisLieuListPage> {
  String _sortBy = 'recent'; // recent, oldest, highest, lowest

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECTION : Créer le provider AVEC les dépendances depuis GetIt
    return ChangeNotifierProvider(
      create: (_) => AvisLieuNotifier(
        repo: di.getIt(), // ✅ Utiliser GetIt au lieu de context.read()
        logger: di.getIt(), // ✅ Utiliser GetIt au lieu de context.read()
        lieuId: widget.lieuId,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Avis',
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                setState(() => _sortBy = value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'recent',
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 18),
                      SizedBox(width: 8),
                      Text('Plus récents'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'oldest',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18),
                      SizedBox(width: 8),
                      Text('Plus anciens'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'highest',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 18),
                      SizedBox(width: 8),
                      Text('Meilleures notes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'lowest',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 18),
                      SizedBox(width: 8),
                      Text('Notes les plus basses'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // En-tête avec info du lieu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha((255 * 0.1).round()),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primaryGreen.withAlpha((255 * 0.3).round()),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lieuNom,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<AvisLieuNotifier>(
                    builder: (context, avisNotifier, _) {
                      if (avisNotifier.avis.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final moyenneNote = avisNotifier.avis.isEmpty
                          ? 0.0
                          : avisNotifier.avis
                                    .map((a) => a.note)
                                    .reduce((a, b) => a + b) /
                                avisNotifier.avis.length;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            icon: Icons.star,
                            label: 'Note moyenne',
                            value: moyenneNote.toStringAsFixed(1),
                            color: AppColors.ratingColor,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: AppColors.mediumGrey.withAlpha((255 * 0.1).round()),
                          ),
                          _buildStatItem(
                            icon: Icons.comment,
                            label: 'Avis',
                            value: '${avisNotifier.avis.length}',
                            color: AppColors.info,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Liste des avis
            Expanded(
              child: Consumer<AvisLieuNotifier>(
                builder: (context, avisNotifier, _) {
                  if (avisNotifier.isLoading) {
                    return const LoadingWidget(
                      message: 'Chargement des avis...',
                    );
                  }

                  if (avisNotifier.error != null) {
                    return AppErrorWidget(
                      message: avisNotifier.error!,
                      onRetry: () => avisNotifier.refreshAvis(),
                    );
                  }

                  if (avisNotifier.avis.isEmpty) {
                    return EmptyStateWidget(
                      title: 'Aucun avis',
                      message:
                          'Soyez le premier à donner votre avis sur ce lieu',
                      icon: Icons.rate_review,
                      onAction: () => _navigateToCreate(),
                      actionLabel: 'Donner mon avis',
                    );
                  }

                  // Trier les avis
                  final sortedAvis = _sortAvis(avisNotifier.avis);

                  return RefreshIndicator(
                    onRefresh: () => avisNotifier.refreshAvis(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedAvis.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final avis = sortedAvis[index];
                        final isMyAvis =
                            context.read<AuthNotifier>().currentUser?.id ==
                            avis.utilisateurId;

                        return AvisLieuCardWidget(
                          avis: avis,
                          isMyAvis: isMyAvis,
                          onTap: () => _navigateToDetail(avis.id),
                          onEdit: isMyAvis ? () => _navigateToEdit(avis) : null,
                          onDelete: isMyAvis ? () => _handleDelete(avis) : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Consumer<AuthNotifier>(
          builder: (context, authNotifier, _) {
            if (!authNotifier.isAuthenticated) {
              return const SizedBox.shrink();
            }

            final currentUserId = authNotifier.currentUser?.id;
            final avisNotifier = context.watch<AvisLieuNotifier>();
            final hasExistingAvis = avisNotifier.avis.any(
              (avis) => avis.utilisateurId == currentUserId,
            );
            if (hasExistingAvis) {
              // Afficher "Modifier mon avis" au lieu de "Donner mon avis"
              final myAvis = avisNotifier.avis.firstWhere(
                (avis) => avis.utilisateurId == currentUserId,
              );

              return FloatingActionButton.extended(
                onPressed: () => _navigateToEdit(myAvis),
                icon: const Icon(Icons.edit),
                label: const Text('Modifier mon avis'),
                backgroundColor: AppColors.primaryOrange,
              );
            }

            return FloatingActionButton.extended(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add),
              label: const Text('Donner mon avis'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
        ),
      ],
    );
  }

  List<dynamic> _sortAvis(List<dynamic> avis) {
    final sortedList = List.from(avis);

    switch (_sortBy) {
      case 'recent':
        sortedList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'oldest':
        sortedList.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'highest':
        sortedList.sort((a, b) => b.note.compareTo(a.note));
        break;
      case 'lowest':
        sortedList.sort((a, b) => a.note.compareTo(b.note));
        break;
    }

    return sortedList;
  }

  Future<void> _navigateToCreate() async {
    // capture du notifier AVANT l'attente
    final avisNotifier = context.read<AvisLieuNotifier>();

    final created = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AvisLieuCreatePage(lieuId: widget.lieuId, lieuNom: widget.lieuNom),
      ),
    );

    if (!mounted) return;
    if (created == true) {
      await avisNotifier.refreshAvis();
    }
  }

  void _navigateToDetail(String avisId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AvisLieuDetailPage(lieuId: widget.lieuId, avisId: avisId),
      ),
    );
  }

  Future<void> _navigateToEdit(dynamic avis) async {
    // capture du notifier AVANT l'attente
    final avisNotifier = context.read<AvisLieuNotifier>();

    final updated = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => AvisLieuEditPage(avis: avis)),
    );

    if (!mounted) return;
    if (updated == true) {
      await avisNotifier.refreshAvis();
    }
  }

  Future<void> _handleDelete(dynamic avis) async {
    // capture du notifier AVANT l'attente
    final avisNotifier = context.read<AvisLieuNotifier>();

    // on suppose que context.deleteAvisLieu affiche une confirmation et supprime
    final confirmed = await context.deleteAvisLieu(
      avisId: avis.id,
      lieuNom: widget.lieuNom,
      note: avis.note,
      texte: avis.texte,
      date: avis.date,
    );

    if (!mounted) return;
    if (confirmed) {
      await avisNotifier.refreshAvis();
    }
  }
}

// ==================== AVIS LIEU CARD WIDGET ====================

class AvisLieuCardWidget extends StatelessWidget {
  final dynamic avis;
  final bool isMyAvis;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AvisLieuCardWidget({
    super.key,
    required this.avis,
    required this.isMyAvis,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec utilisateur et menu
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isMyAvis
                        ? AppColors.primaryOrange
                        : AppColors.primaryBlue,
                    child: Text(
                      avis.utilisateurNom[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              avis.utilisateurNom,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isMyAvis) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withAlpha((255 * 0.2).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Moi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd/MM/yyyy').format(avis.date),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.mediumGrey),
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

              // Note
              RatingWidget(
                rating: avis.note,
                onRatingChanged: (_) {},
                readOnly: true,
                size: 18,
              ),
              const SizedBox(height: 8),

              // Texte de l'avis
              Text(
                avis.texte,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}