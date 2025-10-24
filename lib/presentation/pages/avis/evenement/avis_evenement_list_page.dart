import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/presentation/pages/auth/auth_guard.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AvisEvenementListPage extends StatefulWidget {
  final String evenementId;
  final String evenementNom;

  const AvisEvenementListPage({
    super.key,
    required this.evenementId,
    required this.evenementNom,
  });

  @override
  State<AvisEvenementListPage> createState() => _AvisEvenementListPageState();
}

class _AvisEvenementListPageState extends State<AvisEvenementListPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AvisEvenementNotifierFactory.create(
        context,
        widget.evenementId,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Avis',
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Header avec nom de l'événement
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primaryBlue.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: AppColors.primaryBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avis sur',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          widget.evenementNom,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Liste des avis
            Expanded(
              child: Consumer<AvisEvenementNotifier>(
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
                          'Soyez le premier à donner votre avis sur cet événement',
                      icon: Icons.rate_review,
                      onAction: () => _navigateToCreateAvis(context),
                      actionLabel: 'Donner mon avis',
                    );
                  }

                  // Statistiques
                  final moyenneNote = _calculateMoyenne(avisNotifier.avis);

                  return RefreshIndicator(
                    onRefresh: () => avisNotifier.refreshAvis(),
                    child: Column(
                      children: [
                        // Statistiques des avis
                        _buildStatistiques(context, avisNotifier.avis, moyenneNote),
                        const Divider(height: 1),

                        // Liste des avis
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: avisNotifier.avis.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final avis = avisNotifier.avis[index];
                              return _buildAvisCard(context, avis);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: AuthenticatedWidget(
          
          fallback: FloatingActionButton.extended(
            onPressed: () {
              context.guardedAction(
                onAuthenticated: () => _navigateToCreateAvis(context),
                message:
                    'Connectez-vous pour donner votre avis sur cet événement',
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Donner mon avis'),
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _navigateToCreateAvis(context),
            icon: const Icon(Icons.add),
            label: const Text('Donner mon avis'),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistiques(
    BuildContext context,
    List<dynamic> avis,
    double moyenne,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                moyenne.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
              ),
              RatingWidget(
                rating: moyenne.round(),
                onRatingChanged: (_) {},
                readOnly: true,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                '${avis.length} avis',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.mediumGrey.withOpacity(0.3),
          ),
          Column(
            children: [
              _buildNoteDistribution(context, avis, 5),
              _buildNoteDistribution(context, avis, 4),
              _buildNoteDistribution(context, avis, 3),
              _buildNoteDistribution(context, avis, 2),
              _buildNoteDistribution(context, avis, 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteDistribution(
    BuildContext context,
    List<dynamic> avis,
    int note,
  ) {
    final count = avis.where((a) => a.note == note).length;
    final percentage = avis.isEmpty ? 0.0 : count / avis.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$note',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Icon(Icons.star, size: 12, color: AppColors.ratingColor),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisCard(BuildContext context, dynamic avis) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currentUserId = context.read<AuthNotifier>().currentUser?.id;
    final isOwner = currentUserId == avis.utilisateurId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryOrange,
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
                            Text(
                              avis.utilisateurNom,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dateFormat.format(avis.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                        onTap: () {
                          // Naviguer vers édition
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Supprimer',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                        onTap: () {
                          // Supprimer
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            RatingWidget(
              rating: avis.note,
              onRatingChanged: (_) {},
              readOnly: true,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              avis.texte,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMoyenne(List<dynamic> avis) {
    if (avis.isEmpty) return 0.0;
    final sum = avis.fold<int>(0, (sum, avis) => sum + (avis.note as int));
    return sum / avis.length;
  }

  void _navigateToCreateAvis(BuildContext context) {
    // Naviguer vers création d'avis
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvisEvenementCreatePage(
          evenementId: widget.evenementId,
          evenementNom: widget.evenementNom,
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos des avis'),
        content: const Text(
          'Les avis permettent de partager votre expérience sur cet événement. '
          'Soyez constructif et respectueux dans vos commentaires.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Placeholder pour la page de création
class AvisEvenementCreatePage extends StatelessWidget {
  final String evenementId;
  final String evenementNom;

  const AvisEvenementCreatePage({
    super.key,
    required this.evenementId,
    required this.evenementNom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Donner mon avis'),
      body: const Center(child: Text('AvisEvenementCreatePage - À implémenter')),
    );
  }
}