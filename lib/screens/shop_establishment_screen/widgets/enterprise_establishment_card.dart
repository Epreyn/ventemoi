import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class EnterpriseEstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final int index;
  final RxMap<String, String> enterpriseCategoriesMap;

  const EnterpriseEstablishmentCard({
    super.key,
    required this.establishment,
    required this.index,
    required this.enterpriseCategoriesMap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardAnimation(
      index: index,
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER identique à ShopEstablishmentCard
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
                            // Nom
                            Text(
                              establishment.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18 * widthScale,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Bouton vidéo si disponible
                      if (establishment.videoUrl.isNotEmpty)
                        IconButton(
                          onPressed: () => _launchVideo(establishment.videoUrl),
                          icon: Icon(
                            Icons.play_circle_filled,
                            color: CustomTheme.lightScheme().primary,
                            size: 32 * widthScale,
                          ),
                        ),
                    ],
                  ),
                ),

                // Catégories Enterprise
                if (establishment.enterpriseCategoryIds != null &&
                    establishment.enterpriseCategoryIds!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          establishment.enterpriseCategoryIds!.map((catId) {
                        final catName = enterpriseCategoriesMap[catId] ?? catId;
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace,
                            vertical: UniquesControllers().data.baseSpace / 2,
                          ),
                          decoration: BoxDecoration(
                            color: CustomTheme.lightScheme()
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              UniquesControllers().data.baseSpace,
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
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: UniquesControllers().data.baseSpace * 2),

                // BANNIÈRE AVEC DESCRIPTION
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        UniquesControllers().data.baseSpace,
                      ),
                      color: establishment.bannerUrl.isEmpty
                          ? Colors.grey[100]
                          : null,
                      image: establishment.bannerUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(establishment.bannerUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          UniquesControllers().data.baseSpace,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      padding: EdgeInsets.all(
                          UniquesControllers().data.baseSpace * 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            establishment.description,
                            style: TextStyle(
                              fontSize: 14 * widthScale,
                              color: Colors.white,
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.justify,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // CONTACT RAPIDE
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
                        if (establishment.telephone.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.phone,
                            label: 'Appeler',
                            onTap: () => _launchTel(establishment.telephone),
                            scale: widthScale,
                          ),
                        if (establishment.email.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.email,
                            label: 'Email',
                            onTap: () => _launchEmail(establishment.email),
                            scale: widthScale,
                          ),
                        if (establishment.address.isNotEmpty)
                          _buildContactButton(
                            icon: Icons.directions,
                            label: 'Itinéraire',
                            onTap: () => _launchMaps(establishment.address),
                            scale: widthScale,
                          ),
                      ],
                    ),
                  ),

                // FOOTER spécifique entreprise
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 20 * widthScale,
                        color: CustomTheme.lightScheme().primary,
                      ),
                      SizedBox(width: UniquesControllers().data.baseSpace),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entreprise partenaire',
                              style: TextStyle(
                                fontSize: 14 * widthScale,
                                fontWeight: FontWeight.bold,
                                color: CustomTheme.lightScheme().primary,
                              ),
                            ),
                            if (establishment.hasAcceptedContract)
                              Text(
                                'Certifiée VenteMoi',
                                style: TextStyle(
                                  fontSize: 12 * widthScale,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (establishment.hasAcceptedContract)
                        Icon(
                          Icons.verified,
                          color: CustomTheme.lightScheme().primary,
                          size: 24 * widthScale,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Méthodes helper identiques à ShopEstablishmentCard
  Widget _buildCompactLogo() {
    final size = UniquesControllers().data.baseSpace * 7;
    if (establishment.logoUrl.isNotEmpty) {
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
            image: NetworkImage(establishment.logoUrl),
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
          Icons.business,
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
    return establishment.telephone.isNotEmpty ||
        establishment.email.isNotEmpty ||
        establishment.address.isNotEmpty;
  }

  // Méthodes de lancement
  Future<void> _launchVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
