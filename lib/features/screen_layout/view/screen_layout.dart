import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_loader/view/custom_loader.dart';
import '../../custom_app_bar/view/custom_app_bar.dart';
import '../../custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../custom_card_animation/view/custom_card_animation.dart';
import '../../custom_navigation_menu/view/custom_navigation_menu.dart';
import '../../custom_profile_leading/view/custom_profile_leading.dart';

class ScreenLayout extends StatefulWidget {
  final bool? noAppBar;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool? noFAB;
  final Widget? floatingActionButton;
  final Icon? fabIcon;
  final Text? fabText;
  final Function()? fabOnPressed;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Drawer? drawer;
  final Widget body;
  final bool? showVersion;

  const ScreenLayout({
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.noAppBar,
    this.noFAB,
    this.floatingActionButton,
    this.fabIcon,
    this.fabText,
    this.fabOnPressed,
    this.floatingActionButtonLocation,
    this.drawer,
    required this.body,
    this.showVersion,
  });

  @override
  State<ScreenLayout> createState() => _ScreenLayoutState();
}

class _ScreenLayoutState extends State<ScreenLayout>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _waveAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation pour les vagues - plus rapide
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

    // Animation pour les particules - plus rapide
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    );

    // Animation de pulsation pour les orbes
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Obx(
      () => GestureDetector(
        child: Stack(
          children: [
            // 1) Background animé moderne plus visible
            Positioned.fill(
              child: AnimatedBackground(
                waveAnimation: _waveAnimation,
                particleAnimation: _particleAnimation,
                pulseAnimation: _pulseAnimation,
              ),
            ),

            // 2) Overlay semi-transparent ajusté pour plus de visibilité
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CustomTheme.lightScheme().surface.withOpacity(0.7),
                      CustomTheme.lightScheme().surface.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),

            // 3) Scaffold principal
            Scaffold(
              key: scaffoldKey,
              backgroundColor: Colors.transparent,
              appBar: (widget.noAppBar == true)
                  ? null
                  : widget.appBar ??
                      CustomAppBar(
                        leadingWidgetNumber:
                            UniquesControllers().data.baseSpace,
                        leading: CustomProfileLeading(
                          userId: UniquesControllers()
                              .data
                              .firebaseAuth
                              .currentUser!
                              .uid,
                        ),
                        actions: [
                          CustomAppBarActions(scaffoldKey: scaffoldKey)
                        ],
                      ),
              bottomNavigationBar: widget.bottomNavigationBar,
              floatingActionButton: (widget.noFAB == true)
                  ? null
                  : widget.floatingActionButton ??
                      CustomCardAnimation(
                        index: 0,
                        child: FloatingActionButton.extended(
                          heroTag: UniqueKey().toString(),
                          icon: widget.fabIcon,
                          label: widget.fabText ?? Text(''),
                          onPressed: widget.fabOnPressed,
                        ),
                      ),
              floatingActionButtonLocation:
                  widget.floatingActionButtonLocation ??
                      FloatingActionButtonLocation.endFloat,
              drawer: widget.drawer ?? CustomNavigationMenu(),
              body: widget.body,
            ),

            // 4) Loader overlay
            if (UniquesControllers().data.isInAsyncCall.value)
              Positioned.fill(
                child: Container(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.75),
                  child: const CustomLoader(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget pour le background animé
class AnimatedBackground extends StatelessWidget {
  final Animation<double> waveAnimation;
  final Animation<double> particleAnimation;
  final Animation<double> pulseAnimation;

  const AnimatedBackground({
    Key? key,
    required this.waveAnimation,
    required this.particleAnimation,
    required this.pulseAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient de base plus vibrant
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CustomTheme.lightScheme().primary.withOpacity(0.3),
                CustomTheme.lightScheme().surface,
                CustomTheme.lightScheme().secondary.withOpacity(0.2),
                CustomTheme.lightScheme().tertiary.withOpacity(0.15),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),

        // Orbes lumineux animés
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: OrbPainter(
                animationValue: pulseAnimation.value,
                primaryColor: CustomTheme.lightScheme().primary,
                secondaryColor: CustomTheme.lightScheme().secondary,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Vagues animées plus visibles
        AnimatedBuilder(
          animation: waveAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                animationValue: waveAnimation.value,
                color: CustomTheme.lightScheme().primary.withOpacity(0.25),
                waveHeight: 80,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Deuxième couche de vagues
        AnimatedBuilder(
          animation: waveAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                animationValue: waveAnimation.value + 0.3,
                color: CustomTheme.lightScheme().secondary.withOpacity(0.15),
                waveHeight: 60,
                frequency: 1.5,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Troisième couche de vagues
        AnimatedBuilder(
          animation: waveAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                animationValue: waveAnimation.value + 0.6,
                color: CustomTheme.lightScheme().tertiary.withOpacity(0.1),
                waveHeight: 40,
                frequency: 2,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Particules flottantes plus nombreuses et visibles
        AnimatedBuilder(
          animation: particleAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                animationValue: particleAnimation.value,
                color: CustomTheme.lightScheme().primary.withOpacity(0.6),
              ),
              size: Size.infinite,
            );
          },
        ),

        // Motif géométrique plus visible
        Positioned.fill(
          child: CustomPaint(
            painter: GeometricPatternPainter(
              color: CustomTheme.lightScheme().primary.withOpacity(0.08),
            ),
          ),
        ),
      ],
    );
  }
}

// Painter pour les orbes lumineux
class OrbPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  OrbPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Premier orbe
    final orb1Center = Offset(
      size.width * 0.2 + (math.sin(animationValue * math.pi * 2) * 50),
      size.height * 0.3 + (math.cos(animationValue * math.pi * 2) * 30),
    );

    // Deuxième orbe
    final orb2Center = Offset(
      size.width * 0.8 - (math.sin(animationValue * math.pi * 2) * 40),
      size.height * 0.7 - (math.cos(animationValue * math.pi * 2) * 50),
    );

    // Troisième orbe
    final orb3Center = Offset(
      size.width * 0.5 + (math.cos(animationValue * math.pi * 2) * 60),
      size.height * 0.5 + (math.sin(animationValue * math.pi * 2) * 40),
    );

    _drawOrb(canvas, orb1Center, primaryColor, 150 + animationValue * 30);
    _drawOrb(canvas, orb2Center, secondaryColor, 120 + animationValue * 20);
    _drawOrb(canvas, orb3Center, primaryColor.withOpacity(0.3),
        180 + animationValue * 40);
  }

  void _drawOrb(Canvas canvas, Offset center, Color color, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.1),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(OrbPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

// Painter pour les vagues
class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double waveHeight;
  final double frequency;

  WavePainter({
    required this.animationValue,
    required this.color,
    this.waveHeight = 50,
    this.frequency = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.6);

    for (double i = 0; i <= size.width; i++) {
      final y = size.height * 0.6 +
          waveHeight *
              math.sin((i / size.width * 2 * math.pi * frequency) +
                  (animationValue * 2 * math.pi));
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

// Painter pour les particules
class ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  ParticlePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Seed fixe pour cohérence

    // Plus de particules
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final radius = 3 + random.nextDouble() * 6;

      final y = (baseY - animationValue * size.height * speed) % size.height;
      final opacity = random.nextDouble() * 0.4 + 0.3;

      // Effet de lueur
      final glowPaint = Paint()
        ..color = color.withOpacity(opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(
        Offset(x, y),
        radius * 2,
        glowPaint,
      );

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

// Painter pour le motif géométrique
class GeometricPatternPainter extends CustomPainter {
  final Color color;

  GeometricPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const spacing = 60.0;

    // Grille hexagonale plus visible
    for (double y = 0; y < size.height + spacing; y += spacing * 1.5) {
      for (double x = 0; x < size.width + spacing; x += spacing) {
        final offsetX =
            (y / (spacing * 1.5)).floor() % 2 == 0 ? 0 : spacing / 2;
        _drawHexagon(canvas, Offset(x + offsetX, y), spacing / 3, paint);
      }
    }

    // Lignes de connexion
    final linePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double y = 0; y < size.height + spacing; y += spacing * 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 50),
        linePaint,
      );
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(GeometricPatternPainter oldDelegate) => false;
}
