import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class ShopEstablishmentMobileCard extends StatefulWidget {
  final Establishment establishment;
  final bool isEnterprise;
  final bool isOwnEstablishment;
  final VoidCallback? onBuy;
  final int index;
  final RxMap<String, String> enterpriseCategoriesMap;

  const ShopEstablishmentMobileCard({
    Key? key,
    required this.establishment,
    required this.isEnterprise,
    required this.isOwnEstablishment,
    this.onBuy,
    required this.index,
    required this.enterpriseCategoriesMap,
  }) : super(key: key);

  @override
  State<ShopEstablishmentMobileCard> createState() =>
      _ShopEstablishmentMobileCardState();
}

class _ShopEstablishmentMobileCardState
    extends State<ShopEstablishmentMobileCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
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
                : null,
          ),
          child: Column(
            children: [
              // Partie toujours visible avec bannière en overlay
              ClipRRect(
                borderRadius: _isExpanded 
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    )
                  : BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Bannière en overlay sur le dernier tiers (EN PREMIER pour être derrière)
                    if (widget.establishment.bannerUrl.isNotEmpty)
                      Positioned.fill(
                        left: MediaQuery.of(context).size.width * 0.65, // Commence aux 2/3
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
                    // Contenu principal (AU-DESSUS de la bannière)
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Logo
                          _buildCompactLogo(),
                          const SizedBox(width: 12),
                          // Informations principales
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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
                                          color: CustomTheme.lightScheme()
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
                          const SizedBox(height: 6),
                          // Catégorie (type de boutique)
                          Row(
                            children: [
                              Icon(
                                _getCategoryIcon(),
                                size: 14,
                                color: CustomTheme.lightScheme().primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: FutureBuilder<String>(
                                  future: _getCategoryName(),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ?? 'Chargement...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            CustomTheme.lightScheme().primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Stock de bons ou points pour entreprises
                          if (!widget.isEnterprise)
                            StreamBuilder<QuerySnapshot>(
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
                                  return const SizedBox();
                                }

                                final data = walletSnap.data!.docs.first.data()
                                    as Map<String, dynamic>;
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
                                        color: coupons > 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$coupons bons disponibles',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: coupons > 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          // Pour les entreprises, afficher un indicateur de cashback
                          if (widget.isEnterprise)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.savings,
                                    size: 14,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cashback disponible',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                              ],
                            ),
                          ),
                          // Actions rapides (vidéo et expand)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.establishment.videoUrl.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _launchVideo(widget.establishment.videoUrl);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: CustomTheme.lightScheme().primary,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CustomTheme.lightScheme()
                                              .primary
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
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

              // Partie expansible (description et actions)
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
                                () =>
                                    _launchTel(widget.establishment.telephone),
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
                                'Localiser',
                                () => _launchMaps(widget.establishment.address),
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      // Bouton d'action principal
                      if (!widget.isEnterprise) _buildActionButton(),
                      if (widget.isEnterprise)
                        ElevatedButton.icon(
                          onPressed: () => _showPointsSimulator(context),
                          icon: const Icon(Icons.calculate, size: 18),
                          label: const Text('Simulateur de points'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomTheme.lightScheme().primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
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

  Widget _buildCompactLogo() {
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
          widget.isEnterprise ? Icons.business : Icons.store,
          size: 24,
          color: CustomTheme.lightScheme().primary,
        ),
      );
    }
  }

  IconData _getCategoryIcon() {
    // Icônes par défaut selon le type
    if (widget.isEnterprise) return Icons.business_center;

    // Pour les associations
    final userTypeName = _getUserTypeName();
    if (userTypeName == 'Association') return Icons.volunteer_activism;

    // Pour les boutiques, on peut personnaliser selon la catégorie
    return Icons.shopping_bag;
  }

  String _getUserTypeName() {
    // Cette méthode pourrait être améliorée pour récupérer le vrai nom
    // Pour l'instant on se base sur isEnterprise
    if (widget.isEnterprise) return 'Entreprise';
    return 'Boutique';
  }

  Future<String> _getCategoryName() async {
    if (widget.isEnterprise) {
      // Pour les entreprises, prendre la première catégorie
      if (widget.establishment.enterpriseCategoryIds != null &&
          widget.establishment.enterpriseCategoryIds!.isNotEmpty) {
        final firstCatId = widget.establishment.enterpriseCategoryIds!.first;
        return widget.enterpriseCategoriesMap[firstCatId] ?? 'Entreprise';
      }
      return 'Entreprise partenaire';
    } else {
      // Pour les boutiques/associations
      if (widget.establishment.categoryId.isEmpty) return 'Non catégorisé';

      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('categories')
          .doc(widget.establishment.categoryId)
          .get();

      return doc.data()?['name'] ?? 'Non catégorisé';
    }
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

  Widget _buildActionButton() {
    return FutureBuilder<String>(
      future: _fetchUserTypeName(widget.establishment.userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 40);
        }

        final typeName = snap.data ?? '';
        final isAssociation = typeName == 'Association';

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

            final data =
                walletSnap.data!.docs.first.data() as Map<String, dynamic>;
            final coupons = data['coupons'] ?? 0;
            final isDisabled =
                widget.isOwnEstablishment || (!isAssociation && coupons == 0);

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isDisabled ? null : widget.onBuy,
                icon: Icon(
                  isAssociation
                      ? Icons.volunteer_activism
                      : Icons.shopping_cart,
                  size: 18,
                ),
                label: Text(
                  widget.isOwnEstablishment
                      ? 'Votre établissement'
                      : (isAssociation ? 'Faire un don' : 'Acheter des bons'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isOwnEstablishment
                      ? Colors.grey
                      : (isAssociation
                          ? Colors.green
                          : CustomTheme.lightScheme().primary),
                  foregroundColor: Colors.white,
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
      },
    );
  }

  bool _hasContactInfo() {
    return widget.establishment.telephone.isNotEmpty ||
        widget.establishment.email.isNotEmpty ||
        widget.establishment.address.isNotEmpty;
  }

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
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showPointsSimulator(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final RxString calculatedPoints = '0'.obs;
    final RxDouble enteredAmount = 0.0.obs;

    const double cashbackRate = 0.02; // 2%

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.calculate,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Simulateur de points',
                style: TextStyle(
                  color: CustomTheme.lightScheme().primary,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: '€',
                    suffixStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                    hintText: '0.00',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: CustomTheme.lightScheme().primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    final amount =
                        double.tryParse(value.replaceAll(',', '.')) ?? 0;
                    enteredAmount.value = amount;
                    final points = (amount * cashbackRate).round();
                    calculatedPoints.value = points.toString();
                  },
                ),
                const SizedBox(height: 24),
                Obx(
                  () => enteredAmount.value > 0
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CustomTheme.lightScheme().primary,
                                CustomTheme.lightScheme().primary.withBlue(200),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Vous gagnerez',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                '${calculatedPoints.value} points',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Pour ${enteredAmount.value.toStringAsFixed(2)}€',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Entrez un montant pour calculer vos points',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ],
            ),
          ),
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
}
