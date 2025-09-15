import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class SponsorEstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final int index;
  final bool isPremium; // Pour différencier le format standard et bannière
  final VoidCallback? onTap;
  final String? sponsorLevel; // Bronze ou Silver

  const SponsorEstablishmentCard({
    Key? key,
    required this.establishment,
    required this.index,
    this.isPremium = false,
    this.onTap,
    this.sponsorLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = isPremium ? 200.0 : 140.0;

    // Si sponsorLevel n'est pas fourni, on le récupère depuis Firestore
    if (sponsorLevel == null) {
      return FutureBuilder<String>(
        future: _fetchSponsorLevel(),
        builder: (context, snapshot) {
          final level = snapshot.data ?? 'bronze';
          return _buildCard(context, level, cardHeight);
        },
      );
    }

    return _buildCard(context, sponsorLevel!, cardHeight);
  }

  Future<String> _fetchSponsorLevel() async {
    try {
      final querySnapshot = await Get.find<FirebaseFirestore>()
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

  Widget _buildCard(BuildContext context, String level, double cardHeight) {
    return CustomCardAnimation(
      index: index,
      child: Container(
        height: cardHeight,
        margin: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isPremium 
                  ? CustomTheme.lightScheme().primary.withOpacity(0.2)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isPremium ? 20 : 10,
              offset: Offset(0, isPremium ? 8 : 4),
            ),
          ],
          border: isPremium 
              ? Border.all(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                  width: 2,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(isPremium ? 20 : 16),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: isPremium ? 120 : 80,
                    height: isPremium ? 120 : 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: establishment.logoUrl != null && 
                             establishment.logoUrl!.isNotEmpty
                          ? Image.network(
                              establishment.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildLogoPlaceholder();
                              },
                            )
                          : _buildLogoPlaceholder(),
                    ),
                  ),
                  SizedBox(width: 20),
                  
                  // Informations
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge du niveau sponsor
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: level.toLowerCase() == 'silver'
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
                                color: level.toLowerCase() == 'silver'
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
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'SPONSOR ${level.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              if (level.toLowerCase() == 'silver') ...[
                                SizedBox(width: 4),
                                Icon(
                                  Icons.stars,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Nom de l'établissement
                        Text(
                          establishment.name,
                          style: TextStyle(
                            fontSize: isPremium ? 22 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Description courte
                        if (establishment.description.isNotEmpty)
                          Text(
                            establishment.description,
                            style: TextStyle(
                              fontSize: isPremium ? 15 : 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: isPremium ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                        Spacer(),
                        
                        // Contact info (simple)
                        Row(
                          children: [
                            if (establishment.website != null && establishment.website!.isNotEmpty) ...[
                              Icon(
                                Icons.language,
                                size: 16,
                                color: CustomTheme.lightScheme().primary,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  establishment.website ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CustomTheme.lightScheme().primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Flèche
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.business_rounded,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}