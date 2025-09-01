// lib/screens/shop_establishment_screen/widgets/special_offers_banner.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart' as carousel_ctrl;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/models/special_offer.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';

class SpecialOffersBanner extends StatefulWidget {
  const SpecialOffersBanner({super.key});

  @override
  State<SpecialOffersBanner> createState() => _SpecialOffersBannerState();
}

class _SpecialOffersBannerState extends State<SpecialOffersBanner> {
  final carousel_ctrl.CarouselSliderController _carouselController = carousel_ctrl.CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Vérifier si l'utilisateur est une entreprise/boutique
    final userType = UniquesControllers().getStorage.read('currentUserType');
    final isBusinessUser = userType == 'Boutique' || userType == 'Entreprise' || 
                          userType == 'Sponsor' || userType == 'Association';
    
    // Pour le moment, on affiche toujours le bouton pour tous les utilisateurs
    final showRequestButton = true; // isBusinessUser;
    
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: UniquesControllers()
              .data
              .firebaseFirestore
              .collection('special_offers')
              .orderBy('priority', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              // Si pas d'offres mais on veut montrer le bouton, montrer quand même le bouton
              if (showRequestButton) {
                return _buildRequestBannerButton();
              }
              return const SizedBox.shrink();
            }

            final offers = snapshot.data!.docs
                .map((doc) => SpecialOffer.fromDocument(doc))
                .where((offer) => offer.isActive && offer.isCurrentlyActive)
                .toList();

            if (offers.isEmpty && !showRequestButton) {
              return const SizedBox.shrink();
            }

            // Si une seule offre, affichage simple
            if (offers.length == 1) {
              return Container(
                margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                child: _buildModernBanner(offers.first),
              );
            }

            // Si plusieurs offres, carrousel avec contrôles
            return Column(
          children: [
            const SizedBox(height: 12), // Espace en haut
            Stack(
              children: [
                CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: offers.length,
                  options: CarouselOptions(
                    height: 140,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 6),
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.easeInOutCubic,
                    enlargeCenterPage: true,
                    viewportFraction: 0.92,
                    enableInfiniteScroll: offers.length > 1,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    return _buildModernBanner(offers[index]);
                  },
                ),
                // Flèches de navigation
                Positioned(
                  left: 8,
                  top: 55,
                  child: _buildNavigationButton(
                    Icons.arrow_back_ios_rounded,
                    () => _carouselController.previousPage(),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 55,
                  child: _buildNavigationButton(
                    Icons.arrow_forward_ios_rounded,
                    () => _carouselController.nextPage(),
                  ),
                ),
              ],
            ),
            // Indicateurs de pagination
            const SizedBox(height: 8),
            _buildPaginationIndicator(offers.length),
              ],
            );
          },
        ),
        // Bouton pour demander une bannière
        if (showRequestButton) _buildRequestBannerButton(),
      ],
    );
  }

  Widget _buildModernBanner(SpecialOffer offer) {
    final bgColor = _parseHexColor(offer.backgroundColor ?? '#FF6B35');
    final textColor = _parseHexColor(offer.textColor ?? '#FFFFFF');
    final hasImage = offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty;

    // Debug pour voir l'URL
    if (hasImage) {
      print('🖼️ Tentative de chargement image: ${offer.imageUrl}');
    }

    return GestureDetector(
      onTap: offer.linkUrl != null && offer.linkUrl!.isNotEmpty
          ? () => _openLink(offer.linkUrl!)
          : null,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: bgColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fond de base coloré
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgColor,
                      bgColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              
              // Image de fond si disponible
              if (hasImage) 
                Positioned.fill(
                  child: Image.network(
                    offer.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: bgColor.withOpacity(0.5),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Erreur image: $error');
                      print('📍 URL tentée: ${offer.imageUrl}');
                      // Afficher une icône d'image cassée sur le fond coloré
                      return Container(
                        color: bgColor.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: textColor.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              // Dégradé pour assurer la lisibilité du texte
              if (hasImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              
              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Partie gauche - Textes
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Badges sur la même ligne
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              // Badge "Offre du moment"
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: textColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '🎁',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'OFFRE DU MOMENT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Badge période si dates définies
                              if (offer.startDate != null || offer.endDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: textColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: textColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getDateRangeText(offer),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Titre
                          Flexible(
                            child: Text(
                              offer.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Description
                          Flexible(
                            child: Text(
                              offer.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withOpacity(0.95),
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Partie droite - Bouton d'action
                    if (offer.buttonText != null && offer.buttonText!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              offer.buttonText!,
                              style: TextStyle(
                                color: bgColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (offer.linkUrl != null && offer.linkUrl!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: bgColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Effet de brillance
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentIndex == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentIndex == index
                ? Colors.orange
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  String _getDateRangeText(SpecialOffer offer) {
    final formatter = DateFormat('d MMM', 'fr_FR');
    
    if (offer.startDate != null && offer.endDate != null) {
      return 'Du ${formatter.format(offer.startDate!)} au ${formatter.format(offer.endDate!)}';
    } else if (offer.startDate != null) {
      return 'À partir du ${formatter.format(offer.startDate!)}';
    } else if (offer.endDate != null) {
      return 'Jusqu\'au ${formatter.format(offer.endDate!)}';
    }
    return '';
  }

  Widget _buildRequestBannerButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Naviguer vers la page de demande d'offre
            Get.toNamed(Routes.proRequestOffer);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Je veux ma bannière publicitaire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NOUVEAU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Color _parseHexColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        return Color(int.parse('0xFF$hexColor'));
      }
    } catch (e) {}
    return Colors.orange;
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir le lien',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}