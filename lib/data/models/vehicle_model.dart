import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String brand;
  final String model;
  final int year;
  final double price;
  final int mileage;
  final String fuelType;
  final String transmission;
  final List<String> images;
  final GeoPoint? location;
  final String city;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final DateTime createdAt;
  final bool isFeatured;

  VehicleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.brand,
    required this.model,
    required this.year,
    required this.price,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    required this.images,
    this.location,
    required this.city,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.createdAt,
    this.isFeatured = false,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      mileage: data['mileage'] ?? 0,
      fuelType: data['fuelType'] ?? '',
      transmission: data['transmission'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      location: data['location'],
      city: data['city'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerPhone: data['sellerPhone'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'brand': brand,
      'model': model,
      'year': year,
      'price': price,
      'mileage': mileage,
      'fuelType': fuelType,
      'transmission': transmission,
      'images': images,
      'location': location,
      'city': city,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFeatured': isFeatured,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? brand,
    String? model,
    int? year,
    double? price,
    int? mileage,
    String? fuelType,
    String? transmission,
    List<String>? images,
    GeoPoint? location,
    String? city,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    DateTime? createdAt,
    bool? isFeatured,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      price: price ?? this.price,
      mileage: mileage ?? this.mileage,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      images: images ?? this.images,
      location: location ?? this.location,
      city: city ?? this.city,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      createdAt: createdAt ?? this.createdAt,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}