//Écran de carte interactive
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../core/constants/app_colors.dart';
import '../vehicle/vehicle_detail_screen.dart';

/// Écran de carte interactive affichant les véhicules à proximité
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  double _radiusKm = 50.0; // Rayon de recherche par défaut en km

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialise la localisation de l'utilisateur
  Future<void> _initializeLocation() async {
    final locationProvider = context.read<LocationProvider>();
    
    // Demander la permission et obtenir la position
    final hasPermission = await locationProvider.requestPermission();
    if (hasPermission) {
      await locationProvider.getCurrentLocation();
      _loadVehiclesNearby();
    }
  }

  /// Charge les véhicules à proximité
  void _loadVehiclesNearby() {
    final locationProvider = context.read<LocationProvider>();
    final vehicleProvider = context.read<VehicleProvider>();

    if (locationProvider.currentPosition == null) return;

    // Créer les marqueurs pour les véhicules
    setState(() {
      _markers.clear();

      // Ajouter le marqueur de position actuelle
      _markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Votre position',
            snippet: 'Vous êtes ici',
          ),
        ),
      );

      // Ajouter les marqueurs pour chaque véhicule avec localisation
      for (final vehicle in vehicleProvider.vehicles) {
        if (vehicle.location != null) {
          // Vérifier si le véhicule est dans le rayon
          final distance = locationProvider.calculateDistance(
            locationProvider.currentGeoPoint!,
            vehicle.location!,
          );

          if (distance <= _radiusKm) {
            _markers.add(
              Marker(
                markerId: MarkerId(vehicle.id),
                position: LatLng(
                  vehicle.location!.latitude,
                  vehicle.location!.longitude,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  vehicle.type == 'car'
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(
                  title: vehicle.title,
                  snippet: '${locationProvider.formatDistance(distance)} - ${vehicle.price.toStringAsFixed(0)} FCFA',
                  onTap: () => _onMarkerTapped(vehicle),
                ),
              ),
            );
          }
        }
      }
    });
  }

  /// Gère le clic sur un marqueur
  void _onMarkerTapped(VehicleModel vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleDetailScreen(vehicle: vehicle),
      ),
    );
  }

  /// Construit le widget de carte
  Widget _buildMap(LocationProvider locationProvider) {
    if (locationProvider.currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final initialPosition = CameraPosition(
      target: LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      ),
      zoom: 12,
    );

    return GoogleMap(
      initialCameraPosition: initialPosition,
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapType: MapType.normal,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onCameraMove: (position) {
        // Peut être utilisé pour recharger les véhicules lors du déplacement
      },
    );
  }

  /// Construit le contrôle de rayon
  Widget _buildRadiusControl() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rayon de recherche: ${_radiusKm.toStringAsFixed(0)} km',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _radiusKm,
            min: 5,
            max: 200,
            divisions: 39,
            label: '${_radiusKm.toStringAsFixed(0)} km',
            onChanged: (value) {
              setState(() {
                _radiusKm = value;
              });
            },
            onChangeEnd: (value) {
              _loadVehiclesNearby();
            },
          ),
        ],
      ),
    );
  }

  /// Construit les statistiques
  Widget _buildStats() {
    final locationProvider = context.watch<LocationProvider>();
    
    if (locationProvider.currentPosition == null) {
      return const SizedBox();
    }

    final nearbyCount = _markers.length - 1; // -1 pour exclure le marqueur de position actuelle

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.location_on,
            'Position',
            locationProvider.currentCity ?? 'Chargement...',
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem(
            Icons.directions_car,
            'Véhicules',
            '$nearbyCount trouvé${nearbyCount > 1 ? 's' : ''}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des véhicules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _initializeLocation();
            },
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          if (locationProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Obtention de votre position...'),
                ],
              ),
            );
          }

          if (locationProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      locationProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _initializeLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              _buildMap(locationProvider),
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: _buildStats(),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _buildRadiusControl(),
              ),
            ],
          );
        },
      ),
    );
  }
}