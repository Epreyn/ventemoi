import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_loader/view/custom_loader.dart';
import '../../custom_app_bar/view/custom_app_bar.dart';
// import '../../custom_app_bar/widgets/custom_app_bar_actions.dart'; // Non nécessaire, CustomAppBar gère ses propres actions
import '../../custom_card_animation/view/custom_card_animation.dart';
import '../../custom_navigation_menu/view/custom_navigation_menu.dart';
import '../../custom_profile_leading/view/custom_profile_leading.dart';
import '../controllers/screen_layout_controller.dart';

// Widget statique pour le gradient background
class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomTheme.lightScheme().primary.withOpacity(0.08),
            CustomTheme.lightScheme().primary.withOpacity(0.05),
            CustomTheme.lightScheme().primary.withOpacity(0.03),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

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

class _ScreenLayoutState extends State<ScreenLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      // SOLUTION : Utiliser Container + Padding au lieu de Stack
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CustomTheme.lightScheme().primary.withOpacity(0.08),
              CustomTheme.lightScheme().primary.withOpacity(0.05),
              CustomTheme.lightScheme().primary.withOpacity(0.03),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: (widget.noAppBar == true)
              ? null
              : widget.appBar ??
                  CustomAppBar(
                    leadingWidgetNumber: UniquesControllers().data.baseSpace,
                    leading: CustomProfileLeading(
                      userId: UniquesControllers()
                          .data
                          .firebaseAuth
                          .currentUser!
                          .uid,
                    ),
                    title: const SizedBox.shrink(),
                    // actions sont gérées automatiquement par CustomAppBar
                  ),
          floatingActionButton: widget.noFAB == true
              ? null
              : widget.floatingActionButton ??
                  CustomCardAnimation(
                    index: 0,
                    child: FloatingActionButton.extended(
                      heroTag: "fab_hero",
                      icon: widget.fabIcon,
                      label: widget.fabText ?? const Text(''),
                      onPressed: widget.fabOnPressed,
                    ),
                  ),
          floatingActionButtonLocation: widget.floatingActionButtonLocation ??
              FloatingActionButtonLocation.endFloat,
          drawer: widget.drawer ?? CustomNavigationMenu(),
          body: Stack(
            children: [
              widget.body,
              Obx(() {
                if (UniquesControllers().data.isInAsyncCall.value) {
                  return Container(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.75),
                    child: const CustomLoader(),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}
