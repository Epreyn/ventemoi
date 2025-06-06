import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../controllers/gift_purchase_controller.dart';

class GiftPurchaseDialog extends StatelessWidget {
  final Purchase purchase;

  const GiftPurchaseDialog({
    super.key,
    required this.purchase,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GiftPurchaseController(purchase: purchase));
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: CustomTheme.lightScheme().surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.orange.withOpacity(0.05),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.orange.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.all(UniquesControllers().data.baseSpace),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: Colors.orange[800],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offrir ce bon cadeau',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bon de ${purchase.couponsCount * 50}€',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Contenu
                Flexible(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barre de recherche
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              controller.searchQuery.value = value;
                            },
                            decoration: InputDecoration(
                              hintText: 'Rechercher un utilisateur...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    UniquesControllers().data.baseSpace * 2,
                                vertical:
                                    UniquesControllers().data.baseSpace * 1.5,
                              ),
                            ),
                          ),
                        ),

                        const CustomSpace(heightMultiplier: 2),

                        // Résultats de recherche
                        Obx(() {
                          if (controller.searchQuery.value.isEmpty) {
                            return Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_search,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  Text(
                                    'Recherchez un utilisateur par nom ou email',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: controller.searchUsers(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                  ),
                                );
                              }

                              final users = snapshot.data ?? [];

                              if (users.isEmpty) {
                                return Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const CustomSpace(heightMultiplier: 1),
                                      Text(
                                        'Aucun utilisateur trouvé',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: users.map((userData) {
                                  return _buildUserCard(userData, controller);
                                }).toList(),
                              );
                            },
                          );
                        }),

                        const CustomSpace(heightMultiplier: 3),

                        // Bouton de confirmation
                        Obx(() => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    controller.selectedUser.value != null &&
                                            !controller.isTransferring.value
                                        ? controller.transferPurchase
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation:
                                      controller.selectedUser.value != null
                                          ? 4
                                          : 0,
                                ),
                                child: controller.isTransferring.value
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        controller.selectedUser.value != null
                                            ? 'Offrir à ${controller.getUserDisplayName(controller.selectedUser.value!)}'
                                            : 'Sélectionnez un destinataire',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
      Map<String, dynamic> userData, GiftPurchaseController controller) {
    return Obx(() {
      final isSelected = controller.selectedUser.value?['id'] == userData['id'];

      return Container(
        margin: EdgeInsets.only(bottom: UniquesControllers().data.baseSpace),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.selectUser(userData),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding:
                  EdgeInsets.all(UniquesControllers().data.baseSpace * 1.5),
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.orange.withOpacity(0.5)
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        controller.getInitials(userData),
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Infos utilisateur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.getUserDisplayName(userData),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          controller.getUserSubtitle(userData),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Indicateur de sélection
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
