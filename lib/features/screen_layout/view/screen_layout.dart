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

    return Obx(
      () => GestureDetector(
        //onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Container(
              color: CustomTheme.lightScheme().surface,
            ),
            Positioned.fill(
              child: Image.asset(
                'images/background-opacity.png',
                fit: BoxFit.cover,
              ),
            ),

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

            /// 3) Le "loader" si on est en asynchrone
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
