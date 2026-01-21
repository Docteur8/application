import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';

/// Écran de paramètres de l'application
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (authProvider.user != null) {
      await settingsProvider.loadSettings(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(),
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settingsProvider, authProvider, _) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = settingsProvider.settings;
          final userId = authProvider.user?.uid ?? '';

          return ListView(
            children: [
              // Apparence
              _buildSectionHeader('Apparence'),
              _buildSwitchTile(
                title: 'Mode sombre',
                subtitle: 'Activer le thème sombre',
                value: context.watch<ThemeProvider>().isDarkMode,
                icon: Icons.dark_mode,
                onChanged: (value) {
                  context.read<ThemeProvider>().toggleTheme();
                  settingsProvider.toggleDarkMode(userId, value);
                },
              ),
              _buildListTile(
                title: 'Langue',
                subtitle: settings.language == 'fr' ? 'Français' : 'English',
                icon: Icons.language,
                onTap: () => _showLanguageDialog(userId),
              ),
              const Divider(),

              // Notifications
              _buildSectionHeader('Notifications'),
              _buildSwitchTile(
                title: 'Activer les notifications',
                subtitle: 'Recevoir des notifications push',
                value: settings.enableNotifications,
                icon: Icons.notifications,
                onChanged: (value) => settingsProvider.toggleNotifications(userId, value),
              ),
              if (settings.enableNotifications) ...[
                _buildSwitchTile(
                  title: 'Nouveaux messages',
                  subtitle: 'Être notifié des nouveaux messages',
                  value: settings.notifyNewMessages,
                  icon: Icons.message,
                  onChanged: (value) => settingsProvider.toggleNotifyNewMessages(userId, value),
                ),
                _buildSwitchTile(
                  title: 'Nouveaux véhicules',
                  subtitle: 'Véhicules correspondant à vos critères',
                  value: settings.notifyNewVehicles,
                  icon: Icons.directions_car,
                  onChanged: (value) => settingsProvider.toggleNotifyNewVehicles(userId, value),
                ),
                _buildSwitchTile(
                  title: 'Changements de prix',
                  subtitle: 'Alertes sur les baisses de prix',
                  value: settings.notifyPriceChanges,
                  icon: Icons.trending_down,
                  onChanged: (value) => settingsProvider.toggleNotifyPriceChanges(userId, value),
                ),
                _buildSwitchTile(
                  title: 'Véhicules à proximité',
                  subtitle: 'Nouveaux véhicules près de vous',
                  value: settings.notifyNearbyVehicles,
                  icon: Icons.near_me,
                  onChanged: (value) => settingsProvider.toggleNotifyNearbyVehicles(userId, value),
                ),
              ],
              const Divider(),

              // Localisation
              _buildSectionHeader('Localisation'),
              _buildSwitchTile(
                title: 'Activer la localisation',
                subtitle: 'Autoriser l\'accès à votre position',
                value: settings.enableLocation,
                icon: Icons.location_on,
                onChanged: (value) => settingsProvider.toggleLocation(userId, value),
              ),
              if (settings.enableLocation) ...[
                _buildSliderTile(
                  title: 'Rayon de recherche',
                  subtitle: '${settings.searchRadius.toStringAsFixed(0)} km',
                  value: settings.searchRadius,
                  min: 5,
                  max: 200,
                  divisions: 39,
                  icon: Icons.radar,
                  onChanged: (value) => settingsProvider.updateSearchRadius(userId, value),
                ),
              ],
              const Divider(),

              // Confidentialité
              _buildSectionHeader('Confidentialité'),
              _buildSwitchTile(
                title: 'Afficher mon numéro',
                subtitle: 'Visible sur mes annonces',
                value: settings.showPhoneNumber,
                icon: Icons.phone,
                onChanged: (value) => settingsProvider.toggleShowPhoneNumber(userId, value),
              ),
              _buildSwitchTile(
                title: 'Afficher mon email',
                subtitle: 'Visible sur mon profil',
                value: settings.showEmail,
                icon: Icons.email,
                onChanged: (value) => settingsProvider.toggleShowEmail(userId, value),
              ),
              _buildSwitchTile(
                title: 'Messages de tous',
                subtitle: 'Autoriser les messages de tout le monde',
                value: settings.allowMessagesFromAnyone,
                icon: Icons.chat,
                onChanged: (value) => settingsProvider.toggleAllowMessagesFromAnyone(userId, value),
              ),
              const Divider(),

              // Sécurité
              _buildSectionHeader('Sécurité'),
              _buildSwitchTile(
                title: 'Déconnexion automatique',
                subtitle: 'Se déconnecter après inactivité',
                value: settings.autoLogout,
                icon: Icons.lock_clock,
                onChanged: (value) => settingsProvider.toggleAutoLogout(userId, value),
              ),
              if (settings.autoLogout)
                _buildListTile(
                  title: 'Délai de déconnexion',
                  subtitle: '${settings.autoLogoutMinutes} minutes',
                  icon: Icons.timer,
                  onTap: () => _showAutoLogoutDialog(userId, settings.autoLogoutMinutes),
                ),
              const Divider(),

              // Filtres par défaut
              _buildSectionHeader('Préférences de recherche'),
              _buildListTile(
                title: 'Type de véhicule par défaut',
                subtitle: _getVehicleTypeLabel(settings.defaultVehicleType),
                icon: Icons.filter_list,
                onTap: () => _showVehicleTypeDialog(userId),
              ),
              
              const SizedBox(height: 16),

              // À propos
              _buildSectionHeader('À propos'),
              _buildListTile(
                title: 'Version',
                subtitle: '1.0.0',
                icon: Icons.info,
              ),
              _buildListTile(
                title: 'Conditions d\'utilisation',
                icon: Icons.description,
                onTap: () {
                  // TODO: Afficher les CGU
                },
              ),
              _buildListTile(
                title: 'Politique de confidentialité',
                icon: Icons.privacy_tip,
                onTap: () {
                  // TODO: Afficher la politique
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: subtitle,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _getVehicleTypeLabel(String? type) {
    switch (type) {
      case 'car':
        return 'Voitures uniquement';
      case 'moto':
        return 'Motos uniquement';
      default:
        return 'Tous les types';
    }
  }

  Future<void> _showResetDialog() async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'Réinitialiser les paramètres',
      message: 'Voulez-vous restaurer tous les paramètres par défaut ?',
      confirmText: 'Réinitialiser',
      cancelText: 'Annuler',
    );

    if (confirm && mounted) {
      final authProvider = context.read<AuthProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      if (authProvider.user != null) {
        final success = await settingsProvider.resetToDefaults(authProvider.user!.uid);
        
        if (mounted) {
          if (success) {
            Helpers.showSnackBar(context, 'Paramètres réinitialisés');
          } else {
            Helpers.showSnackBar(context, 'Erreur lors de la réinitialisation', isError: true);
          }
        }
      }
    }
  }

  Future<void> _showLanguageDialog(String userId) async {
    final settingsProvider = context.read<SettingsProvider>();
    final currentLanguage = settingsProvider.settings.language;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.updateLanguage(userId, value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.updateLanguage(userId, value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVehicleTypeDialog(String userId) async {
    final settingsProvider = context.read<SettingsProvider>();
    final currentType = settingsProvider.settings.defaultVehicleType;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type de véhicule par défaut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: const Text('Tous les types'),
              value: null,
              groupValue: currentType,
              onChanged: (value) {
                settingsProvider.setDefaultVehicleType(userId, value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String?>(
              title: const Text('Voitures uniquement'),
              value: 'car',
              groupValue: currentType,
              onChanged: (value) {
                settingsProvider.setDefaultVehicleType(userId, value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String?>(
              title: const Text('Motos uniquement'),
              value: 'moto',
              groupValue: currentType,
              onChanged: (value) {
                settingsProvider.setDefaultVehicleType(userId, value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAutoLogoutDialog(String userId, int currentMinutes) async {
    final settingsProvider = context.read<SettingsProvider>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Délai de déconnexion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('15 minutes'),
              value: 15,
              groupValue: currentMinutes,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.updateAutoLogoutMinutes(userId, value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('30 minutes'),
              value: 30,
              groupValue: currentMinutes,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.updateAutoLogoutMinutes(userId, value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('60 minutes'),
              value: 60,
              groupValue: currentMinutes,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.updateAutoLogoutMinutes(userId, value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}