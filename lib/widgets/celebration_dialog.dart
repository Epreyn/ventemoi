import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/services/gift_notification_service_simple.dart';

class CelebrationDialog extends StatefulWidget {
  final List<GiftNotification> notifications;
  final VoidCallback onClose;

  const CelebrationDialog({
    Key? key,
    required this.notifications,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Initialize scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    // Start animations
    _confettiController.play();
    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
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
    final primaryColor = isPoints ? Colors.amber : Colors.purple;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.shade300,
            primaryColor.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPoints ? Icons.star_rounded : Icons.card_giftcard_rounded,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            isPoints ? 'Points reçus !' : 'Bon cadeau reçu !',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (isPoints)
            Text(
              '${notification.pointsAmount} points',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            )
          else if (notification.voucherData != null)
            Column(
              children: [
                Text(
                  '${notification.voucherData!['amount']}€',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.voucherData!['establishmentName'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'De : ${notification.fromName}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextNotification() {
    if (_currentIndex < widget.notifications.length - 1) {
      setState(() {
        _currentIndex++;
      });
      // Replay confetti for each new notification
      _confettiController.play();
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // Main content
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gift card
                  _buildGiftCard(notification),
                  
                  const SizedBox(height: 20),
                  
                  // Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.notifications.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: List.generate(
                              widget.notifications.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == _currentIndex
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action button
                  ElevatedButton(
                    onPressed: _nextNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: notification.type == 'points' 
                          ? Colors.amber.shade700 
                          : Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      hasMore ? 'Suivant' : 'Fermer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.red,
              ],
              createParticlePath: drawStar,
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
              blastDirection: pi / 2,
              maxBlastForce: 100,
              minBlastForce: 80,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the celebration dialog
Future<void> showCelebrationDialog(
  BuildContext context,
  List<GiftNotification> notifications,
) async {
  if (notifications.isEmpty) return;
  
  final giftService = Get.find<GiftNotificationServiceSimple>();
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (context) => CelebrationDialog(
      notifications: notifications,
      onClose: () async {
        await giftService.markAllAsShown();
      },
    ),
  );
}