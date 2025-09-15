import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_icon_button/view/custom_icon_button.dart';
import '../controllers/shop_establishment_card_controller.dart';

class ShopEstablishmentCard extends StatefulWidget {
  final Establishment establishment;
  final VoidCallback? onBuy;
  final int index;
  final bool isOwnEstablishment;

  const ShopEstablishmentCard({
    super.key,
    required this.establishment,
    this.onBuy,
    required this.index,
    this.isOwnEstablishment = false,
  });

  @override
  State<ShopEstablishmentCard> createState() => _ShopEstablishmentCardState();
}

class _ShopEstablishmentCardState extends State<ShopEstablishmentCard> {
  bool _showFullDescription = false;

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(
      ShopEstablishmentCardController(),
      tag: 'shop-establishment-card-controller-${widget.index}',
    );

    return CustomCardAnimation(
      index: widget.index,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cardWidth = constraints.maxWidth;
          final cardHeight = constraints.maxHeight;
          final widthScale = cardWidth / 300.0;

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
                  : (widget.establishment.isAssociation && !widget.establishment.isVisible)
                      ? BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1.5,
                        )
                      : BorderSide.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER : Logo + Nom + Catégorie ---
                Container(
                  padding:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      _buildCompactLogo(),
                      SizedBox(width: UniquesControllers().data.baseSpace * 2),
                      // Infos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom avec badge "Vous" si c'est son propre établissement
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
                                        color:
                                            CustomTheme.lightScheme().primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Message pour les associations non visibles
                            if (widget.establishment.isAssociation && !widget.establishment.isVisible)
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
                                    SizedBox(width: 8),
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
                            // Description condensée sous le nom
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.establishment.description,
                                    style: TextStyle(
                                      fontSize: 13 * widthScale,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                    maxLines: _showFullDescription ? null : 2,
                                    overflow: _showFullDescription
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                  ),
                                  if (widget.establishment.description.length >
                                      100)
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showFullDescription =
                                              !_showFullDescription;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _showFullDescription
                                              ? 'Voir moins'
                                              : 'Voir plus',
                                          style: TextStyle(
                                            fontSize: 12 * widthScale,
                                            color: CustomTheme.lightScheme()
                                                .primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icône de cashback en haut à droite - Uniquement pour les entreprises
                      FutureBuilder<String>(
                        future: _getEstablishmentType(),
                        builder: (context, snapshot) {
                          final typeName = snapshot.data ?? '';
                          final isEnterprise = typeName == 'Entreprise';

                          if (!isEnterprise) return SizedBox.shrink();

                          return Container(
                            padding: EdgeInsets.symmetric(
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
                                SizedBox(width: 4),
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
                        },
                      ),
                    ],
                  ),
                ),

                // Catégorie
                FutureBuilder<String>(
                  future:
                      cc.getCategoryNameById(widget.establishment.categoryId),
                  builder: (context, snapshot) {
                    final categoryName = snapshot.data ?? 'Chargement...';
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: UniquesControllers().data.baseSpace * 2,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: UniquesControllers().data.baseSpace,
                        vertical: UniquesControllers().data.baseSpace / 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            CustomTheme.lightScheme().primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          UniquesControllers().data.baseSpace,
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
                  },
                ),
                SizedBox(height: UniquesControllers().data.baseSpace * 2),

                // --- BANNIÈRE (sans description qui est maintenant en haut) ---
                Expanded(
                  child: Stack(
                    children: [
                      Container(
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
                                  image:
                                      NetworkImage(widget.establishment.bannerUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.establishment.bannerUrl.isEmpty
                            ? Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              )
                            : null,
                      ),
                      // Dégradé de droite vers la gauche
                      if (widget.establishment.bannerUrl.isNotEmpty)
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace * 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              UniquesControllers().data.baseSpace,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.black.withOpacity(0.2),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 0.7],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // --- CONTACT RAPIDE ---
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
                            onTap: () =>
                                _launchTel(widget.establishment.telephone),
                            scale: widthScale,
                          ),
                        if (widget.establishment.email.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.email,
                            label: 'Email',
                            onTap: () =>
                                _launchEmail(widget.establishment.email),
                            scale: widthScale,
                          ),
                        if (widget.establishment.address.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.directions,
                            label: 'Itinéraire',
                            onTap: () =>
                                _launchMaps(widget.establishment.address),
                            scale: widthScale,
                          ),
                        if (widget.establishment.videoUrl.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.play_circle_outline,
                            label: 'Vidéo',
                            onTap: () =>
                                _launchVideoLink(widget.establishment.videoUrl),
                            scale: widthScale,
                          ),
                      ],
                    ),
                  ),

                // --- FOOTER : Stock + Action ---
                Container(
                  padding:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
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
                  child: FutureBuilder<String>(
                    future: _fetchUserTypeName(widget.establishment.userId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final typeName = snap.data ?? '';

                      return StreamBuilder<QuerySnapshot>(
                        stream: UniquesControllers()
                            .data
                            .firebaseFirestore
                            .collection('wallets')
                            .where('user_id',
                                isEqualTo: widget.establishment.userId)
                            .limit(1)
                            .snapshots(),
                        builder: (context, walletSnap) {
                          if (!walletSnap.hasData ||
                              walletSnap.data!.docs.isEmpty) {
                            return const Text('Chargement...');
                          }

                          final data = walletSnap.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final coupons = data['coupons'] ?? 0;
                          final isAssociation = typeName == 'Association';
                          final isSponsor = typeName == 'Sponsor';
                          final isEnterprise = typeName == 'Entreprise';
                          final showVouchers = typeName == 'Boutique' || typeName == 'Commerçant';
                          final isDisabled = widget.isOwnEstablishment ||
                              (!isAssociation && !isSponsor && coupons == 0);

                          return Row(
                            children: [
                              // Stock avec icône - N'afficher que pour les boutiques/commerçants
                              if (showVouchers)
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          UniquesControllers().data.baseSpace,
                                        ),
                                        decoration: BoxDecoration(
                                          color: coupons > 0
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.confirmation_number,
                                          color: coupons > 0
                                              ? Colors.green
                                              : Colors.red,
                                          size: 20 * widthScale,
                                        ),
                                      ),
                                      SizedBox(
                                          width: UniquesControllers()
                                              .data
                                              .baseSpace),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$coupons bons',
                                            style: TextStyle(
                                              fontSize: 16 * widthScale,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            coupons > 0
                                                ? 'Disponibles'
                                                : 'Stock épuisé',
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
                              // Pour les sponsors, afficher leur niveau avec un design attrayant
                              if (isSponsor)
                                Expanded(
                                  child: FutureBuilder<DocumentSnapshot>(
                                    future: UniquesControllers()
                                        .data
                                        .firebaseFirestore
                                        .collection('establishments')
                                        .where('user_id', isEqualTo: widget.establishment.userId)
                                        .limit(1)
                                        .get()
                                        .then((snap) => snap.docs.isNotEmpty ? snap.docs.first.reference.get() : Future.value(null)),
                                    builder: (context, estabSnap) {
                                      String sponsorLevel = '';
                                      if (estabSnap.hasData && estabSnap.data != null) {
                                        final estabData = estabSnap.data!.data() as Map<String, dynamic>?;
                                        sponsorLevel = estabData?['sponsor_level'] ?? 'bronze';
                                      }

                                      final isSilver = sponsorLevel == 'silver';

                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: UniquesControllers().data.baseSpace * 1.5,
                                          vertical: UniquesControllers().data.baseSpace,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isSilver
                                                ? [
                                                    Color(0xFFB8B8B8), // Argent clair
                                                    Color(0xFF7D7D7D), // Argent foncé
                                                  ]
                                                : [
                                                    Color(0xFFCD7F32), // Bronze clair
                                                    Color(0xFF8B4513), // Bronze foncé
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSilver
                                                  ? Colors.grey.withOpacity(0.3)
                                                  : Colors.brown.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.workspace_premium,
                                              color: Colors.white,
                                              size: 24 * widthScale,
                                            ),
                                            SizedBox(width: UniquesControllers().data.baseSpace),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'SPONSOR',
                                                  style: TextStyle(
                                                    fontSize: 11 * widthScale,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white.withOpacity(0.9),
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                                Text(
                                                  isSilver ? 'SILVER' : 'BRONZE',
                                                  style: TextStyle(
                                                    fontSize: 18 * widthScale,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isSilver) ...[
                                              SizedBox(width: UniquesControllers().data.baseSpace),
                                              Icon(
                                                Icons.stars,
                                                color: Colors.white,
                                                size: 20 * widthScale,
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // Pour les entreprises, afficher le cashback
                              if (isEnterprise)
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          UniquesControllers().data.baseSpace,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.savings,
                                          color: Colors.blue,
                                          size: 20 * widthScale,
                                        ),
                                      ),
                                      SizedBox(
                                          width: UniquesControllers()
                                              .data
                                              .baseSpace),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${widget.establishment.cashbackPercentage.toStringAsFixed(0)}% cashback',
                                            style: TextStyle(
                                              fontSize: 16 * widthScale,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          Text(
                                            'En points',
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

                              // Si c'est une association, ajouter un Expanded vide pour maintenir l'alignement
                              if (isAssociation) Expanded(child: Container()),
                              // Bouton d'action
                              ElevatedButton.icon(
                                onPressed: isDisabled ? null : widget.onBuy,
                                icon: Icon(
                                  isAssociation
                                      ? Icons.volunteer_activism
                                      : isSponsor
                                          ? Icons.info_outline
                                          : isEnterprise
                                              ? Icons.business_center
                                              : Icons.shopping_cart,
                                  size: 20 * widthScale,
                                  color: widget.isOwnEstablishment
                                      ? Colors.grey[600]
                                      : CustomTheme.lightScheme().onPrimary,
                                ),
                                label: Text(
                                  widget.isOwnEstablishment
                                      ? 'Votre établissement'
                                      : (isAssociation
                                          ? 'Faire un don'
                                          : isSponsor
                                              ? 'En savoir plus'
                                              : isEnterprise
                                                  ? 'Voir les offres'
                                                  : 'Acheter'),
                                  style: TextStyle(
                                    fontSize: 14 * widthScale,
                                    color: widget.isOwnEstablishment
                                        ? Colors.grey[600]
                                        : CustomTheme.lightScheme().onPrimary,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.isOwnEstablishment
                                      ? Colors.grey[300]
                                      : (isAssociation
                                          ? Colors.green
                                          : CustomTheme.lightScheme().primary),
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        UniquesControllers().data.baseSpace * 2,
                                    vertical:
                                        UniquesControllers().data.baseSpace *
                                            1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      UniquesControllers().data.baseSpace * 3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Logo compact dans le header
  Widget _buildCompactLogo() {
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
          Icons.store,
          size: size * 0.5,
          color: CustomTheme.lightScheme().primary,
        ),
      );
    }
  }

  /// Bouton de contact
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

  /// Vérifie si des infos de contact existent
  bool _hasContactInfo() {
    return widget.establishment.telephone.isNotEmpty ||
        widget.establishment.email.isNotEmpty ||
        widget.establishment.address.isNotEmpty;
  }

  /// Récupération du type d'établissement
  Future<String> _getEstablishmentType() async {
    return await _fetchUserTypeName(widget.establishment.userId);
  }

  /// Récupération du user_type.name
  Future<String> _fetchUserTypeName(String userId) async {
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
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
