import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/domains/entities/avis_lieu_evenement_entity.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AvisEvenementEditPage extends StatefulWidget {
  final AvisEvenementEntity avis;

  const AvisEvenementEditPage({
    super.key,
    required this.avis,
  });

  @override
  State<AvisEvenementEditPage> createState() => _AvisEvenementEditPageState();
}

class _AvisEvenementEditPageState extends State<AvisEvenementEditPage> {
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
              // Info événement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryBlue.withAlpha((255 * 0.3).round()),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          color: AppColors.primaryBlue,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.avis.evenementNom,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Publié le ${DateFormat('dd/MM/yyyy').format(widget.avis.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Note
              Text(
                'Votre note',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      '$_note / 5',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                    ),
                    const SizedBox(height: 12),
                    RatingWidget(
                      rating: _note,
                      onRatingChanged: (note) {
                        setState(() => _note = note);
                      },
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getRatingLabel(_note),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Commentaire
              Text(
                'Votre commentaire',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: '',
                hint: 'Partagez votre expérience...',
                controller: _texteController,
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

              // Boutons
              Consumer<UpdateAvisEvenementNotifier>(
                builder: (context, updateAvisNotifier, _) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: updateAvisNotifier.isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: updateAvisNotifier.isLoading
                                  ? null
                                  : () => _handleSubmit(updateAvisNotifier),
                              child: updateAvisNotifier.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Enregistrer'),
                            ),
                          ),
                        ],
                      ),
                      if (updateAvisNotifier.error != null) ...[
                        const SizedBox(height: 12),
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
                                  updateAvisNotifier.error!,
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

  String _getRatingLabel(int note) {
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

  void _handleSubmit(UpdateAvisEvenementNotifier updateAvisNotifier) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final avis = await updateAvisNotifier.updateAvis(
      avisId: widget.avis.id,
      note: _note,
      texte: _texteController.text.trim(),
    );

    if (avis != null && mounted) {
      SnackBarHelper.showSuccess(
        context,
        'Votre avis a été modifié avec succès',
      );
      Navigator.pop(context, true); // Retourner true pour rafraîchir
    }
  }
}