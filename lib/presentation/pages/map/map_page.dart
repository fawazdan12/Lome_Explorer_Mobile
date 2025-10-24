import 'dart:async';
import 'package:event_flow/config/theme/app_color.dart';
import 'package:event_flow/core/providers/geo_provider.dart';
import 'package:event_flow/core/providers/lieu_evenement_provider.dart';
import 'package:event_flow/presentation/pages/evenement/evenement_detail_page.dart';
import 'package:event_flow/presentation/pages/lieu/lieu_detail_page.dart';
import 'package:event_flow/presentation/pages/map/models/map_item.dart';
import 'package:event_flow/presentation/pages/map/widgets/map_filter_chip.dart';
import 'package:event_flow/presentation/pages/map/widgets/map_itinerary_panel.dart';
import 'package:event_flow/presentation/pages/map/widgets/map_marker_widget.dart';
import 'package:event_flow/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  LatLng? _userPosition;
  MapItem? _selectedItem;
  MapItem? _navigationDestination;

  Set<MapItemType> _selectedFilters = {};
  bool _isFollowingUser = true;
  StreamSubscription<Position>? _positionSubscription;

  // Lomé par défaut
  static const LatLng _lomeCenter = LatLng(6.1319, 1.2228);

  @override
  void initState() {
    super.initState();
    
    // ✅ CORRECTION : Utiliser addPostFrameCallback pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    // Détecter la position utilisateur
    await _detectUserPosition();

    // Charger les lieux et événements
    if (mounted) {
      context.read<LieuxNotifier>().fetchLieux();
      context.read<EvenementsNotifier>().fetchEvenements();
    }
  }

  Future<void> _detectUserPosition() async {
    try {
      final locationNotifier = context.read<UserLocationNotifier>();
      await locationNotifier.detectLocation();

      if (locationNotifier.location != null && mounted) {
        setState(() {
          _userPosition = LatLng(
            locationNotifier.location!.latitude,
            locationNotifier.location!.longitude,
          );
        });

        // Centrer la carte sur l'utilisateur
        _centerMapOnUser();

        // Commencer à suivre la position
        _startPositionTracking();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Impossible de détecter votre position',
        );
      }
    }
  }

  void _startPositionTracking() {
    final positionWatcher = context.read<PositionWatcherNotifier>();

    positionWatcher.startWatching(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    // Écouter les changements de position
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _userPosition = LatLng(position.latitude, position.longitude);
            });

            // Si on suit l'utilisateur, centrer la carte
            if (_isFollowingUser) {
              _centerMapOnUser(animate: true);
            }

            // Si navigation active, mettre à jour l'itinéraire
            if (_navigationDestination != null) {
              _updateNavigationRoute();
            }
          }
        });
  }

  void _centerMapOnUser({bool animate = false}) {
    if (_userPosition != null && _mapController != null) {
      final cameraUpdate = CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _userPosition!,
          zoom: 15,
          tilt: animate ? 45 : 0,
        ),
      );

      if (animate) {
        _mapController!.animateCamera(cameraUpdate);
      } else {
        _mapController!.moveCamera(cameraUpdate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          _buildMap(),

          // Filtres en haut
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: MapFilterChips(
              selectedFilters: _selectedFilters,
              onFiltersChanged: (filters) {
                setState(() {
                  _selectedFilters = filters;
                  _updateMarkers();
                });
              },
            ),
          ),

          // Bouton position utilisateur
          Positioned(
            bottom: _navigationDestination != null ? 280 : 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'user_location',
              onPressed: () {
                setState(() {
                  _isFollowingUser = true;
                });
                _centerMapOnUser(animate: true);
              },
              backgroundColor: _isFollowingUser
                  ? AppColors.primaryOrange
                  : Colors.white,
              child: Icon(
                Icons.my_location,
                color: _isFollowingUser
                    ? Colors.white
                    : AppColors.primaryOrange,
              ),
            ),
          ),

          // Bouton zoom avant
          Positioned(
            bottom: _navigationDestination != null ? 360 : 180,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'zoom_in',
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.zoomIn());
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.black87),
            ),
          ),

          // Bouton zoom arrière
          Positioned(
            bottom: _navigationDestination != null ? 420 : 240,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'zoom_out',
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.zoomOut());
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.remove, color: Colors.black87),
            ),
          ),

          // Panneau d'itinéraire si navigation active
          if (_navigationDestination != null && _userPosition != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MapItineraryPanel(
                destination: _navigationDestination!,
                userPosition: _userPosition!,
                distance: _calculateDistance(
                  _userPosition!,
                  _navigationDestination!.position,
                ),
                duration: _estimateDuration(
                  _calculateDistance(
                    _userPosition!,
                    _navigationDestination!.position,
                  ),
                ),
                onClose: () {
                  setState(() {
                    _navigationDestination = null;
                    _polylines.clear();
                    _isFollowingUser = false;
                  });
                },
                onStartNavigation: _openGoogleMapsNavigation,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _userPosition ?? _lomeCenter,
        zoom: 14,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMarkers();
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onCameraMove: (_) {
        // Désactiver le suivi si l'utilisateur bouge la carte
        if (_isFollowingUser) {
          setState(() {
            _isFollowingUser = false;
          });
        }
      },
      onTap: (_) {
        // Fermer la sélection si on clique ailleurs
        if (_selectedItem != null && _navigationDestination == null) {
          setState(() {
            _selectedItem = null;
          });
        }
      },
    );
  }

  Future<void> _updateMarkers() async {
    final markers = <Marker>{};

    // Marker position utilisateur
    if (_userPosition != null) {
      final userIcon = await CustomMarkerHelper.createMarkerIcon(
        type: MapItemType.userPosition,
        context: context,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('user_position'),
          position: _userPosition!,
          icon: userIcon,
          anchor: const Offset(0.5, 0.5),
          zIndex: 999,
        ),
      );
    }

    // Markers des lieux
    if (_selectedFilters.isEmpty ||
        _selectedFilters.contains(MapItemType.lieu)) {
      final lieuxNotifier = context.read<LieuxNotifier>();
      for (final lieu in lieuxNotifier.lieux) {
        final mapItem = MapItem.fromLieu(lieu);
        final icon = await CustomMarkerHelper.createMarkerIcon(
          type: MapItemType.lieu,
          context: context,
        );

        markers.add(
          Marker(
            markerId: MarkerId('lieu_${lieu.id}'),
            position: mapItem.position,
            icon: icon,
            onTap: () => _onMarkerTapped(mapItem),
          ),
        );
      }
    }

    // Markers des événements
    if (_selectedFilters.isEmpty ||
        _selectedFilters.contains(MapItemType.evenement)) {
      final evenementsNotifier = context.read<EvenementsNotifier>();
      for (final evenement in evenementsNotifier.evenements) {
        if (evenement.lieuLatitude != null && evenement.lieuLongitude != null) {
          final mapItem = MapItem.fromEvenement(evenement);
          final icon = await CustomMarkerHelper.createMarkerIcon(
            type: MapItemType.evenement,
            context: context,
          );

          markers.add(
            Marker(
              markerId: MarkerId('evenement_${evenement.id}'),
              position: mapItem.position,
              icon: icon,
              onTap: () => _onMarkerTapped(mapItem),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  void _onMarkerTapped(MapItem item) {
    setState(() {
      _selectedItem = item;
    });

    // Centrer la carte sur le marker
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: item.position, zoom: 16),
      ),
    );

    // Afficher le bottom sheet avec les détails
    _showItemDetails(item);
  }

  void _showItemDetails(MapItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: MapMarkerInfoWindow(
          item: item,
          onTap: () {
            Navigator.pop(context);
            _navigateToDetails(item);
          },
          onDirections: () {
            Navigator.pop(context);
            _startNavigation(item);
          },
        ),
      ),
    );
  }

  void _navigateToDetails(MapItem item) {
    if (item.type == MapItemType.lieu) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LieuDetailPage(lieuId: item.id)),
      );
    } else if (item.type == MapItemType.evenement) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EvenementDetailPage(evenementId: item.id),
        ),
      );
    }
  }

  void _startNavigation(MapItem destination) {
    if (_userPosition == null) {
      SnackBarHelper.showError(context, 'Position utilisateur non disponible');
      return;
    }

    setState(() {
      _navigationDestination = destination;
      _isFollowingUser = true;
    });

    // Créer l'itinéraire
    _createRoute(destination);

    // Centrer la carte pour voir les deux points
    _fitBounds([_userPosition!, destination.position]);
  }

  void _createRoute(MapItem destination) {
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [_userPosition!, destination.position],
      color: AppColors.primaryBlue,
      width: 5,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );

    setState(() {
      _polylines = {polyline};
    });
  }

  void _updateNavigationRoute() {
    if (_navigationDestination != null && _userPosition != null) {
      _createRoute(_navigationDestination!);
    }
  }

  void _fitBounds(List<LatLng> positions) {
    if (_mapController == null || positions.isEmpty) return;

    double minLat = positions[0].latitude;
    double maxLat = positions[0].latitude;
    double minLng = positions[0].longitude;
    double maxLng = positions[0].longitude;

    for (final pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000;
  }

  int _estimateDuration(double distanceKm) {
    return ((distanceKm / 40) * 60).round();
  }

  Future<void> _openGoogleMapsNavigation() async {
    if (_navigationDestination == null) return;

    final destination = _navigationDestination!.position;
    final url = Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}&mode=d',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        final webUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}',
        );
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Impossible d\'ouvrir Google Maps');
      }
    }
  }
}