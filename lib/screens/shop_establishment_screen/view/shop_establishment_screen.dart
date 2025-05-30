import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/shop_establishment_screen_controller.dart';

// Widgets
import '../widgets/shop_establishment_card.dart';
import '../widgets/enterprise_establishment_card.dart';
import '../widgets/shop_establishment_search_bar.dart';

class ShopEstablishmentScreen extends StatelessWidget {
  const ShopEstablishmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ShopEstablishmentScreenController());

    return ScreenLayout(
      noFAB: true,
      body: DefaultTabController(
        length: 3, // 0 => Boutiques, 1 => Associations, 2 => Entreprises
        child: Column(
          children: [
            // --- En-tête : zone de recherche + filtres (varie selon l'onglet) ---
            _buildSearchAndFilters(cc),

            // --- Barre d'onglets ---
            TabBar(
              onTap: (index) => cc.selectedTabIndex.value = index,
              tabs: const [
                Tab(text: 'Boutiques'),
                Tab(text: 'Associations'),
                Tab(text: 'Entreprises'),
              ],
            ),

            // --- Contenu : un TabBarView avec 3 onglets ---
            Expanded(
              child: Obx(() {
                final list = cc.displayedEstablishments;
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Aucun établissement trouvé'),
                  );
                }

                return TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Onglet 0 : Boutiques
                    _buildGridView(list, cc, tabIndex: 0),
                    // Onglet 1 : Associations
                    _buildGridView(list, cc, tabIndex: 1),
                    // Onglet 2 : Entreprises
                    _buildGridView(list, cc, tabIndex: 2),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche la barre de recherche et les filtres,
  /// qui varient selon l'onglet sélectionné (`cc.selectedTabIndex`).
  Widget _buildSearchAndFilters(ShopEstablishmentScreenController cc) {
    return Padding(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
      child: Obx(() {
        final currentTab = cc.selectedTabIndex.value;

        if (currentTab == 2) {
          // --- ONGLET ENTREPRISES ---
          return Column(
            children: [
              // Barre de recherche simplifiée
              Padding(
                padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une entreprise',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(90)),
                    ),
                  ),
                  onChanged: cc.setSearchText, // => filter
                ),
              ),
              SizedBox(height: UniquesControllers().data.baseSpace * 1.5),

              // Filtres => enterpriseCategoriesMap + selectedEnterpriseCatIds
              Row(
                children: [
                  // Affichage des chips pour chaque catId sélectionné
                  ...cc.selectedEnterpriseCatIds.map((catId) {
                    final cName = cc.enterpriseCategoriesMap[catId] ?? catId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(cName),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          cc.selectedEnterpriseCatIds.remove(catId);
                          cc.filterEstablishments();
                        },
                      ),
                    );
                  }).toList(),

                  const Spacer(),

                  // Bouton "Filtres"
                  ElevatedButton.icon(
                    onPressed: () {
                      // bottomSheet => applique => selectedEnterpriseCatIds
                      cc.openBottomSheet(
                        'Filtres',
                        actionName: 'Appliquer',
                        actionIcon: Icons.check,
                      );
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtres'),
                  ),
                ],
              ),
            ],
          );
        } else {
          // --- ONGLET 0 => BOUTIQUES, 1 => ASSOCIATIONS ---
          return Column(
            children: [
              // Barre de recherche "ShopEstablishmentSearchBar"
              ShopEstablishmentSearchBar(controller: cc),
              SizedBox(height: UniquesControllers().data.baseSpace * 1.5),

              // Filtres => categoriesMap + selectedCatIds
              Row(
                children: [
                  ...cc.selectedCatIds.map((catId) {
                    final cName = cc.categoriesMap[catId] ?? catId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(cName),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          cc.selectedCatIds.remove(catId);
                          cc.filterEstablishments();
                        },
                      ),
                    );
                  }).toList(),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      cc.openBottomSheet(
                        'Filtres',
                        actionName: 'Appliquer',
                        actionIcon: Icons.check,
                      );
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtres'),
                  ),
                ],
              ),
            ],
          );
        }
      }),
    );
  }

  /// Affiche la grille pour l'onglet [tabIndex].
  /// - si tabIndex==2 (Entreprises), on utilise `EnterpriseEstablishmentCard`
  /// - sinon, on utilise `ShopEstablishmentCard`.
  Widget _buildGridView(
    List establishments,
    ShopEstablishmentScreenController cc, {
    required int tabIndex,
  }) {
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

          // Si on est dans l'onglet "Entreprises"
          if (tabIndex == 2) {
            // Affiche le widget EnterpriseEstablishmentCard
            return EnterpriseEstablishmentCard(
              index: 3 + index,
              establishment: est,
              enterpriseCategoriesMap: cc.enterpriseCategoriesMap,
            );
          } else {
            // Boutique ou Association => ShopEstablishmentCard (avec bouton "Acheter/Donner")
            return ShopEstablishmentCard(
              index: 3 + index,
              establishment: est,
              onBuy: () => cc.buyEstablishment(est),
            );
          }
        },
      ),
    );
  }
}
