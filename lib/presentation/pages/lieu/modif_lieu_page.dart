import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/domains/entities/lieu_entity.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as getit;
import 'package:event_flow/presentation/pages/auth/guard_lieu_evenement.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LieuEditPage extends StatefulWidget {
  final LieuEntity lieu;

  const LieuEditPage({super.key, required this.lieu});

  @override
  State<LieuEditPage> createState() => _LieuEditPageState();
}

class _LieuEditPageState extends State<LieuEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String? _selectedCategorie;
  bool _isLoading = false;

  final List<String> _categories = [
    'Restaurant',
    'Bar',
    'Hôtel',
    'Musée',
    'Parc',
    'Centre commercial',
    'Salle de sport',
    'Cinéma',
    'Théâtre',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Vérifier l'authentification et la propriété
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOwnership();
    });
    _nomController = TextEditingController(text: widget.lieu.nom);
    _descriptionController = TextEditingController(
      text: widget.lieu.description,
    );
    _latitudeController = TextEditingController(
      text: widget.lieu.latitude.toStringAsFixed(6),
    );
    _longitudeController = TextEditingController(
      text: widget.lieu.longitude.toStringAsFixed(6),
    );
    _selectedCategorie = widget.lieu.categorie;
  }

  /// Vérifier que l'utilisateur est authentifié ET propriétaire
  Future<void> _checkOwnership() async {
    final canEdit = await OwnershipGuard.checkOwnershipForAction(
      context: context,
      action: 'modifier',
      lieu: widget.lieu,
    );

    if (!canEdit && mounted) {
      // Retour automatique si pas de permission
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Modifier le lieu'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom
              CustomTextField(
                label: 'Nom du lieu',
                hint: 'Ex: Restaurant Le Palmier',
                controller: _nomController,
                prefixIcon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  if (value.length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catégorie',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategorie,
                    decoration: InputDecoration(
                      hintText: 'Sélectionnez une catégorie',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _categories.map((categorie) {
                      return DropdownMenuItem(
                        value: categorie,
                        child: Text(categorie),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategorie = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une catégorie';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                label: 'Description',
                hint: 'Décrivez le lieu...',
                controller: _descriptionController,
                prefixIcon: Icons.description,
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  if (value.length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Localisation
              Text(
                'Localisation',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Latitude
              CustomTextField(
                label: 'Latitude',
                hint: 'Ex: 6.1312',
                controller: _latitudeController,
                prefixIcon: Icons.location_on,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la latitude';
                  }
                  final latitude = double.tryParse(value);
                  if (latitude == null) {
                    return 'Latitude invalide';
                  }
                  if (latitude < -90 || latitude > 90) {
                    return 'La latitude doit être entre -90 et 90';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Longitude
              CustomTextField(
                label: 'Longitude',
                hint: 'Ex: 1.2220',
                controller: _longitudeController,
                prefixIcon: Icons.location_on,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la longitude';
                  }
                  final longitude = double.tryParse(value);
                  if (longitude == null) {
                    return 'Longitude invalide';
                  }
                  if (longitude < -180 || longitude > 180) {
                    return 'La longitude doit être entre -180 et 180';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ID du lieu: ${widget.lieu.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
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
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ CORRECTION : Utiliser GetIt au lieu de context.read
  void _handleSubmit() async {
    // ✅ Double vérification avant soumission
    final canEdit = await context.canEditLieu(widget.lieu);
    if (!canEdit) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nom = _nomController.text.trim();
      final description = _descriptionController.text.trim();
      final categorie = _selectedCategorie!;
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());

      // ✅ CORRECTION : Utiliser GetIt
      await getit.getIt<LieuEvenementService>().updateLieu(
        id: widget.lieu.id,
        nom: nom,
        description: description,
        categorie: categorie,
        latitude: latitude,
        longitude: longitude,
      );

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Lieu modifié avec succès');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la modification: ';

        if (e.toString().contains('401') ||
            e.toString().contains('authentication')) {
          errorMessage =
              'Erreur d\'authentification. Veuillez vous reconnecter.';
          await context.read<AuthNotifier>().logout();
          if (mounted) {
            await Navigator.pushNamed(context, '/login');
            Navigator.pop(context);
          }
        } else {
          errorMessage += e.toString();
        }

        SnackBarHelper.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}