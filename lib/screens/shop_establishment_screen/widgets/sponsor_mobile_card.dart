import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class SponsorMobileCard extends StatefulWidget {
  final Establishment establishment;
  final int index;
  final bool isOwnEstablishment;

  const SponsorMobileCard({
    Key? key,
    required this.establishment,
    required this.index,
    this.isOwnEstablishment = false,
  }) : super(key: key);

  @override
  State<SponsorMobileCard> createState() => _SponsorMobileCardState();
}

class _SponsorMobileCardState extends State<SponsorMobileCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return CustomCardAnimation(
      index: widget.index,
      child: FutureBuilder<String>(
        future: _fetchSponsorLevel(),
        builder: (context, snapshot) {
          final sponsorLevel = snapshot.data ?? 'bronze';
          final isSilver = sponsorLevel.toLowerCase() == 'silver';

          return GestureDetector(
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
                  // Partie toujours visible
                  ClipRRect(
                    borderRadius: _isExpanded
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        )
                      : BorderRadius.circular(16),
                    child: Container(
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
                                // Badge sponsor
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
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
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.workspace_premium,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'SPONSOR ${isSilver ? 'SILVER' : 'BRONZE'}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (isSilver) ...[
                                        const SizedBox(width: 3),
                                        Icon(
                                          Icons.stars,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Catégorie
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 14,
                                      color: CustomTheme.lightScheme().primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sponsor officiel',
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
                              ],
                            ),
                          ),
                          // Flèche d'expansion
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
                    ),
                  ),

                  // Partie expansible (description et contacts)
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
                                    () => _launchTel(widget.establishment.telephone),
                                  ),
                                if (widget.establishment.email.isNotEmpty)
                                  _buildContactChip(
                                    Icons.email,
                                    'Email',
                                    () => _launchEmail(widget.establishment.email),
                                  ),
                                if (widget.establishment.website != null &&
                                    widget.establishment.website!.isNotEmpty)
                                  _buildContactChip(
                                    Icons.language,
                                    'Site web',
                                    () => _launchUrl(widget.establishment.website!),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
      // En cas d'erreur, retourner bronze par défaut
    }
    return 'bronze';
  }

  Widget _buildCompactLogo() {
    const size = 48.0;
    if (widget.establishment.logoUrl != null &&
        widget.establishment.logoUrl!.isNotEmpty) {
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
            image: NetworkImage(widget.establishment.logoUrl!),
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
          size: 24,
          color: Colors.grey[400],
        ),
      );
    }
  }

  bool _hasContactInfo() {
    return widget.establishment.telephone.isNotEmpty ||
        widget.establishment.email.isNotEmpty ||
        (widget.establishment.website != null &&
         widget.establishment.website!.isNotEmpty);
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
}