import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/vehicle_card.dart';
import '../vehicle/vehicle_detail_screen.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.user == null || authProvider.userData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, authProvider),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileHeader(authProvider),
                    _buildSettingsSection(context),
                    _buildMyVehiclesSection(context, authProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider authProvider) {
    return SliverAppBar(
      floating: true,
      title: const Text(AppStrings.profile),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            final confirm = await Helpers.showConfirmDialog(
              context,
              title: 'Déconnexion',
              message: 'Voulez-vous vraiment vous déconnecter ?',
            );

            if (confirm) {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: Text(
              authProvider.userData!.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authProvider.userData!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.userData!.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          if (authProvider.userData!.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(
                  authProvider.userData!.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Paramètres',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Paramètres de l\'application'),
          subtitle: const Text('Notifications, confidentialité, etc.'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return SwitchListTile(
              title: const Text('Mode sombre'),
              subtitle: const Text('Activer le thème sombre'),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Modifier le profil'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Implement edit profile
          },
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildMyVehiclesSection(BuildContext context, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Mes annonces',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Consumer<VehicleProvider>(
          builder: (context, vehicleProvider, _) {
            // Initialize user vehicles stream
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (vehicleProvider.userVehicles.isEmpty) {
                vehicleProvider.loadUserVehicles(authProvider.user!.uid);
              }
            });

            if (vehicleProvider.userVehicles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.car_rental, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune annonce',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: vehicleProvider.userVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicleProvider.userVehicles[index];
                return VehicleCard(
                  vehicle: vehicle,
                  isFavorite: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VehicleDetailScreen(vehicle: vehicle),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}