// lib/screens/pro_establishment_profile_screen/widgets/pro_establishment_enterprise_categories_section.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../widgets/enterprise_category_cascade_selector.dart';
import '../controllers/pro_establishment_profile_screen_controller.dart';

class ProEstablishmentEnterpriseCategoriesSection extends StatelessWidget {
  final ProEstablishmentProfileScreenController controller;

  const ProEstablishmentEnterpriseCategoriesSection({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Si pas d'abonnement actif, afficher un message
      if (!controller.hasActiveSubscription.value) {
        return _buildNoSubscriptionCard();
      }

      return StreamBuilder<List<EnterpriseCategory>>(
        stream: controller.getEnterpriseCategoriesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'MÉTIERS & SERVICES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Card principale
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec icône
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.business_center,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vos domaines d\'activité',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Sélectionnez jusqu\'à ${controller.enterpriseCategorySlots.value} catégories',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Sélecteur de catégories
                    Obx(() => EnterpriseCategoryCascadingSelector(
                          categories: categories,
                          selectedIds: controller.selectedEnterpriseCategoryIds,
                          onToggle: controller.toggleEnterpriseCategory,
                          onRemove: controller.removeEnterpriseCategory,
                          maxSelections:
                              controller.enterpriseCategorySlots.value,
                          selectedOptions: controller.selectedSubcategoryOptions,
                          onOptionsChanged: controller.updateSubcategoryOptions,
                        )),

                    // Message d'information selon l'abonnement
                    if (controller.subscriptionStatus.value.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getSubscriptionColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getSubscriptionColor().withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getSubscriptionIcon(),
                              color: _getSubscriptionColor(),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getSubscriptionMessage(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _getSubscriptionColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Boutons d'action
              Obx(() {
                if (controller.hasModifications.value) {
                  return Container(
                    margin: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                controller.saveEnterpriseCategoriesChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text('Enregistrer les modifications'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed:
                              controller.resetEnterpriseCategoriesChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Annuler'),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
            ],
          );
        },
      );
    });
  }

  Widget _buildNoSubscriptionCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.orange[700],
          ),
          SizedBox(height: 16),
          Text(
            'Abonnement requis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Activez votre abonnement pour ajouter vos métiers et services',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.orange[700],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Naviguer vers la page d'abonnement
              Get.offAllNamed('/subscription');
            },
            icon: Icon(Icons.star),
            label: Text('Voir les abonnements'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubscriptionColor() {
    switch (controller.subscriptionStatus.value) {
      case 'premium':
        return Colors.purple;
      case 'standard':
        return Colors.blue;
      case 'basic':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubscriptionIcon() {
    switch (controller.subscriptionStatus.value) {
      case 'premium':
        return Icons.workspace_premium;
      case 'standard':
        return Icons.star;
      case 'basic':
        return Icons.circle;
      default:
        return Icons.info_outline;
    }
  }

  String _getSubscriptionMessage() {
    final endDate = controller.subscriptionEndDate.value;
    if (endDate != null) {
      final daysLeft = endDate.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        return 'Abonnement ${controller.subscriptionStatus.value} actif - $daysLeft jours restants';
      } else {
        return 'Votre abonnement a expiré';
      }
    }
    return 'Abonnement ${controller.subscriptionStatus.value}';
  }
}
