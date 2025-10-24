class ApiConstants {
  // Base URL de l'API
  static const String baseUrl = 'http://10.0.2.2:8000'; // 10.5.49.39
  
  // Endpoints d'authentification
  static const String authRegister = '/fastapi/auth/register/';
  static const String authLogin = '/fastapi/auth/login/';
  static const String authLogout = '/fastapi/auth/logout/';
  static const String authProfile = '/fastapi/auth/profile/';
  static const String authToken = '/fastapi/auth/token/';

  // Endpoints Lieux
  static const String lieux = '/fastapi/api/lieux/';
  static const String lieuDetail = '/fastapi/api/lieux/{id}/';
  static const String lieuEvenements = '/fastapi/api/lieux/{id}/evenements/';
  static const String lieuAvis = '/fastapi/api/lieux/{id}/avis/';
  static const String lieuProximite = '/fastapi/api/lieux/recherche_proximite/';

  // Endpoints Événements
  static const String evenements = '/fastapi/api/evenements/';
  static const String evenementDetail = '/fastapi/api/evenements/{id}/';
  static const String evenementAvis = '/fastapi/api/evenements/{id}/avis/';
  static const String evenementAujourd = '/fastapi/api/evenements/aujourd_hui/';
  static const String evenementSemaine = '/fastapi/api/evenements/cette_semaine/';

  // Endpoints Avis
  static const String avisLieux = '/fastapi/api/avis-lieux/';
  static const String avisEvenements = '/fastapi/api/avis-evenements/';

  // Endpoints Géolocalisation
  static const String geoDetectLocation = '/fastapi/geo/detect-location/';
  static const String geoGeocode = '/fastapi/geo/geocode/';
  static const String geoReverseGeocode = '/fastapi/geo/reverse-geocode/';
  static const String geoLieuxProximite = '/fastapi/geo/lieux-proximite/';
  static const String geoEvenementsProximite = '/fastapi/geo/evenements-proximite/';
  static const String geoSuggestions = '/fastapi/geo/suggestions/';
  static const String geoDistance = '/fastapi/geo/distance/';
  static const String geoQuartiers = '/fastapi/geo/quartiers-lome/';
  static const String geoValidateLome = '/fastapi/geo/validate-lome/';
  static const String geoIpLocation = '/fastapi/geo/ip-location/';
  static const String geoMapData = '/fastapi/geo/map-data/';

  // Endpoints Statistiques
  static const String stats = '/fastapi/stats/';
  static const String lieuPopulaires = '/fastapi/lieux-populaires/';
  static const String evenementsTendances = '/fastapi/evenements-tendances/';
  static const String donneesLome = '/fastapi/donnees-lome/';

  // WebSocket
  static const String wsEvents = 'ws://10.0.2.2:8000/ws/events/';
  static const String wsPersonal = 'ws://10.0.2.2:8000/ws/personal/';
  static String wsLocation(double lat, double lng, {int radius = 10}) {
    return 'ws://10.0.2.2:8000/ws/location/$lat/$lng/$radius/';
  }

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String contentType = 'Content-Type';
  static const String contentTypeJson = 'application/json';
  static const String authorization = 'Authorization';
  
  // ✅✅✅ CORRECTION ICI ✅✅✅
  // Django REST Framework TokenAuthentication utilise "Token" et non "Bearer"
  static const String bearerToken = 'Token '; // ← Changé de 'Bearer ' à 'Token '
  // ✅✅✅ FIN DE LA CORRECTION ✅✅✅
}

class LocalStorageKeys {
  static const String token = 'auth_token';
  static const String utilisateur = 'utilisateur';
  static const String isLoggedIn = 'is_logged_in';
  static const String lieux = 'lieux_cache';
  static const String evenements = 'evenements_cache';
  static const String userLocation = 'user_location';
  static const String theme = 'theme_preference';
  static const String langue = 'language_preference';
}