import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../quotes_screen/controllers/quotes_screen_controller.dart';
import '../../quotes_screen/widgets/quote_form_dialog.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class UnifiedMobileCard extends StatefulWidget {
  final Establishment establishment;
  final bool isOwnEstablishment;
  final VoidCallback? onBuy;
  final int index;
  final RxMap<String, String>? enterpriseCategoriesMap;

  const UnifiedMobileCard({
    Key? key,
    required this.establishment,
    required this.isOwnEstablishment,
    this.onBuy,
    required this.index,
    this.enterpriseCategoriesMap,
  }) : super(key: key);

  @override
  State<UnifiedMobileCard> createState() => _UnifiedMobileCardState();
}

class _UnifiedMobileCardState extends State<UnifiedMobileCard> {
  bool _isExpanded = false;
  String _userTypeName = '';
  String _sponsorLevel = 'bronze';

  @override
  void initState() {
    super.initState();
    _loadUserType();
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

    return CustomCardAnimation(
      index: widget.index,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: widget.isOwnEstablishment
                ? Border.all(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                    width: 2,
                  )
                : (isAssociation && !widget.establishment.isVisible)
                    ? Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1.5,
                      )
                    : null,
          ),
          child: Column(
            children: [
              // Partie toujours visible
              ClipRRect(
                borderRadius: _isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      )
                    : BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Bannière en overlay (sur le dernier tiers)
                    if (widget.establishment.bannerUrl.isNotEmpty)
                      Positioned.fill(
                        left: MediaQuery.of(context).size.width * 0.65,
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0.85),
                                Colors.white,
                              ],
                              stops: const [0.0, 0.1, 0.3, 0.6, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(widget.establishment.bannerUrl),
                                fit: BoxFit.cover,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Contenu principal
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Logo
                          _buildCompactLogo(isEnterprise, isSponsor),
                          const SizedBox(width: 12),
                          // Informations principales avec description sur l'image
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
                                          fontSize: 16,
                                          color: widget.establishment.bannerUrl.isNotEmpty
                                              ? Colors.white
                                              : Colors.black,
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
                                        maxLines: 1,
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
                                          color: widget.establishment.bannerUrl.isNotEmpty
                                              ? Colors.white.withOpacity(0.9)
                                              : CustomTheme.lightScheme()
                                                  .primary
                                                  .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Vous',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: CustomTheme.lightScheme().primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Description sur l'image
                                Expanded(
                                  child: Text(
                                    widget.establishment.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.establishment.bannerUrl.isNotEmpty
                                          ? Colors.white
                                          : Colors.grey[600],
                                      height: 1.3,
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Affichage selon le type
                                _buildTypeSpecificInfo(
                                  isEnterprise,
                                  isSponsor,
                                  isAssociation,
                                  isBoutique,
                                ),
                              ],
                            ),
                          ),
                          // Actions rapides et badges
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Badge spécifique selon le type
                              _buildRightBadge(isEnterprise, isSponsor),
                              const SizedBox(height: 8),
                              // Bouton expand
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Partie expansible
              if (_isExpanded)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description complète
                      Text(
                        widget.establishment.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Boutons de contact (incluant vidéo)
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
                            // Bouton vidéo toujours visible si disponible
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
      ),
    );
  }

  Widget _buildCompactLogo(bool isEnterprise, bool isSponsor) {
    const size = 48.0;
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
          size: 24,
          color: CustomTheme.lightScheme().primary,
        ),
      );
    }
  }

  Widget _buildRightBadge(bool isEnterprise, bool isSponsor) {
    // Cashback pour entreprises
    if (isEnterprise) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
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
              size: 14,
            ),
            const SizedBox(width: 3),
            Text(
              '${widget.establishment.cashbackPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Tag sponsor
    if (isSponsor) {
      final isSilver = _sponsorLevel == 'silver';
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSilver
                  ? Colors.grey.withOpacity(0.4)
                  : Colors.brown.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SPONSOR',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.5,
                    height: 1,
                  ),
                ),
                Text(
                  isSilver ? 'SILVER' : 'BRONZE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            if (isSilver) ...[
              const SizedBox(width: 3),
              const Icon(
                Icons.stars,
                size: 12,
                color: Colors.white,
              ),
            ],
          ],
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
    // Bons disponibles pour les commerces uniquement
    if (isBoutique) {
      return StreamBuilder<QuerySnapshot>(
        stream: UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .where('user_id', isEqualTo: widget.establishment.userId)
            .limit(1)
            .snapshots(),
        builder: (context, walletSnap) {
          if (!walletSnap.hasData || walletSnap.data!.docs.isEmpty) {
            return const SizedBox();
          }

          final data = walletSnap.data!.docs.first.data() as Map<String, dynamic>;
          final coupons = data['coupons'] ?? 0;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: coupons > 0
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.confirmation_number,
                  size: 14,
                  color: coupons > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '$coupons bons disponibles',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: coupons > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Pour les associations
    if (isAssociation) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism,
              size: 14,
              color: Colors.purple,
            ),
            SizedBox(width: 4),
            Text(
              'Accepte les dons',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      );
    }

    // Pour les entreprises, afficher les catégories
    if (isEnterprise &&
        widget.establishment.enterpriseCategoryIds != null &&
        widget.establishment.enterpriseCategoryIds!.isNotEmpty &&
        widget.enterpriseCategoriesMap != null) {
      final firstCatId = widget.establishment.enterpriseCategoryIds!.first;
      final catName = widget.enterpriseCategoriesMap![firstCatId] ?? 'Entreprise';
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: CustomTheme.lightScheme().primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business_center,
              size: 14,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(width: 4),
            Text(
              catName,
              style: TextStyle(
                fontSize: 12,
                color: CustomTheme.lightScheme().primary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
          border: Border.all(
            color: Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
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
    // Bouton "Demander un devis" pour les entreprises
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
              fontWeight: FontWeight.bold,
              color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isOwnEstablishment
                ? Colors.grey[300]
                : CustomTheme.lightScheme().primary,
            foregroundColor: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    // Pour les associations
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
              fontWeight: FontWeight.bold,
              color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isOwnEstablishment ? Colors.grey[300] : Colors.green,
            foregroundColor: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    // Pour les sponsors
    if (isSponsor) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.isOwnEstablishment ? null : () => _showSponsorInfo(),
          icon: Icon(
            Icons.info_outline,
            size: 18,
            color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
          ),
          label: Text(
            widget.isOwnEstablishment ? 'Votre sponsor' : 'En savoir plus',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isOwnEstablishment
                ? Colors.grey[300]
                : CustomTheme.lightScheme().primary,
            foregroundColor: widget.isOwnEstablishment ? Colors.grey[600] : Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    // Pour les boutiques/commerçants
    if (isBoutique) {
      return StreamBuilder<QuerySnapshot>(
        stream: UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .where('user_id', isEqualTo: widget.establishment.userId)
            .limit(1)
            .snapshots(),
        builder: (context, walletSnap) {
          if (!walletSnap.hasData || walletSnap.data!.docs.isEmpty) {
            return const SizedBox();
          }

          final data = walletSnap.data!.docs.first.data() as Map<String, dynamic>;
          final coupons = data['coupons'] ?? 0;
          final isDisabled = widget.isOwnEstablishment || coupons == 0;

          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDisabled ? null : widget.onBuy,
              icon: Icon(
                Icons.shopping_cart,
                size: 18,
                color: widget.isOwnEstablishment || isDisabled ? Colors.grey[600] : Colors.black,
              ),
              label: Text(
                widget.isOwnEstablishment
                    ? 'Votre établissement'
                    : 'Acheter des bons',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isOwnEstablishment || isDisabled ? Colors.grey[600] : Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isOwnEstablishment || isDisabled
                    ? Colors.grey[300]
                    : CustomTheme.lightScheme().primary,
                foregroundColor: widget.isOwnEstablishment || isDisabled ? Colors.grey[600] : Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        },
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
    return await _fetchUserTypeName(widget.establishment.userId);
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

  void _showSponsorInfo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.establishment.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sponsor de l\'application',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CustomTheme.lightScheme().primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.establishment.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (widget.establishment.website != null &&
                widget.establishment.website!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _launchUrl(widget.establishment.website!),
                child: Text(
                  widget.establishment.website!,
                  style: TextStyle(
                    color: CustomTheme.lightScheme().primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
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
}