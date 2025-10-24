import 'package:event_flow/config/api_execption.dart';
import 'package:event_flow/data/models/avis_lieu_event_geo_model.dart';
import 'package:event_flow/data/models/hive_model.dart';
import 'package:event_flow/data/models/lieu_evenement_model.dart';
import 'package:event_flow/data/models/utilisateur_model.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';


class LocalDataSource {
  final Logger _logger;
  late Box<HiveUtilisateur> _utilisateurBox;
  late Box<HiveLieu> _lieuBox;
  late Box<HiveEvenement> _evenementBox;
  late Box<HiveLocation> _locationBox;

  LocalDataSource({required Logger logger}) : _logger = logger;

  /// Initialiser les boîtes Hive
  Future<void> initialize() async {
    try {
      _utilisateurBox = await Hive.openBox<HiveUtilisateur>('utilisateur');
      _lieuBox = await Hive.openBox<HiveLieu>('lieux');
      _evenementBox = await Hive.openBox<HiveEvenement>('evenements');
      _locationBox = await Hive.openBox<HiveLocation>('location');
      _logger.i('Boîtes Hive initialisées');
    } catch (e) {
      _logger.e('Erreur lors de l\'initialisation de Hive: $e');
      rethrow;
    }
  }

  // ==================== UTILISATEUR ====================

  Future<void> cacheUtilisateur(UtilisateurModel utilisateur) async {
    try {
      final hiveUser = HiveUtilisateur(
        id: utilisateur.id,
        username: utilisateur.username,
        email: utilisateur.email,
        tel: utilisateur.tel,
        dateCreation: utilisateur.dateCreation,
        isActive: utilisateur.isActive,
        nombreLieux: utilisateur.nombreLieux,
        nombreEvenements: utilisateur.nombreEvenements,
      );
      await _utilisateurBox.put('current_user', hiveUser);
      _logger.d('Utilisateur en cache: ${utilisateur.username}');
    } catch (e) {
      _logger.e('Erreur cache utilisateur: $e');
      throw CacheException('Erreur lors de la mise en cache de l\'utilisateur');
    }
  }

  Future<UtilisateurModel?> getCachedUtilisateur() async {
    try {
      final hiveUser = _utilisateurBox.get('current_user');
      if (hiveUser != null) {
        _logger.d('Utilisateur récupéré du cache');
        return UtilisateurModel(
          id: hiveUser.id,
          username: hiveUser.username,
          email: hiveUser.email,
          tel: hiveUser.tel,
          dateCreation: hiveUser.dateCreation,
          isActive: hiveUser.isActive,
          nombreLieux: hiveUser.nombreLieux,
          nombreEvenements: hiveUser.nombreEvenements,
        );
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lecture cache utilisateur: $e');
      throw CacheException('Erreur lors de la lecture du cache utilisateur');
    }
  }

  Future<void> clearUtilisateur() async {
    try {
      await _utilisateurBox.clear();
      _logger.d('Cache utilisateur vidé');
    } catch (e) {
      _logger.e('Erreur suppression utilisateur cache: $e');
    }
  }

  // ==================== LIEUX ====================

  Future<void> cacheLieux(List<LieuModel> lieux) async {
    try {
      await _lieuBox.clear();
      for (int i = 0; i < lieux.length; i++) {
        final lieu = lieux[i];
        final hiveLieu = HiveLieu(
          id: lieu.id,
          nom: lieu.nom,
          description: lieu.description,
          categorie: lieu.categorie,
          latitude: lieu.latitude,
          longitude: lieu.longitude,
          dateCreation: lieu.dateCreation,
          proprietaireNom: lieu.proprietaireNom,
          proprietaireId: lieu.proprietaireId,
          nombreEvenements: lieu.nombreEvenements,
          moyenneAvis: lieu.moyenneAvis,
        );
        await _lieuBox.put(lieu.id, hiveLieu);
      }
      _logger.d('${lieux.length} lieux en cache');
    } catch (e) {
      _logger.e('Erreur cache lieux: $e');
      throw CacheException('Erreur lors de la mise en cache des lieux');
    }
  }

  Future<List<LieuModel>> getCachedLieux() async {
    try {
      final hiveLieux = _lieuBox.values.toList();
      final lieux = hiveLieux
          .map((h) => LieuModel(
                id: h.id,
                nom: h.nom,
                description: h.description,
                categorie: h.categorie,
                latitude: h.latitude,
                longitude: h.longitude,
                dateCreation: h.dateCreation,
                proprietaireNom: h.proprietaireNom,
                proprietaireId: h.proprietaireId,
                nombreEvenements: h.nombreEvenements,
                moyenneAvis: h.moyenneAvis,
              ))
          .toList();
      _logger.d('${lieux.length} lieux récupérés du cache');
      return lieux;
    } catch (e) {
      _logger.e('Erreur lecture cache lieux: $e');
      throw CacheException('Erreur lors de la lecture du cache des lieux');
    }
  }

  Future<LieuModel?> getCachedLieuById(String id) async {
    try {
      final hiveLieu = _lieuBox.get(id);
      if (hiveLieu != null) {
        return LieuModel(
          id: hiveLieu.id,
          nom: hiveLieu.nom,
          description: hiveLieu.description,
          categorie: hiveLieu.categorie,
          latitude: hiveLieu.latitude,
          longitude: hiveLieu.longitude,
          dateCreation: hiveLieu.dateCreation,
          proprietaireNom: hiveLieu.proprietaireNom,
          proprietaireId: hiveLieu.proprietaireId,
          nombreEvenements: hiveLieu.nombreEvenements,
          moyenneAvis: hiveLieu.moyenneAvis,
        );
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lecture cache lieu: $e');
      throw CacheException('Erreur lors de la lecture du cache du lieu');
    }
  }

  Future<void> clearLieux() async {
    try {
      await _lieuBox.clear();
      _logger.d('Cache lieux vidé');
    } catch (e) {
      _logger.e('Erreur suppression lieux cache: $e');
    }
  }

  // ==================== ÉVÉNEMENTS ====================

  Future<void> cacheEvenements(List<EvenementModel> evenements) async {
    try {
      await _evenementBox.clear();
      for (int i = 0; i < evenements.length; i++) {
        final evt = evenements[i];
        final hiveEvt = HiveEvenement(
          id: evt.id,
          nom: evt.nom,
          description: evt.description,
          dateDebut: evt.dateDebut,
          dateFin: evt.dateFin,
          lieuId: evt.lieuId,
          lieuNom: evt.lieuNom,
          lieuLatitude: evt.lieuLatitude,
          lieuLongitude: evt.lieuLongitude,
          organisateurId: evt.organisateurId,
          organisateurNom: evt.organisateurNom,
          moyenneAvis: evt.moyenneAvis,
          nombreAvis: evt.nombreAvis,
          distance: evt.distance,
        );
        await _evenementBox.put(evt.id, hiveEvt);
      }
      _logger.d('${evenements.length} événements en cache');
    } catch (e) {
      _logger.e('Erreur cache événements: $e');
      throw CacheException('Erreur lors de la mise en cache des événements');
    }
  }

  Future<List<EvenementModel>> getCachedEvenements() async {
    try {
      final hiveEvenements = _evenementBox.values.toList();
      final evenements = hiveEvenements
          .map((h) => EvenementModel(
                id: h.id,
                nom: h.nom,
                description: h.description,
                dateDebut: h.dateDebut,
                dateFin: h.dateFin,
                lieuId: h.lieuId,
                lieuNom: h.lieuNom,
                lieuLatitude: h.lieuLatitude,
                lieuLongitude: h.lieuLongitude,
                organisateurId: h.organisateurId,
                organisateurNom: h.organisateurNom,
                moyenneAvis: h.moyenneAvis,
                nombreAvis: h.nombreAvis,
                distance: h.distance,
              ))
          .toList();
      _logger.d('${evenements.length} événements récupérés du cache');
      return evenements;
    } catch (e) {
      _logger.e('Erreur lecture cache événements: $e');
      throw CacheException('Erreur lors de la lecture du cache des événements');
    }
  }

  Future<void> clearEvenements() async {
    try {
      await _evenementBox.clear();
      _logger.d('Cache événements vidé');
    } catch (e) {
      _logger.e('Erreur suppression événements cache: $e');
    }
  }

  // ==================== LOCALISATION ====================

  Future<void> cacheLocation(LocationModel location) async {
    try {
      final hiveLocation = HiveLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        city: location.city,
        quartier: location.quartier,
        source: location.source,
        cachedAt: DateTime.now(),
      );
      await _locationBox.put('user_location', hiveLocation);
      _logger.d('Localisation en cache');
    } catch (e) {
      _logger.e('Erreur cache localisation: $e');
      throw CacheException('Erreur lors de la mise en cache de la localisation');
    }
  }

  Future<LocationModel?> getCachedLocation() async {
    try {
      final hiveLocation = _locationBox.get('user_location');
      if (hiveLocation != null) {
        // Vérifier si le cache a moins de 10 minutes
        final difference = DateTime.now().difference(hiveLocation.cachedAt);
        if (difference.inMinutes < 10) {
          _logger.d('Localisation récupérée du cache');
          return LocationModel(
            latitude: hiveLocation.latitude,
            longitude: hiveLocation.longitude,
            address: hiveLocation.address,
            city: hiveLocation.city,
            quartier: hiveLocation.quartier,
            source: hiveLocation.source,
          );
        }
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lecture cache localisation: $e');
      throw CacheException('Erreur lors de la lecture du cache de localisation');
    }
  }

  Future<void> clearLocation() async {
    try {
      await _locationBox.clear();
      _logger.d('Cache localisation vidé');
    } catch (e) {
      _logger.e('Erreur suppression localisation cache: $e');
    }
  }

  // ==================== CACHE GÉNÉRAL ====================

  Future<void> clearAllCache() async {
    try {
      await _utilisateurBox.clear();
      await _lieuBox.clear();
      await _evenementBox.clear();
      await _locationBox.clear();
      _logger.d('Tous les caches vidés');
    } catch (e) {
      _logger.e('Erreur suppression tous caches: $e');
    }
  }

  bool hasCachedData() {
    return _utilisateurBox.isNotEmpty || _lieuBox.isNotEmpty;
  }
}