import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_delete_page.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_edit_page.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as di;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AvisLieuDetailPage extends StatefulWidget {
  final String lieuId;
  final String avisId;

  const AvisLieuDetailPage({
    super.key,
    required this.lieuId,
    required this.avisId,
  });

  @override
  State<AvisLieuDetailPage> createState() => _AvisLieuDetailPageState();
}

class _AvisLieuDetailPageState extends State<AvisLieuDetailPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AvisLieuNotifier(
        repo: di.getIt(),
        logger: di.getIt(),
        lieuId: widget.lieuId,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Détail de l\'avis',
          actions: [
            Consumer2<AvisLieuNotifier, AuthNotifier>(
              builder: (context, avisNotifier, authNotifier, _) {
                final avisIndex = avisNotifier.avis.indexWhere(
                  (a) => a.id == widget.avisId,
                );

                if (avisIndex == -1) return const SizedBox.shrink();

                final avis = avisNotifier.avis[avisIndex];

                final isMyAvis =
                    authNotifier.currentUser?.id == avis.utilisateurId;

                if (!isMyAvis) return const SizedBox.shrink();

                return PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => _navigateToEdit(avis),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => _handleDelete(avis),
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer2<AvisLieuNotifier, AuthNotifier>(
          builder: (context, avisNotifier, authNotifier, _) {
            if (avisNotifier.isLoading) {
              return const LoadingWidget(message: 'Chargement de l\'avis...');
            }

            if (avisNotifier.error != null) {
              return AppErrorWidget(
                message: avisNotifier.error!,
                onRetry: () => avisNotifier.refreshAvis(),
              );
            }

            final avisIndex = avisNotifier.avis.indexWhere(
              (a) => a.id == widget.avisId,
            );

            if (avisIndex == -1) {
              return const EmptyStateWidget(
                title: 'Avis non trouvé',
                message: 'L\'avis demandé n\'existe pas ou a été supprimé',
                icon: Icons.rate_review_outlined,
              );
            }

            final avis = avisNotifier.avis[avisIndex];

            final isMyAvis = authNotifier.currentUser?.id == avis.utilisateurId;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec le lieu
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreen.withAlpha((255 * 0.7).round()),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                avis.lieuNom,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((255 * 0.2).round()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Avis publié',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auteur et date
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: isMyAvis
                                  ? AppColors.primaryOrange
                                  : AppColors.primaryBlue,
                              child: Text(
                                avis.utilisateurNom[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        avis.utilisateurNom,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (isMyAvis) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryOrange
                                                .withAlpha((255 * 0.2).round()),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'Mon avis',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primaryOrange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: AppColors.mediumGrey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Publié le ${DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(avis.date)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.mediumGrey,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Note
                        Text(
                          'Note',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getRatingColor(avis.note).withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getRatingColor(
                                avis.note,
                              ).withAlpha((255 * 0.3).round()),
                            ),
                          ),
                          child: Column(
                            children: [
                              RatingWidget(
                                rating: avis.note,
                                onRatingChanged: (_) {},
                                readOnly: true,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(avis.note),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getRatingText(avis.note),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Commentaire
                        Text(
                          'Commentaire',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            avis.texte,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Informations supplémentaires
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Informations',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                context,
                                icon: Icons.badge,
                                label: 'ID de l\'avis',
                                value: avis.id,
                              ),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                context,
                                icon: Icons.person,
                                label: 'ID utilisateur',
                                value: avis.utilisateurId,
                              ),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                context,
                                icon: Icons.location_city,
                                label: 'ID du lieu',
                                value: avis.lieuId,
                              ),
                            ],
                          ),
                        ),

                        // Actions si c'est mon avis
                        if (isMyAvis) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _navigateToEdit(avis),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Modifier'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _handleDelete(avis),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Supprimer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mediumGrey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(int note) {
    if (note >= 4) return AppColors.success;
    if (note >= 3) return AppColors.warning;
    return AppColors.error;
  }

  String _getRatingText(int note) {
    switch (note) {
      case 1:
        return 'Très décevant';
      case 2:
        return 'Décevant';
      case 3:
        return 'Moyen';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  void _navigateToEdit(dynamic avis) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AvisLieuEditPage(avis: avis)),
    ).then((updated) {
      if (updated == true && mounted) {
        context.read<AvisLieuNotifier>().refreshAvis();
      }
    });
  }

  void _handleDelete(dynamic avis) async {
    final confirmed = await context.deleteAvisLieu(
      avisId: avis.id,
      lieuNom: avis.lieuNom,
      note: avis.note,
      texte: avis.texte,
      date: avis.date,
    );

    if (confirmed && mounted) {
      Navigator.pop(context);
      SnackBarHelper.showSuccess(context, 'Avis supprimé avec succès');
    }
  }
}
