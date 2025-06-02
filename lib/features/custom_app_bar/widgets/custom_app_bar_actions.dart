import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';
import 'package:ventemoi/features/custom_icon_button/view/custom_icon_button.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../controllers/custom_app_bar_actions_controller.dart';

class CustomAppBarActions extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CustomAppBarActions({super.key, this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(CustomAppBarActionsController());

    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

    // Responsive font sizes
    final largeFontSize = isSmallScreen
        ? UniquesControllers().data.baseSpace * 1.5 // Smaller on mobile
        : UniquesControllers().data.baseSpace * 2;

    final smallFontSize = isSmallScreen
        ? UniquesControllers().data.baseSpace * 1.2
        : UniquesControllers().data.baseSpace * 1.5;

    return Obx(() {
      final real = cc.realPoints.value;
      final pending = cc.pendingPoints.value;

      final isBoutique = cc.isBoutique.value;
      final coupons = cc.couponsRestants.value;
      final couponsPending = cc.couponsPending.value;

      final isAdmin = cc.isAdmin.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Boutique info
          if (isBoutique)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$coupons Bons',
                    style: TextStyle(
                      fontSize: largeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // couponsPending
                Visibility(
                  visible: (couponsPending > 0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isSmallScreen
                          ? '$couponsPending en attente' // Shorter text on mobile
                          : '$couponsPending bons en attente',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          if (isBoutique) const CustomSpace(widthMultiplier: 2),

          // Separator - only show on larger screens
          if (isBoutique && !isSmallScreen)
            Text(
              '|',
              style: TextStyle(
                fontSize: largeFontSize,
                fontStyle: FontStyle.italic,
              ),
            ),

          if (isBoutique && !isSmallScreen)
            const CustomSpace(widthMultiplier: 2),

          // Points info (for non-admin users)
          if (!isAdmin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Points display
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$real Points',
                    style: TextStyle(
                      fontSize: largeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Pending points
                Visibility(
                  visible: (pending > 0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isSmallScreen
                          ? '$pending en attente' // Shorter text on mobile
                          : '$pending points en attente',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          const CustomSpace(widthMultiplier: 2),

          // Menu button
          CustomIconButton(
            tag: UniqueKey().toString(),
            iconData: Icons.menu,
            backgroundColor: CustomTheme.lightScheme().primary,
            buttonSize: isSmallScreen ? 36 : null, // Smaller button on mobile
            onPressed: () {
              if (scaffoldKey != null) scaffoldKey?.currentState?.openDrawer();
            },
          ),

          const CustomSpace(widthMultiplier: 2),
        ],
      );
    });
  }
}
