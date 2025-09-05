import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class SponsorEstablishmentCard extends StatelessWidget {
  final Establishment establishment;
  final int index;
  final bool isPremium; // Pour différencier le format standard et bannière
  final VoidCallback? onTap;

  const SponsorEstablishmentCard({
    Key? key,
    required this.establishment,
    required this.index,
    this.isPremium = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = isPremium ? 200.0 : 140.0;
    
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
                        // Badge Premium si applicable
                        if (isPremium)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber[600]!,
                                  Colors.orange[600]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'SPONSOR PREMIUM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
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