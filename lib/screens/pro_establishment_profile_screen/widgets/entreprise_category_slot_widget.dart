import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../features/custom_dropdown_stream_builder/view/custom_dropdown_stream_builder.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../controllers/pro_establishment_profile_screen_controller.dart';

class EnterpriseCategorySlotsWidget extends StatelessWidget {
  final ProEstablishmentProfileScreenController controller;

  const EnterpriseCategorySlotsWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slots = controller.enterpriseCategorySlots.value;
      final categories = controller.selectedEnterpriseCategories;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec informations sur les slots
          Row(
            children: [
              Text(
                'Catégories d\'entreprise',
                style: TextStyle(
                  fontSize: UniquesControllers().data.baseSpace * 1.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: UniquesControllers().data.baseSpace,
                  vertical: UniquesControllers().data.baseSpace / 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(
                    UniquesControllers().data.baseSpace,
                  ),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  '$slots slots disponibles',
                  style: TextStyle(
                    fontSize: UniquesControllers().data.baseSpace * 1.4,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const CustomSpace(heightMultiplier: 1),

          // Information sur les slots
          Container(
            padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(
                UniquesControllers().data.baseSpace,
              ),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: UniquesControllers().data.baseSpace * 2,
                      color: Colors.blue,
                    ),
                    const CustomSpace(widthMultiplier: 1),
                    Expanded(
                      child: Text(
                        'Vous disposez de 2 slots gratuits. Slots supplémentaires : 50€ HT/slot.',
                        style: TextStyle(
                          fontSize: UniquesControllers().data.baseSpace * 1.4,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const CustomSpace(heightMultiplier: 2),

          // Liste des dropdowns de catégories
          ...List.generate(categories.length, (index) {
            final isExtraSlot = index >= 2; // Les slots 3+ sont payants

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomDropdownStreamBuilder<EnterpriseCategory>(
                        tag: 'enterprise-category-$index',
                        stream: controller.getEnterpriseCategoriesStream(),
                        initialItem: categories[index],
                        labelText:
                            'Catégorie ${index + 1}${isExtraSlot ? ' (Premium)' : ''}',
                        onChanged: (EnterpriseCategory? cat) {
                          categories[index].value = cat;
                        },
                      ),
                    ),

                    // Icône premium pour les slots payants
                    if (isExtraSlot) ...[
                      const CustomSpace(widthMultiplier: 1),
                      Container(
                        padding: EdgeInsets.all(
                          UniquesControllers().data.baseSpace / 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(
                            UniquesControllers().data.baseSpace / 2,
                          ),
                        ),
                        child: Icon(
                          Icons.star,
                          size: UniquesControllers().data.baseSpace * 1.5,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
                const CustomSpace(heightMultiplier: 2),
              ],
            );
          }),

          // Bouton pour ajouter un slot
          Center(
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: controller.addCategorySlot,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un slot (50€ HT)'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                      vertical: UniquesControllers().data.baseSpace,
                    ),
                  ),
                ),
                const CustomSpace(heightMultiplier: 1),
                Text(
                  'Payement sécurisé via Stripe',
                  style: TextStyle(
                    fontSize: UniquesControllers().data.baseSpace * 1.2,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
