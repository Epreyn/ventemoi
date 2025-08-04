import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../controllers/shop_establishment_screen_controller.dart';
import '../widgets/shop_establishment_card.dart';
import '../widgets/enterprise_establishment_card.dart';
import '../widgets/empty_state_widget.dart';

class ShopEstablishmentScreen extends StatelessWidget {
  const ShopEstablishmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ShopEstablishmentScreenController());

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
        showGreeting: true,
      ),
      noFAB: true,
      body: Column(
        children: [
          _buildSearchBar(cc),
          _buildModernTabs(cc),
          _buildTabDescription(cc), // Nouvelle ligne pour les descriptions
          Expanded(
            child: _buildContent(cc),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ShopEstablishmentScreenController cc) {
    return Container(
      height: 56,
      margin: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 2,
        vertical: UniquesControllers().data.baseSpace,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              Icons.search,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un établissement...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: cc.setSearchText,
            ),
          ),
          Obx(() {
            final filterCount =
                cc.selectedTabIndex.value == 0 // Entreprises devenu Partenaires
                    ? cc.selectedEnterpriseCatIds.length
                    : cc.selectedCatIds.length;

            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: filterCount > 0
                        ? CustomTheme.lightScheme().primary
                        : Colors.grey[600],
                  ),
                  onPressed: () => _showFilterBottomSheet(cc),
                ),
                if (filterCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CustomTheme.lightScheme().primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildModernTabs(ShopEstablishmentScreenController cc) {
    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 2,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Obx(() => AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                left: cc.selectedTabIndex.value * (Get.width - 32) / 4,
                child: Container(
                  width: (Get.width - 32) / 4,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          Row(
            children: [
              _buildTabButton(cc, 0, 'Partenaires',
                  Icons.business), // Renommé Entreprises -> Partenaires
              _buildTabButton(cc, 1, 'Commerces',
                  Icons.redeem), // Renommé Boutiques -> Commerces
              _buildTabButton(cc, 2, 'Associations', Icons.volunteer_activism),
              _buildTabButton(cc, 3, 'Sponsors', Icons.handshake),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    ShopEstablishmentScreenController cc,
    int index,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => cc.selectedTabIndex.value = index,
        child: Container(
          height: 48,
          color: Colors.transparent,
          child: Obx(() {
            final isSelected = cc.selectedTabIndex.value == index;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? CustomTheme.lightScheme().primary
                      : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? CustomTheme.lightScheme().primary
                        : Colors.grey[600],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // Nouvelle méthode pour afficher les descriptions
  Widget _buildTabDescription(ShopEstablishmentScreenController cc) {
    return Obx(() {
      String description = '';
      switch (cc.selectedTabIndex.value) {
        case 0: // Partenaires (anciennement Entreprises)
          description =
              'Cumulez des points en vous fournissant via les entreprises partenaires de VenteMoi';
          break;
        case 1: // Commerces (anciennement Boutiques)
          description =
              'Utilisez vos points pour acheter des bons dans les commerces locaux participants';
          break;
        case 2: // Associations
          description =
              'Soutenez les associations locales en faisant des dons avec vos points';
          break;
        case 3: // Sponsors
          description =
              'Découvrez nos sponsors qui soutiennent l\'économie circulaire et solidaire';
          break;
      }

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 2,
          vertical: UniquesControllers().data.baseSpace,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 2,
          vertical: UniquesControllers().data.baseSpace,
        ),
        decoration: BoxDecoration(
          color: CustomTheme.lightScheme().primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CustomTheme.lightScheme().primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showFilterBottomSheet(ShopEstablishmentScreenController cc) {
    // Réinitialiser les sélections temporaires
    cc.localSelectedCatIds.value = Set.from(cc.selectedCatIds);
    cc.localSelectedEnterpriseCatIds.value =
        Set.from(cc.selectedEnterpriseCatIds);
    cc.localSelectedSponsorCatIds.value = Set.from(cc.selectedSponsorCatIds);

    cc.openBottomSheet(
      'Filtrer par catégorie',
      subtitle: 'Sélectionnez une ou plusieurs catégories',
      hasAction: true,
      actionName: 'Appliquer les filtres',
      actionIcon: Icons.filter_list,
      primaryColor: CustomTheme.lightScheme().primary,
      headerWidget: _buildFilterHeader(cc),
      maxWidth: 600,
    );
  }

  Widget _buildFilterHeader(ShopEstablishmentScreenController cc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CustomTheme.lightScheme().primary.withOpacity(0.1),
            CustomTheme.lightScheme().primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: CustomTheme.lightScheme().primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              int filterCount = 0;
              switch (cc.selectedTabIndex.value) {
                case 0: // Partenaires
                  filterCount = cc.selectedEnterpriseCatIds.length;
                  break;
                case 1: // Commerces
                case 2: // Associations
                  filterCount = cc.selectedCatIds.length;
                  break;
                case 3: // Sponsors
                  filterCount = cc.selectedSponsorCatIds.length;
                  break;
              }

              return Text(
                filterCount > 0
                    ? '$filterCount catégorie${filterCount > 1 ? 's' : ''} sélectionnée${filterCount > 1 ? 's' : ''}'
                    : 'Aucune catégorie sélectionnée',
                style: TextStyle(
                  fontSize: 14,
                  color: CustomTheme.lightScheme().primary,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ShopEstablishmentScreenController cc) {
    return Obx(() {
      final establishments = cc.displayedEstablishments;

      if (establishments.isEmpty) {
        return const EmptyStateWidget();
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildGrid(establishments, cc),
      );
    });
  }

  Widget _buildGrid(List<Establishment> establishments,
      ShopEstablishmentScreenController cc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double maxCardWidth = 500.0;
        const double minCardWidth = 400.0;

        int crossAxisCount = 1;
        if (constraints.maxWidth > minCardWidth * 1.5) {
          crossAxisCount = (constraints.maxWidth / minCardWidth).floor();
          final cardWidth = constraints.maxWidth / crossAxisCount;
          if (cardWidth > maxCardWidth) {
            crossAxisCount = (constraints.maxWidth / maxCardWidth).ceil();
          }
        }

        return GridView.builder(
          padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: UniquesControllers().data.baseSpace * 2,
            mainAxisSpacing: UniquesControllers().data.baseSpace * 2,
          ),
          itemCount: establishments.length,
          itemBuilder: (context, index) {
            final establishment = establishments[index];
            final tName =
                cc.userTypeNameCache[establishment.userId] ?? 'INVISIBLE';

            // Utiliser la bonne carte selon le type
            if (tName == 'Entreprise') {
              return EnterpriseEstablishmentCard(
                establishment: establishment,
                index: index,
                enterpriseCategoriesMap: cc.enterpriseCategoriesMap,
              );
            } else {
              return ShopEstablishmentCard(
                establishment: establishment,
                onBuy: () => cc.buyEstablishment(establishment),
                index: index,
              );
            }
          },
        );
      },
    );
  }

  List<Widget> _buildCategoryChips(ShopEstablishmentScreenController cc) {
    final isEnterprise = cc.selectedTabIndex.value == 2;
    final categories =
        isEnterprise ? cc.enterpriseCategoriesMap : cc.categoriesMap;
    final selectedIds = isEnterprise
        ? cc.localSelectedEnterpriseCatIds
        : cc.localSelectedCatIds;

    if (categories.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.category_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune catégorie disponible',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return categories.entries.map((entry) {
      final isSelected = selectedIds.contains(entry.key);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              selectedIds.add(entry.key);
            } else {
              selectedIds.remove(entry.key);
            }
          },
          avatar: isSelected
              ? const Icon(Icons.check_circle, size: 18)
              : Icon(
                  Icons.circle_outlined,
                  size: 18,
                  color: Colors.grey[400],
                ),
          selectedColor: CustomTheme.lightScheme().primary.withOpacity(0.2),
          checkmarkColor: CustomTheme.lightScheme().primary,
          backgroundColor: Colors.grey[100],
          side: BorderSide(
            color: isSelected
                ? CustomTheme.lightScheme().primary
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }).toList();
  }
}
