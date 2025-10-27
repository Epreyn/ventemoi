import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import 'establishment_detail_popup_v3.dart';

/// Carte compacte et stylisée pour desktop/tablet
/// Affiche uniquement les infos essentielles
/// Toutes les actions sont dans le popup au clic
class CompactEstablishmentCardV2 extends StatefulWidget {
  final Establishment establishment;
  final bool isOwnEstablishment;
  final VoidCallback? onBuy;
  final int index;
  final RxMap<String, String>? enterpriseCategoriesMap;
  final RxMap<String, String>? categoriesMap;

  const CompactEstablishmentCardV2({
    Key? key,
    required this.establishment,
    required this.isOwnEstablishment,
    this.onBuy,
    required this.index,
    this.enterpriseCategoriesMap,
    this.categoriesMap,
  }) : super(key: key);

  @override
  State<CompactEstablishmentCardV2> createState() =>
      _CompactEstablishmentCardV2State();
}

class _CompactEstablishmentCardV2State
    extends State<CompactEstablishmentCardV2> {
  String _userTypeName = '';
  int _availableCoupons = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final typeName = await _getUserTypeName();
    final coupons = await _loadAvailableCoupons();
    if (mounted) {
      setState(() {
        _userTypeName = typeName;
        _availableCoupons = coupons;
      });
    }
  }

  Future<int> _loadAvailableCoupons() async {
    try {
      final walletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: widget.establishment.userId)
          .limit(1)
          .get();

      if (walletQuery.docs.isNotEmpty) {
        final data = walletQuery.docs.first.data();
        return data['coupons'] ?? 0;
      }
    } catch (e) {
      // Ignorer les erreurs
    }
    return 0;
  }

  Future<String> _getUserTypeName() async {
    try {
      if (widget.establishment.userId.isEmpty) return '';

      final userDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(widget.establishment.userId)
          .get();

      if (!userDoc.exists) return '';

      final userData = userDoc.data() as Map<String, dynamic>;
      final typeId = userData['user_type_id'] ?? '';

      if (typeId.isEmpty) return '';

      final typeDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .doc(typeId)
          .get();

      if (!typeDoc.exists) return '';

      final typeData = typeDoc.data() as Map<String, dynamic>;
      return typeData['name'] ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnterprise = _userTypeName == 'Entreprise';
    final isSponsor = _userTypeName == 'Sponsor';
    final isAssociation = _userTypeName == 'Association';
    final isBoutique =
        _userTypeName == 'Boutique' || _userTypeName == 'Commerçant';

    return CustomCardAnimation(
      index: widget.index,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _openDetailPopup,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, _isHovered ? -6.0 : 0.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? CustomTheme.lightScheme().primary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: _isHovered ? 24 : 12,
                  offset: Offset(0, _isHovered ? 10 : 4),
                  spreadRadius: _isHovered ? 3 : 0,
                ),
              ],
              border: widget.isOwnEstablishment
                  ? Border.all(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.5),
                      width: 2,
                    )
                  : (isAssociation && !widget.establishment.isVisible)
                      ? Border.all(
                          color: Colors.orange.withOpacity(0.5),
                          width: 1.5,
                        )
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image compacte avec overlay
                _buildCompactImage(isEnterprise, isSponsor, isAssociation),

                // Contenu minimal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom uniquement
                        Text(
                          widget.establishment.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Adresse courte
                        if (widget.establishment.address.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.establishment.address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        const Spacer(),

                        // Catégories avec compteur
                        _buildCategoryWithCounter(isEnterprise),

                        const SizedBox(height: 8),

                        // Bouton "Voir plus" - Plus petit pour éviter overflow
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _openDetailPopup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  CustomTheme.lightScheme().primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Voir plus',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward,
                                    size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactImage(
      bool isEnterprise, bool isSponsor, bool isAssociation) {
    final hasImage = widget.establishment.bannerUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond
            if (hasImage)
              Image.network(
                widget.establishment.bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CustomTheme.lightScheme().primary.withOpacity(0.2),
                        CustomTheme.lightScheme().primary.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CustomTheme.lightScheme().primary.withOpacity(0.2),
                      CustomTheme.lightScheme().primary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.business,
                  size: 56,
                  color: CustomTheme.lightScheme().primary.withOpacity(0.4),
                ),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(hasImage ? 0.4 : 0.2),
                  ],
                ),
              ),
            ),

            // Badge type (petit, coin supérieur gauche)
            Positioned(
              top: 10,
              left: 10,
              child: _buildCompactTypeBadge(
                  isEnterprise, isSponsor, isAssociation),
            ),

            // Logo (petit, coin supérieur droit)
            if (widget.establishment.logoUrl.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.establishment.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.store,
                        color: CustomTheme.lightScheme().primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Badge bons disponibles (pour boutiques/commerces)
            if (_availableCoupons > 0 && !isEnterprise)
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomTheme.lightScheme().primary.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$_availableCoupons',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Badge cashback (pour entreprises)
            if (isEnterprise && widget.establishment.cashbackPercentage > 0)
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.establishment.cashbackPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTypeBadge(
      bool isEnterprise, bool isSponsor, bool isAssociation) {
    Color badgeColor;
    IconData badgeIcon;

    if (isSponsor) {
      badgeColor = const Color(0xFFCD7F32); // Bronze par défaut
      badgeIcon = Icons.workspace_premium;
    } else if (isAssociation) {
      badgeColor = Colors.green;
      badgeIcon = Icons.volunteer_activism;
    } else if (isEnterprise) {
      badgeColor = Colors.blue;
      badgeIcon = Icons.business;
    } else {
      badgeColor = CustomTheme.lightScheme().primary;
      badgeIcon = Icons.store;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(badgeIcon, size: 12, color: Colors.white),
    );
  }

  Widget _buildCategoryWithCounter(bool isEnterprise) {
    String? categoryName;
    int totalCategories = 0;

    if (isEnterprise && widget.enterpriseCategoriesMap != null) {
      final catIds = widget.establishment.enterpriseCategoryIds ?? [];
      totalCategories = catIds.length;
      if (catIds.isNotEmpty) {
        categoryName = widget.enterpriseCategoriesMap!.value[catIds.first];
      }
    } else if (widget.categoriesMap != null) {
      final catId = widget.establishment.categoryId;
      if (catId.isNotEmpty) {
        categoryName = widget.categoriesMap!.value[catId];
        totalCategories = 1;
      }
    }

    if (categoryName == null) return const SizedBox.shrink();

    final remaining = totalCategories - 1;

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: CustomTheme.lightScheme().primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CustomTheme.lightScheme().primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              categoryName,
              style: TextStyle(
                fontSize: 11,
                color: CustomTheme.lightScheme().primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (remaining > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openDetailPopup() {
    // Préparer les noms de catégories
    final List<String> categoryNames = [];
    final isEnterprise = _userTypeName == 'Entreprise';

    if (isEnterprise && widget.enterpriseCategoriesMap != null) {
      final catIds = widget.establishment.enterpriseCategoryIds ?? [];
      for (final id in catIds) {
        final name = widget.enterpriseCategoriesMap!.value[id];
        if (name != null) categoryNames.add(name);
      }
    } else if (widget.categoriesMap != null) {
      final catId = widget.establishment.categoryId;
      if (catId.isNotEmpty) {
        final name = widget.categoriesMap!.value[catId];
        if (name != null) categoryNames.add(name);
      }
    }

    Get.dialog(
      EstablishmentDetailPopupV3(
        establishment: widget.establishment,
        userTypeName: _userTypeName,
        availableCoupons: _availableCoupons,
        onBuy: widget.onBuy,
        isOwnEstablishment: widget.isOwnEstablishment,
        categoryNames: categoryNames,
      ),
      barrierDismissible: true,
    );
  }
}
