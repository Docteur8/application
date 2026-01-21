import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les paramètres de l'utilisateur
class SettingsModel {
  // Notifications
  final bool enableNotifications;
  final bool notifyNewMessages;
  final bool notifyNewVehicles;
  final bool notifyPriceChanges;
  final bool notifyNearbyVehicles;

  // Localisation
  final bool enableLocation;
  final bool showLocationOnProfile;
  final double searchRadius; // en kilomètres
  final bool autoUpdateLocation;

  // Confidentialité
  final bool showPhoneNumber;
  final bool showEmail;
  final bool allowMessagesFromAnyone;
  final bool showOnlineStatus;

  // Affichage
  final bool darkMode;
  final String language;
  final String currency;
  final bool compactView;
  
  // Filtres par défaut
  final String? defaultVehicleType; // 'car', 'moto', ou null pour tous
  final String? defaultSortBy;
  final double? maxPriceFilter;
  final int? maxMileageFilter;

  // Sécurité
  final bool requireBiometric;
  final bool autoLogout;
  final int autoLogoutMinutes;

  SettingsModel({
    this.enableNotifications = true,
    this.notifyNewMessages = true,
    this.notifyNewVehicles = false,
    this.notifyPriceChanges = false,
    this.notifyNearbyVehicles = false,
    this.enableLocation = true,
    this.showLocationOnProfile = false,
    this.searchRadius = 50.0,
    this.autoUpdateLocation = false,
    this.showPhoneNumber = true,
    this.showEmail = false,
    this.allowMessagesFromAnyone = true,
    this.showOnlineStatus = true,
    this.darkMode = false,
    this.language = 'fr',
    this.currency = 'FCFA',
    this.compactView = false,
    this.defaultVehicleType,
    this.defaultSortBy,
    this.maxPriceFilter,
    this.maxMileageFilter,
    this.requireBiometric = false,
    this.autoLogout = false,
    this.autoLogoutMinutes = 30,
  });

  /// Crée un modèle depuis Firestore
  factory SettingsModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return SettingsModel();
    }

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return SettingsModel();
    }

    return SettingsModel(
      enableNotifications: data['enableNotifications'] ?? true,
      notifyNewMessages: data['notifyNewMessages'] ?? true,
      notifyNewVehicles: data['notifyNewVehicles'] ?? false,
      notifyPriceChanges: data['notifyPriceChanges'] ?? false,
      notifyNearbyVehicles: data['notifyNearbyVehicles'] ?? false,
      enableLocation: data['enableLocation'] ?? true,
      showLocationOnProfile: data['showLocationOnProfile'] ?? false,
      searchRadius: (data['searchRadius'] ?? 50.0).toDouble(),
      autoUpdateLocation: data['autoUpdateLocation'] ?? false,
      showPhoneNumber: data['showPhoneNumber'] ?? true,
      showEmail: data['showEmail'] ?? false,
      allowMessagesFromAnyone: data['allowMessagesFromAnyone'] ?? true,
      showOnlineStatus: data['showOnlineStatus'] ?? true,
      darkMode: data['darkMode'] ?? false,
      language: data['language'] ?? 'fr',
      currency: data['currency'] ?? 'FCFA',
      compactView: data['compactView'] ?? false,
      defaultVehicleType: data['defaultVehicleType'],
      defaultSortBy: data['defaultSortBy'],
      maxPriceFilter: data['maxPriceFilter']?.toDouble(),
      maxMileageFilter: data['maxMileageFilter'],
      requireBiometric: data['requireBiometric'] ?? false,
      autoLogout: data['autoLogout'] ?? false,
      autoLogoutMinutes: data['autoLogoutMinutes'] ?? 30,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'enableNotifications': enableNotifications,
      'notifyNewMessages': notifyNewMessages,
      'notifyNewVehicles': notifyNewVehicles,
      'notifyPriceChanges': notifyPriceChanges,
      'notifyNearbyVehicles': notifyNearbyVehicles,
      'enableLocation': enableLocation,
      'showLocationOnProfile': showLocationOnProfile,
      'searchRadius': searchRadius,
      'autoUpdateLocation': autoUpdateLocation,
      'showPhoneNumber': showPhoneNumber,
      'showEmail': showEmail,
      'allowMessagesFromAnyone': allowMessagesFromAnyone,
      'showOnlineStatus': showOnlineStatus,
      'darkMode': darkMode,
      'language': language,
      'currency': currency,
      'compactView': compactView,
      'defaultVehicleType': defaultVehicleType,
      'defaultSortBy': defaultSortBy,
      'maxPriceFilter': maxPriceFilter,
      'maxMileageFilter': maxMileageFilter,
      'requireBiometric': requireBiometric,
      'autoLogout': autoLogout,
      'autoLogoutMinutes': autoLogoutMinutes,
    };
  }

  /// Copie avec modifications
  SettingsModel copyWith({
    bool? enableNotifications,
    bool? notifyNewMessages,
    bool? notifyNewVehicles,
    bool? notifyPriceChanges,
    bool? notifyNearbyVehicles,
    bool? enableLocation,
    bool? showLocationOnProfile,
    double? searchRadius,
    bool? autoUpdateLocation,
    bool? showPhoneNumber,
    bool? showEmail,
    bool? allowMessagesFromAnyone,
    bool? showOnlineStatus,
    bool? darkMode,
    String? language,
    String? currency,
    bool? compactView,
    String? defaultVehicleType,
    String? defaultSortBy,
    double? maxPriceFilter,
    int? maxMileageFilter,
    bool? requireBiometric,
    bool? autoLogout,
    int? autoLogoutMinutes,
  }) {
    return SettingsModel(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notifyNewMessages: notifyNewMessages ?? this.notifyNewMessages,
      notifyNewVehicles: notifyNewVehicles ?? this.notifyNewVehicles,
      notifyPriceChanges: notifyPriceChanges ?? this.notifyPriceChanges,
      notifyNearbyVehicles: notifyNearbyVehicles ?? this.notifyNearbyVehicles,
      enableLocation: enableLocation ?? this.enableLocation,
      showLocationOnProfile: showLocationOnProfile ?? this.showLocationOnProfile,
      searchRadius: searchRadius ?? this.searchRadius,
      autoUpdateLocation: autoUpdateLocation ?? this.autoUpdateLocation,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      showEmail: showEmail ?? this.showEmail,
      allowMessagesFromAnyone: allowMessagesFromAnyone ?? this.allowMessagesFromAnyone,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      compactView: compactView ?? this.compactView,
      defaultVehicleType: defaultVehicleType ?? this.defaultVehicleType,
      defaultSortBy: defaultSortBy ?? this.defaultSortBy,
      maxPriceFilter: maxPriceFilter ?? this.maxPriceFilter,
      maxMileageFilter: maxMileageFilter ?? this.maxMileageFilter,
      requireBiometric: requireBiometric ?? this.requireBiometric,
      autoLogout: autoLogout ?? this.autoLogout,
      autoLogoutMinutes: autoLogoutMinutes ?? this.autoLogoutMinutes,
    );
  }
}