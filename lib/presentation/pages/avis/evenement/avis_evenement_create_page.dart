import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/avis_provider.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AvisEvenementCreatePage extends StatefulWidget {
  final String evenementId;
  final String evenementNom;

  const AvisEvenementCreatePage({
    super.key,
    required this.evenementId,
    required this.evenementNom,
  });

  @override
  State<AvisEvenementCreatePage> createState() =>
      _AvisEvenementCreatePageState();
}

class _AvisEvenementCreatePageState extends State<AvisEvenementCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _texteController = TextEditingController();
  int _note = 5;

  @override
  void dispose() {
    _texteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Donner mon avis',
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
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: AppColors.primaryBlue,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vous donnez votre avis sur',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
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
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
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
              const SizedBox(height: 12),

              // Conseils
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conseils pour un bon avis',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Décrivez votre expérience de manière détaillée\n'
                            '• Soyez honnête et constructif\n'
                            '• Restez respectueux',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Boutons
              Consumer<CreateAvisEvenementNotifier>(
                builder: (context, createAvisNotifier, _) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: createAvisNotifier.isLoading
                            ? null
                            : () => _handleSubmit(createAvisNotifier),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: createAvisNotifier.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Publier mon avis'),
                      ),
                      if (createAvisNotifier.error != null) ...[
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
                                  createAvisNotifier.error!,
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

  void _handleSubmit(CreateAvisEvenementNotifier createAvisNotifier) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final avis = await createAvisNotifier.createAvis(
      evenementId: widget.evenementId,
      note: _note,
      texte: _texteController.text.trim(),
    );

    if (avis != null && mounted) {
      SnackBarHelper.showSuccess(
        context,
        'Votre avis a été publié avec succès',
      );
      Navigator.pop(context, true); // Retourner true pour rafraîchir la liste
    }
  }
}