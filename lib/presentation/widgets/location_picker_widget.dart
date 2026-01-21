//Widget de sélection de localisation
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/location_provider.dart';
import '../../core/constants/app_colors.dart';

/// Widget pour permettre à l'utilisateur de sélectionner une localisation sur une carte
class LocationPickerWidget extends StatefulWidget {
  final GeoPoint? initialLocation;
  final Function(GeoPoint, String) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  String _selectedAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialise la position (position actuelle ou position initiale)
  Future<void> _initializePosition() async {
    final locationProvider = context.read<LocationProvider>();

    if (widget.initialLocation != null) {
      // Utiliser la position initiale fournie
      _selectedPosition = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _getAddressFromPosition(_selectedPosition!);
    } else {
      // Obtenir la position actuelle
      setState(() => _isLoading = true);
      final success = await locationProvider.getCurrentLocation();
      setState(() => _isLoading = false);

      if (success && locationProvider.currentPosition != null) {
        setState(() {
          _selectedPosition = LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
          _selectedAddress = locationProvider.currentAddress ?? '';
        });
      }
    }
  }

  /// Obtient l'adresse à partir d'une position
  Future<void> _getAddressFromPosition(LatLng position) async {
    final locationProvider = context.read<LocationProvider>();
    final address = await locationProvider.getAddress(
      position.latitude,
      position.longitude,
    );
    setState(() {
      _selectedAddress = address;
    });
  }

  /// Gère le clic sur la carte
  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _getAddressFromPosition(position);
  }

  /// Confirme la sélection
  void _confirmSelection() {
    if (_selectedPosition != null) {
      final geoPoint = GeoPoint(
        _selectedPosition!.latitude,
        _selectedPosition!.longitude,
      );
      widget.onLocationSelected(geoPoint, _selectedAddress);
      Navigator.of(context).pop();
    }
  }

  /// Utilise la position actuelle
  Future<void> _useCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();
    
    setState(() => _isLoading = true);
    final success = await locationProvider.getCurrentLocation();
    setState(() => _isLoading = false);

    if (success && locationProvider.currentPosition != null) {
      setState(() {
        _selectedPosition = LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
        _selectedAddress = locationProvider.currentAddress ?? '';
      });

      // Déplacer la caméra vers la nouvelle position
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_selectedPosition!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner la localisation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _isLoading ? null : _useCurrentLocation,
            tooltip: 'Ma position',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Carte
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedPosition ?? const LatLng(5.3600, -4.0083), // Abidjan par défaut
                    zoom: 14,
                  ),
                  markers: _selectedPosition != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedPosition!,
                            draggable: true,
                            onDragEnd: (newPosition) {
                              _onMapTapped(newPosition);
                            },
                          ),
                        }
                      : {},
                  onTap: _onMapTapped,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),

                // Carte d'information de l'adresse
                if (_selectedAddress.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_on, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Localisation sélectionnée',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedAddress,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Bouton de confirmation
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: _selectedPosition != null ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Confirmer cette localisation'),
                  ),
                ),
              ],
            ),
    );
  }
}