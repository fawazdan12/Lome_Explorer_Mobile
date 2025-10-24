import 'package:event_flow/config/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map_item.dart';

/// Widget pour afficher les détails d'un marker en popup
class MapMarkerInfoWindow extends StatelessWidget {
  final MapItem item;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const MapMarkerInfoWindow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type et nom
            Row(
              children: [
                Icon(
                  _getIcon(),
                  color: _getColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (item.categorie != null) ...[
              const SizedBox(height: 4),
              Chip(
                label: Text(item.categorie!),
                backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
            if (item.moyenneAvis != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: AppColors.ratingColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.moyenneAvis!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (item.nombreAvis != null)
                    Text(
                      ' (${item.nombreAvis} avis)',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Y aller'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (item.type) {
      case MapItemType.lieu:
        return Icons.place;
      case MapItemType.evenement:
        return Icons.event;
      case MapItemType.userPosition:
        return Icons.my_location;
    }
  }

  Color _getColor() {
    switch (item.type) {
      case MapItemType.lieu:
        return AppColors.primaryGreen;
      case MapItemType.evenement:
        return AppColors.primaryBlue;
      case MapItemType.userPosition:
        return AppColors.primaryOrange;
    }
  }
}

/// Classe helper pour créer des markers personnalisés
class CustomMarkerHelper {
  static Future<BitmapDescriptor> createMarkerIcon({
    required MapItemType type,
    required BuildContext context,
  }) async {
    // Couleur selon le type
    Color color;
    switch (type) {
      case MapItemType.lieu:
        color = AppColors.primaryGreen;
        break;
      case MapItemType.evenement:
        color = AppColors.primaryBlue;
        break;
      case MapItemType.userPosition:
        color = AppColors.primaryOrange;
        break;
    }

    // Utiliser l'icône par défaut avec couleur
    return BitmapDescriptor.defaultMarkerWithHue(
      _colorToHue(color),
    );
  }

  static double _colorToHue(Color color) {
    // Convertir la couleur en teinte (hue) pour Google Maps
    if (color == AppColors.primaryGreen) return BitmapDescriptor.hueGreen;
    if (color == AppColors.primaryBlue) return BitmapDescriptor.hueBlue;
    if (color == AppColors.primaryOrange) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueRed;
  }
}