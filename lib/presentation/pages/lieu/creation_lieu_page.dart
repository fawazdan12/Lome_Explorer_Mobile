import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/auth_provider.dart';
import 'package:event_flow/core/providers/geo_provider.dart';
import 'package:event_flow/core/services/lieu_evenement_service.dart';
import 'package:event_flow/domains/entities/geolocation_entity.dart';
import 'package:event_flow/domains/injections/service_locator.dart' as getit;
import 'package:event_flow/presentation/pages/auth/auth_guard.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class LieuCreatePage extends StatefulWidget {
  const LieuCreatePage({super.key});

  @override
  State<LieuCreatePage> createState() => _LieuCreatePageState();
}

class _LieuCreatePageState extends State<LieuCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _searchController = TextEditingController();

  GoogleMapController? _mapController;
  String? _selectedCategorie;
  LatLng? _selectedPosition;
  bool _isLoading = false;
  bool _isSearching = false;
  List<QuartierEntity> _searchResults = [];

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

  // Position par défaut (Lomé)
  static const LatLng _lomeCenter = LatLng(6.1319, 1.2228);

  @override
  void initState() {
    super.initState();
    // ✅ Vérifier l'authentification au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
    _loadQuartiers();
    _detectUserLocation();
  }

  /// Vérifier que l'utilisateur est authentifié
  Future<void> _checkAuthentication() async {
    final authNotifier = context.read<AuthNotifier>();

    if (!authNotifier.isAuthenticated) {
      final shouldLogin = await AuthGuard.requireAuth(
        context,
        message: 'Vous devez être connecté pour créer un lieu.',
      );

      if (!shouldLogin && mounted) {
        // Retour à la page précédente si refus
        Navigator.pop(context);
        return;
      }

      if (shouldLogin && mounted) {
        // Redirection vers login
        final result = await Navigator.pushNamed(context, '/login');
        if (result != true && mounted) {
          // Si pas de connexion réussie, retour
          Navigator.pop(context);
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadQuartiers() async {
    final quartiersNotifier = context.read<QuartiersNotifier>();
    await quartiersNotifier.fetchQuartiers();
  }

  Future<void> _detectUserLocation() async {
    try {
      final locationNotifier = context.read<UserLocationNotifier>();
      await locationNotifier.detectLocation();

      if (locationNotifier.location != null && mounted) {
        final location = locationNotifier.location!;
        setState(() {
          _selectedPosition = LatLng(location.latitude, location.longitude);
          _latitudeController.text = location.latitude.toStringAsFixed(6);
          _longitudeController.text = location.longitude.toStringAsFixed(6);
        });

        // Centrer la carte sur la position détectée
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _selectedPosition!, zoom: 15),
          ),
        );
      }
    } catch (e) {
      // Utiliser Lomé par défaut si échec
      setState(() {
        _selectedPosition = _lomeCenter;
        _latitudeController.text = _lomeCenter.latitude.toStringAsFixed(6);
        _longitudeController.text = _lomeCenter.longitude.toStringAsFixed(6);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Créer un lieu'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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

              // Section Localisation
              Text(
                'Localisation',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Barre de recherche de lieu
              _buildSearchBar(),
              const SizedBox(height: 12),

              // Résultats de recherche
              if (_isSearching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                _buildSearchResults(),

              const SizedBox(height: 16),

              // Carte interactive
              _buildMap(),
              const SizedBox(height: 16),

              // Coordonnées GPS (lecture seule, remplies automatiquement)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Latitude',
                      hint: 'Ex: 6.1312',
                      controller: _latitudeController,
                      prefixIcon: Icons.location_on,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Latitude requise';
                        }
                        final latitude = double.tryParse(value);
                        if (latitude == null) {
                          return 'Latitude invalide';
                        }
                        if (latitude < -90 || latitude > 90) {
                          return 'Entre -90 et 90';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final lat = double.tryParse(value);
                        final lng = double.tryParse(_longitudeController.text);
                        if (lat != null && lng != null) {
                          setState(() {
                            _selectedPosition = LatLng(lat, lng);
                          });
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(_selectedPosition!),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Longitude',
                      hint: 'Ex: 1.2220',
                      controller: _longitudeController,
                      prefixIcon: Icons.location_on,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Longitude requise';
                        }
                        final longitude = double.tryParse(value);
                        if (longitude == null) {
                          return 'Longitude invalide';
                        }
                        if (longitude < -180 || longitude > 180) {
                          return 'Entre -180 et 180';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final lat = double.tryParse(_latitudeController.text);
                        final lng = double.tryParse(value);
                        if (lat != null && lng != null) {
                          setState(() {
                            _selectedPosition = LatLng(lat, lng);
                          });
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(_selectedPosition!),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Boutons d'aide pour la position
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _detectUserLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Ma position'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showQuartiersDialog,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Quartiers'),
                    ),
                  ),
                ],
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
                        'Recherchez un lieu, cliquez sur la carte ou utilisez votre position actuelle',
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
                          : const Text('Créer'),
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher un lieu ou une adresse...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchResults.clear();
                  });
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (value) {
        if (value.length > 2) {
          _searchLocation(value);
        } else {
          setState(() {
            _searchResults.clear();
          });
        }
      },
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            leading: Icon(Icons.location_on, color: AppColors.primaryGreen),
            title: Text(result.nom),
            subtitle: Text(
              'Lat: ${result.latitude.toStringAsFixed(4)}, '
              'Lng: ${result.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => _selectSearchResult(result),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedPosition ?? _lomeCenter,
            zoom: 14,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: (position) {
            setState(() {
              _selectedPosition = position;
              _latitudeController.text = position.latitude.toStringAsFixed(6);
              _longitudeController.text = position.longitude.toStringAsFixed(6);
            });
          },
          markers: _selectedPosition != null
              ? {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: _selectedPosition!,
                    draggable: true,
                    onDragEnd: (newPosition) {
                      setState(() {
                        _selectedPosition = newPosition;
                        _latitudeController.text = newPosition.latitude
                            .toStringAsFixed(6);
                        _longitudeController.text = newPosition.longitude
                            .toStringAsFixed(6);
                      });
                    },
                  ),
                }
              : {},
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      // Rechercher dans les quartiers
      final quartiersNotifier = context.read<QuartiersNotifier>();
      if (quartiersNotifier.quartiers.isEmpty) {
        await quartiersNotifier.fetchQuartiers();
      }

      final results = quartiersNotifier.quartiers
          .where((q) => q.nom.toLowerCase().contains(query.toLowerCase()))
          .toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      // Si aucun résultat dans les quartiers, essayer le géocodage
      if (results.isEmpty) {
        await _geocodeAddress(query);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de la recherche');
      }
    }
  }

  Future<void> _geocodeAddress(String address) async {
    try {
      final geocodeNotifier = context.read<GeocodeAddressNotifier>();
      final location = await geocodeNotifier.geocodeAddress(address);

      if (location != null) {
        // Créer un résultat avec l'adresse géocodée
        final quartier = QuartierEntity(
          key: 'geocoded',
          nom: address,
          latitude: location.latitude,
          longitude: location.longitude,
        );

        setState(() {
          _searchResults = [quartier];
        });
      }
    } catch (e) {
      // Ignorer l'erreur silencieusement
    }
  }

  void _selectSearchResult(QuartierEntity result) {
    setState(() {
      _selectedPosition = LatLng(result.latitude, result.longitude);
      _latitudeController.text = result.latitude.toStringAsFixed(6);
      _longitudeController.text = result.longitude.toStringAsFixed(6);
      _searchResults.clear();
      _searchController.clear();
    });

    // Centrer la carte sur le résultat
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _selectedPosition!, zoom: 16),
      ),
    );

    // Fermer le clavier
    FocusScope.of(context).unfocus();
  }

  void _showQuartiersDialog() {
    final quartiersNotifier = context.read<QuartiersNotifier>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un quartier'),
        content: SizedBox(
          width: double.maxFinite,
          child: quartiersNotifier.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: quartiersNotifier.quartiers.length,
                  itemBuilder: (context, index) {
                    final quartier = quartiersNotifier.quartiers[index];
                    return ListTile(
                      leading: Icon(
                        Icons.location_city,
                        color: AppColors.primaryGreen,
                      ),
                      title: Text(quartier.nom),
                      onTap: () {
                        _selectSearchResult(quartier);
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

  // Dans _handleSubmit, ajouter une double vérification :
  Future<void> _handleSubmit() async {
    // ✅ Double vérification avant soumission
    final authNotifier = context.read<AuthNotifier>();
    if (!authNotifier.isAuthenticated) {
      SnackBarHelper.showError(
        context,
        'Vous devez être connecté pour créer un lieu',
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

    if (_selectedPosition == null) {
      SnackBarHelper.showError(
        context,
        'Veuillez sélectionner une position sur la carte',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nom = _nomController.text.trim();
      final description = _descriptionController.text.trim();
      final categorie = _selectedCategorie!;
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());

      await getit.getIt<LieuEvenementService>().createLieu(
        nom: nom,
        description: description,
        categorie: categorie,
        latitude: latitude,
        longitude: longitude,
      );

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Lieu créé avec succès');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la création: ';

        // Gestion des erreurs spécifiques
        if (e.toString().contains('401') ||
            e.toString().contains('authentication')) {
          errorMessage =
              'Erreur d\'authentification. Veuillez vous reconnecter.';

          // Déconnexion automatique en cas d'erreur 401
          await context.read<AuthNotifier>().logout();
          if (mounted) {
            await Navigator.pushNamed(context, '/login');
            Navigator.pop(context);
          }
        } else if (e.toString().contains('Network')) {
          errorMessage =
              'Erreur de connexion. Vérifiez votre connexion Internet.';
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
