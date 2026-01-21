import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service de géolocalisation pour obtenir la position de l'utilisateur
/// et calculer les distances entre les points
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Vérifie si les services de localisation sont activés
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Vérifie les permissions de localisation
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Demande la permission de localisation à l'utilisateur
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('La permission de localisation a été refusée');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'La permission de localisation est définitivement refusée. '
        'Veuillez l\'activer dans les paramètres de l\'application.'
      );
    }

    return permission;
  }

  /// Obtient la position actuelle de l'utilisateur avec haute précision
  Future<Position> getCurrentPosition() async {
    // Vérifier si le service de localisation est activé
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Les services de localisation sont désactivés. '
        'Veuillez les activer dans les paramètres.'
      );
    }

    // Demander la permission
    await requestPermission();

    // Obtenir la position avec haute précision
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Obtient la position actuelle avec précision moyenne (plus rapide)
  Future<Position> getCurrentPositionFast() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés');
    }

    await requestPermission();

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    );
  }

  /// Surveille les changements de position en temps réel
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10 mètres
      ),
    );
  }

  /// Convertit une position en GeoPoint pour Firestore
  GeoPoint positionToGeoPoint(Position position) {
    return GeoPoint(position.latitude, position.longitude);
  }

  /// Convertit un GeoPoint en coordonnées lisibles
  Map<String, double> geoPointToCoordinates(GeoPoint geoPoint) {
    return {
      'latitude': geoPoint.latitude,
      'longitude': geoPoint.longitude,
    };
  }

  /// Calcule la distance entre deux positions en kilomètres
  /// Utilise la formule de Haversine pour une précision maximale
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Conversion en kilomètres
  }

  /// Calcule la distance entre deux GeoPoints
  double calculateDistanceBetweenGeoPoints(GeoPoint start, GeoPoint end) {
    return calculateDistance(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Calcule la distance entre la position actuelle et un GeoPoint
  Future<double> calculateDistanceFromCurrentPosition(GeoPoint destination) async {
    final position = await getCurrentPosition();
    return calculateDistance(
      position.latitude,
      position.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  /// Obtient l'adresse à partir des coordonnées (géocodage inverse)
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        return 'Adresse non disponible';
      }

      final place = placemarks.first;
      
      // Construire l'adresse complète
      List<String> addressParts = [];
      
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }

      return addressParts.join(', ');
    } catch (e) {
      return 'Erreur lors de la récupération de l\'adresse';
    }
  }

  /// Obtient seulement la ville à partir des coordonnées
  Future<String> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        return 'Ville inconnue';
      }

      final place = placemarks.first;
      return place.locality ?? place.administrativeArea ?? 'Ville inconnue';
    } catch (e) {
      return 'Ville inconnue';
    }
  }

  /// Obtient les coordonnées à partir d'une adresse (géocodage)
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      return locations.isNotEmpty ? locations.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Formate la distance pour l'affichage
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.toStringAsFixed(0)} km';
    }
  }

  /// Vérifie si une position est dans un rayon donné (en km)
  bool isWithinRadius(
    double centerLat,
    double centerLon,
    double targetLat,
    double targetLon,
    double radiusKm,
  ) {
    final distance = calculateDistance(centerLat, centerLon, targetLat, targetLon);
    return distance <= radiusKm;
  }

  /// Ouvre l'application de navigation native avec les coordonnées
  Future<void> openNavigation(double latitude, double longitude) async {
    // Cette fonctionnalité sera implémentée avec url_launcher
    // pour ouvrir Google Maps ou Apple Maps selon la plateforme
  }

  /// Obtient les paramètres de localisation recommandés
  LocationSettings getRecommendedSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }
}