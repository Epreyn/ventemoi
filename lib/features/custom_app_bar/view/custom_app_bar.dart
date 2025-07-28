import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventemoi/core/routes/app_routes.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_animation/view/custom_animation.dart';
import '../../../screens/notifications_screen/view/notifications_screen.dart';
import '../../../screens/notifications_screen/widget/notifications_badge.dart';
import '../controllers/custom_app_bar_actions_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final double? leadingWidgetNumber;
  final Widget? title;
  final List<Widget>? actions;
  final bool showUserInfo;
  final bool showPoints;
  final bool showNotifications;
  final bool showDrawerButton;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Color? backgroundColor;
  final double height;
  final bool showGreeting;
  final bool modernStyle;

  const CustomAppBar({
    super.key,
    this.leading,
    this.leadingWidgetNumber,
    this.title,
    this.actions,
    this.showUserInfo = true,
    this.showPoints = true,
    this.showNotifications = true,
    this.showDrawerButton = true,
    this.scaffoldKey,
    this.backgroundColor,
    this.height = 90,
    this.showGreeting = true,
    this.modernStyle = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(CustomAppBarActionsController());

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFf2d8a1), // Couleur spécifiée
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: UniquesControllers().data.baseSpace * 2,
            vertical: UniquesControllers().data.baseSpace,
          ),
          child: _buildNewLayoutContent(cc, context),
        ),
      ),
    );
  }

  Widget _buildNewLayoutContent(
      CustomAppBarActionsController cc, BuildContext context) {
    return Row(
      children: [
        // Bouton Menu tout à gauche
        if (showDrawerButton)
          CustomAnimation(
            duration: UniquesControllers().data.baseAnimationDuration,
            delay: UniquesControllers().data.baseAnimationDuration,
            curve: Curves.easeOutQuart,
            xStartPosition: -20,
            isOpacity: true,
            child: Builder(
              builder: (context) => IconButton(
                icon: Container(
                  padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () {
                  if (scaffoldKey != null) {
                    scaffoldKey!.currentState?.openDrawer();
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                },
              ),
            ),
          ),

        const SizedBox(width: 12),

        // Titre et sous-titre à droite du bouton menu
        CustomAnimation(
          duration: UniquesControllers().data.baseAnimationDuration,
          delay: UniquesControllers().data.baseAnimationDuration * 1.2,
          curve: Curves.easeOutQuart,
          yStartPosition: -10,
          isOpacity: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vente Moi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Le Don des Affaires',
                style: TextStyle(
                  fontSize: 14,
                  color: CustomTheme.lightScheme().primary,
                ),
              ),
            ],
          ),
        ),

        // Espacement flexible
        const Spacer(),

        // Section droite : Bonjour + Nom, Image, Points
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bonjour + Nom (cliquable)
            if (showUserInfo && showGreeting)
              StreamBuilder<String>(
                stream: _getUserNameStream(),
                builder: (context, snapshot) {
                  return CustomAnimation(
                    duration: UniquesControllers().data.baseAnimationDuration,
                    delay:
                        UniquesControllers().data.baseAnimationDuration * 1.5,
                    curve: Curves.easeOutQuart,
                    xStartPosition: 20,
                    isOpacity: true,
                    child: InkWell(
                      onTap: () => Get.toNamed('/profile'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bonjour,',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              snapshot.data ?? 'Utilisateur',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(width: 12),

            // Avatar utilisateur (cliquable)
            if (showUserInfo)
              StreamBuilder<String>(
                stream: _getUserImageStream(),
                builder: (context, snapshot) {
                  return CustomAnimation(
                    duration: UniquesControllers().data.baseAnimationDuration,
                    delay:
                        UniquesControllers().data.baseAnimationDuration * 1.7,
                    curve: Curves.easeOutQuart,
                    xStartPosition: 20,
                    isOpacity: true,
                    child: InkWell(
                      onTap: () => Get.toNamed(Routes.profile),
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: CustomTheme.lightScheme().primary,
                        backgroundImage:
                            snapshot.hasData && snapshot.data!.isNotEmpty
                                ? NetworkImage(snapshot.data!)
                                : null,
                        child: !snapshot.hasData || snapshot.data!.isEmpty
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(width: 12),

            // Points
            if (showPoints)
              Obx(() => CustomAnimation(
                    duration: UniquesControllers().data.baseAnimationDuration,
                    delay: UniquesControllers().data.baseAnimationDuration * 2,
                    curve: Curves.easeOutQuart,
                    xStartPosition: 20,
                    isOpacity: true,
                    child: _buildPointsWidget(cc),
                  )),
          ],
        ),
      ],
    );
  }

  Widget _buildPointsWidget(CustomAppBarActionsController cc) {
    final realPoints = cc.realPoints.value;
    final pendingPoints = cc.pendingPoints.value;
    final isBoutique = cc.isBoutique.value;
    final coupons = cc.couponsRestants.value;
    final couponsPending = cc.couponsPending.value;
    final isAdmin = cc.isAdmin.value;

    if (isAdmin && !isBoutique) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Infos boutique
        if (isBoutique) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: UniquesControllers().data.baseSpace * 1.5,
              vertical: UniquesControllers().data.baseSpace *
                  0.5, // Réduit pour minimiser la hauteur
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize:
                  MainAxisSize.min, // Important pour minimiser la hauteur
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      color: CustomTheme.lightScheme().primary,
                      size: 16, // Réduit la taille de l'icône
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$coupons',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Réduit la taille de la police
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bons',
                      style: TextStyle(
                        fontSize: 11, // Réduit la taille de la police
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                if (couponsPending > 0)
                  Text(
                    '$couponsPending en attente',
                    style: TextStyle(
                      fontSize: 9, // Réduit la taille de la police
                      color: Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Points (sauf admin) - cliquable
        if (!isAdmin)
          InkWell(
            onTap: () => Get.toNamed(Routes.clientHistory),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: UniquesControllers().data.baseSpace * 1.5,
                vertical: UniquesControllers().data.baseSpace *
                    0.5, // Réduit pour minimiser la hauteur
              ),
              decoration: BoxDecoration(
                color: CustomTheme.lightScheme().primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    MainAxisSize.min, // Important pour minimiser la hauteur
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 16, // Réduit la taille de l'icône
                      ),
                      const SizedBox(width: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          '$realPoints',
                          key: ValueKey(realPoints),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Réduit la taille de la police
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'pts',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11, // Réduit la taille de la police
                        ),
                      ),
                    ],
                  ),
                  if (pendingPoints > 0)
                    Text(
                      '$pendingPoints en attente',
                      style: const TextStyle(
                        fontSize: 9, // Réduit la taille de la police
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Stream<String> _getUserImageStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data()?['image_url'] ?? '');
  }

  Stream<String> _getUserNameStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data()?['name'] ?? 'Utilisateur');
  }
}
