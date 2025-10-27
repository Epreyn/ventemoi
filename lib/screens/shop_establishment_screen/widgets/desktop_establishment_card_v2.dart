import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../quotes_screen/controllers/quotes_screen_controller.dart';
import '../../quotes_screen/widgets/quote_form_dialog.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

/// Carte optimisée pour Desktop/Tablet (v2)
/// Basée sur les meilleures pratiques UX/UI 2025 :
/// - Layout horizontal compact
/// - Informations essentielles visibles sans interaction
/// - Entièrement cliquable pour meilleure accessibilité
/// - Adapté aux grilles 2-4 colonnes
class DesktopEstablishmentCardV2 extends StatefulWidget {
  final Establishment establishment;
  final bool isOwnEstablishment;
  final VoidCallback? onBuy;
  final int index;
  final RxMap<String, String>? enterpriseCategoriesMap;
  final RxMap<String, String>? categoriesMap;

  const DesktopEstablishmentCardV2({
    Key? key,
    required this.establishment,
    required this.isOwnEstablishment,
    this.onBuy,
    required this.index,
    this.enterpriseCategoriesMap,
    this.categoriesMap,
  }) : super(key: key);

  @override
  State<DesktopEstablishmentCardV2> createState() =>
      _DesktopEstablishmentCardV2State();
}

class _DesktopEstablishmentCardV2State
    extends State<DesktopEstablishmentCardV2> {
  String _userTypeName = '';
  String _sponsorLevel = 'bronze';
  int _availableCoupons = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _loadAvailableCoupons();
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
        final data = walletQuery.docs.first.data();
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

  Future<String> _fetchSponsorLevel() async {
    try {
      final sponsorDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsors')
          .where('user_id', isEqualTo: widget.establishment.userId)
          .limit(1)
          .get();

      if (sponsorDoc.docs.isEmpty) return 'bronze';

      final data = sponsorDoc.docs.first.data();
      return data['level'] ?? 'bronze';
    } catch (e) {
      return 'bronze';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnterprise = _userTypeName == 'Entreprise';
    final isSponsor = _userTypeName == 'Sponsor';
    final isAssociation = _userTypeName == 'Association';
    final isBoutique =
        _userTypeName == 'Boutique' || _userTypeName == 'Commerçant';

    final hasImage = widget.establishment.bannerUrl.isNotEmpty;

    return CustomCardAnimation(
      index: widget.index,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _handleCardTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, _isHovered ? -4.0 : 0.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? CustomTheme.lightScheme().primary.withOpacity(0.15)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
              border: widget.isOwnEstablishment
                  ? Border.all(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.4),
                      width: 2,
                    )
                  : (isAssociation && !widget.establishment.isVisible)
                      ? Border.all(
                          color: Colors.orange.withOpacity(0.4),
                          width: 1.5,
                        )
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Banner avec overlay gradient
                _buildImageBanner(hasImage, isSponsor, isAssociation),

                // Contenu principal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header avec nom et badge
                        _buildHeader(
                            isEnterprise, isSponsor, isAssociation, isBoutique),

                        const SizedBox(height: 8),

                        // Description (2 lignes max)
                        if (widget.establishment.description.isNotEmpty)
                          _buildDescription(),

                        const SizedBox(height: 12),

                        // Catégories chips
                        _buildCategories(isEnterprise),

                        const Spacer(),

                        // Footer avec infos et actions
                        _buildFooter(isSponsor, isAssociation, isBoutique),
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

  Widget _buildImageBanner(bool hasImage, bool isSponsor, bool isAssociation) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasImage
                ? [Colors.black.withOpacity(0.3), Colors.transparent]
                : [
                    CustomTheme.lightScheme().primary.withOpacity(0.1),
                    CustomTheme.lightScheme().primary.withOpacity(0.05),
                  ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond
            if (hasImage)
              Image.network(
                widget.establishment.bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported,
                      size: 48, color: Colors.grey[400]),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CustomTheme.lightScheme().primary.withOpacity(0.15),
                      CustomTheme.lightScheme().primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.business,
                  size: 64,
                  color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                ),
              ),

            // Gradient overlay pour meilleure lisibilité
            if (hasImage)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),

            // Badge type (coin supérieur gauche)
            Positioned(
              top: 12,
              left: 12,
              child: _buildTypeBadge(isSponsor, isAssociation),
            ),

            // Logo (coin supérieur droit)
            if (widget.establishment.logoUrl.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.establishment.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.store,
                        color: CustomTheme.lightScheme().primary,
                      ),
                    ),
                  ),
                ),
              ),

            // Bons disponibles badge (coin inférieur gauche)
            if (_availableCoupons > 0)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CustomTheme.lightScheme().primary,
                        CustomTheme.lightScheme().primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomTheme.lightScheme().primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.card_giftcard,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$_availableCoupons bon${_availableCoupons > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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

  Widget _buildTypeBadge(bool isSponsor, bool isAssociation) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    if (isSponsor) {
      badgeColor = _getSponsorColor();
      badgeIcon = Icons.workspace_premium;
      badgeText = _sponsorLevel.toUpperCase();
    } else if (isAssociation) {
      badgeColor = Colors.green;
      badgeIcon = Icons.volunteer_activism;
      badgeText = 'ASSO';
    } else if (_userTypeName == 'Entreprise') {
      badgeColor = Colors.blue;
      badgeIcon = Icons.business;
      badgeText = 'SERVICE';
    } else {
      badgeColor = CustomTheme.lightScheme().primary;
      badgeIcon = Icons.store;
      badgeText = 'COMMERCE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSponsorColor() {
    switch (_sponsorLevel.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Widget _buildHeader(
      bool isEnterprise, bool isSponsor, bool isAssociation, bool isBoutique) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.establishment.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.establishment.address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.grey[600]),
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
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.establishment.description,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategories(bool isEnterprise) {
    final List<String> categoryNames = [];

    if (isEnterprise && widget.enterpriseCategoriesMap != null) {
      final catIds = widget.establishment.enterpriseCategoryIds ?? [];
      for (final id in catIds.take(2)) {
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

    if (categoryNames.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: categoryNames
          .map(
            (name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  color: CustomTheme.lightScheme().primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFooter(bool isSponsor, bool isAssociation, bool isBoutique) {
    return Column(
      children: [
        const Divider(height: 24),
        Row(
          children: [
            // Contact info
            if (widget.establishment.telephone.isNotEmpty)
              _buildIconButton(
                icon: Icons.phone,
                label: 'Appeler',
                color: Colors.green,
                onTap: () => _launchPhone(widget.establishment.telephone),
              ),
            if (widget.establishment.email.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.email,
                label: 'Email',
                color: Colors.blue,
                onTap: () => _launchEmail(widget.establishment.email),
              ),
            ],

            const Spacer(),

            // Action button
            if (!isSponsor && !isAssociation && !widget.isOwnEstablishment)
              _buildActionButton(isBoutique),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isBoutique) {
    if (_userTypeName == 'Entreprise') {
      return ElevatedButton.icon(
        onPressed: _openQuoteDialog,
        icon: const Icon(Icons.request_quote, size: 16),
        label: const Text('Devis'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      );
    } else if (isBoutique) {
      return ElevatedButton.icon(
        onPressed: widget.onBuy,
        icon: const Icon(Icons.shopping_cart, size: 16),
        label: const Text('Acheter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomTheme.lightScheme().primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _handleCardTap() {
    // Action au tap sur la carte (peut ouvrir une page détail)
    // Pour l'instant, on garde le comportement simple
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openQuoteDialog() {
    final qc = Get.put(QuotesScreenController());

    Get.dialog(
      QuoteFormDialog(
        enterprise: widget.establishment,
        controller: qc,
      ),
      barrierDismissible: true,
    );
  }
}
