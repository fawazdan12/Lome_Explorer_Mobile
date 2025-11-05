import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/domains/entities/evenement_entity.dart';
import 'package:event_flow/presentation/pages/auth/guard_lieu_evenement.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EvenementEditPage extends StatefulWidget {
  final EvenementEntity evenement;

  const EvenementEditPage({super.key, required this.evenement});

  @override
  State<EvenementEditPage> createState() => _EvenementEditPageState();
}

class _EvenementEditPageState extends State<EvenementEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _descriptionController;

  late DateTime _dateDebut;
  late DateTime _dateFin;
  late String _selectedLieuId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ Vérifier l'authentification et la propriété
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOwnership();
    });
    _nomController = TextEditingController(text: widget.evenement.nom);
    _descriptionController = TextEditingController(
      text: widget.evenement.description,
    );
    _dateDebut = widget.evenement.dateDebut;
    _dateFin = widget.evenement.dateFin;
    _selectedLieuId = widget.evenement.lieuId!;

    // Charger les lieux disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LieuxNotifier>().fetchLieux();
    });
  }

  /// Vérifier que l'utilisateur est authentifié ET organisateur
  Future<void> _checkOwnership() async {
    final canEdit = await OwnershipGuard.checkOwnershipForAction(
      context: context,
      action: 'modifier',
      evenement: widget.evenement,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Modifier l\'événement'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom
              CustomTextField(
                label: 'Nom de l\'événement',
                hint: 'Ex: Concert de jazz',
                controller: _nomController,
                prefixIcon: Icons.event,
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

              // Description
              CustomTextField(
                label: 'Description',
                hint: 'Décrivez l\'événement...',
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

              // Dates et horaires
              Text(
                'Dates et horaires',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Date de début
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Date de début'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(_dateDebut),
                ),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _selectDateTime(isDebut: true),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 12),

              // Date de fin
              ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text('Date de fin'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_dateFin)),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _selectDateTime(isDebut: false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 24),

              // Lieu
              Text(
                'Lieu',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Consumer<LieuxNotifier>(
                builder: (context, lieuxNotifier, _) {
                  if (lieuxNotifier.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (lieuxNotifier.lieux.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Aucun lieu disponible',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // Vérifier si le lieu actuel existe encore
                  final lieuExists = lieuxNotifier.lieux.any(
                    (l) => l.id == _selectedLieuId,
                  );
                  if (!lieuExists) {
                    _selectedLieuId = lieuxNotifier.lieux.first.id;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedLieuId,
                    decoration: InputDecoration(
                      hintText: 'Sélectionnez un lieu',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: lieuxNotifier.lieux.map((lieu) {
                      return DropdownMenuItem(
                        value: lieu.id,
                        child: Text(lieu.nom),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLieuId = value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner un lieu';
                      }
                      return null;
                    },
                  );
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: ${widget.evenement.id}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Organisateur: ${widget.evenement.organisateurNom}',
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

  Future<void> _selectDateTime({required bool isDebut}) async {
    final initialDate = isDebut ? _dateDebut : _dateFin;

    // Sélection de la date
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (date == null) return;

    // Sélection de l'heure
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isDebut) {
        _dateDebut = dateTime;
        // Ajuster la date de fin si nécessaire
        if (_dateFin.isBefore(_dateDebut)) {
          _dateFin = _dateDebut.add(const Duration(hours: 2));
        }
      } else {
        // Vérifier que la date de fin est après la date de début
        if (dateTime.isBefore(_dateDebut)) {
          SnackBarHelper.showError(
            context,
            'La date de fin doit être après la date de début',
          );
          return;
        }
        _dateFin = dateTime;
      }
    });
  }

  void _handleSubmit() async {
  // ✅ Double vérification avant soumission
  final canEdit = await context.canEditEvenement(widget.evenement);
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
    final dateDebut = _dateDebut;  
    final dateFin = _dateFin;
    final lieuId = _selectedLieuId;

    await context.read<LieuEvenementService>().updateEvenement(
      id: widget.evenement.id, 
      nom: nom, 
      description: description, 
      dateDebut: dateDebut,  
      dateFin: dateFin,
      lieuId: lieuId
    );

    if (mounted) {
      SnackBarHelper.showSuccess(
        context,
        'Événement modifié avec succès',
      );
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      String errorMessage = 'Erreur lors de la modification: ';
      
      if (e.toString().contains('401') || 
          e.toString().contains('authentication')) {
        errorMessage = 'Erreur d\'authentification. Veuillez vous reconnecter.';
        await context.read<AuthNotifier>().logout();
        if (mounted) {
          await Navigator.pushNamed(context, '/login');
          Navigator.pop(context);
        }
      } else if (e.toString().contains('403') || 
                 e.toString().contains('permission')) {
        errorMessage = 'Vous n\'avez pas la permission de modifier cet événement.';
        Navigator.pop(context);
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
