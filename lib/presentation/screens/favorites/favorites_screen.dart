import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/vehicle_card.dart';
import '../vehicle/vehicle_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<VehicleProvider, AuthProvider>(
        builder: (context, vehicleProvider, authProvider, _) {
          if (vehicleProvider.favoriteVehicles.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun favori',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ajoutez des véhicules à vos favoris',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: vehicleProvider.favoriteVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicleProvider.favoriteVehicles[index];
              return VehicleCard(
                vehicle: vehicle,
                isFavorite: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VehicleDetailScreen(vehicle: vehicle),
                    ),
                  );
                },
                onFavorite: authProvider.user != null
                    ? () {
                        vehicleProvider.toggleFavorite(
                          authProvider.user!.uid,
                          vehicle.id,
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
