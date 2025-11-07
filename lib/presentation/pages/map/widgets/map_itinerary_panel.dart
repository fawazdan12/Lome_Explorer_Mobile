import 'package:event_flow/config/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map_item.dart';

/// Panneau d'affichage de l'itinéraire
class MapItineraryPanel extends StatelessWidget {
  final MapItem destination;
  final LatLng userPosition;
  final double distance;
  final int duration; 
  final VoidCallback onClose;
  final VoidCallback onStartNavigation;

  const MapItineraryPanel({
    super.key,
    required this.destination,
    required this.userPosition,
    required this.distance,
    required this.duration,
    required this.onClose,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.2).round()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée de glissement
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // En-tête
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.nom,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            destination.type == MapItemType.lieu
                                ? Icons.place
                                : Icons.event,
                            size: 16,
                            color: AppColors.mediumGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            destination.type == MapItemType.lieu
                                ? destination.categorie ?? 'Lieu'
                                : 'Événement',
                            style: TextStyle(
                              color: AppColors.mediumGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Informations de trajet
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Distance
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.straighten,
                    title: 'Distance',
                    value: '${distance.toStringAsFixed(1)} km',
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                // Durée
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.access_time,
                    title: 'Durée',
                    value: _formatDuration(duration),
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryBlue.withAlpha((255 * 0.1).round()),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Suivez l\'itinéraire en temps réel pour vous rendre à votre destination',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bouton de démarrage
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: onStartNavigation,
              icon: const Icon(Icons.navigation),
              label: const Text('Démarrer la navigation'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mediumGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h${mins > 0 ? ' ${mins}min' : ''}';
  }
}