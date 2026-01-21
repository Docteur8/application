import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadVehicleImage(File imageFile) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('vehicles').child(fileName);
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Erreur lors du téléchargement de l\'image: $e');
    }
  }

  Future<List<String>> uploadMultipleVehicleImages(List<File> imageFiles) async {
    try {
      final List<String> imageUrls = [];
      
      for (final imageFile in imageFiles) {
        final url = await uploadVehicleImage(imageFile);
        imageUrls.add(url);
      }
      
      return imageUrls;
    } catch (e) {
      throw Exception('Erreur lors du téléchargement des images: $e');
    }
  }

  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileName = '$userId.jpg';
      final ref = _storage.ref().child('profiles').child(fileName);
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Erreur lors du téléchargement de la photo de profil: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }

  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        await deleteImage(url);
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression des images: $e');
    }
  }
}