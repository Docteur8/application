import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/vehicle_model.dart';
import '../data/repositories/vehicle_repository.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleRepository _vehicleRepository = VehicleRepository();

  List<VehicleModel> _vehicles = [];
  List<VehicleModel> _userVehicles = [];
  List<VehicleModel> _favoriteVehicles = [];
  List<String> _favoriteIds = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedType;
  String _sortBy = 'date_desc';

  List<VehicleModel> get vehicles => _vehicles;
  List<VehicleModel> get userVehicles => _userVehicles;
  List<VehicleModel> get favoriteVehicles => _favoriteVehicles;
  List<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedType => _selectedType;
  String get sortBy => _sortBy;

  void setFilter(String? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void loadVehicles() {
    _vehicleRepository
        .getVehiclesStream(
          type: _selectedType,
          sortBy: _sortBy,
        )
        .listen((vehicles) {
      _vehicles = vehicles;
      notifyListeners();
    });
  }

  void loadUserVehicles(String userId) {
    _vehicleRepository.getUserVehiclesStream(userId).listen((vehicles) {
      _userVehicles = vehicles;
      notifyListeners();
    });
  }

  Future<void> loadFavorites(String userId) async {
    try {
      final userDoc = await _vehicleRepository.getVehicle(userId);
      if (userDoc != null) {
        _favoriteIds = List<String>.from(userDoc.toFirestore()['favorites'] ?? []);
        _favoriteVehicles = await _vehicleRepository.getVehiclesByIds(_favoriteIds);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<bool> addVehicle({
    required VehicleModel vehicle,
    required List<File> imageFiles,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _vehicleRepository.addVehicle(
        vehicle: vehicle,
        imageFiles: imageFiles,
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

  Future<bool> updateVehicle({
    required String vehicleId,
    required VehicleModel vehicle,
    List<File>? newImageFiles,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _vehicleRepository.updateVehicle(
        vehicleId: vehicleId,
        vehicle: vehicle,
        newImageFiles: newImageFiles,
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

  Future<bool> deleteVehicle(String vehicleId, List<String> imageUrls) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _vehicleRepository.deleteVehicle(vehicleId, imageUrls);

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

  Future<void> toggleFavorite(String userId, String vehicleId) async {
    try {
      await _vehicleRepository.toggleFavorite(userId, vehicleId);
      await loadFavorites(userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  bool isFavorite(String vehicleId) {
    return _favoriteIds.contains(vehicleId);
  }

  Future<List<VehicleModel>> searchVehicles(String query) async {
    try {
      return await _vehicleRepository.searchVehicles(query);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<VehicleModel?> getVehicle(String vehicleId) async {
    try {
      return await _vehicleRepository.getVehicle(vehicleId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}