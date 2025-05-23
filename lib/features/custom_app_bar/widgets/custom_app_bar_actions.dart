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

    return Obx(() {
      final real = cc.realPoints.value;
      final pending = cc.pendingPoints.value;

      final isBoutique = cc.isBoutique.value;
      final coupons = cc.couponsRestants.value;
      final couponsPending = cc.couponsPending.value;

      final isAdmin = cc.isAdmin.value;

      return Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isBoutique) ...[
                Text(
                  '$coupons Bons',
                  style: TextStyle(
                    fontSize: UniquesControllers().data.baseSpace * 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // couponsPending
                Visibility(
                  visible: (couponsPending > 0),
                  child: Text(
                    '$couponsPending bons en attente',
                    style: TextStyle(
                      fontSize: UniquesControllers().data.baseSpace * 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isBoutique) const CustomSpace(widthMultiplier: 2),
          if (isBoutique)
            Text(
              '|',
              style: TextStyle(
                fontSize: UniquesControllers().data.baseSpace * 2,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (isBoutique) const CustomSpace(widthMultiplier: 2),
          if (!isAdmin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Affichage "Points" (pour tout le monde)
                Text(
                  '$real Points',
                  style: TextStyle(
                    fontSize: UniquesControllers().data.baseSpace * 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Affichage "Points en attente" (pour tout le monde)
                Visibility(
                  visible: (pending > 0),
                  child: Text(
                    '$pending points en attente',
                    style: TextStyle(
                      fontSize: UniquesControllers().data.baseSpace * 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          const CustomSpace(widthMultiplier: 2),
          CustomIconButton(
            tag: UniqueKey().toString(),
            iconData: Icons.menu,
            backgroundColor: CustomTheme.lightScheme().primary,
            onPressed: () {
              if (scaffoldKey != null) scaffoldKey?.currentState?.openDrawer();
            },
          ),
          // CustomIconButton(
          //   tag: UniqueKey().toString(),
          //   iconData: Icons.logout,
          //   backgroundColor: CustomTheme.lightScheme().primary,
          //   onPressed: cc.logout,
          // ),
          // SizedBox(
          //   width: UniquesControllers().data.baseSpace * 25,
          //   height: UniquesControllers().data.baseSpace * 5,
          //   child: CustomFABButton(
          //     tag: UniqueKey().toString(),
          //     text: 'Déconnexion',
          //     iconData: Icons.logout,
          //     onPressed: cc.logout,
          //   ),
          // ),
          const CustomSpace(widthMultiplier: 2),
        ],
      );
    });
  }
}
