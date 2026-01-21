import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../chat/chat_screen.dart';
import '../../widgets/error_widget.dart'; 

class VehicleDetailScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  int _currentImageIndex = 0;

  Future<void> _openChat(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (authProvider.user == null || authProvider.userData == null) {
      Helpers.showSnackBar(
        context,
        'Vous devez être connecté pour envoyer un message',
        isError: true,
      );
      return;
    }

    if (authProvider.user!.uid == widget.vehicle.sellerId) {
      Helpers.showSnackBar(
        context,
        'Vous ne pouvez pas vous envoyer de message',
        isError: true,
      );
      return;
    }

    Helpers.showLoadingDialog(context);

    final chatId = await chatProvider.createOrGetChat(
      currentUserId: authProvider.user!.uid,
      otherUserId: widget.vehicle.sellerId,
      currentUserName: authProvider.userData!.name,
      otherUserName: widget.vehicle.sellerName,
      vehicleId: widget.vehicle.id,
      vehicleTitle: widget.vehicle.title,
      vehicleImage: widget.vehicle.images.isNotEmpty ? widget.vehicle.images.first : '',
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (chatId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserId: widget.vehicle.sellerId,
            otherUserName: widget.vehicle.sellerName,
            vehicleTitle: widget.vehicle.title,
          ),
        ),
      );
    } else {
      Helpers.showSnackBar(
        context,
        'Erreur lors de l\'ouverture du chat',
        isError: true,
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageGallery(),
                _buildPriceSection(),
                _buildDetailsSection(),
                _buildDescriptionSection(),
                _buildSellerSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      actions: [
        Consumer2<VehicleProvider, AuthProvider>(
          builder: (context, vehicleProvider, authProvider, _) {
            if (authProvider.user == null) return const SizedBox();
            
            return IconButton(
              icon: Icon(
                vehicleProvider.isFavorite(widget.vehicle.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: vehicleProvider.isFavorite(widget.vehicle.id)
                    ? Colors.red
                    : null,
              ),
              onPressed: () {
                vehicleProvider.toggleFavorite(
                  authProvider.user!.uid,
                  widget.vehicle.id,
                );
              },
            );
          },
        ),
      ],
    );
  }

  // --- MODIFICATION INTELLIGENTE ICI ---
  Widget _buildImageGallery() {
    // Cas 1 : Aucune image fournie pour le véhicule
    if (widget.vehicle.images.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        color: Colors.grey[100],
        child: const CustomErrorWidget(
          message: 'Aucune photo disponible pour ce véhicule.',
          // Pas de retry ici car c'est une absence de données, pas une erreur réseau
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: widget.vehicle.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.vehicle.images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                // Cas 2 : Erreur lors du chargement d'une image spécifique
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: CustomErrorWidget(
                    message: 'Impossible de charger l\'image.',
                    onRetry: () {
                      // Astuce simple pour forcer le widget à se reconstruire et retenter le chargement
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.vehicle.images.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.vehicle.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? AppColors.primary
                        : AppColors.grey,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Helpers.formatPrice(widget.vehicle.price),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.vehicle.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.vehicle.type == AppStrings.car
                  ? AppColors.carColor
                  : AppColors.motoColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.vehicle.type == AppStrings.car ? AppStrings.cars : AppStrings.motos,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caractéristiques',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.branding_watermark, 'Marque', widget.vehicle.brand),
          _buildDetailRow(Icons.directions_car, 'Modèle', widget.vehicle.model),
          _buildDetailRow(Icons.calendar_today, 'Année', '${widget.vehicle.year}'),
          _buildDetailRow(Icons.speed, 'Kilométrage', Helpers.formatMileage(widget.vehicle.mileage)),
          _buildDetailRow(Icons.local_gas_station, 'Carburant', widget.vehicle.fuelType),
          _buildDetailRow(Icons.settings, 'Transmission', widget.vehicle.transmission),
          _buildDetailRow(Icons.location_on, 'Ville', widget.vehicle.city),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            widget.vehicle.description,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendeur',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary,
                child: Text(
                  widget.vehicle.sellerName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicle.sellerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Membre depuis ${Helpers.formatDate(widget.vehicle.createdAt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _makePhoneCall(widget.vehicle.sellerPhone),
                icon: const Icon(Icons.phone),
                label: const Text(AppStrings.call),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(Icons.message),
                label: const Text(AppStrings.messages),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}