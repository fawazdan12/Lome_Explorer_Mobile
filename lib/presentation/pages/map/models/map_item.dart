import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Type d'élément sur la carte
enum MapItemType {
  lieu,
  evenement,
  userPosition,
}

/// Modèle représentant un élément sur la carte
class MapItem {
  final String id;
  final String nom;
  final String? description;
  final MapItemType type;
  final LatLng position;
  final String? categorie;
  final double? moyenneAvis;
  final int? nombreAvis;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const MapItem({
    required this.id,
    required this.nom,
    this.description,
    required this.type,
    required this.position,
    this.categorie,
    this.moyenneAvis,
    this.nombreAvis,
    this.dateDebut,
    this.dateFin,
  });

  /// Créer MapItem depuis LieuEntity
  factory MapItem.fromLieu(dynamic lieu) {
    return MapItem(
      id: lieu.id,
      nom: lieu.nom,
      description: lieu.description,
      type: MapItemType.lieu,
      position: LatLng(lieu.latitude, lieu.longitude),
      categorie: lieu.categorie,
      moyenneAvis: lieu.moyenneAvis,
    );
  }

  /// Créer MapItem depuis EvenementEntity
  factory MapItem.fromEvenement(dynamic evenement) {
    return MapItem(
      id: evenement.id,
      nom: evenement.nom,
      description: evenement.description,
      type: MapItemType.evenement,
      position: LatLng(
        evenement.lieuLatitude ?? 0,
        evenement.lieuLongitude ?? 0,
      ),
      dateDebut: evenement.dateDebut,
      dateFin: evenement.dateFin,
      moyenneAvis: evenement.moyenneAvis,
      nombreAvis: evenement.nombreAvis,
    );
  }

  /// Créer MapItem pour la position utilisateur
  factory MapItem.userPosition(LatLng position) {
    return MapItem(
      id: 'user_position',
      nom: 'Ma position',
      type: MapItemType.userPosition,
      position: position,
    );
  }
}