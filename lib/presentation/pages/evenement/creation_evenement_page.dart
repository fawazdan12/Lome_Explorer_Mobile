import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as getit;
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/presentation/pages/auth/auth_guard.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EvenementCreatePage extends StatefulWidget {
  const EvenementCreatePage({super.key});

  @override
  State<EvenementCreatePage> createState() => _EvenementCreatePageState();
}

class _EvenementCreatePageState extends State<EvenementCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchLieuController = TextEditingController();

  String? _selectedLieuId;
  String? _selectedLieuNom;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isLoading = false;
  List<dynamic> _lieuxFiltered = [];

  @override
  void initState() {
    super.initState();
    
    // Vérifier l'authentification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final authNotifier = context.read<AuthNotifier>();
    
    if (!authNotifier.isAuthenticated) {
      final shouldLogin = await AuthGuard.requireAuth(
        context,
        message: 'Vous devez être connecté pour créer un événement.',
      );
      
      if (!shouldLogin && mounted) {
        Navigator.pop(context);
        return;
      }
      
      if (shouldLogin && mounted) {
        final result = await Navigator.pushNamed(context, '/login');
        if (result != true && mounted) {
          Navigator.pop(context);
          return;
        }
      }
    }
    
    // Charger les lieux disponibles si authentifié
    if (mounted && authNotifier.isAuthenticated) {
      context.read<LieuxNotifier>().fetchLieux();
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _searchLieuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Créer un événement',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info en-tête
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Créez un événement pour partager avec la communauté',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nom de l'événement
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

              // Section Dates et Horaires
              Text(
                'Dates et horaires',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Date de début
              _buildDateTimeCard(
                context: context,
                label: 'Début de l\'événement',
                icon: Icons.event,
                iconColor: AppColors.primaryBlue,
                dateTime: _dateDebut,
                onTap: () => _selectDateTime(isDebut: true),
              ),
              const SizedBox(height: 12),

              // Date de fin
              _buildDateTimeCard(
                context: context,
                label: 'Fin de l\'événement',
                icon: Icons.event_available,
                iconColor: AppColors.primaryGreen,
                dateTime: _dateFin,
                onTap: () => _selectDateTime(isDebut: false),
              ),
              const SizedBox(height: 24),

              // Section Lieu
              Text(
                'Lieu de l\'événement',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Lieu sélectionné ou Recherche
              if (_selectedLieuId != null)
                _buildSelectedLieu()
              else
                _buildLieuSearch(),

              const SizedBox(height: 24),

              // Validation
              if (_dateDebut != null && _dateFin != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Durée: ${_getDuration()}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
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
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Créer l\'événement'),
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

  Widget _buildDateTimeCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required DateTime? dateTime,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('dd MMMM yyyy \'à\' HH:mm', 'fr_FR');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: dateTime != null ? iconColor : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: dateTime != null
              ? iconColor.withOpacity(0.05)
              : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateTime != null
                        ? dateFormat.format(dateTime)
                        : 'Sélectionner une date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dateTime != null
                              ? AppColors.darkGrey
                              : AppColors.mediumGrey,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_calendar,
              color: iconColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLieu() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.place, color: AppColors.primaryGreen),
        ),
        title: Text(
          _selectedLieuNom ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Lieu sélectionné'),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _selectedLieuId = null;
              _selectedLieuNom = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLieuSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barre de recherche
        TextField(
          controller: _searchLieuController,
          decoration: InputDecoration(
            hintText: 'Rechercher un lieu...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchLieuController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchLieuController.clear();
                        _lieuxFiltered.clear();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            _filterLieux(value);
          },
        ),
        const SizedBox(height: 12),

        // Résultats de recherche
        if (_lieuxFiltered.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _lieuxFiltered.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final lieu = _lieuxFiltered[index];
                return ListTile(
                  leading: Icon(Icons.place, color: AppColors.primaryGreen),
                  title: Text(lieu.nom),
                  subtitle: Text(lieu.categorie),
                  onTap: () {
                    setState(() {
                      _selectedLieuId = lieu.id;
                      _selectedLieuNom = lieu.nom;
                      _searchLieuController.clear();
                      _lieuxFiltered.clear();
                    });
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          )
        else if (_searchLieuController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Aucun lieu trouvé',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mediumGrey),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _showLieuxDialog(),
            icon: const Icon(Icons.list),
            label: const Text('Voir tous les lieux'),
          ),
      ],
    );
  }

  void _filterLieux(String query) {
    final lieuxNotifier = context.read<LieuxNotifier>();
    
    if (query.isEmpty) {
      setState(() {
        _lieuxFiltered = [];
      });
      return;
    }

    setState(() {
      _lieuxFiltered = lieuxNotifier.lieux
          .where((lieu) =>
              lieu.nom.toLowerCase().contains(query.toLowerCase()) ||
              lieu.categorie.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
    });
  }

  void _showLieuxDialog() {
    final lieuxNotifier = context.read<LieuxNotifier>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un lieu'),
        content: SizedBox(
          width: double.maxFinite,
          child: lieuxNotifier.isLoading
              ? const Center(child: CircularProgressIndicator())
              : lieuxNotifier.lieux.isEmpty
                  ? const Center(child: Text('Aucun lieu disponible'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: lieuxNotifier.lieux.length,
                      itemBuilder: (context, index) {
                        final lieu = lieuxNotifier.lieux[index];
                        return ListTile(
                          leading: Icon(
                            Icons.place,
                            color: AppColors.primaryGreen,
                          ),
                          title: Text(lieu.nom),
                          subtitle: Text(lieu.categorie),
                          onTap: () {
                            setState(() {
                              _selectedLieuId = lieu.id;
                              _selectedLieuNom = lieu.nom;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime({required bool isDebut}) async {
    final initialDate = isDebut
        ? (_dateDebut ?? DateTime.now())
        : (_dateFin ?? _dateDebut ?? DateTime.now());

    // Sélection de la date
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      helpText: isDebut ? 'Date de début' : 'Date de fin',
    );

    if (date == null) return;

    // Sélection de l'heure
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      helpText: isDebut ? 'Heure de début' : 'Heure de fin',
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
        if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) {
          _dateFin = _dateDebut!.add(const Duration(hours: 2));
        }
      } else {
        // Vérifier que la date de fin est après la date de début
        if (_dateDebut != null && dateTime.isBefore(_dateDebut!)) {
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

  String _getDuration() {
    if (_dateDebut == null || _dateFin == null) return '';
    
    final duration = _dateFin!.difference(_dateDebut!);
    
    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      return '${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}'
          '${hours > 0 ? ' et $hours heure${hours > 1 ? 's' : ''}' : ''}';
    } else if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}'
          '${minutes > 0 ? ' et $minutes minute${minutes > 1 ? 's' : ''}' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  Future<void> _handleSubmit() async {
    // Vérifier l'authentification
    final authNotifier = context.read<AuthNotifier>();
    if (!authNotifier.isAuthenticated) {
      SnackBarHelper.showError(
        context,
        'Vous devez être connecté pour créer un événement',
      );
      
      final shouldLogin = await AuthGuard.requireAuth(context);
      if (shouldLogin && mounted) {
        await Navigator.pushNamed(context, '/login');
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateDebut == null) {
      SnackBarHelper.showError(
        context,
        'Veuillez sélectionner une date de début',
      );
      return;
    }

    if (_dateFin == null) {
      SnackBarHelper.showError(
        context,
        'Veuillez sélectionner une date de fin',
      );
      return;
    }

    if (_selectedLieuId == null) {
      SnackBarHelper.showError(
        context,
        'Veuillez sélectionner un lieu',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nom = _nomController.text.trim();
      final description = _descriptionController.text.trim();
      final dateHeure = _dateDebut!;
      final lieuId = _selectedLieuId!;

      // Utiliser GetIt pour le service
      await getit.getIt<LieuEvenementService>().createEvenement(
        nom: nom,
        description: description,
        dateHeure: dateHeure,
        lieuId: lieuId,
      );

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Événement créé avec succès',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la création: ';
        
        if (e.toString().contains('401') || 
            e.toString().contains('authentication')) {
          errorMessage = 'Erreur d\'authentification. Veuillez vous reconnecter.';
          
          await context.read<AuthNotifier>().logout();
          if (mounted) {
            await Navigator.pushNamed(context, '/login');
            Navigator.pop(context);
          }
        } else if (e.toString().contains('Network')) {
          errorMessage = 'Erreur de connexion. Vérifiez votre connexion Internet.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
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