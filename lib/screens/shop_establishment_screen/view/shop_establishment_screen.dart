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
import '../widgets/shop_establishment_card.dart';
import '../widgets/enterprise_establishment_card.dart';
import '../widgets/shop_establishment_mobile_card.dart';
import '../widgets/sponsor_establishment_card.dart';
import '../widgets/sponsor_card_styled.dart';
import '../widgets/sponsor_mobile_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/special_offers_banner.dart';

class ShopEstablishmentScreen extends StatefulWidget {
  const ShopEstablishmentScreen({Key? key}) : super(key: key);

  @override
  State<ShopEstablishmentScreen> createState() => _ShopEstablishmentScreenState();
}

class _ShopEstablishmentScreenState extends State<ShopEstablishmentScreen> {
  late ScrollController _scrollController;
  double _bannerHeight = 150.0; // Hauteur initiale de la bannière
  static const double _maxBannerHeight = 150.0;
  bool _bannerIsHidden = false;
  bool _isScrolling = false;
  Timer? _scrollEndTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentPosition = _scrollController.position.pixels;
    double targetHeight;

    // Phase 1: Cacher la bannière (0 à 150 pixels de scroll)
    if (currentPosition <= 0) {
      targetHeight = _maxBannerHeight;
    } else if (currentPosition >= _maxBannerHeight) {
      targetHeight = 0;
    } else {
      targetHeight = _maxBannerHeight - currentPosition;
    }

    // Ne mettre à jour que si la différence est significative
    if ((targetHeight - _bannerHeight).abs() > 3.0) {
      setState(() {
        _bannerHeight = targetHeight.clamp(0.0, _maxBannerHeight);
        _bannerIsHidden = _bannerHeight < 1.0;
      });
    }

    // Détecter la fin du scroll pour snap
    _isScrolling = true;
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 150), () {
      _snapBanner();
    });
  }

  void _snapBanner() {
    if (!_scrollController.hasClients) return;

    final currentPosition = _scrollController.position.pixels;

    // Si on est dans la zone de la bannière, on snap
    if (currentPosition > 10 && currentPosition < _maxBannerHeight - 10) {
      // Si on est plus proche du haut (< 75px), on remonte
      if (currentPosition < 75) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        // Sinon on cache la bannière mais on s'arrête là
        // pour que la barre de recherche reste visible
        _scrollController.animateTo(
          _maxBannerHeight,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
    _isScrolling = false;
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _scrollController.dispose();
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
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Bannière avec animation de hauteur
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: _isScrolling
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                height: _bannerHeight,
                child: _bannerHeight > 0
                    ? ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 0,
                          maxHeight: _maxBannerHeight,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: _bannerHeight > 20 ? 1.0 : _bannerHeight / 20,
                            child: const SpecialOffersBanner(),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            // Section épinglée contenant barre de recherche, onglets et description
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
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
        // Définir les breakpoints et tailles de cartes
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final bool isSmallDesktop = constraints.maxWidth >= 900 && constraints.maxWidth < 1400;
        final bool isLargeDesktop = constraints.maxWidth >= 1400;

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

              // Pour les sponsors sur mobile, utiliser la carte mobile dédiée
              if (tName == 'Sponsor') {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: UniquesControllers().data.baseSpace * 2,
                  ),
                  child: SponsorMobileCard(
                    establishment: establishment,
                    index: index,
                    isOwnEstablishment: isOwnEstablishment,
                  ),
                );
              }

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

              // Utiliser la bonne carte selon le type et l'onglet
              if (cc.selectedTabIndex.value == 3) {
                // Onglet Sponsors - utiliser la carte stylisée
                return SponsorCardStyled(
                  establishment: establishment,
                  index: index,
                  isOwnEstablishment: isOwnEstablishment,
                );
              } else if (tName == 'Entreprise') {
                return EnterpriseEstablishmentCard(
                  establishment: establishment,
                  index: index,
                  enterpriseCategoriesMap: cc.enterpriseCategoriesMap,
                );
              } else if (tName == 'Sponsor') {
                // Les sponsors utilisent la carte stylisée même en dehors de l'onglet 3
                return SponsorCardStyled(
                  establishment: establishment,
                  index: index,
                  isOwnEstablishment: isOwnEstablishment,
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

// Delegate pour la section épinglée (recherche + onglets + description)
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent {
    // Calcul précis des hauteurs :
    // Barre de recherche: 56 + marges (16*2) = 72
    // Onglets: 48 + marge bottom (8) = 56
    // Description: variable mais environ 60-80
    return 210.0;
  }

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Ajouter une ombre quand le header est épinglé
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
    return child != oldDelegate.child;
  }
}
