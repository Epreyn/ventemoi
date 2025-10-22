import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../quotes_screen/controllers/quotes_screen_controller.dart';
import '../../quotes_screen/widgets/quote_form_dialog.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';

/// Version 2 - Design épuré selon les best practices UX/UI 2025
/// - Hauteur réduite : 80px
/// - Pas de description sur la carte de base
/// - Logo compact : 40px
/// - Ombres ultra-légères
/// - Border radius 12px
/// - Informations condensées
class UnifiedMobileCardV2 extends StatefulWidget {
  final Establishment establishment;
  final bool isOwnEstablishment;
  final VoidCallback? onBuy;
  final int index;
  final RxMap<String, String>? enterpriseCategoriesMap;
  final RxMap<String, String>? categoriesMap;

  const UnifiedMobileCardV2({
    Key? key,
    required this.establishment,
    required this.isOwnEstablishment,
    this.onBuy,
    required this.index,
    this.enterpriseCategoriesMap,
    this.categoriesMap,
  }) : super(key: key);

  @override
  State<UnifiedMobileCardV2> createState() => _UnifiedMobileCardV2State();
}

class _UnifiedMobileCardV2State extends State<UnifiedMobileCardV2> {
  bool _isExpanded = false;
  String _userTypeName = '';
  String _sponsorLevel = 'bronze';
  int _availableCoupons = 0;
  bool _shouldShowImages = false; // Contrôle l'affichage des images avec shimmer

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _loadAvailableCoupons();

    // Délai léger avant de charger les images (effet shimmer pendant le chargement)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _shouldShowImages = true;
        });
      }
    });
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
      if (mounted) {
        setState(() {
          _availableCoupons = 0;
        });
      }
    }
  }

  Future<void> _loadUserType() async {
    final typeName = await _getUserTypeName();
    if (mounted) {
      setState(() {
        _userTypeName = typeName;
      });
      if (typeName == 'Sponsor') {
        _loadSponsorLevel();
      }
    }
  }

  Future<void> _loadSponsorLevel() async {
    final level = await _fetchSponsorLevel();
    if (mounted) {
      setState(() {
        _sponsorLevel = level;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnterprise = _userTypeName == 'Entreprise';
    final isSponsor = _userTypeName == 'Sponsor';
    final isAssociation = _userTypeName == 'Association';
    final isBoutique = _userTypeName == 'Boutique' || _userTypeName == 'Commerçant';

    // Afficher un shimmer complet de la carte pendant le chargement
    if (!_shouldShowImages) {
      return _buildShimmerCard();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Stack(
        children: [
          Stack(
            children: [
              // Carte principale
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  // Bannière en fond avec 20% d'opacité (subtile)
                  image: _shouldShowImages && widget.establishment.bannerUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.establishment.bannerUrl),
                          fit: BoxFit.cover,
                          opacity: 0.20,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: widget.isOwnEstablishment
                        ? CustomTheme.lightScheme().primary
                        : Colors.grey.shade300,
                    width: widget.isOwnEstablishment ? 2 : 1,
                  ),
                ),
                child: Column(
                children: [
                  // Partie compacte (80px au lieu de 100px)
                  ClipRRect(
                    borderRadius: _isExpanded
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          )
                        : BorderRadius.circular(12),
                    child: Container(
                      height: 80, // Réduit de 100px à 80px
                      // Overlay blanc léger pour améliorer la lisibilité tout en laissant voir le fond
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7), // Réduit à 70% pour voir la bannière
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Logo compact (40px au lieu de 48px)
                          _buildCompactLogo(isEnterprise, isSponsor),
                          const SizedBox(width: 12),
                          // Informations principales (SANS description)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Nom
                                Text(
                                  widget.establishment.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Info spécifique au type (condensée)
                                _buildTypeSpecificInfo(
                                  isEnterprise,
                                  isSponsor,
                                  isAssociation,
                                  isBoutique,
                                ),
                              ],
                            ),
                          ),
                          // Colonne droite : Badge + Expand
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Badge spécifique ou "Vous"
                              if (widget.isOwnEstablishment)
                                _buildYouBadge()
                              else
                                _buildRightBadge(isEnterprise, isSponsor, isBoutique),
                              const Spacer(),
                              // Bouton expand minimaliste
                              Icon(
                                _isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Partie expansible
                  if (_isExpanded)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75), // Réduit à 75% pour voir la bannière
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Catégories complètes (TOUTES les catégories)
                          if (isEnterprise &&
                              widget.establishment.enterpriseCategoryIds != null &&
                              widget.establishment.enterpriseCategoryIds!.isNotEmpty &&
                              widget.enterpriseCategoriesMap != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catégories :',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: widget.establishment.enterpriseCategoryIds!
                                      .map((catId) {
                                    final categoryName =
                                        widget.enterpriseCategoriesMap![catId] ?? catId;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: CustomTheme.lightScheme()
                                              .primary
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        categoryName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: CustomTheme.lightScheme().primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),

                          // Description complète (affichée SEULEMENT en mode étendu)
                          Text(
                            widget.establishment.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Boutons de contact
                          if (_hasContactInfo())
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.establishment.telephone.isNotEmpty)
                                  _buildContactChip(
                                    Icons.phone,
                                    'Appeler',
                                    () => _launchTel(widget.establishment.telephone),
                                  ),
                                if (widget.establishment.email.isNotEmpty)
                                  _buildContactChip(
                                    Icons.email,
                                    'Email',
                                    () => _launchEmail(widget.establishment.email),
                                  ),
                                if (widget.establishment.address.isNotEmpty)
                                  _buildContactChip(
                                    Icons.location_on,
                                    'Itinéraire',
                                    () => _launchMaps(widget.establishment.address),
                                  ),
                                if (widget.establishment.videoUrl.isNotEmpty)
                                  _buildContactChip(
                                    Icons.play_circle_outline,
                                    'Vidéo',
                                    () => _launchVideo(widget.establishment.videoUrl),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          // Bouton d'action principal
                          _buildActionButton(
                            isEnterprise,
                            isSponsor,
                            isAssociation,
                            isBoutique,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Badge promotionnel ribbon (coin supérieur droit) - Best practice 2025
            if (_shouldShowPromoBadge())
              Positioned(
                top: 0,
                right: 0,
                child: _buildPromotionalRibbon(),
              ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildCompactLogo(bool isEnterprise, bool isSponsor) {
    const size = 40.0;

    // Si on a un logo URL, afficher l'image
    if (widget.establishment.logoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1.5,
          ),
          image: DecorationImage(
            image: NetworkImage(widget.establishment.logoUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Pas de logo : afficher l'icône par défaut
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CustomTheme.lightScheme().primary.withOpacity(0.1),
        border: Border.all(
          color: CustomTheme.lightScheme().primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Icon(
        isEnterprise
            ? Icons.business
            : isSponsor
                ? Icons.workspace_premium
                : Icons.store,
        size: 20,
        color: CustomTheme.lightScheme().primary,
      ),
    );
  }

  /// Shimmer pour la carte entière pendant le chargement
  /// Skeleton loader qui simule la structure exacte de la carte
  Widget _buildShimmerCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Logo shimmer (cercle)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Contenu shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Titre shimmer (nom de l'établissement)
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 15,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Sous-titre shimmer (catégorie/info)
                Row(
                  children: [
                    // Icône shimmer
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Texte catégorie shimmer
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 11,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Colonne droite
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Badge shimmer (cashback/nombre de bons)
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 50,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const Spacer(),
              // Icône expand shimmer
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYouBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: CustomTheme.lightScheme().primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Vous',
        style: TextStyle(
          fontSize: 9,
          color: CustomTheme.lightScheme().primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRightBadge(bool isEnterprise, bool isSponsor, bool isBoutique) {
    // ENTREPRISE : Affichage du cashback
    if (isEnterprise) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.savings, color: Colors.blue[700], size: 12),
            const SizedBox(width: 2),
            Text(
              '${widget.establishment.cashbackPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // BOUTIQUE : Affichage du nombre de bons (même emplacement que cashback)
    if (isBoutique) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _availableCoupons > 0
              ? Colors.green[50]
              : Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number,
              size: 12,
              color: _availableCoupons > 0 ? Colors.green[700] : Colors.red[700],
            ),
            const SizedBox(width: 2),
            Text(
              '$_availableCoupons',
              style: TextStyle(
                color: _availableCoupons > 0 ? Colors.green[700] : Colors.red[700],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // SPONSOR : Badge niveau
    if (isSponsor) {
      final isSilver = _sponsorLevel == 'silver';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSilver
                ? [const Color(0xFFB8B8B8), const Color(0xFF7D7D7D)]
                : [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isSilver ? 'SILVER' : 'BRONZE',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTypeSpecificInfo(
    bool isEnterprise,
    bool isSponsor,
    bool isAssociation,
    bool isBoutique,
  ) {
    if (isEnterprise &&
        widget.establishment.enterpriseCategoryIds != null &&
        widget.establishment.enterpriseCategoryIds!.isNotEmpty &&
        widget.enterpriseCategoriesMap != null) {
      final categories = widget.establishment.enterpriseCategoryIds!;
      final categoryNames = categories
          .map((catId) => widget.enterpriseCategoriesMap![catId] ?? catId)
          .toList();

      final remainingCount = categoryNames.length - 1;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business_center,
            size: 11,
            color: CustomTheme.lightScheme().primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              categoryNames.first,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (remainingCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+$remainingCount',
                style: TextStyle(
                  fontSize: 9,
                  color: CustomTheme.lightScheme().primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      );
    }

    // BOUTIQUE : Affichage de la catégorie uniquement (nombre de bons déplacé dans _buildRightBadge)
    if (isBoutique && widget.categoriesMap != null && widget.establishment.categoryId.isNotEmpty) {
      final categoryName = widget.categoriesMap![widget.establishment.categoryId] ?? 'Commerce';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer,
            size: 11,
            color: CustomTheme.lightScheme().primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              categoryName,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (isAssociation && widget.categoriesMap != null && widget.establishment.categoryId.isNotEmpty) {
      final categoryName = widget.categoriesMap![widget.establishment.categoryId] ?? 'Association';
      return Text(
        categoryName,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return const SizedBox();
  }

  Widget _buildContactChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: CustomTheme.lightScheme().primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    bool isEnterprise,
    bool isSponsor,
    bool isAssociation,
    bool isBoutique,
  ) {
    if (isEnterprise) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.isOwnEstablishment ? null : () => _showQuoteForm(context),
          icon: Icon(
            Icons.description,
            size: 18,
            color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
          ),
          label: Text(
            widget.isOwnEstablishment ? 'Votre entreprise' : 'Demander un devis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isOwnEstablishment
                ? Colors.grey[300]
                : CustomTheme.lightScheme().primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
    }

    if (isAssociation) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.isOwnEstablishment ? null : widget.onBuy,
          icon: Icon(
            Icons.volunteer_activism,
            size: 18,
            color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
          ),
          label: Text(
            widget.isOwnEstablishment ? 'Votre association' : 'Faire un don',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isOwnEstablishment ? Colors.grey[300] : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
    }

    if (isSponsor) {
      return const SizedBox.shrink();
    }

    if (isBoutique) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.isOwnEstablishment ? null : widget.onBuy,
          icon: Icon(
            Icons.shopping_cart,
            size: 18,
            color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
          ),
          label: Text(
            widget.isOwnEstablishment ? 'Votre établissement' : 'Acheter des bons',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isOwnEstablishment
                ? Colors.grey[300]
                : CustomTheme.lightScheme().primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  bool _hasContactInfo() {
    return widget.establishment.telephone.isNotEmpty ||
        widget.establishment.email.isNotEmpty ||
        widget.establishment.address.isNotEmpty ||
        widget.establishment.videoUrl.isNotEmpty;
  }

  Future<String> _getUserTypeName() async {
    try {
      final snapUser = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(widget.establishment.userId)
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
    } catch (e) {}
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

  void _launchVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchTel(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Détermine si on affiche le badge promotionnel ribbon
  /// Best practice 2025 : Afficher un badge pour attirer l'attention sur les offres spéciales
  bool _shouldShowPromoBadge() {
    // Afficher le ribbon pour :
    // - Entreprises avec cashback > 10%

    if (_userTypeName == 'Entreprise' && widget.establishment.cashbackPercentage > 10) {
      return true;
    }

    return false;
  }

  /// Badge promotionnel en ribbon diagonal - Style 2025
  /// Positionné en coin supérieur droit pour attirer l'attention
  Widget _buildPromotionalRibbon() {
    // Uniquement pour les entreprises avec cashback > 10%
    final label = '${widget.establishment.cashbackPercentage.toStringAsFixed(0)}%';
    final color = Colors.blue[600]!;

    return ClipPath(
      clipper: _RibbonClipper(),
      child: Container(
        width: 70,
        height: 70,
        color: color,
        alignment: Alignment.topRight,
        padding: const EdgeInsets.only(top: 12, right: 6),
        child: Transform.rotate(
          angle: 0.785398, // 45 degrés en radians
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom clipper pour créer le ribbon diagonal (coin supérieur droit)
class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width - 60, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, 60);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
