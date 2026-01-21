import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/services/location_service.dart';

/// Provider pour gérer l'état de la géolocalisation dans l'application
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  GeoPoint? _currentGeoPoint;
  String? _currentAddress;
  String? _currentCity;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasPermission = false;
  bool _isServiceEnabled = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  GeoPoint? get currentGeoPoint => _currentGeoPoint;
  String? get currentAddress => _currentAddress;
  String? get currentCity => _currentCity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPermission => _hasPermission;
  bool get isServiceEnabled => _isServiceEnabled;

  /// Initialise la localisation et demande les permissions
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Vérifier si le service est activé
      _isServiceEnabled = await _locationService.isLocationServiceEnabled();

      if (!_isServiceEnabled) {
        _errorMessage = 'Les services de localisation sont désactivés';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Vérifier les permissions
      final permission = await _locationService.checkPermission();
      _hasPermission = permission == LocationPermission.always ||
                      permission == LocationPermission.whileInUse;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Demande la permission de localisation
  Future<bool> requestPermission() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final permission = await _locationService.requestPermission();
      _hasPermission = permission == LocationPermission.always ||
                      permission == LocationPermission.whileInUse;

      _isLoading = false;
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _hasPermission = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<bool> getCurrentLocation() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentPosition = await _locationService.getCurrentPosition();
      _currentGeoPoint = _locationService.positionToGeoPoint(_currentPosition!);

      // Obtenir l'adresse et la ville
      _currentAddress = await _locationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      _currentCity = await _locationService.getCityFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtient la position actuelle rapidement (précision moyenne)
  Future<bool> getCurrentLocationFast() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentPosition = await _locationService.getCurrentPositionFast();
      _currentGeoPoint = _locationService.positionToGeoPoint(_currentPosition!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Calcule la distance entre la position actuelle et un point
  double? calculateDistanceFromCurrent(GeoPoint destination) {
    if (_currentPosition == null) return null;

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  /// Calcule la distance entre deux points
  double calculateDistance(GeoPoint start, GeoPoint end) {
    return _locationService.calculateDistanceBetweenGeoPoints(start, end);
  }

  /// Formate une distance pour l'affichage
  String formatDistance(double distanceInKm) {
    return _locationService.formatDistance(distanceInKm);
  }

  /// Obtient l'adresse à partir de coordonnées
  Future<String> getAddress(double latitude, double longitude) async {
    return await _locationService.getAddressFromCoordinates(latitude, longitude);
  }

  /// Obtient la ville à partir de coordonnées
  Future<String> getCity(double latitude, double longitude) async {
    return await _locationService.getCityFromCoordinates(latitude, longitude);
  }

  /// Vérifie si un point est dans un rayon donné de la position actuelle
  bool isNearby(GeoPoint target, double radiusKm) {
    if (_currentPosition == null) return false;

    return _locationService.isWithinRadius(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      target.latitude,
      target.longitude,
      radiusKm,
    );
  }

  /// Réinitialise l'état
  void reset() {
    _currentPosition = null;
    _currentGeoPoint = null;
    _currentAddress = null;
    _currentCity = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Efface l'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}