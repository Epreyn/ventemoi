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
import '../widgets/shop_establishment_mobile_card.dart';
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
          _buildTabDescription(cc),
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
            final filterCount = cc.selectedTabIndex.value == 0
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajustement des breakpoints pour le responsive
        final isSmallScreen = constraints.maxWidth < 450; // Réduit de 500 à 450
        final isVerySmallScreen =
            constraints.maxWidth < 380; // Pour les très petits écrans

        return Container(
          height: 48,
          margin: EdgeInsets.symmetric(
            horizontal: UniquesControllers().data.baseSpace * 2,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth;
              final tabWidth = containerWidth / 4;

              return Stack(
                children: [
                  Obx(() => AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutExpo,
                        left: cc.selectedTabIndex.value * tabWidth,
                        child: Container(
                          width: tabWidth,
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
                      _buildResponsiveTabButton(cc, 0, 'Partenaires',
                          Icons.business, isVerySmallScreen || isSmallScreen),
                      _buildResponsiveTabButton(cc, 1, 'Commerces', Icons.store,
                          isVerySmallScreen || isSmallScreen),
                      _buildResponsiveTabButton(
                          cc,
                          2,
                          'Associations',
                          Icons.volunteer_activism,
                          isVerySmallScreen || isSmallScreen),
                      _buildResponsiveTabButton(cc, 3, 'Sponsors',
                          Icons.handshake, isVerySmallScreen || isSmallScreen),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildResponsiveTabButton(
    ShopEstablishmentScreenController cc,
    int index,
    String label,
    IconData icon,
    bool isSmallScreen,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => cc.selectedTabIndex.value = index,
        child: Container(
          height: 48,
          color: Colors.transparent,
          child: Obx(() {
            final isSelected = cc.selectedTabIndex.value == index;

            // Sur petits écrans, afficher icône seule si non sélectionné
            // et icône + texte si sélectionné
            if (isSmallScreen && !isSelected) {
              return Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: Colors.grey[600],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12), // Ajout du padding horizontal
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: isSmallScreen ? 18 : 20,
                    color: isSelected
                        ? CustomTheme.lightScheme().primary
                        : Colors.grey[600],
                  ),
                  if (!isSmallScreen || isSelected) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        // Ajout de FittedBox pour ajuster le texte
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? CustomTheme.lightScheme().primary
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabDescription(ShopEstablishmentScreenController cc) {
    return Obx(() {
      String description = '';
      Widget richDescription;

      switch (cc.selectedTabIndex.value) {
        case 0: // Partenaires
          richDescription = RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: 'Cumulez des points',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CustomTheme.lightScheme().primary,
                  ),
                ),
                const TextSpan(
                  text: ' en vous fournissant via les ',
                ),
                TextSpan(
                  text: 'entreprises partenaires',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const TextSpan(
                  text: ' de VenteMoi',
                ),
              ],
            ),
          );
          break;
        case 1: // Commerces
          richDescription = RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: 'Utilisez vos points',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CustomTheme.lightScheme().primary,
                  ),
                ),
                const TextSpan(
                  text: ' pour acheter des bons dans les ',
                ),
                TextSpan(
                  text: 'commerces locaux',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const TextSpan(
                  text: ' participants',
                ),
              ],
            ),
          );
          break;
        case 2: // Associations
          richDescription = RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: 'Soutenez',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CustomTheme.lightScheme().primary,
                  ),
                ),
                const TextSpan(
                  text: ' les ',
                ),
                TextSpan(
                  text: 'associations locales',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const TextSpan(
                  text: ' en faisant des ',
                ),
                TextSpan(
                  text: 'dons avec vos points',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CustomTheme.lightScheme().primary,
                  ),
                ),
              ],
            ),
          );
          break;
        case 3: // Sponsors
          richDescription = RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: 'Découvrez nos ',
                ),
                TextSpan(
                  text: 'sponsors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CustomTheme.lightScheme().primary,
                  ),
                ),
                const TextSpan(
                  text: ' qui soutiennent ',
                ),
                TextSpan(
                  text: 'l\'économie circulaire et solidaire',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          );
          break;
        default:
          richDescription = Text('');
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
              child: richDescription,
            ),
          ],
        ),
      );
    });
  }

  void _showFilterBottomSheet(ShopEstablishmentScreenController cc) {
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
        // Détection mobile vs desktop
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Format liste horizontale condensée sur mobile
          return ListView.builder(
            padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
            itemCount: establishments.length,
            itemBuilder: (context, index) {
              final establishment = establishments[index];
              final tName =
                  cc.userTypeNameCache[establishment.userId] ?? 'INVISIBLE';
              final isOwnEstablishment =
                  cc.isOwnEstablishment(establishment.userId);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: UniquesControllers().data.baseSpace * 2,
                ),
                child: ShopEstablishmentMobileCard(
                  establishment: establishment,
                  isEnterprise: tName == 'Entreprise',
                  isOwnEstablishment: isOwnEstablishment,
                  onBuy: isOwnEstablishment
                      ? null
                      : () => cc.buyEstablishment(establishment),
                  index: index,
                  enterpriseCategoriesMap: cc.enterpriseCategoriesMap,
                ),
              );
            },
          );
        } else {
          // Format grille sur desktop
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
              final isOwnEstablishment =
                  cc.isOwnEstablishment(establishment.userId);

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
                  onBuy: isOwnEstablishment
                      ? null
                      : () => cc.buyEstablishment(establishment),
                  index: index,
                  isOwnEstablishment: isOwnEstablishment,
                );
              }
            },
          );
        }
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
