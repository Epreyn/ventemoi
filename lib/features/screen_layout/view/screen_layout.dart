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
import '../controllers/screen_layout_controller.dart';

class ScreenLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    // Utiliser l'instance singleton au lieu de créer un nouveau contrôleur
    final controller = ScreenLayoutController.instance;

    return Obx(
      () => GestureDetector(
        child: Stack(
          children: [
            // 1) Background blanc
            Container(
              color: Colors.white,
            ),

            // 2) Vagues orange en haut
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Obx(() => CustomPaint(
                    painter: TopWavesPainter(
                      wave1Progress: controller.wave3Progress.value,
                      wave2Progress: controller.wave4Progress.value,
                      primaryColor: CustomTheme.lightScheme().primary,
                    ),
                    size: Size(MediaQuery.of(context).size.width, 200),
                  )),
            ),

            // 3) Vagues noires en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Obx(() => CustomPaint(
                    painter: BottomWavesPainter(
                      wave1Progress: controller.wave1Progress.value,
                      wave2Progress: controller.wave2Progress.value,
                    ),
                    size: Size(MediaQuery.of(context).size.width, 200),
                  )),
            ),

            // 4) Scaffold principal
            Scaffold(
              key: scaffoldKey,
              backgroundColor: Colors.transparent,
              appBar: (noAppBar == true)
                  ? null
                  : appBar ??
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
              bottomNavigationBar: bottomNavigationBar,
              floatingActionButton: (noFAB == true)
                  ? null
                  : floatingActionButton ??
                      CustomCardAnimation(
                        index: 0,
                        child: FloatingActionButton.extended(
                          heroTag: UniqueKey().toString(),
                          icon: fabIcon,
                          label: fabText ?? Text(''),
                          onPressed: fabOnPressed,
                        ),
                      ),
              floatingActionButtonLocation: floatingActionButtonLocation ??
                  FloatingActionButtonLocation.endFloat,
              drawer: drawer ?? CustomNavigationMenu(),
              body: body,
            ),

            // 5) Loader overlay
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

// Painter pour les vagues orange en haut
class TopWavesPainter extends CustomPainter {
  final double wave1Progress;
  final double wave2Progress;
  final Color primaryColor;

  TopWavesPainter({
    required this.wave1Progress,
    required this.wave2Progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Première vague orange avec phase décalée
    final paint1 = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, 0);

    for (double i = 0; i <= size.width; i++) {
      // Phase initiale de 0.3 pour cette vague
      final phase = (wave1Progress + 0.3) * 2 * math.pi;
      final y = 60 + 20 * math.sin((i / size.width * 4 * math.pi) + phase);
      path1.lineTo(i, y);
    }

    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Deuxième vague orange avec phase différente
    final paint2 = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, 0);

    for (double i = 0; i <= size.width; i++) {
      // Phase initiale de 0.7 pour cette vague
      final phase = (wave2Progress + 0.7) * 2 * math.pi;
      final y = 80 + 15 * math.sin((i / size.width * 3 * math.pi) + phase);
      path2.lineTo(i, y);
    }

    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Troisième vague orange avec mouvement inverse
    final paint3 = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, 0);

    for (double i = 0; i <= size.width; i++) {
      // Phase inversée et décalée de 0.5
      final phase = -(wave1Progress + 0.5) * 2 * math.pi;
      final y = 100 + 10 * math.sin((i / size.width * 5 * math.pi) + phase);
      path3.lineTo(i, y);
    }

    path3.lineTo(size.width, 0);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(TopWavesPainter oldDelegate) =>
      wave1Progress != oldDelegate.wave1Progress ||
      wave2Progress != oldDelegate.wave2Progress;
}

// Painter pour les vagues noires en bas
class BottomWavesPainter extends CustomPainter {
  final double wave1Progress;
  final double wave2Progress;

  BottomWavesPainter({
    required this.wave1Progress,
    required this.wave2Progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Première vague noire avec phase 0
    final paint1 = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      final phase = wave1Progress * 2 * math.pi;
      final y = 140 - 25 * math.sin((i / size.width * 3 * math.pi) + phase);
      path1.lineTo(i, y);
    }

    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Deuxième vague noire avec phase décalée de 0.4
    final paint2 = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      final phase = -(wave2Progress + 0.4) * 2 * math.pi;
      final y = 120 - 20 * math.sin((i / size.width * 4 * math.pi) + phase);
      path2.lineTo(i, y);
    }

    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Troisième vague noire avec phase décalée de 0.2
    final paint3 = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      final phase = (wave1Progress + 0.2) * 2 * math.pi;
      final y = 100 - 15 * math.sin((i / size.width * 5 * math.pi) + phase);
      path3.lineTo(i, y);
    }

    path3.lineTo(size.width, size.height);
    path3.close();
    canvas.drawPath(path3, paint3);

    // Quatrième vague noire avec phase décalée de 0.8
    final paint4 = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path4 = Path();
    path4.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      final phase = (wave2Progress + 0.8) * 2 * math.pi * 1.5;
      final y = 80 - 10 * math.sin((i / size.width * 6 * math.pi) + phase);
      path4.lineTo(i, y);
    }

    path4.lineTo(size.width, size.height);
    path4.close();
    canvas.drawPath(path4, paint4);
  }

  @override
  bool shouldRepaint(BottomWavesPainter oldDelegate) =>
      wave1Progress != oldDelegate.wave1Progress ||
      wave2Progress != oldDelegate.wave2Progress;
}
