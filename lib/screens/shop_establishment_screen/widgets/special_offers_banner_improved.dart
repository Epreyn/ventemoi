import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart' as carousel_ctrl;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/models/special_offer.dart';
import '../../../core/classes/unique_controllers.dart';

class SpecialOffersBannerImproved extends StatefulWidget {
  const SpecialOffersBannerImproved({super.key});

  @override
  State<SpecialOffersBannerImproved> createState() => _SpecialOffersBannerImprovedState();
}

class _SpecialOffersBannerImprovedState extends State<SpecialOffersBannerImproved> with WidgetsBindingObserver {
  carousel_ctrl.CarouselSliderController? _carouselController;
  int _currentIndex = 0;
  bool _isDisposed = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carouselController = carousel_ctrl.CarouselSliderController();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isPaused = true;
    WidgetsBinding.instance.removeObserver(this);
    _carouselController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isPaused = true;
        break;
      case AppLifecycleState.resumed:
        _isPaused = false;
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;
    
    return StreamBuilder<QuerySnapshot>(
      stream: UniquesControllers()
          .data
          .firebaseFirestore
          .collection('special_offers')
          .where('is_active', isEqualTo: true)
          .orderBy('priority', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final offers = snapshot.data!.docs
            .map((doc) => SpecialOffer.fromDocument(doc))
            .where((offer) => offer.isActive && offer.isCurrentlyActive)
            .toList();

        if (offers.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sur desktop, afficher une grille d'offres
        if (isDesktop && offers.length > 1) {
          return _buildDesktopGrid(offers);
        }
        
        // Sur tablette, afficher 2 offres côte à côte
        if (isTablet && offers.length > 1) {
          return _buildTabletLayout(offers);
        }

        // Sur mobile ou une seule offre
        return _buildMobileCarousel(offers);
      },
    );
  }

  Widget _buildDesktopGrid(List<SpecialOffer> offers) {
    // Afficher jusqu'à 3 offres côte à côte
    final itemsToShow = offers.take(3).toList();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: itemsToShow.map((offer) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: offer != itemsToShow.last ? 12 : 0,
              ),
              child: _buildCompactOfferCard(offer),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabletLayout(List<SpecialOffer> offers) {
    // Afficher 2 offres côte à côte sur tablette
    final itemsToShow = offers.take(2).toList();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: itemsToShow.map((offer) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: offer != itemsToShow.last ? 12 : 0,
              ),
              child: _buildCompactOfferCard(offer),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCarousel(List<SpecialOffer> offers) {
    if (offers.length == 1) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: _buildModernBanner(offers.first),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Stack(
          children: [
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: offers.length,
              options: CarouselOptions(
                height: 140,
                autoPlay: !_isPaused && !_isDisposed,
                autoPlayInterval: const Duration(seconds: 6),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.easeInOutCubic,
                enlargeCenterPage: true,
                viewportFraction: 0.92,
                enableInfiniteScroll: offers.length > 1,
                pauseAutoPlayOnTouch: true,
                pauseAutoPlayOnManualNavigate: true,
                pauseAutoPlayInFiniteScroll: false,
                onPageChanged: (index, reason) {
                  // Éviter les updates pendant la destruction
                  if (_isDisposed || !mounted) return;

                  // Éviter les setState trop fréquents
                  if (_currentIndex != index) {
                    Future.microtask(() {
                      if (!_isDisposed && mounted) {
                        setState(() {
                          _currentIndex = index;
                        });
                      }
                    });
                  }
                },
              ),
              itemBuilder: (context, index, realIndex) {
                return _buildModernBanner(offers[index]);
              },
            ),
            if (offers.length > 1) ...[
              Positioned(
                left: 8,
                top: 55,
                child: _buildNavigationButton(
                  Icons.arrow_back_ios_rounded,
                  () {
                    if (!_isDisposed && _carouselController != null) {
                      _carouselController?.previousPage();
                    }
                  },
                ),
              ),
              Positioned(
                right: 8,
                top: 55,
                child: _buildNavigationButton(
                  Icons.arrow_forward_ios_rounded,
                  () {
                    if (!_isDisposed && _carouselController != null) {
                      _carouselController?.nextPage();
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        if (offers.length > 1) ...[
          const SizedBox(height: 8),
          _buildPaginationIndicator(offers.length),
        ],
      ],
    );
  }

  Widget _buildCompactOfferCard(SpecialOffer offer) {
    final bgColor = _parseHexColor(offer.backgroundColor ?? '#FFF3CD');
    final textColor = _parseHexColor(offer.textColor ?? '#856404');
    final hasImage = offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTap: offer.linkUrl != null && offer.linkUrl!.isNotEmpty
          ? () => _openLink(offer.linkUrl!)
          : null,
      child: Container(
        height: 200,
        constraints: BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: bgColor.withOpacity(0.15),
          border: Border.all(
            color: bgColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image en haut (ratio 16:9)
              if (hasImage)
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.2),
                  ),
                  child: Image.network(
                    offer.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: bgColor.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.local_offer,
                            size: 40,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 80,
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
                  child: Center(
                    child: Icon(
                      Icons.local_offer_rounded,
                      size: 40,
                      color: textColor.withOpacity(0.3),
                    ),
                  ),
                ),
              
              // Contenu texte
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'OFFRE DU MOMENT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Titre
                      Text(
                        offer.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Description
                      Expanded(
                        child: Text(
                          offer.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Bouton
                      if (offer.buttonText != null && offer.buttonText!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: offer.linkUrl != null && offer.linkUrl!.isNotEmpty
                                      ? () => _openLink(offer.linkUrl!)
                                      : null,
                                  style: TextButton.styleFrom(
                                    backgroundColor: bgColor.withOpacity(0.1),
                                    foregroundColor: textColor,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    offer.buttonText!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBanner(SpecialOffer offer) {
    final bgColor = _parseHexColor(offer.backgroundColor ?? '#FFF3CD');
    final textColor = _parseHexColor(offer.textColor ?? '#856404');
    final hasImage = offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty;

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
              // Fond coloré ou image
              if (hasImage)
                Positioned.fill(
                  child: Image.network(
                    offer.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [bgColor, bgColor.withOpacity(0.8)],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [bgColor, bgColor.withOpacity(0.8)],
                    ),
                  ),
                ),
              
              // Overlay gradient pour lisibilité
              if (hasImage)
                Container(
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
              
              // Contenu
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasImage ? Colors.white.withOpacity(0.2) : textColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: hasImage ? Colors.white.withOpacity(0.3) : textColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '🎁 OFFRE DU MOMENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: hasImage ? Colors.white : textColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Titre
                          Text(
                            offer.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: hasImage ? Colors.white : textColor,
                              shadows: hasImage ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ] : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Description
                          Text(
                            offer.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasImage ? Colors.white.withOpacity(0.95) : textColor.withOpacity(0.9),
                              height: 1.2,
                              shadows: hasImage ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ] : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Bouton
                    if (offer.buttonText != null && offer.buttonText!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: hasImage ? Colors.white.withOpacity(0.95) : textColor.withOpacity(0.95),
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
                                color: hasImage ? bgColor : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: hasImage ? bgColor : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: Colors.grey[800]),
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
            color: _currentIndex == index ? Colors.orange : Colors.grey.withOpacity(0.3),
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
    return Colors.amber[100]!;
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