import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/services/gift_notification_service_simple.dart';

class CelebrationDialogImproved extends StatefulWidget {
  final List<GiftNotification> notifications;
  final VoidCallback onClose;

  const CelebrationDialogImproved({
    super.key,
    required this.notifications,
    required this.onClose,
  });

  @override
  State<CelebrationDialogImproved> createState() => _CelebrationDialogImprovedState();
}

class _CelebrationDialogImprovedState extends State<CelebrationDialogImproved>
    with TickerProviderStateMixin {
  late ConfettiController _leftConfettiController;
  late ConfettiController _rightConfettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize confetti controllers for both sides
    _leftConfettiController = ConfettiController(duration: const Duration(seconds: 5));
    _rightConfettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    // Initialize scale animation with bounce
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    // Initialize bounce animation for the icon
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));
    
    // Start animations
    _leftConfettiController.play();
    _rightConfettiController.play();
    _scaleController.forward();
    _fadeController.forward();
    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _leftConfettiController.dispose();
    _rightConfettiController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  Widget _buildGiftCard(GiftNotification notification) {
    final isPoints = notification.type == 'points';
    final primaryColor = isPoints ? const Color(0xFFFFB800) : const Color(0xFF7C4DFF);
    final secondaryColor = isPoints ? const Color(0xFFFFA000) : const Color(0xFF6200EA);
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec gradient (prend toute la largeur)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor,
                        secondaryColor,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icône animée
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -10 * _bounceAnimation.value),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPoints ? Icons.stars_rounded : Icons.card_giftcard_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isPoints ? '🎉 Points reçus !' : '🎁 Bon cadeau reçu !',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenu
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Montant
                      if (isPoints)
                        Column(
                          children: [
                            Text(
                              '${notification.pointsAmount}',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                height: 1,
                              ),
                            ),
                            Text(
                              'POINTS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor.withOpacity(0.7),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        )
                      else if (notification.voucherData != null)
                        Column(
                          children: [
                            Text(
                              '${notification.voucherData!['amount']}€',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification.voucherData!['establishmentName'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Expéditeur
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'De ${notification.fromName}',
                              style: TextStyle(
                                fontSize: 16,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _nextNotification() {
    if (_currentIndex < widget.notifications.length - 1) {
      setState(() {
        _currentIndex++;
      });
      // Replay confetti for each new notification
      _leftConfettiController.play();
      _rightConfettiController.play();
    } else {
      widget.onClose();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notifications[_currentIndex];
    final hasMore = _currentIndex < widget.notifications.length - 1;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Contenu principal avec animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gift card
                  _buildGiftCard(notification),
                  
                  const SizedBox(height: 20),
                  
                  // Points de navigation
                  if (widget.notifications.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.notifications.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentIndex ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentIndex
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Bouton d'action
                  ElevatedButton(
                    onPressed: _nextNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: notification.type == 'points' 
                          ? const Color(0xFFFFB800)
                          : const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 8,
                      shadowColor: notification.type == 'points' 
                          ? const Color(0xFFFFB800).withOpacity(0.4)
                          : const Color(0xFF7C4DFF).withOpacity(0.4),
                    ),
                    child: Text(
                      hasMore ? 'Suivant' : 'Super !',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Confetti depuis le coin bas gauche
          Positioned(
            bottom: 0,
            left: 0,
            child: ConfettiWidget(
              confettiController: _leftConfettiController,
              blastDirection: -pi / 3, // Tire en diagonale vers le haut-droite
              emissionFrequency: 0.02,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 50,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.red,
                Colors.cyan,
              ],
              createParticlePath: drawStar,
            ),
          ),
          
          // Confetti depuis le coin bas droit
          Positioned(
            bottom: 0,
            right: 0,
            child: ConfettiWidget(
              confettiController: _rightConfettiController,
              blastDirection: -2 * pi / 3, // Tire en diagonale vers le haut-gauche
              emissionFrequency: 0.02,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 50,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.red,
                Colors.cyan,
              ],
              createParticlePath: drawStar,
            ),
          ),
        ],
      ),
    );
  }
}

// Fonction helper mise à jour
Future<void> showCelebrationDialogImproved(
  BuildContext context,
  List<GiftNotification> notifications,
) async {
  if (notifications.isEmpty) return;
  
  final giftService = Get.find<GiftNotificationServiceSimple>();
  
  // Ne pas marquer comme montré si c'est une notification de test
  final hasTestNotification = notifications.any((n) => n.id.startsWith('test-'));
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => CelebrationDialogImproved(
      notifications: notifications,
      onClose: () async {
        // Ne marquer comme montré que les vraies notifications
        if (!hasTestNotification) {
          await giftService.markAllAsShown();
        } else {
          print('🧪 Test notification detected, not marking as shown');
          // Nettoyer les documents de test
          await giftService.cleanTestDocuments();
        }
      },
    ),
  );
}