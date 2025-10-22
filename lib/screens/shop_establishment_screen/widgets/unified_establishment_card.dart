import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../quotes_screen/controllers/quotes_screen_controller.dart';
import '../../quotes_screen/widgets/quote_form_dialog.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../controllers/shop_establishment_card_controller.dart';

class UnifiedEstablishmentCard extends StatefulWidget {
  final Establishment establishment;
  final VoidCallback? onBuy;
  final int index;
  final bool isOwnEstablishment;
  final RxMap<String, String>? enterpriseCategoriesMap;
  final RxMap<String, String>? categoriesMap;

  const UnifiedEstablishmentCard({
    super.key,
    required this.establishment,
    this.onBuy,
    required this.index,
    this.isOwnEstablishment = false,
    this.enterpriseCategoriesMap,
    this.categoriesMap,
  });

  @override
  State<UnifiedEstablishmentCard> createState() => _UnifiedEstablishmentCardState();
}

class _UnifiedEstablishmentCardState extends State<UnifiedEstablishmentCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  bool _showFullDescription = false;
  String _userTypeName = '';
  String _sponsorLevel = 'bronze';
  late ScrollController _categoriesScrollController;
  Timer? _autoScrollTimer;
  int _availableCoupons = 0; // Stocker le nombre de bons

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _categoriesScrollController = ScrollController();
    _loadUserType();
    _loadSponsorLevel();
    _loadAvailableCoupons(); // Charger les bons une seule fois
    // DÉSACTIVÉ : Auto-scroll qui peut causer des crashes
    // _startAutoScroll();
  }

  @override
  void dispose() {
    _categoriesScrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.establishment.enterpriseCategoryIds != null &&
        widget.establishment.enterpriseCategoryIds!.length > 3) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_categoriesScrollController.hasClients) {
          final maxScroll = _categoriesScrollController.position.maxScrollExtent;
          final currentScroll = _categoriesScrollController.offset;
          final nextScroll = currentScroll + 100;

          if (nextScroll >= maxScroll) {
            _categoriesScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            _categoriesScrollController.animateTo(
              nextScroll,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  Future<void> _loadUserType() async {
    final typeName = await _fetchUserTypeName(widget.establishment.userId);
    if (mounted) {
      setState(() {
        _userTypeName = typeName;
      });
    }
  }

  Future<void> _loadSponsorLevel() async {
    if (_userTypeName == 'Sponsor') {
      final level = await _fetchSponsorLevel();
      if (mounted) {
        setState(() {
          _sponsorLevel = level;
        });
      }
    }
  }

  Future<void> _loadAvailableCoupons() async {
    try {
      final walletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: widget.establishment.userId)
          .limit(1)
          .get();

      if (walletQuery.docs.isNotEmpty && mounted) {
        final data = walletQuery.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _availableCoupons = data['coupons'] ?? 0;
        });
      }
    } catch (e) {
      // En cas d'erreur, on met 0 bons
      if (mounted) {
        setState(() {
          _availableCoupons = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Réactivation du contrôleur Get
    final cc = Get.put(
      ShopEstablishmentCardController(),
      tag: 'shop-establishment-card-controller-${widget.establishment.id}',
    );

    return CustomCardAnimation(
      index: widget.index,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cardWidth = constraints.maxWidth;
          final widthScale = cardWidth / 300.0;

          final isEnterprise = _userTypeName == 'Entreprise';
          final isSponsor = _userTypeName == 'Sponsor';
          final isAssociation = _userTypeName == 'Association';
          final isBoutique = _userTypeName == 'Boutique' || _userTypeName == 'Commerçant';

          return Card(
            elevation: UniquesControllers().data.baseSpace,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                UniquesControllers().data.baseSpace * 2,
              ),
              side: widget.isOwnEstablishment
                  ? BorderSide(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                      width: 2,
                    )
                  : (isAssociation && !widget.establishment.isVisible)
                      ? BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1.5,
                        )
                      : BorderSide.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER avec Logo, Nom et Badge spécifique
                Container(
                  padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      _buildCompactLogo(isEnterprise, isSponsor),
                      SizedBox(width: UniquesControllers().data.baseSpace * 2),
                      // Infos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom avec badge "Vous"
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.establishment.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18 * widthScale,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isOwnEstablishment)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CustomTheme.lightScheme()
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Vous',
                                      style: TextStyle(
                                        fontSize: 11 * widthScale,
                                        color: CustomTheme.lightScheme().primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Message pour associations non visibles
                            if (isAssociation && !widget.establishment.isVisible)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16 * widthScale,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Cette association sera visible dès qu\'un don sera effectué',
                                        style: TextStyle(
                                          fontSize: 12 * widthScale,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Description supprimée d'ici, sera sur l'image
                          ],
                        ),
                      ),
                      // Badge en haut à droite selon le type
                      _buildTopRightBadge(isEnterprise, isSponsor, widthScale),
                    ],
                  ),
                ),

                // Catégories avec hauteur limitée
                _buildCategories(cc, isEnterprise, widthScale),
                SizedBox(height: UniquesControllers().data.baseSpace),

                // BANNIÈRE IMAGE AVEC DESCRIPTION EN OVERLAY
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        UniquesControllers().data.baseSpace,
                      ),
                      color: widget.establishment.bannerUrl.isEmpty
                          ? Colors.grey[100]
                          : null,
                      image: widget.establishment.bannerUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(widget.establishment.bannerUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Dégradé pour la lisibilité du texte
                        if (widget.establishment.bannerUrl.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                UniquesControllers().data.baseSpace,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: const [0.4, 1.0],
                              ),
                            ),
                          ),
                        // Description en overlay sur l'image
                        Positioned(
                          left: UniquesControllers().data.baseSpace * 2,
                          right: UniquesControllers().data.baseSpace * 2,
                          bottom: UniquesControllers().data.baseSpace * 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.establishment.description,
                                style: TextStyle(
                                  fontSize: 13 * widthScale,
                                  color: widget.establishment.bannerUrl.isNotEmpty
                                      ? Colors.white
                                      : Colors.grey[600],
                                  height: 1.4,
                                  shadows: widget.establishment.bannerUrl.isNotEmpty
                                      ? [
                                          Shadow(
                                            offset: const Offset(1, 1),
                                            blurRadius: 3,
                                            color: Colors.black.withOpacity(0.8),
                                          ),
                                        ]
                                      : null,
                                ),
                                maxLines: _showFullDescription ? null : 3,
                                overflow: _showFullDescription
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ),
                              if (widget.establishment.description.length > 150)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showFullDescription = !_showFullDescription;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _showFullDescription ? 'Voir moins' : 'Voir plus',
                                      style: TextStyle(
                                        fontSize: 12 * widthScale,
                                        color: widget.establishment.bannerUrl.isNotEmpty
                                            ? Colors.white
                                            : CustomTheme.lightScheme().primary,
                                        fontWeight: FontWeight.w600,
                                        shadows: widget.establishment.bannerUrl.isNotEmpty
                                            ? [
                                                Shadow(
                                                  offset: const Offset(1, 1),
                                                  blurRadius: 2,
                                                  color: Colors.black.withOpacity(0.8),
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Si pas d'image, afficher l'icône au centre
                        if (widget.establishment.bannerUrl.isEmpty)
                          Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // CONTACT RAPIDE (incluant vidéo)
                if (_hasContactInfo())
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                      vertical: UniquesControllers().data.baseSpace,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.establishment.telephone.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.phone,
                            label: 'Appeler',
                            onTap: () => _launchTel(widget.establishment.telephone),
                            scale: widthScale,
                          ),
                        if (widget.establishment.email.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.email,
                            label: 'Email',
                            onTap: () => _launchEmail(widget.establishment.email),
                            scale: widthScale,
                          ),
                        if (widget.establishment.address.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.directions,
                            label: 'Itinéraire',
                            onTap: () => _launchMaps(widget.establishment.address),
                            scale: widthScale,
                          ),
                        if (widget.establishment.videoUrl.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.play_circle_outline,
                            label: 'Vidéo',
                            onTap: () => _launchVideoLink(widget.establishment.videoUrl),
                            scale: widthScale,
                          ),
                      ],
                    ),
                  ),

                // FOOTER avec Bons/Actions - Avec FutureBuilder pour les boutiques
                Container(
                  padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.05),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                        UniquesControllers().data.baseSpace * 2,
                      ),
                      bottomRight: Radius.circular(
                        UniquesControllers().data.baseSpace * 2,
                      ),
                    ),
                  ),
                  child: _buildFooterContent(
                    isEnterprise,
                    isSponsor,
                    isAssociation,
                    isBoutique,
                    widthScale,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopRightBadge(bool isEnterprise, bool isSponsor, double widthScale) {
    // Cashback pour entreprises/partenaires
    if (isEnterprise) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue[200]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings,
              color: Colors.blue[700],
              size: 16 * widthScale,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.establishment.cashbackPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12 * widthScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Tag Bronze/Silver pour sponsors
    if (isSponsor) {
      final isSilver = _sponsorLevel == 'silver';
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSilver
                ? [
                    const Color(0xFFB8B8B8),
                    const Color(0xFF7D7D7D),
                  ]
                : [
                    const Color(0xFFCD7F32),
                    const Color(0xFF8B4513),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSilver
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.brown.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 16 * widthScale,
            ),
            const SizedBox(width: 4),
            Text(
              isSilver ? 'SILVER' : 'BRONZE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * widthScale,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (isSilver) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.stars,
                size: 14 * widthScale,
                color: Colors.white,
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCategories(
    ShopEstablishmentCardController? cc, // rendu nullable pour test
    bool isEnterprise,
    double widthScale,
  ) {
    // VERSION SIMPLIFIÉE : Affichage statique des catégories
    if (isEnterprise &&
        widget.establishment.enterpriseCategoryIds != null &&
        widget.establishment.enterpriseCategoryIds!.isNotEmpty &&
        widget.enterpriseCategoriesMap != null) {

      final categories = widget.establishment.enterpriseCategoryIds!;
      final categoryNames = categories
          .map((catId) => widget.enterpriseCategoriesMap![catId] ?? catId)
          .toList();

      // Limiter à 3 catégories max pour éviter les problèmes
      final displayCategories = categoryNames.take(3).toList();
      final hasMore = categoryNames.length > 3;

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 2,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...displayCategories.map((catName) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: UniquesControllers().data.baseSpace * 1.2,
                vertical: UniquesControllers().data.baseSpace / 2,
              ),
              decoration: BoxDecoration(
                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  UniquesControllers().data.baseSpace,
                ),
                border: Border.all(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                catName,
                style: TextStyle(
                  fontSize: 12 * widthScale,
                  color: CustomTheme.lightScheme().primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
            if (hasMore)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: UniquesControllers().data.baseSpace * 1.2,
                  vertical: UniquesControllers().data.baseSpace / 2,
                ),
                decoration: BoxDecoration(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(
                    UniquesControllers().data.baseSpace,
                  ),
                  border: Border.all(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  '+${categoryNames.length - 3}',
                  style: TextStyle(
                    fontSize: 12 * widthScale,
                    color: CustomTheme.lightScheme().primary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (widget.establishment.categoryId.isNotEmpty && widget.categoriesMap != null) {
      // Affichage pour boutiques et associations
      final categoryName = widget.categoriesMap![widget.establishment.categoryId] ??
                          widget.establishment.categoryId;

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 2,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 1.2,
          vertical: UniquesControllers().data.baseSpace / 2,
        ),
        decoration: BoxDecoration(
          color: CustomTheme.lightScheme().primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            UniquesControllers().data.baseSpace,
          ),
          border: Border.all(
            color: CustomTheme.lightScheme().primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          categoryName,
          style: TextStyle(
            fontSize: 12 * widthScale,
            color: CustomTheme.lightScheme().primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildFooterContent(
    bool isEnterprise,
    bool isSponsor,
    bool isAssociation,
    bool isBoutique,
    double widthScale,
  ) {
    // Utiliser directement la variable d'état au lieu du FutureBuilder
    return Row(
      children: [
        // Partie gauche : infos selon le type
        if (isBoutique) ...[
          // Bons disponibles pour les commerces
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    UniquesControllers().data.baseSpace,
                  ),
                  decoration: BoxDecoration(
                    color: _availableCoupons > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.confirmation_number,
                    color: _availableCoupons > 0 ? Colors.green : Colors.red,
                    size: 20 * widthScale,
                  ),
                ),
                SizedBox(width: UniquesControllers().data.baseSpace),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_availableCoupons bons',
                      style: TextStyle(
                        fontSize: 16 * widthScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _availableCoupons > 0 ? 'Disponibles' : 'Stock épuisé',
                      style: TextStyle(
                        fontSize: 12 * widthScale,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else
          Expanded(child: Container()),

        // Partie droite : bouton d'action
        _buildActionButton(
          isEnterprise,
          isSponsor,
          isAssociation,
          isBoutique,
          _availableCoupons,
          widthScale,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    bool isEnterprise,
    bool isSponsor,
    bool isAssociation,
    bool isBoutique,
    int coupons,
    double widthScale,
  ) {
    // Bouton "Demander un devis" pour les entreprises
    if (isEnterprise) {
      return ElevatedButton.icon(
        onPressed: widget.isOwnEstablishment ? null : () => _showQuoteForm(context),
        icon: Icon(
          Icons.description,
          size: 20 * widthScale,
          color: Colors.black,
        ),
        label: Text(
          widget.isOwnEstablishment ? 'Votre entreprise' : 'Demander un devis',
          style: TextStyle(
            fontSize: 14 * widthScale,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isOwnEstablishment
              ? Colors.grey[300]
              : CustomTheme.lightScheme().primary,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: UniquesControllers().data.baseSpace * 2,
            vertical: UniquesControllers().data.baseSpace * 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              UniquesControllers().data.baseSpace * 3,
            ),
          ),
        ),
      );
    }

    // Pour les sponsors, pas de bouton d'action
    if (isSponsor) {
      return const SizedBox.shrink();
    }

    // Autres types (boutiques et associations)
    final isDisabled = widget.isOwnEstablishment ||
        (!isAssociation && coupons == 0);

    return ElevatedButton.icon(
      onPressed: isDisabled ? null : widget.onBuy,
      icon: Icon(
        isAssociation
            ? Icons.volunteer_activism
            : Icons.shopping_cart,
        size: 20 * widthScale,
        color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
      ),
      label: Text(
        widget.isOwnEstablishment
            ? 'Votre établissement'
            : (isAssociation
                ? 'Faire un don'
                : 'Acheter'),
        style: TextStyle(
          fontSize: 14 * widthScale,
          color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.isOwnEstablishment
            ? Colors.grey[300]
            : (isAssociation
                ? Colors.green
                : CustomTheme.lightScheme().primary),
        foregroundColor: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
        padding: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 2,
          vertical: UniquesControllers().data.baseSpace * 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            UniquesControllers().data.baseSpace * 3,
          ),
        ),
      ),
    );
  }

  // VERSION SIMPLIFIÉE SANS STREAMBUILDER NI FUTUREBUILDER
  Widget _buildSimpleActionButton(
    bool isEnterprise,
    bool isSponsor,
    bool isAssociation,
    bool isBoutique,
    double widthScale,
  ) {
    // Bouton "Demander un devis" pour les entreprises
    if (isEnterprise) {
      return ElevatedButton.icon(
        onPressed: widget.isOwnEstablishment ? null : () => _showQuoteForm(context),
        icon: Icon(
          Icons.description,
          size: 20 * widthScale,
          color: Colors.black,
        ),
        label: Text(
          widget.isOwnEstablishment ? 'Votre entreprise' : 'Demander un devis',
          style: TextStyle(
            fontSize: 14 * widthScale,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isOwnEstablishment
              ? Colors.grey[300]
              : CustomTheme.lightScheme().primary,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: UniquesControllers().data.baseSpace * 2,
            vertical: UniquesControllers().data.baseSpace * 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              UniquesControllers().data.baseSpace * 3,
            ),
          ),
        ),
      );
    }

    // Pour les sponsors, pas de bouton d'action
    if (isSponsor) {
      return const SizedBox.shrink();
    }

    // Autres types (boutiques et associations) - sans vérification des coupons
    return ElevatedButton.icon(
      onPressed: widget.isOwnEstablishment ? null : widget.onBuy,
      icon: Icon(
        isAssociation
            ? Icons.volunteer_activism
            : Icons.shopping_cart,
        size: 20 * widthScale,
        color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
      ),
      label: Text(
        widget.isOwnEstablishment
            ? 'Votre établissement'
            : (isAssociation
                ? 'Faire un don'
                : 'Acheter'),
        style: TextStyle(
          fontSize: 14 * widthScale,
          color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.isOwnEstablishment
            ? Colors.grey[300]
            : (isAssociation
                ? Colors.green
                : CustomTheme.lightScheme().primary),
        foregroundColor: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
        padding: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 2,
          vertical: UniquesControllers().data.baseSpace * 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            UniquesControllers().data.baseSpace * 3,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLogo(bool isEnterprise, bool isSponsor) {
    final size = UniquesControllers().data.baseSpace * 7;
    if (widget.establishment.logoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(widget.establishment.logoUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CustomTheme.lightScheme().primary.withOpacity(0.1),
          border: Border.all(
            color: CustomTheme.lightScheme().primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          isEnterprise
              ? Icons.business
              : isSponsor
                  ? Icons.workspace_premium
                  : Icons.store,
          size: size * 0.5,
          color: CustomTheme.lightScheme().primary,
        ),
      );
    }
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double scale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UniquesControllers().data.baseSpace),
      child: Padding(
        padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24 * scale,
              color: CustomTheme.lightScheme().primary,
            ),
            SizedBox(height: UniquesControllers().data.baseSpace / 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12 * scale,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasContactInfo() {
    return widget.establishment.telephone.isNotEmpty ||
        widget.establishment.email.isNotEmpty ||
        widget.establishment.address.isNotEmpty ||
        widget.establishment.videoUrl.isNotEmpty;
  }

  Future<String> _fetchUserTypeName(String userId) async {
    try {
      final snapUser = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(userId)
          .get();
      if (!snapUser.exists) return '';

      final userData = snapUser.data()!;
      final userTypeId = userData['user_type_id'] ?? '';
      if (userTypeId.isEmpty) return '';

      final snapType = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .doc(userTypeId)
          .get();
      if (!snapType.exists) return '';

      final typeData = snapType.data()!;
      return typeData['name'] ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> _fetchSponsorLevel() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('establishments')
          .where('user_id', isEqualTo: widget.establishment.userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return data['sponsor_level'] ?? 'bronze';
      }
    } catch (e) {
      // En cas d'erreur
    }
    return 'bronze';
  }

  void _showQuoteForm(BuildContext context) {
    final tempController = QuotesScreenController();
    tempController.resetForm();

    Get.dialog(
      QuoteFormDialog(
        enterprise: widget.establishment,
        controller: tempController,
      ),
      barrierDismissible: false,
    ).then((_) {
      tempController.onClose();
    });
  }

  void _launchVideoLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchTel(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}