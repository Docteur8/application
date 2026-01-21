//écran d'ajout de véhicule avec localisation

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/location_picker_widget.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();
  final _mileageController = TextEditingController();
  final _cityController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();


  String _selectedType = 'car';
  String _selectedFuelType = 'Essence';
  String _selectedTransmission = 'Manuelle';
  List<File> _selectedImages = [];
  GeoPoint? _selectedLocation;
  String _selectedAddress = '';


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _mileageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((img) => File(img.path)).toList();
      });
    }
  }

  /// Ouvre le sélecteur de localisation
  Future<void> _pickLocation() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerWidget(
          initialLocation: _selectedLocation,
          onLocationSelected: (geoPoint, address) {
            setState(() {
              _selectedLocation = geoPoint;
              _selectedAddress = address;
            });
          },
        ),
      ),
    );
  }

  /// Utilise la position actuelle
  Future<void> _useCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();

    final success = await locationProvider.getCurrentLocation();

    if (success && locationProvider.currentGeoPoint != null) {
      setState(() {
        _selectedLocation = locationProvider.currentGeoPoint;
        _selectedAddress = locationProvider.currentAddress ?? '';
        _cityController.text = locationProvider.currentCity ?? '';
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Localisation actuelle utilisée');
      }
    } else {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Impossible d\'obtenir votre position',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      Helpers.showSnackBar(
        context,
        'Veuillez ajouter au moins une image',
        isError: true,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null || authProvider.userData == null) {
      Helpers.showSnackBar(context, 'Vous devez être connecté', isError: true);
      return;
    }

    final vehicle = VehicleModel(
      id: '',
      title: _titleController.text,
      description: _descriptionController.text,
      type: _selectedType,
      brand: _brandController.text,
      model: _modelController.text,
      year: int.parse(_yearController.text),
      price: double.parse(_priceController.text),
      mileage: int.parse(_mileageController.text),
      fuelType: _selectedFuelType,
      transmission: _selectedTransmission,
      images: [],
      location: _selectedLocation,
      city: _cityController.text,
      sellerId: authProvider.user!.uid,
      sellerName: authProvider.userData!.name,
      sellerPhone: authProvider.userData!.phone,
      createdAt: DateTime.now(),
    );

    final vehicleProvider = context.read<VehicleProvider>();
    final success = await vehicleProvider.addVehicle(
      vehicle: vehicle,
      imageFiles: _selectedImages,
    );

    if (!mounted) return;

    if (success) {
      Helpers.showSnackBar(context, AppStrings.vehicleAdded);
      Navigator.of(context).pop();
    } else {
      Helpers.showSnackBar(
        context,
        vehicleProvider.errorMessage ?? AppStrings.errorOccurred,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addVehicle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildTypeSection(),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _titleController,
              label: AppStrings.title,
              validator: Validators.validateRequired,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: AppStrings.description,
              maxLines: 4,
              validator: Validators.validateRequired,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _brandController,
                    label: AppStrings.brand,
                    validator: Validators.validateRequired,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _modelController,
                    label: AppStrings.model,
                    validator: Validators.validateRequired,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _yearController,
                    label: AppStrings.year,
                    keyboardType: TextInputType.number,
                    validator: Validators.validateYear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _priceController,
                    label: AppStrings.price,
                    keyboardType: TextInputType.number,
                    validator: Validators.validatePrice,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _mileageController,
              label: AppStrings.mileage,
              keyboardType: TextInputType.number,
              validator: Validators.validateMileage,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: AppStrings.fuelType,
              value: _selectedFuelType,
              items: ['Essence', 'Diesel', 'Électrique', 'Hybride'],
              onChanged: (value) {
                setState(() {
                  _selectedFuelType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: AppStrings.transmission,
              value: _selectedTransmission,
              items: ['Manuelle', 'Automatique'],
              onChanged: (value) {
                setState(() {
                  _selectedTransmission = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _cityController,
              label: 'Ville',
              validator: Validators.validateRequired,
            ),
            const SizedBox(height: 16),
            _buildLocationSection(),
            const SizedBox(height: 32),
            Consumer<VehicleProvider>(
              builder: (context, provider, _) {
                return CustomButton(
                  text: AppStrings.publish,
                  onPressed: _handleSubmit,
                  isLoading: provider.isLoading,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  // Section de sélection de la localisation du véhicule
Widget _buildLocationSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Localisation du véhicule',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),

      // Affichage de l'adresse sélectionnée
      if (_selectedAddress.isNotEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedAddress,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),

      Row(
        children: [
          // Bouton ouvrir la carte
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map),
              label: const Text('Choisir sur la carte'),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton position actuelle
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Ma position'),
            ),
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Message si aucune localisation sélectionnée
      if (_selectedLocation == null)
        const Text(
          'Aucune localisation sélectionnée',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
    ],
  );
}


  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos du véhicule',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isEmpty)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text('Ajouter des photos'),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Ajouter plus de photos'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de véhicule',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard('car', 'Voiture', Icons.directions_car),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildTypeCard('moto', 'Moto', Icons.two_wheeler)),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
    ? Colors.blue.withValues(alpha: 0.1)
    : null,

        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
