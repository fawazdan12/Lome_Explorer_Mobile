import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/domains/entities/avis_lieu_evenement_entity.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AvisLieuEditPage extends StatefulWidget {
  final AvisLieuEntity avis;

  const AvisLieuEditPage({
    super.key,
    required this.avis,
  });

  @override
  State<AvisLieuEditPage> createState() => _AvisLieuEditPageState();
}

class _AvisLieuEditPageState extends State<AvisLieuEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _texteController;
  late int _note;

  @override
  void initState() {
    super.initState();
    _texteController = TextEditingController(text: widget.avis.texte);
    _note = widget.avis.note;
  }

  @override
  void dispose() {
    _texteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Modifier mon avis',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info du lieu et date
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withAlpha((255 * 0.3).round()),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                'Avis sur',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.mediumGrey,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.avis.lieuNom,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Publié le ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.avis.date)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Note
              Text(
                'Votre note',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Note actuelle: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                  ),
                  ...List.generate(5, (index) {
                    return Icon(
                      index < widget.avis.note ? Icons.star : Icons.star_border,
                      color: AppColors.ratingColor,
                      size: 16,
                    );
                  }),
                ],
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_note != widget.avis.note) ...[
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: _getRatingColor(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _getRatingText(),
                          style: TextStyle(
                            color: _getRatingColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Texte de l'avis
              Text(
                'Votre commentaire',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Modifiez votre commentaire',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
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

              // Comparaison si modifié
              if (_texteController.text != widget.avis.texte ||
                  _note != widget.avis.note) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous avez modifié votre avis',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Boutons d'action
              Consumer<UpdateAvisLieuNotifier>(
                builder: (context, updateNotifier, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: updateNotifier.isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: updateNotifier.isLoading
                                  ? null
                                  : () => _handleSubmit(updateNotifier),
                              icon: updateNotifier.isLoading
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
                                  : const Icon(Icons.save),
                              label: Text(
                                updateNotifier.isLoading
                                    ? 'Enregistrement...'
                                    : 'Enregistrer',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (updateNotifier.error != null) ...[
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
                                  updateNotifier.error!,
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

  void _handleSubmit(UpdateAvisLieuNotifier updateNotifier) async {
    if (_note == 0) {
      SnackBarHelper.showError(
        context,
        'Veuillez donner une note',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier si des modifications ont été apportées
    if (_note == widget.avis.note && 
        _texteController.text.trim() == widget.avis.texte) {
      SnackBarHelper.showInfo(
        context,
        'Aucune modification détectée',
      );
      return;
    }

    updateNotifier.clearError();

    final avis = await updateNotifier.updateAvis(
      avisId: widget.avis.id,
      note: _note,
      texte: _texteController.text.trim(),
    );

    if (avis != null && mounted) {
      SnackBarHelper.showSuccess(
        context,
        'Avis modifié avec succès',
      );
      Navigator.pop(context, true);
    }
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