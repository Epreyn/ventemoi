// lib/screens/shop_establishment_screen/widgets/special_offers_banner_v2.dart
// Version 2 - Design épuré avec meilleures pratiques UX/UI 2025

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart' as carousel_ctrl;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/models/special_offer.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';

/// Bannière V2 avec design épuré et meilleures pratiques UX/UI 2025
/// - Hauteur augmentée pour meilleure visibilité
/// - Une seule bannière visible à la fois (viewportFraction: 1.0)
/// - Suppression des dégradés latéraux confusants
/// - Marges pour respiration visuelle
/// - Hiérarchie de contenu simplifiée
class SpecialOffersBannerV2 extends StatefulWidget {
  const SpecialOffersBannerV2({super.key});

  @override
  State<SpecialOffersBannerV2> createState() => _SpecialOffersBannerV2State();
}

class _SpecialOffersBannerV2State extends State<SpecialOffersBannerV2> {
  final carousel_ctrl.CarouselSliderController _carouselController =
      carousel_ctrl.CarouselSliderController();
  int _currentIndex = 0;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: UniquesControllers()
          .data
          .firebaseFirestore
          .collection('special_offers')
          .orderBy('priority', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildRequestBannerButton();
        }

        final offers = snapshot.data!.docs
            .map((doc) => SpecialOffer.fromDocument(doc))
            .where((offer) => offer.isActive && offer.isCurrentlyActive)
            .toList();

        if (offers.isEmpty) {
          return _buildRequestBannerButton();
        }

        // Déterminer les paramètres adaptatifs selon les best practices 2025
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 1200;
        final isTablet = screenWidth > 600 && screenWidth <= 1200;
        final isMobile = screenWidth <= 600;

        // Hauteurs augmentées pour meilleure visibilité (best practice UX 2025)
        double bannerHeight;
        double horizontalMargin;

        if (isMobile) {
          bannerHeight = 200;
          horizontalMargin = 16;
        } else if (isTablet) {
          bannerHeight = 220;
          horizontalMargin = 24;
        } else {
          bannerHeight = 240;
          horizontalMargin = 32;
        }

        // Si une seule offre, affichage simple avec bouton
        if (offers.length == 1) {
          return Container(
            height: bannerHeight,
            margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 12),
            child: _buildPremiumBanner(offers.first, isDesktop),
          );
        }

        // Carrousel pour plusieurs offres - Design épuré
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Container(
            height: bannerHeight + 40, // +40 pour pagination et bouton
            child: Stack(
              children: [
                // Carrousel principal
                CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: offers.length,
                  options: CarouselOptions(
                    height: bannerHeight,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 8), // 8s selon best practices
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.easeInOutCubic,
                    enlargeCenterPage: false,
                    viewportFraction: 1.0, // Une seule bannière visible (best practice)
                    enableInfiniteScroll: offers.length > 1,
                    padEnds: false,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 12),
                      child: _buildPremiumBanner(offers[index], isDesktop),
                    );
                  },
                ),

                // Flèches de navigation (desktop uniquement, au hover)
                if (isDesktop && _isHovering && offers.length > 1) ...[
                  Positioned(
                    left: horizontalMargin + 12,
                    top: bannerHeight / 2 - 8,
                    child: _buildNavigationButton(
                      Icons.arrow_back_ios_rounded,
                      () => _carouselController.previousPage(),
                    ),
                  ),
                  Positioned(
                    right: horizontalMargin + 12,
                    top: bannerHeight / 2 - 8,
                    child: _buildNavigationButton(
                      Icons.arrow_forward_ios_rounded,
                      () => _carouselController.nextPage(),
                    ),
                  ),
                ],

                // Indicateurs de pagination
                if (offers.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: _buildPaginationIndicator(offers.length),
                  ),

                // Bouton "Je veux ma pub" - Position fixe en bas à droite
                Positioned(
                  bottom: 4,
                  right: horizontalMargin,
                  child: _buildFloatingRequestButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bannière premium avec design épuré et hiérarchie claire
  Widget _buildPremiumBanner(SpecialOffer offer, bool isDesktop) {
    final bgColor = _parseHexColor(offer.backgroundColor ?? '#FF6B35');
    final textColor = _parseHexColor(offer.textColor ?? '#FFFFFF');
    final hasImage = offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTap: offer.linkUrl != null && offer.linkUrl!.isNotEmpty
          ? () => _openLink(offer.linkUrl!)
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // Plus moderne
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fond coloré
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgColor,
                      bgColor.withOpacity(0.85),
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
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),

              // Overlay pour lisibilité
              if (hasImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // Contenu - Hiérarchie simplifiée avec gestion overflow
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge unique (priorité au plus important)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: textColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎁', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              'OFFRE DU MOMENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Titre - 1 ligne maximum (best practice)
                      Text(
                        offer.title,
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Description - 2 lignes maximum (best practice)
                      Flexible(
                        child: Text(
                          offer.description,
                          style: TextStyle(
                            fontSize: isDesktop ? 15 : 13,
                            color: textColor.withOpacity(0.95),
                            height: 1.3,
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

                      const SizedBox(height: 12),

                      // CTA proéminent (best practice)
                      if (offer.buttonText != null && offer.buttonText!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: textColor,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (offer.linkUrl != null && offer.linkUrl!.isNotEmpty) ...[
                                const SizedBox(width: 6),
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
                  ),
                ),
              ),

              // Effet de brillance subtil
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
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
      color: Colors.white.withOpacity(0.95),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: Colors.grey[800]),
        ),
      ),
    );
  }

  Widget _buildPaginationIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentIndex == index
                ? Colors.orange
                : Colors.grey.withOpacity(0.4),
            boxShadow: _currentIndex == index
                ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingRequestButton() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => Get.toNamed(Routes.proRequestOffer),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Je veux ma pub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestBannerButton() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(Routes.proRequestOffer),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Je veux ma pub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
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
