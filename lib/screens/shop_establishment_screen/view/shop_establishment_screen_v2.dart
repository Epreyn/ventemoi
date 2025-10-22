import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../controllers/shop_establishment_screen_controller.dart';
import '../widgets/unified_establishment_card.dart';
import '../widgets/unified_mobile_card_fixed.dart'; // V1 - Conservé pour référence
import '../widgets/unified_mobile_card_v2.dart'; // V2 - Design minimaliste
import '../widgets/empty_state_widget.dart';
import '../widgets/special_offers_banner_v2.dart';

/// Version 2 de la page Shop - Design épuré et moderne
/// Garde toutes les fonctionnalités mais avec une UI/UX améliorée
class ShopEstablishmentScreenV2 extends StatefulWidget {
  const ShopEstablishmentScreenV2({Key? key}) : super(key: key);

  @override
  State<ShopEstablishmentScreenV2> createState() => _ShopEstablishmentScreenV2State();
}

class _ShopEstablishmentScreenV2State extends State<ShopEstablishmentScreenV2> {
  final ScrollController _scrollController = ScrollController();
  bool _bannerCollapsed = false; // État de la bannière
  static const double _maxBannerHeight = 240.0; // Hauteur augmentée pour meilleure visibilité
  static const double _minBannerHeight = 0.0;

  @override
  void initState() {
    super.initState();
    // Pas de listener de scroll - contrôle manuel uniquement
  }

  void _toggleBanner() {
    setState(() {
      _bannerCollapsed = !_bannerCollapsed;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ShopEstablishmentScreenController());

    return ScreenLayout(
      appBar: CustomAppBar(
        key: const ValueKey('shop_establishment_app_bar_v2'),
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
        showGreeting: true,
      ),
      noFAB: true,
      body: Column(
        children: [
          // Bannière toujours visible (sauf si masquée manuellement)
          if (!_bannerCollapsed)
            SizedBox(
              height: _maxBannerHeight,
              child: Stack(
                children: [
                  const SpecialOffersBannerV2(),
                  // Bouton chevron pour masquer - en bas à gauche
                  Positioned(
                    bottom: 4,
                    left: 16,
                    child: InkWell(
                      onTap: _toggleBanner,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: CustomTheme.lightScheme().primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bouton pour afficher la bannière si elle est masquée
          if (_bannerCollapsed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Center(
                child: InkWell(
                  onTap: _toggleBanner,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade200, Colors.orange.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🎁',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Offres du moment',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.orange.shade900,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

          // Header compact avec recherche et filtres
          _buildCompactHeader(cc),

          // Onglets avec badges de comptage
          _buildCompactTabs(cc),

          // Contenu
          Expanded(
            child: _buildContent(cc),
          ),
        ],
      ),
    );
  }

  /// Header compact avec recherche, filtres et toggle vue
  Widget _buildCompactHeader(ShopEstablishmentScreenController cc) {
    return Padding(
      padding: EdgeInsets.only(
        top: UniquesControllers().data.baseSpace * 2,
        left: UniquesControllers().data.baseSpace * 2,
        right: UniquesControllers().data.baseSpace * 2,
        bottom: UniquesControllers().data.baseSpace,
      ),
      child: Row(
        children: [
          // Barre de recherche compacte
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, size: 20, color: Colors.grey),
                  ),
                  Expanded(
                    child: Center(
                      child: Obx(() {
                        String hint = 'Rechercher...';
                        if (cc.selectedTabIndex.value == 0) {
                          hint = 'Partenaires, catégories...';
                        } else if (cc.selectedTabIndex.value == 1) {
                          hint = 'Commerces...';
                        } else if (cc.selectedTabIndex.value == 2) {
                          hint = 'Associations...';
                        } else if (cc.selectedTabIndex.value == 3) {
                          hint = 'Sponsors...';
                        }

                        return TextField(
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: cc.setSearchText,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton filtre avec badge
          Obx(() {
            final filterCount = cc.selectedTabIndex.value == 0
                ? cc.selectedEnterpriseCatIds.length
                : cc.selectedCatIds.length;

            return Stack(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: filterCount > 0
                        ? CustomTheme.lightScheme().primary.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: filterCount > 0
                          ? CustomTheme.lightScheme().primary
                          : Colors.grey[600],
                    ),
                    onPressed: () => _showFilterBottomSheet(cc),
                  ),
                ),
                if (filterCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CustomTheme.lightScheme().primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
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
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Onglets compacts avec badges de comptage
  Widget _buildCompactTabs(ShopEstablishmentScreenController cc) {
    return Padding(
      padding: EdgeInsets.only(
        left: UniquesControllers().data.baseSpace * 2,
        right: UniquesControllers().data.baseSpace * 2,
        top: UniquesControllers().data.baseSpace,
        bottom: UniquesControllers().data.baseSpace,
      ),
      child: SizedBox(
        height: 40,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 600;

            return Obx(() {
              return Row(
                children: [
                  _buildTabChip(cc, 0, 'Partenaires', Icons.business_rounded, isWideScreen),
                  const SizedBox(width: 8),
                  _buildTabChip(cc, 1, 'Commerces', Icons.store_rounded, isWideScreen),
                  const SizedBox(width: 8),
                  _buildTabChip(cc, 2, 'Associations', Icons.volunteer_activism_rounded, isWideScreen),
                  const SizedBox(width: 8),
                  _buildTabChip(cc, 3, 'Sponsors', Icons.workspace_premium_rounded, isWideScreen),
                ],
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildTabChip(ShopEstablishmentScreenController cc, int index, String label, IconData icon, bool isWideScreen) {
    final isSelected = cc.selectedTabIndex.value == index;

    // Compter les établissements pour ce tab
    int count = 0;
    final tName = ['Entreprise', 'Boutique', 'Association', 'Sponsor'][index];
    for (final e in cc.displayedEstablishments) {
      final estType = cc.userTypeNameCache[e.userId] ?? '';
      if (estType == tName) count++;
    }

    // Sur écran étroit : onglets non sélectionnés plus petits (juste l'icône)
    // Sur écran large : tous les onglets ont la même taille avec texte
    final showText = isWideScreen || isSelected;
    final useExpanded = isWideScreen || isSelected;

    final tabContent = GestureDetector(
      onTap: () => cc.selectedTabIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? CustomTheme.lightScheme().primary
              : Colors.transparent,
          border: isSelected
              ? null
              : Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: useExpanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Icône toujours affichée
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              // Texte et badge affichés sur écran large OU si sélectionné
              if (showText) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : CustomTheme.lightScheme().primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : CustomTheme.lightScheme().primary,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );

    // Sur écran large ou si sélectionné : utilise Expanded pour répartir l'espace
    // Sur écran étroit et non sélectionné : juste la taille du contenu (icône)
    if (useExpanded) {
      return Expanded(child: tabContent);
    } else {
      return tabContent;
    }
  }


  void _showFilterBottomSheet(ShopEstablishmentScreenController cc) {
    cc.localSelectedCatIds.value = Set<String>.from(cc.selectedCatIds.toList());
    cc.localSelectedEnterpriseCatIds.value =
        Set<String>.from(cc.selectedEnterpriseCatIds.toList());
    cc.localSelectedSponsorCatIds.value = Set<String>.from(cc.selectedSponsorCatIds.toList());

    cc.openBottomSheet(
      'Filtres avancés',
      subtitle: 'Toutes les catégories',
      hasAction: true,
      actionName: 'Appliquer',
      actionIcon: Icons.check_rounded,
      primaryColor: CustomTheme.lightScheme().primary,
      maxWidth: 600,
    );
  }

  Widget _buildContent(ShopEstablishmentScreenController cc) {
    return Obx(() {
      final establishments = cc.displayedEstablishments;
      final currentTab = cc.selectedTabIndex.value;

      if (establishments.isEmpty) {
        return const Center(child: EmptyStateWidget());
      }

      // Pas d'AnimatedSwitcher pour éviter le "saut"
      return _buildEstablishmentsList(establishments, cc, currentTab);
    });
  }

  Widget _buildEstablishmentsList(
    List<Establishment> establishments,
    ShopEstablishmentScreenController cc,
    int currentTab,
  ) {
    return LayoutBuilder(
      key: ValueKey('content_$currentTab'), // Force recréation quand onglet change
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Vue liste sur mobile
          return ListView.builder(
            key: ValueKey('listview_$currentTab'), // Force recréation complète du ListView
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: UniquesControllers().data.baseSpace * 2,
              right: UniquesControllers().data.baseSpace * 2,
              top: UniquesControllers().data.baseSpace,
              bottom: UniquesControllers().data.baseSpace * 2,
            ),
            itemCount: establishments.length,
            itemBuilder: (context, index) => _buildMobileCard(establishments[index], cc, index, currentTab),
          );
        } else {
          // Vue grille sur desktop/tablet uniquement
          return GridView.builder(
            key: ValueKey('gridview_$currentTab'), // Force recréation complète du GridView
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: UniquesControllers().data.baseSpace * 2,
              right: UniquesControllers().data.baseSpace * 2,
              top: UniquesControllers().data.baseSpace,
              bottom: UniquesControllers().data.baseSpace * 2,
            ),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 380,
              childAspectRatio: 0.75,
              crossAxisSpacing: UniquesControllers().data.baseSpace * 2,
              mainAxisSpacing: UniquesControllers().data.baseSpace * 2,
            ),
            itemCount: establishments.length,
            itemBuilder: (context, index) => _buildDesktopCard(establishments[index], cc, index, currentTab),
          );
        }
      },
    );
  }

  Widget _buildMobileCard(Establishment establishment, ShopEstablishmentScreenController cc, int index, int currentTab) {
    final tName = cc.userTypeNameCache[establishment.userId] ?? 'INVISIBLE';
    final isOwnEstablishment = cc.isOwnEstablishment(establishment.userId);

    return Padding(
      padding: EdgeInsets.only(bottom: UniquesControllers().data.baseSpace * 2),
      child: UnifiedMobileCardV2( // V2 - Design minimaliste
        key: ValueKey('mobile_v2_${currentTab}_${establishment.id}'),
        establishment: establishment,
        isOwnEstablishment: isOwnEstablishment,
        onBuy: (isOwnEstablishment || (tName != 'Boutique' && tName != 'Association'))
            ? null
            : () => cc.buyEstablishment(establishment),
        index: index,
        enterpriseCategoriesMap: tName == 'Entreprise' ? cc.enterpriseCategoriesMap : null,
        categoriesMap: (tName == 'Boutique' || tName == 'Association') ? cc.categoriesMap : null,
      ),
    );
  }

  Widget _buildDesktopCard(Establishment establishment, ShopEstablishmentScreenController cc, int index, int currentTab) {
    final tName = cc.userTypeNameCache[establishment.userId] ?? 'INVISIBLE';
    final isOwnEstablishment = cc.isOwnEstablishment(establishment.userId);

    return UnifiedEstablishmentCard(
      key: ValueKey('desktop_v2_${currentTab}_${establishment.id}'),
      establishment: establishment,
      onBuy: (isOwnEstablishment || (tName != 'Boutique' && tName != 'Association'))
          ? null
          : () => cc.buyEstablishment(establishment),
      index: index,
      isOwnEstablishment: isOwnEstablishment,
      enterpriseCategoriesMap: tName == 'Entreprise' ? cc.enterpriseCategoriesMap : null,
      categoriesMap: (tName == 'Boutique' || tName == 'Association') ? cc.categoriesMap : null,
    );
  }
}
