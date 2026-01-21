import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle_model.dart';
import '../services/firebase_service.dart';

class VehicleRepository {
  final _uuid = const Uuid();

  Future<String> addVehicle({
    required VehicleModel vehicle,
    required List<File> imageFiles,
  }) async {
    try {
      final imageUrls = await _uploadImages(imageFiles);

      final vehicleWithImages = vehicle.copyWith(images: imageUrls);

      final docRef = await FirebaseService.vehiclesCollection
          .add(vehicleWithImages.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du véhicule: $e');
    }
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required VehicleModel vehicle,
    List<File>? newImageFiles,
  }) async {
    try {
      List<String> imageUrls = vehicle.images;

      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final newUrls = await _uploadImages(newImageFiles);
        imageUrls = [...vehicle.images, ...newUrls];
      }

      final updatedVehicle = vehicle.copyWith(images: imageUrls);

      await FirebaseService.vehiclesCollection
          .doc(vehicleId)
          .update(updatedVehicle.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du véhicule: $e');
    }
  }

  Future<void> deleteVehicle(String vehicleId, List<String> imageUrls) async {
    try {
      await Future.wait([
        FirebaseService.vehiclesCollection.doc(vehicleId).delete(),
        _deleteImages(imageUrls),
      ]);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du véhicule: $e');
    }
  }

  Future<VehicleModel?> getVehicle(String vehicleId) async {
    try {
      final doc = await FirebaseService.vehiclesCollection.doc(vehicleId).get();
      if (doc.exists) {
        return VehicleModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du véhicule: $e');
    }
  }

  Stream<List<VehicleModel>> getVehiclesStream({
    String? type,
    String? sortBy,
    int limit = 20,
  }) {
    return FirebaseService.vehiclesStream(
      type: type,
      sortBy: sortBy,
      limit: limit,
    ).map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<VehicleModel>> getUserVehiclesStream(String userId) {
    return FirebaseService.userVehiclesStream(userId).map((snapshot) {
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<VehicleModel>> searchVehicles(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await FirebaseService.searchVehicles(query);
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  Future<List<VehicleModel>> getVehiclesByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];

      final vehicles = <VehicleModel>[];
      for (final id in ids) {
        final doc = await FirebaseService.vehiclesCollection.doc(id).get();
        if (doc.exists) {
          vehicles.add(VehicleModel.fromFirestore(doc));
        }
      }
      return vehicles;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des véhicules: $e');
    }
  }

  Future<void> toggleFavorite(String userId, String vehicleId) async {
    try {
      final userDoc = await FirebaseService.usersCollection.doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>?;
      final favorites = List<String>.from(data?['favorites'] ?? []);

      if (favorites.contains(vehicleId)) {
        favorites.remove(vehicleId);
      } else {
        favorites.add(vehicleId);
      }

      await FirebaseService.usersCollection.doc(userId).update({
        'favorites': favorites,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des favoris: $e');
    }
  }

  Future<bool> isFavorite(String userId, String vehicleId) async {
    try {
      final userDoc = await FirebaseService.usersCollection.doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>?;
      final favorites = List<String>.from(data?['favorites'] ?? []);
      return favorites.contains(vehicleId);
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> _uploadImages(List<File> imageFiles) async {
    final imageUrls = <String>[];

    for (final file in imageFiles) {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = FirebaseService.storageRef
          .child('vehicles')
          .child(fileName);

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    return imageUrls;
  }

  Future<void> _deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (e) {
        // Ignore errors when deleting images
      }
    }
  }

  Future<void> deleteImage(String vehicleId, String imageUrl) async {
    try {
      final doc = await FirebaseService.vehiclesCollection.doc(vehicleId).get();
      if (doc.exists) {
        final vehicle = VehicleModel.fromFirestore(doc);
        final updatedImages = vehicle.images.where((url) => url != imageUrl).toList();

        await FirebaseService.vehiclesCollection.doc(vehicleId).update({
          'images': updatedImages,
        });

        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }
}