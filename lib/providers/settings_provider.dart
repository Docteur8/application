import 'package:flutter/foundation.dart';
import '../data/models/settings_model.dart';
import '../data/services/firebase_service.dart';

/// Provider pour gérer les paramètres de l'application
class SettingsProvider extends ChangeNotifier {
  SettingsModel _settings = SettingsModel();
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge les paramètres depuis Firestore
  Future<void> loadSettings(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final doc = await FirebaseService.firestore
          .collection('settings')
          .doc(userId)
          .get();

      _settings = SettingsModel.fromFirestore(doc);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement des paramètres: $e';
      notifyListeners();
    }
  }

  /// Sauvegarde les paramètres dans Firestore
  Future<bool> saveSettings(String userId, SettingsModel settings) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await FirebaseService.firestore
          .collection('settings')
          .doc(userId)
          .set(settings.toFirestore());

      _settings = settings;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors de la sauvegarde: $e';
      notifyListeners();
      return false;
    }
  }

  /// Met à jour un paramètre spécifique
  Future<bool> updateSetting(String userId, String key, dynamic value) async {
    try {
      await FirebaseService.firestore
          .collection('settings')
          .doc(userId)
          .update({key: value});

      // Recharger les paramètres
      await loadSettings(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
      return false;
    }
  }

  // === Méthodes de mise à jour rapide ===

  Future<void> toggleNotifications(String userId, bool value) async {
    final updated = _settings.copyWith(enableNotifications: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleDarkMode(String userId, bool value) async {
    final updated = _settings.copyWith(darkMode: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleLocation(String userId, bool value) async {
    final updated = _settings.copyWith(enableLocation: value);
    await saveSettings(userId, updated);
  }

  Future<void> updateSearchRadius(String userId, double value) async {
    final updated = _settings.copyWith(searchRadius: value);
    await saveSettings(userId, updated);
  }

  Future<void> updateLanguage(String userId, String language) async {
    final updated = _settings.copyWith(language: language);
    await saveSettings(userId, updated);
  }

  Future<void> toggleNotifyNewMessages(String userId, bool value) async {
    final updated = _settings.copyWith(notifyNewMessages: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleNotifyNewVehicles(String userId, bool value) async {
    final updated = _settings.copyWith(notifyNewVehicles: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleNotifyPriceChanges(String userId, bool value) async {
    final updated = _settings.copyWith(notifyPriceChanges: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleNotifyNearbyVehicles(String userId, bool value) async {
    final updated = _settings.copyWith(notifyNearbyVehicles: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleShowPhoneNumber(String userId, bool value) async {
    final updated = _settings.copyWith(showPhoneNumber: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleShowEmail(String userId, bool value) async {
    final updated = _settings.copyWith(showEmail: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleAllowMessagesFromAnyone(String userId, bool value) async {
    final updated = _settings.copyWith(allowMessagesFromAnyone: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleShowOnlineStatus(String userId, bool value) async {
    final updated = _settings.copyWith(showOnlineStatus: value);
    await saveSettings(userId, updated);
  }

  Future<void> toggleAutoLogout(String userId, bool value) async {
    final updated = _settings.copyWith(autoLogout: value);
    await saveSettings(userId, updated);
  }

  Future<void> updateAutoLogoutMinutes(String userId, int minutes) async {
    final updated = _settings.copyWith(autoLogoutMinutes: minutes);
    await saveSettings(userId, updated);
  }

  Future<void> setDefaultVehicleType(String userId, String? type) async {
    final updated = _settings.copyWith(defaultVehicleType: type);
    await saveSettings(userId, updated);
  }

  Future<void> setDefaultSortBy(String userId, String? sortBy) async {
    final updated = _settings.copyWith(defaultSortBy: sortBy);
    await saveSettings(userId, updated);
  }

  /// Réinitialise tous les paramètres aux valeurs par défaut
  Future<bool> resetToDefaults(String userId) async {
    final defaultSettings = SettingsModel();
    return await saveSettings(userId, defaultSettings);
  }

  /// Efface l'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}