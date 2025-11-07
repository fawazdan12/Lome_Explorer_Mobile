import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/presentation/pages/avis/lieu/avis_lieu_edit_page.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AvisLieuCreatePage extends StatefulWidget {
  final String lieuId;
  final String lieuNom;

  const AvisLieuCreatePage({
    super.key,
    required this.lieuId,
    required this.lieuNom,
  });

  @override
  State<AvisLieuCreatePage> createState() => _AvisLieuCreatePageState();
}

class _AvisLieuCreatePageState extends State<AvisLieuCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _texteController = TextEditingController();
  int _note = 0;

  @override
  void dispose() {
    _texteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkExistingAvis();
  }

  Future<void> _checkExistingAvis() async {
    // Vérifier si l'utilisateur a déjà donné un avis
    final avisNotifier = context.read<AvisLieuNotifier>();

    // Récupérer les avis du lieu
    await avisNotifier.fetchAvis();

    // Chercher un avis de l'utilisateur actuel
    final currentUserId = context.read<AuthNotifier>().currentUser?.id;
    // Rechercher l'avis correspondant à l'utilisateur courant de manière sûre
    final matching = avisNotifier.avis.where(
      (avis) => avis.utilisateurId == currentUserId,
    );
    final existingAvis = matching.isNotEmpty ? matching.first : null;

    if (existingAvis != null && mounted) {
      // L'utilisateur a déjà un avis
      _showExistingAvisDialog(existingAvis);
    }
  }

  void _showExistingAvisDialog(dynamic existingAvis) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: 12),
            const Text('Avis existant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous avez déjà donné un avis sur ce lieu.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingWidget(
                    rating: existingAvis.note,
                    onRatingChanged: (_) {},
                    readOnly: true,
                    size: 18,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    existingAvis.texte,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vous ne pouvez donner qu\'un seul avis par lieu. '
              'Voulez-vous modifier votre avis existant ?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context); // Retourner à la page précédente
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              // Naviguer vers modification
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AvisLieuEditPage(avis: existingAvis),
                ),
              );
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Donner mon avis'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info du lieu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withAlpha((255 * 0.3).round()),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withAlpha((255 * 0.2).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vous donnez un avis sur',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.mediumGrey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.lieuNom,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Note
              Text(
                'Votre note',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Cliquez sur les étoiles pour noter',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
              ),
              const SizedBox(height: 16),
              Center(
                child: RatingWidget(
                  rating: _note,
                  onRatingChanged: (note) {
                    setState(() => _note = note);
                  },
                  size: 40,
                ),
              ),
              if (_note > 0) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getRatingColor().withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getRatingText(),
                      style: TextStyle(
                        color: _getRatingColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Texte de l'avis
              Text(
                'Votre commentaire',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Partagez votre expérience avec la communauté',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Commentaire',
                hint: 'Décrivez votre expérience dans ce lieu...',
                controller: _texteController,
                prefixIcon: Icons.comment,
                maxLines: 8,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un commentaire';
                  }
                  if (value.length < 10) {
                    return 'Le commentaire doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Message d'encouragement
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Un avis constructif aide les autres utilisateurs à faire leur choix',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de soumission
              Consumer<CreateAvisLieuNotifier>(
                builder: (context, createNotifier, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: createNotifier.isLoading
                            ? null
                            : () => _handleSubmit(createNotifier),
                        icon: createNotifier.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          createNotifier.isLoading
                              ? 'Publication...'
                              : 'Publier mon avis',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                      if (createNotifier.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withAlpha((255 * 0.3).round()),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  createNotifier.error!,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit(CreateAvisLieuNotifier createNotifier) async {
    if (_note == 0) {
      SnackBarHelper.showError(context, 'Veuillez donner une note');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    createNotifier.clearError();

    final avis = await createNotifier.createAvis(
      lieuId: widget.lieuId,
      note: _note,
      texte: _texteController.text.trim(),
    );

    if (mounted) {
      if (avis != null) {
        SnackBarHelper.showSuccess(context, 'Avis publié avec succès');
        Navigator.pop(context, true);
      } else if (createNotifier.error != null) {
        // ✅ Gérer le message d'erreur spécifique
        final error = createNotifier.error!;

        if (error.contains('déjà donné un avis') ||
            error.contains('already exists')) {
          // Avis en double détecté
          _showDuplicateAvisError();
        } else {
          // Autre erreur
          SnackBarHelper.showError(context, error);
        }
      }
    }
  }

  void _showDuplicateAvisError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avis déjà existant'),
        content: const Text(
          'Vous avez déjà donné un avis sur ce lieu. '
          'Veuillez modifier votre avis existant depuis la liste des avis.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer dialogue
              Navigator.pop(context); // Retourner à la liste
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor() {
    if (_note >= 4) return AppColors.success;
    if (_note >= 3) return AppColors.warning;
    return AppColors.error;
  }

  String _getRatingText() {
    switch (_note) {
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
}
