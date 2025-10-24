import 'package:event_flow/config/theme/app_color.dart';
import 'package:flutter/material.dart';
import '../models/map_item.dart';

/// Filtres pour la carte
class MapFilterChips extends StatelessWidget {
  final Set<MapItemType> selectedFilters;
  final ValueChanged<Set<MapItemType>> onFiltersChanged;

  const MapFilterChips({
    super.key,
    required this.selectedFilters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Tous',
              icon: Icons.layers,
              isSelected: selectedFilters.isEmpty,
              onTap: () {
                onFiltersChanged({});
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Lieux',
              icon: Icons.place,
              color: AppColors.primaryGreen,
              isSelected: selectedFilters.contains(MapItemType.lieu) &&
                  !selectedFilters.contains(MapItemType.evenement),
              onTap: () {
                final newFilters = <MapItemType>{MapItemType.lieu};
                onFiltersChanged(newFilters);
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Événements',
              icon: Icons.event,
              color: AppColors.primaryBlue,
              isSelected: selectedFilters.contains(MapItemType.evenement) &&
                  !selectedFilters.contains(MapItemType.lieu),
              onTap: () {
                final newFilters = <MapItemType>{MapItemType.evenement};
                onFiltersChanged(newFilters);
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Les deux',
              icon: Icons.dashboard,
              color: AppColors.primaryOrange,
              isSelected: selectedFilters.contains(MapItemType.lieu) &&
                  selectedFilters.contains(MapItemType.evenement),
              onTap: () {
                final newFilters = <MapItemType>{
                  MapItemType.lieu,
                  MapItemType.evenement,
                };
                onFiltersChanged(newFilters);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.mediumGrey;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : chipColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? chipColor : chipColor.withOpacity(0.5),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}