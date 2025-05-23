import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/enterprises_list_screen_controller.dart';
import '../widgets/enterprise_card.dart';

class EnterprisesListScreen extends StatelessWidget {
  const EnterprisesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(EnterprisesListScreenController());

    return ScreenLayout(
      noFAB: true,
      body: Column(
        children: [
          // Barre de recherche
          CustomCardAnimation(
            index: 0,
            child: Padding(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Rechercher un établissement',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(90)),
                  ),
                ),
                onChanged: cc.onSearchChanged,
              ),
            ),
          ),

          // Filtres (chips + bouton)
          CustomCardAnimation(
            index: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: UniquesControllers().data.baseSpace),
              child: Obx(() {
                final selIds = cc.selectedCategoryIds;
                final chips = <Widget>[];

                // Pour chaque catID sélectionné, on affiche un Chip
                for (final cId in selIds) {
                  final cName = cc.enterpriseCategoriesMap[cId] ?? cId;
                  chips.add(
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(cName),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          cc.selectedCategoryIds.remove(cId);
                          cc.filterEnterprises();
                        },
                      ),
                    ),
                  );
                }

                // Espace + bouton
                chips.add(const Spacer());
                chips.add(
                  ElevatedButton.icon(
                    onPressed: () {
                      cc.openBottomSheet('Filtres',
                          actionName: 'Appliquer', actionIcon: Icons.check);
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtres'),
                  ),
                );

                return Row(children: chips);
              }),
            ),
          ),

          // Liste
          Expanded(
            child: Obx(() {
              final list = cc.displayedEnterprises;
              if (list.isEmpty) {
                return const Center(child: Text('Aucune entreprise trouvée'));
              }
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final e = list[i];
                  return CustomCardAnimation(
                    index: 2 + i,
                    child: EnterpriseCard(establishment: e),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
