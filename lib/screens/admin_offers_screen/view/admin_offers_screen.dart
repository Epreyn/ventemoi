// lib/screens/admin_offers_screen/view/admin_offers_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_offers_screen_controller.dart';
import '../../../core/models/special_offer.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';

class AdminOffersScreen extends StatelessWidget {
  const AdminOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminOffersScreenController());
    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
      ),
      fabIcon: const Icon(Icons.add_rounded, size: 24),
      fabText: const Text('Nouvelle offre'),
      fabOnPressed: controller.openCreateOfferBottomSheet,
      body: Column(
        children: [
          // Titre sobre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Offres du Moment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Divider(height: 1),
          // Contenu
          Expanded(
            child: Obx(() {
              if (controller.allOffers.isEmpty) {
                return _buildEmptyState(controller);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.allOffers.length,
                itemBuilder: (context, index) {
                  final offer = controller.allOffers[index];
                  return CustomCardAnimation(
                    index: index,
                    child: _buildOfferCard(offer, controller),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdminOffersScreenController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune offre créée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première offre du moment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.openCreateOfferBottomSheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Créer une offre',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(SpecialOffer offer, AdminOffersScreenController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: offer.isCurrentlyActive ? 4 : 1,
      child: Column(
        children: [
          // Prévisualisation du bandeau
          _buildOfferPreview(offer, controller),
          
          // Informations et actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offer.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(offer),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Métadonnées
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.low_priority,
                      'Priorité: ${offer.priority}',
                      Colors.blue,
                    ),
                    if (offer.startDate != null)
                      _buildInfoChip(
                        Icons.calendar_today,
                        'Début: ${_formatDate(offer.startDate!)}',
                        Colors.green,
                      ),
                    if (offer.endDate != null)
                      _buildInfoChip(
                        Icons.event,
                        'Fin: ${_formatDate(offer.endDate!)}',
                        Colors.orange,
                      ),
                    if (offer.linkUrl != null && offer.linkUrl!.isNotEmpty)
                      _buildInfoChip(
                        Icons.link,
                        'Avec lien',
                        Colors.purple,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Switch actif/inactif
                    Row(
                      children: [
                        Text(
                          offer.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: offer.isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: offer.isActive,
                          onChanged: (value) {
                            controller.toggleOfferStatus(offer.id, value);
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Bouton modifier
                    IconButton(
                      onPressed: () => controller.openEditOfferBottomSheet(offer),
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                      tooltip: 'Modifier',
                    ),
                    
                    // Bouton supprimer
                    IconButton(
                      onPressed: () => controller.deleteOffer(offer.id),
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferPreview(SpecialOffer offer, AdminOffersScreenController controller) {
    final bgColor = controller.parseHexColor(offer.backgroundColor ?? '#FF6B35');
    final textColor = controller.parseHexColor(offer.textColor ?? '#FFFFFF');
    final hasImage = offer.imageUrl != null && offer.imageUrl!.isNotEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Text(
            'APERÇU DU BANDEAU',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(
              color: bgColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image de fond avec dégradé
                if (hasImage) ...[
                  Positioned.fill(
                    child: Image.network(
                      offer.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: bgColor.withOpacity(0.5),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: bgColor.withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 30,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Dégradé sur l'image
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            bgColor.withOpacity(0.95),
                            bgColor.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          bgColor,
                          bgColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
                
                // Contenu
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Badge période si dates définies
                            if (offer.startDate != null || offer.endDate != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getDateText(offer, controller),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            
                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: textColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: textColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '🎁 OFFRE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            
                            Text(
                              offer.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              offer.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.95),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (offer.buttonText != null && offer.buttonText!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            offer.buttonText!,
                            style: TextStyle(
                              color: bgColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDateText(SpecialOffer offer, AdminOffersScreenController controller) {
    if (offer.startDate != null && offer.endDate != null) {
      return 'Du ${controller.formatDateFr(offer.startDate!)} au ${controller.formatDateFr(offer.endDate!)}';
    } else if (offer.startDate != null) {
      return 'À partir du ${controller.formatDateFr(offer.startDate!)}';
    } else if (offer.endDate != null) {
      return 'Jusqu\'au ${controller.formatDateFr(offer.endDate!)}';
    }
    return '';
  }

  Widget _buildStatusBadge(SpecialOffer offer) {
    if (!offer.isCurrentlyActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Inactive',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            size: 16,
            color: Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            'Active',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}