import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class SponsorCardStyled extends StatelessWidget {
  final Establishment establishment;
  final int index;
  final bool isOwnEstablishment;

  const SponsorCardStyled({
    super.key,
    required this.establishment,
    required this.index,
    this.isOwnEstablishment = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCardAnimation(
      index: index,
      child: FutureBuilder<String>(
        future: _fetchSponsorLevel(),
        builder: (context, snapshot) {
          final sponsorLevel = snapshot.data ?? 'bronze';
          final isSilver = sponsorLevel.toLowerCase() == 'silver';

          return LayoutBuilder(
            builder: (ctx, constraints) {
              final cardWidth = constraints.maxWidth;
              final widthScale = cardWidth / 300.0;

              return Card(
                elevation: UniquesControllers().data.baseSpace,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    UniquesControllers().data.baseSpace * 2,
                  ),
                  side: isOwnEstablishment
                      ? BorderSide(
                          color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER avec badge sponsor
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
                                        establishment.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18 * widthScale,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isOwnEstablishment)
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
                              ],
                            ),
                          ),
                          // Badge sponsor en haut à droite (à la place du cashback)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
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
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isSilver
                                      ? Colors.grey.withOpacity(0.3)
                                      : Colors.brown.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
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
                                SizedBox(width: 4),
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
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.stars,
                                    size: 14 * widthScale,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Catégories (type de sponsor)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: UniquesControllers().data.baseSpace * 2,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 14 * widthScale,
                                  color: CustomTheme.lightScheme().primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sponsor officiel',
                                  style: TextStyle(
                                    fontSize: 12 * widthScale,
                                    color: CustomTheme.lightScheme().primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: UniquesControllers().data.baseSpace * 2,
                      ),
                      child: Text(
                        establishment.description,
                        style: TextStyle(
                          fontSize: 13 * widthScale,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bannière avec image de fond
                    if (establishment.bannerUrl.isNotEmpty)
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace * 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              UniquesControllers().data.baseSpace * 2,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(establishment.bannerUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    else
                      // Si pas de bannière, afficher un placeholder ou plus de description
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 2,
                          ),
                          padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isSilver
                                  ? [
                                      Color(0xFFB8B8B8).withOpacity(0.1),
                                      Color(0xFF7D7D7D).withOpacity(0.05),
                                    ]
                                  : [
                                      Color(0xFFCD7F32).withOpacity(0.1),
                                      Color(0xFF8B4513).withOpacity(0.05),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(
                              UniquesControllers().data.baseSpace * 2,
                            ),
                            border: Border.all(
                              color: isSilver
                                  ? Colors.grey.withOpacity(0.2)
                                  : Colors.brown.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  size: 48 * widthScale,
                                  color: isSilver
                                      ? Color(0xFF7D7D7D)
                                      : Color(0xFF8B4513),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'SPONSOR ${isSilver ? "SILVER" : "BRONZE"}',
                                  style: TextStyle(
                                    fontSize: 16 * widthScale,
                                    fontWeight: FontWeight.bold,
                                    color: isSilver
                                        ? Color(0xFF7D7D7D)
                                        : Color(0xFF8B4513),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Partenaire officiel de l\'application',
                                  style: TextStyle(
                                    fontSize: 12 * widthScale,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Contact rapide
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
                            if (establishment.website != null &&
                                establishment.website!.isNotEmpty)
                              _buildContactButton(
                                icon: Icons.language,
                                label: 'Site web',
                                onTap: () => _launchUrl(establishment.website!),
                                scale: widthScale,
                              ),
                          ],
                        ),
                      ),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String> _fetchSponsorLevel() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('establishments')
          .where('user_id', isEqualTo: establishment.userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return data['sponsor_level'] ?? 'bronze';
      }
    } catch (e) {
      // En cas d'erreur, retourner bronze par défaut
    }
    return 'bronze';
  }

  Widget _buildCompactLogo() {
    const size = 60.0;
    if (establishment.logoUrl != null && establishment.logoUrl!.isNotEmpty) {
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
            image: NetworkImage(establishment.logoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.business_rounded,
          size: 30,
          color: Colors.grey[400],
        ),
      );
    }
  }

  bool _hasContactInfo() {
    return establishment.telephone.isNotEmpty ||
        establishment.email.isNotEmpty ||
        (establishment.website != null && establishment.website!.isNotEmpty);
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double scale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20 * scale,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11 * scale,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
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

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
                establishment.name,
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
              'Sponsor officiel de l\'application',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CustomTheme.lightScheme().primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              establishment.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (establishment.website != null &&
                establishment.website!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _launchUrl(establishment.website!),
                child: Text(
                  establishment.website!,
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
}