// Créer ce nouveau fichier pour la carte modernisée
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class ModernEstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final VoidCallback? onTap;
  final int index;
  final bool isEnterprise;

  const ModernEstablishmentCard({
    Key? key,
    required this.establishment,
    this.onTap,
    required this.index,
    required this.isEnterprise,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tout le code de la section 5 va ici
    return CustomCardAnimation(
      index: index,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          establishment.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ajouter toutes les méthodes helper de la section 5
  Widget _buildImageSection() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        image: establishment.bannerUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(establishment.bannerUrl),
                fit: BoxFit.cover,
              )
            : null,
        gradient: establishment.bannerUrl.isEmpty
            ? LinearGradient(
                colors: [
                  CustomTheme.lightScheme().primary.withOpacity(0.3),
                  CustomTheme.lightScheme().primary.withOpacity(0.1),
                ],
              )
            : null,
      ),
      child: Stack(
        children: [
          // Logo
          Positioned(
            bottom: -20,
            left: 16,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: establishment.logoUrl.isNotEmpty
                    ? Image.network(
                        establishment.logoUrl,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.store,
                        color: CustomTheme.lightScheme().primary,
                      ),
              ),
            ),
          ),

          // Badge vidéo
          if (establishment.videoUrl.isNotEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Vidéo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                establishment.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (establishment.hasAcceptedContract)
              Icon(
                Icons.verified,
                size: 16,
                color: CustomTheme.lightScheme().primary,
              ),
          ],
        ),
        const SizedBox(height: 4),
        _buildCategoryChip(),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return FutureBuilder<String>(
      future: _getCategoryName(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: CustomTheme.lightScheme().primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            snapshot.data!,
            style: TextStyle(
              fontSize: 11,
              color: CustomTheme.lightScheme().primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    if (isEnterprise) {
      return _buildEnterpriseFooter();
    }

    return _buildShopFooter();
  }

  Widget _buildShopFooter() {
    return StreamBuilder<QuerySnapshot>(
      stream: UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: establishment.userId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final coupons = data['coupons'] ?? 0;

        return Row(
          children: [
            Icon(
              Icons.confirmation_number,
              size: 16,
              color: coupons > 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              '$coupons bons',
              style: TextStyle(
                fontSize: 12,
                color: coupons > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (onTap != null && coupons > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CustomTheme.lightScheme().primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Acheter',
                  style: TextStyle(
                    color: CustomTheme.lightScheme().onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEnterpriseFooter() {
    return Row(
      children: [
        if (establishment.telephone.isNotEmpty)
          _buildContactIcon(
              Icons.phone, () => _launchTel(establishment.telephone)),
        if (establishment.email.isNotEmpty)
          _buildContactIcon(
              Icons.email, () => _launchEmail(establishment.email)),
        if (establishment.address.isNotEmpty)
          _buildContactIcon(
              Icons.location_on, () => _launchMaps(establishment.address)),
      ],
    );
  }

  Widget _buildContactIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: CustomTheme.lightScheme().primary,
          ),
        ),
      ),
    );
  }

  // Méthodes helper
  Future<String> _getCategoryName() async {
    if (establishment.categoryId.isEmpty) return '';

    final doc = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .doc(establishment.categoryId)
        .get();

    return doc.data()?['name'] ?? '';
  }

  void _launchTel(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
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
}
