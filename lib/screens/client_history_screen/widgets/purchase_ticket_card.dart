import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../controllers/client_history_screen_controller.dart';
import 'client_history_seller_name.dart';
import 'gift_purchase_dialog.dart';

class PurchaseTicketCard extends StatelessWidget {
  final Purchase purchase;
  final bool isTablet;

  const PurchaseTicketCard({
    super.key,
    required this.purchase,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isDonation = purchase.couponsCount == 0;
    final amount = purchase.couponsCount * 50;
    final dateFr = DateFormat('dd MMMM yyyy', 'fr_FR').format(purchase.date);
    final timeFr = DateFormat('HH:mm', 'fr_FR').format(purchase.date);

    return Container(
      height: isTablet ? 180 : 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Motif de fond subtil
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TicketPatternPainter(
                      color: Colors.orange.withOpacity(0.03),
                    ),
                  ),
                ),

                // Contenu principal
                Padding(
                  padding:
                      EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                  child: Row(
                    children: [
                      // Partie gauche - Infos principales
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Type et montant
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        UniquesControllers().data.baseSpace *
                                            1.5,
                                    vertical:
                                        UniquesControllers().data.baseSpace *
                                            0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDonation
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isDonation ? 'DON' : 'BON D\'ACHAT',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const CustomSpace(heightMultiplier: 1),
                                if (!isDonation)
                                  Text(
                                    '$amount €',
                                    style: TextStyle(
                                      fontSize: isTablet ? 32 : 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                    ),
                                  ),
                              ],
                            ),

                            // Établissement
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.store,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: ClientHistorySellerNameCell(
                                        sellerId: purchase.sellerId,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomSpace(heightMultiplier: 0.5),
                                Text(
                                  '$dateFr à $timeFr',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Séparateur vertical avec pointillés ou fissure - Déplacé plus proche de la partie droite
                      Container(
                        width: 30,
                        margin: EdgeInsets.only(
                          left: UniquesControllers().data.baseSpace,
                          right: UniquesControllers().data.baseSpace * 0.5,
                        ),
                        child: purchase.isReclaimed
                            ? CustomPaint(
                                size: Size(30, double.infinity),
                                painter: _TearPainter(),
                              )
                            : CustomPaint(
                                size: Size(1, double.infinity),
                                painter: _DashedLinePainter(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                      ),

                      // Partie droite - Code et statut
                      SizedBox(
                        width: isTablet ? 140 : 120,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!purchase.isReclaimed) ...[
                              Icon(
                                Icons.qr_code_2,
                                size: 32,
                                color: Colors.orange.withOpacity(0.4),
                              ),
                              const CustomSpace(heightMultiplier: 1),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      UniquesControllers().data.baseSpace * 1.5,
                                  vertical:
                                      UniquesControllers().data.baseSpace * 0.8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  purchase.reclamationPassword,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Colors.black87,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const CustomSpace(heightMultiplier: 0.5),
                              Text(
                                'Code à présenter',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ] else ...[
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 32,
                                  color: Colors.green[700],
                                ),
                              ),
                              const CustomSpace(heightMultiplier: 1),
                              Text(
                                'Utilisé',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bouton donner en haut à droite de la partie gauche pour les tickets non réclamés
                if (!purchase.isReclaimed && purchase.couponsCount > 0)
                  Positioned(
                    top: UniquesControllers().data.baseSpace * 2,
                    right: isTablet ? 200 : 180,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showGiftDialog(context, purchase),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace * 2,
                            vertical: UniquesControllers().data.baseSpace * 1.2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.amber[400]!,
                                Colors.amber[600]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'OFFRIR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Overlay pour les tickets utilisés
                if (purchase.isReclaimed)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
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

  void _showGiftDialog(BuildContext context, Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => GiftPurchaseDialog(purchase: purchase),
    );
  }
}

// Painter pour la fissure déchirée
class _TearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    final random = math.Random(42);

    // Créer une ligne déchirée irrégulière
    double x = size.width / 2;
    path.moveTo(x, 0);

    for (double y = 0; y < size.height; y += 8) {
      // Variation aléatoire de la position x
      final variation = (random.nextDouble() - 0.5) * 20;
      x = size.width / 2 + variation;

      if (y == 0) {
        path.moveTo(x, y);
      } else {
        // Créer des zigzags irréguliers
        final midX = size.width / 2 + (random.nextDouble() - 0.5) * 15;
        final midY = y - 4;
        path.quadraticBezierTo(midX, midY, x, y);
      }
    }

    // Dessiner l'ombre de la déchirure
    final shadowPath = Path.from(path);
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(shadowPath, shadowPaint);

    // Dessiner la déchirure principale
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Ajouter quelques détails de papier déchiré
    for (int i = 0; i < 5; i++) {
      final tearY = random.nextDouble() * size.height;
      final tearX = size.width / 2 + (random.nextDouble() - 0.5) * 10;
      final tearLength = random.nextDouble() * 10 + 5;

      canvas.drawLine(
        Offset(tearX, tearY),
        Offset(tearX + tearLength * (random.nextBool() ? 1 : -1), tearY + 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter pour les lignes pointillées
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    final dashHeight = 5.0;
    final dashSpace = 5.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter pour le motif de fond
class _TicketPatternPainter extends CustomPainter {
  final Color color;

  _TicketPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Créer un motif de cercles subtils
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
