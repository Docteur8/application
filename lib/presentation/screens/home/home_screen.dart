import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/vehicle_card.dart';
import '../vehicle/vehicle_detail_screen.dart';
import '../vehicle/add_vehicle_screen.dart';
import '../profile/profile_screen.dart';
import '../favorites/favorites_screen.dart';
import '../chat/chat_list_screen.dart';
import '../map/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicleProvider = context.read<VehicleProvider>();
      final authProvider = context.read<AuthProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      
      // Charger les paramètres
      if (authProvider.user != null) {
        settingsProvider.loadSettings(authProvider.user!.uid).then((_) {
          // Appliquer les filtres par défaut depuis les paramètres
          final settings = settingsProvider.settings;
          if (settings.defaultVehicleType != null) {
            vehicleProvider.setFilter(settings.defaultVehicleType);
          }
          if (settings.defaultSortBy != null) {
            vehicleProvider.setSortBy(settings.defaultSortBy!);
          }
        });
        
        vehicleProvider.loadFavorites(authProvider.user!.uid);
      }
      
      vehicleProvider.loadVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const FavoritesScreen();
      case 2:
        return const ChatListScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilters(),
        Expanded(child: _buildVehicleList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchVehicles,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MapScreen(),
                ),
              );
            },
            tooltip: 'Voir la carte',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<VehicleProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip(
                label: AppStrings.all,
                isSelected: provider.selectedType == null,
                onTap: () => provider.setFilter(null),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: AppStrings.cars,
                isSelected: provider.selectedType == 'car',
                onTap: () => provider.setFilter('car'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: AppStrings.motos,
                isSelected: provider.selectedType == 'moto',
                onTap: () => provider.setFilter('moto'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.greyLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    return Consumer2<VehicleProvider, AuthProvider>(
      builder: (context, vehicleProvider, authProvider, _) {
        if (vehicleProvider.vehicles.isEmpty) {
          return const Center(
            child: Text('Aucun véhicule disponible'),
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
          itemCount: vehicleProvider.vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicleProvider.vehicles[index];
            return VehicleCard(
              vehicle: vehicle,
              isFavorite: vehicleProvider.isFavorite(vehicle.id),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddVehicleScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Vendre'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}