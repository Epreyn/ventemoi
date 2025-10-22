import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../controllers/shop_establishment_screen_controller.dart';
import '../widgets/unified_establishment_card.dart';
import '../widgets/unified_mobile_card_fixed.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/special_offers_banner.dart';

class ShopEstablishmentScreen extends StatefulWidget {
  const ShopEstablishmentScreen({Key? key}) : super(key: key);

  @override
  State<ShopEstablishmentScreen> createState() => _ShopEstablishmentScreenState();
}

class _ShopEstablishmentScreenState extends State<ShopEstablishmentScreen> {
  late ScrollController _scrollController;
  late ScrollController _bannerScrollController;
  double _bannerHeight = 150.0; // Hauteur initiale de la bannière
  static const double _maxBannerHeight = 150.0;
  bool _bannerIsHidden = false;
  bool _isScrolling = false;
  Timer? _scrollEndTimer;
  bool _isScrollingGrid = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _bannerScrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final offset = _scrollController.offset;
        final newHeight = (_maxBannerHeight - offset).clamp(0.0, _maxBannerHeight);
        if ((newHeight - _bannerHeight).abs() > 1) {
          setState(() {
            _bannerHeight = newHeight;
            _bannerIsHidden = _bannerHeight < 1.0;
          });
        }
      }
    });
  }


  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _scrollController.dispose();
    _bannerScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ShopEstablishmentScreenController());

    return ScreenLayout(
      appBar: CustomAppBar(
        key: const ValueKey('shop_establishment_app_bar'),
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
        showGreeting: true,
      ),
      noFAB: true,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          // Mettre à jour la hauteur de la bannière en fonction du scroll
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final offset = _scrollController.offset;
              final newHeight = (_maxBannerHeight - offset).clamp(0.0, _maxBannerHeight);
              if ((newHeight - _bannerHeight).abs() > 1) {
                setState(() {
                  _bannerHeight = newHeight;
                  _bannerIsHidden = _bannerHeight < 1.0;
                });
              }
            }
          });

          return <Widget>[
            // Bannière collapsible
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: _maxBannerHeight,
              floating: false,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(
                background: const SpecialOffersBanner(
                  key: ValueKey('special_offers_banner'),
                ),
                collapseMode: CollapseMode.parallax,
              ),
            ),
            // Section fixe avec recherche, onglets et description
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                minHeight: 210,
                maxHeight: 210,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      _buildSearchBar(cc),
                      _buildModernTabs(cc),
                      _buildTabDescription(cc),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildContent(cc),
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
            child: Obx(() {
              String hintText = 'Rechercher un établissement...';
              if (cc.selectedTabIndex.value == 0) {
                hintText = 'Rechercher (nom, description, catégories)...';
              }
              return TextField(
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: cc.setSearchText,
              );
            }),
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
        onTap: () {
          cc.selectedTabIndex.value = index;
        },
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
    cc.localSelectedCatIds.value = Set<String>.from(cc.selectedCatIds.toList());
    cc.localSelectedEnterpriseCatIds.value =
        Set<String>.from(cc.selectedEnterpriseCatIds.toList());
    cc.localSelectedSponsorCatIds.value = Set<String>.from(cc.selectedSponsorCatIds.toList());

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
      final currentTab = cc.selectedTabIndex.value;

      if (establishments.isEmpty) {
        return const Center(child: EmptyStateWidget());
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildGrid(establishments, cc, key: ValueKey('grid_tab_$currentTab')),
      );
    });
  }

  Widget _buildGrid(List<Establishment> establishments,
      ShopEstablishmentScreenController cc, {Key? key}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        // Définir les breakpoints et tailles de cartes
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final bool isSmallDesktop = constraints.maxWidth >= 900 && constraints.maxWidth < 1400;
        final bool isLargeDesktop = constraints.maxWidth >= 1400;

        if (isMobile) {
          // Format liste horizontale condensée sur mobile avec carte unifiée
          return ListView.builder(
            controller: cc.getCurrentScrollController(),
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
                child: UnifiedMobileCardFixed(
                  key: ValueKey('unified_mobile_${establishment.id}'),
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
            },
          );
        } else {
          // Format grille adaptatif avec taille maximale variable selon l'écran
          double maxCardWidth;
          double aspectRatio;

          if (isTablet) {
            maxCardWidth = 350.0; // Cartes plus petites sur tablette
            aspectRatio = 0.8;
          } else if (isSmallDesktop) {
            maxCardWidth = 380.0; // Taille moyenne sur petit desktop
            aspectRatio = 0.75;
          } else {
            maxCardWidth = 420.0; // Taille max sur grand écran
            aspectRatio = 0.75;
          }

          return GridView.builder(
            controller: cc.getCurrentScrollController(),
            padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCardWidth,
              childAspectRatio: aspectRatio,
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

              // Utiliser la carte unifiée pour desktop/tablet
              return UnifiedEstablishmentCard(
                key: ValueKey('unified_${establishment.id}'),
                establishment: establishment,
                onBuy: (isOwnEstablishment || (tName != 'Boutique' && tName != 'Association'))
                    ? null
                    : () => cc.buyEstablishment(establishment),
                index: index,
                isOwnEstablishment: isOwnEstablishment,
                enterpriseCategoriesMap: tName == 'Entreprise' ? cc.enterpriseCategoriesMap : null,
                categoriesMap: (tName == 'Boutique' || tName == 'Association') ? cc.categoriesMap : null,
              );
            },
          );
        }
      },
    );
  }

}

// Delegate pour le header sticky
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: shrinkOffset > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

