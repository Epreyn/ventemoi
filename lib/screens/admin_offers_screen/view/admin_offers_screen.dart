// lib/screens/admin_offers_screen/view/admin_offers_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_offers_screen_controller.dart';
import '../../../core/models/special_offer.dart';
import '../../../core/theme/custom_theme.dart';
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
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: CustomTheme.lightScheme().primary,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: CustomTheme.lightScheme().primary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty),
                        const SizedBox(width: 8),
                        Text('Demandes en attente'),
                        Obx(() => controller.pendingRequests.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${controller.pendingRequests.length}',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              )
                            : const SizedBox.shrink()),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer),
                        const SizedBox(width: 8),
                        Text('Offres actives'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu des tabs
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Demandes en attente
                  _buildPendingRequestsTab(controller),
                  
                  // Tab 2: Offres actives
                  _buildActiveOffersTab(controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsTab(AdminOffersScreenController controller) {
    return Obx(() {
      if (controller.pendingRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune demande en attente',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Les nouvelles demandes apparaîtront ici',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.pendingRequests.length,
        itemBuilder: (context, index) {
          final request = controller.pendingRequests[index];
          return _buildRequestCard(request, controller);
        },
      );
    });
  }

  Widget _buildRequestCard(Map<String, dynamic> request, AdminOffersScreenController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // En-tête de la carte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.business, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['establishment_name'] ?? 'Établissement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Demande du ${_formatDate(request['created_at'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text('En attente', style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.orange[100],
                ),
              ],
            ),
          ),
          
          // Contenu de l'offre
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    Icon(Icons.title, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request['title'] ?? '',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request['description'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                
                // Image preview si présente
                if (request['image_url'] != null && request['image_url'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        request['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text('Image non disponible', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                
                // Dates
                if (request['start_date'] != null || request['end_date'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Période souhaitée: ${_formatDate(request['start_date'])} - ${_formatDate(request['end_date'])}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
                
                // Contact
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Contact: ${request['contact_phone'] ?? 'Non fourni'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showRejectDialog(controller, request['id']),
                  icon: Icon(Icons.close, color: Colors.red),
                  label: Text('Refuser', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.approveRequest(request),
                  icon: Icon(Icons.check, color: Colors.white),
                  label: Text('Approuver', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOffersTab(AdminOffersScreenController controller) {
    return Obx(() {
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
    });
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
            'Aucune offre active',
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
              backgroundColor: CustomTheme.lightScheme().primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(SpecialOffer offer, AdminOffersScreenController controller) {
    final bgColor = controller.parseHexColor(offer.backgroundColor ?? '#FFF3CD');
    final textColor = controller.parseHexColor(offer.textColor ?? '#856404');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Preview de l'offre
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
                  Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(offer.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  offer.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Informations et actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              children: [
                // Statut et dates
                Row(
                  children: [
                    // Statut
                    Chip(
                      label: Text(
                        offer.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: offer.isActive ? Colors.green : Colors.grey,
                      avatar: Icon(
                        offer.isActive ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Priorité
                    Chip(
                      label: Text(
                        'Priorité: ${offer.priority}',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[100],
                    ),
                    const Spacer(),
                    // Dates
                    if (offer.startDate != null || offer.endDate != null)
                      Text(
                        '${controller.formatDateFr(offer.startDate ?? DateTime.now())} - ${controller.formatDateFr(offer.endDate ?? DateTime.now())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Toggle activation
                    Switch(
                      value: offer.isActive,
                      onChanged: (value) {
                        controller.toggleOfferStatus(offer.id!, value);
                      },
                      activeColor: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    // Éditer
                    IconButton(
                      onPressed: () => controller.openEditOfferBottomSheet(offer),
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                      tooltip: 'Modifier',
                    ),
                    // Supprimer
                    IconButton(
                      onPressed: () => controller.deleteOffer(offer.id!),
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

  void _showRejectDialog(AdminOffersScreenController controller, String requestId) {
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: Text('Refuser la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Veuillez indiquer la raison du refus:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Raison du refus...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.rejectRequest(requestId, reasonController.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Refuser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Non définie';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Date invalide';
    }
  }
}