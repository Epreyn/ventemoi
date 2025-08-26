import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../controllers/points_transfer_controller.dart';

class PointsTransferDialog extends StatelessWidget {
  const PointsTransferDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PointsTransferController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                // Header avec points disponibles
                Container(
                  padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CustomTheme.lightScheme().primary.withOpacity(0.1),
                        CustomTheme.lightScheme().primary.withOpacity(0.05),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
                        decoration: BoxDecoration(
                          color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: CustomTheme.lightScheme().primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transférer des points',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Obx(() => Text(
                              'Vous avez ${controller.availablePoints.value} points',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            )),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Champ de saisie des points
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nombre de points à transférer',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller.pointsController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  suffixText: 'points',
                                  suffixStyle: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: CustomTheme.lightScheme().primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(() {
                                final points = controller.pointsToTransfer.value;
                                final available = controller.availablePoints.value;
                                final isValid = points > 0 && points <= available;
                                
                                return Text(
                                  points > available
                                      ? 'Vous n\'avez que ${available} points disponibles'
                                      : points > 0
                                          ? 'Transfert de $points points'
                                          : 'Saisissez le nombre de points',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: points > available
                                        ? Colors.red
                                        : isValid
                                            ? Colors.green
                                            : Colors.grey[600],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Recherche utilisateur
                        const Text(
                          'Rechercher un destinataire',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Nom, email ou établissement...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: CustomTheme.lightScheme().primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => controller.searchQuery.value = value,
                        ),
                        const SizedBox(height: 16),

                        // Utilisateur sélectionné
                        Obx(() {
                          if (controller.selectedUser.value != null) {
                            final user = controller.selectedUser.value!;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: CustomTheme.lightScheme().primary,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: CustomTheme.lightScheme().primary,
                                    child: Text(
                                      controller.getInitials(user),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          controller.getUserDisplayName(user),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (controller.getUserSubtitle(user).isNotEmpty)
                                          Text(
                                            controller.getUserSubtitle(user),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => controller.selectedUser.value = null,
                                    color: CustomTheme.lightScheme().primary,
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        // Liste des résultats de recherche
                        Obx(() {
                          if (controller.searchQuery.value.length < 2) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'Tapez au moins 2 caractères pour rechercher',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            );
                          }

                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: controller.searchUsers(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final users = snapshot.data!;
                              if (users.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(
                                      'Aucun utilisateur trouvé',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: users.map((user) {
                                  final isSelected = controller.selectedUser.value?['id'] == user['id'];
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? CustomTheme.lightScheme().primary.withOpacity(0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? CustomTheme.lightScheme().primary
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () => controller.selectUser(user),
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? CustomTheme.lightScheme().primary
                                            : Colors.grey[300],
                                        child: Text(
                                          controller.getInitials(user),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        controller.getUserDisplayName(user),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: controller.getUserSubtitle(user).isNotEmpty
                                          ? Text(
                                              controller.getUserSubtitle(user),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                          : null,
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check_circle,
                                              color: CustomTheme.lightScheme().primary,
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Footer avec boutons
                Container(
                  padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Obx(() {
                          final canTransfer = controller.canTransfer;
                          final isTransferring = controller.isTransferring.value;

                          return ElevatedButton(
                            onPressed: canTransfer && !isTransferring
                                ? () => controller.transferPoints()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CustomTheme.lightScheme().primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isTransferring
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Transférer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}