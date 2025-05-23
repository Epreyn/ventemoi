import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/shop_establishment_screen_controller.dart';
import '../widgets/shop_establishment_card.dart';
import '../widgets/shop_establishment_search_bar.dart';

class ShopEstablishmentScreen extends StatelessWidget {
  const ShopEstablishmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ShopEstablishmentScreenController());

    return ScreenLayout(
      noFAB: true,
      body: DefaultTabController(
        length: 2,
        // On peut éventuellement gérer le TabController soi-même,
        // mais ici on laisse Flutter le faire. On synchronisera la valeur
        // dans onTap: (index) => cc.selectedTabIndex.value = index;
        child: Column(
          children: [
            // --- BARRE DE RECHERCHE + FILTRES ---
            // On place ce bloc en haut
            Padding(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
              child: Column(
                children: [
                  // Barre de recherche
                  ShopEstablishmentSearchBar(controller: cc),

                  // Espace
                  SizedBox(height: UniquesControllers().data.baseSpace * 1.5),

                  // Zone de chips => catégories + bouton Filtres
                  Obx(() {
                    final chips = <Widget>[];

                    // On génère les chips pour les catégories sélectionnées
                    for (var catId in cc.selectedCatIds) {
                      final catName = cc.categoriesMap[catId] ?? catId;
                      chips.add(
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(catName),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () {
                              cc.selectedCatIds.remove(catId);
                              cc.filterEstablishments();
                            },
                          ),
                        ),
                      );
                    }

                    chips.add(const Spacer());

                    // Bouton "Filtres"
                    chips.add(
                      CustomCardAnimation(
                        index: 1,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            cc.openBottomSheet('Filtres',
                                actionName: 'Appliquer',
                                actionIcon: Icons.check);
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filtres'),
                        ),
                      ),
                    );

                    return Row(children: chips);
                  }),
                ],
              ),
            ),

            // --- TAB BAR ---
            CustomCardAnimation(
              index: 2,
              child: TabBar(
                onTap: (index) => cc.selectedTabIndex.value = index,
                tabs: const [
                  Tab(text: 'Boutiques'),
                  Tab(text: 'Associations'),
                ],
              ),
            ),

            // --- CONTENU DES ONGLETS ---
            Expanded(
              child: Obx(() {
                final list = cc.displayedEstablishments;
                if (list.isEmpty) {
                  return const Center(
                      child: Text('Aucun établissement trouvé'));
                }

                return TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  // On peut empêcher le swipe en mettant
                  // physics: NeverScrollableScrollPhysics()
                  children: [
                    // Onglet 0: Boutiques
                    _buildGridView(list, cc),
                    // Onglet 1: Associations
                    _buildGridView(list, cc),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(
      List establishments, ShopEstablishmentScreenController cc) {
    return Padding(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
      child: GridView.builder(
        itemCount: establishments.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: UniquesControllers().data.baseSpace * 50,
          mainAxisSpacing: UniquesControllers().data.baseSpace,
          crossAxisSpacing: UniquesControllers().data.baseSpace,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (ctx, index) {
          final est = establishments[index];
          return ShopEstablishmentCard(
            index: 3 + index,
            establishment: est,
            onBuy: () => cc.buyEstablishment(est),
          );
        },
      ),
    );
  }
}
