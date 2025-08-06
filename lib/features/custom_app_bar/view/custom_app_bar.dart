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
        color: const Color(0xFFf2d8a1),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 350;
    final isSmallScreen = screenWidth < 500;

    return Row(
      children: [
        // Partie gauche : Bouton Menu + Titre
        Row(
          mainAxisSize: MainAxisSize.min,
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
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: CustomTheme.lightScheme().primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
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

            // Titre et sous-titre
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
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isVerySmallScreen)
                    Text(
                      'Le Don des Affaires',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: CustomTheme.lightScheme().primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),

        // Espacement flexible qui pousse tout à droite
        const Spacer(),

        // Partie droite : Bonjour + Nom, Image, Points
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bonjour + Nom (caché sur très petits écrans)
            if (showUserInfo && showGreeting && !isVerySmallScreen)
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
                      onTap: () => Get.toNamed(Routes.profile),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isSmallScreen)
                              Text(
                                'Bonjour,',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            Text(
                              snapshot.data ?? 'Utilisateur',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
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

            // Avatar utilisateur
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
                        radius: isSmallScreen ? 18 : 22,
                        backgroundColor: CustomTheme.lightScheme().primary,
                        backgroundImage:
                            snapshot.hasData && snapshot.data!.isNotEmpty
                                ? NetworkImage(snapshot.data!)
                                : null,
                        child: !snapshot.hasData || snapshot.data!.isEmpty
                            ? Icon(
                                Icons.person,
                                color: Colors.white,
                                size: isSmallScreen ? 16 : 20,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(width: 12),

            // Points
            if (showPoints)
              Obx(() {
                final isAdmin = cc.isAdmin.value;
                final isBoutique = cc.isBoutique.value;

                // Si admin sans boutique, ne pas afficher les points
                if (isAdmin && !isBoutique) {
                  return const SizedBox.shrink();
                }

                return CustomAnimation(
                  duration: UniquesControllers().data.baseAnimationDuration,
                  delay: UniquesControllers().data.baseAnimationDuration * 2,
                  curve: Curves.easeOutQuart,
                  xStartPosition: 20,
                  isOpacity: true,
                  child: _buildPointsWidget(cc, isSmallScreen),
                );
              }),
          ],
        ),
      ],
    );
  }

  Widget _buildPointsWidget(
      CustomAppBarActionsController cc, bool isSmallScreen) {
    final realPoints = cc.realPoints.value;
    final pendingPoints = cc.pendingPoints.value;
    final isBoutique = cc.isBoutique.value;
    final coupons = cc.couponsRestants.value;
    final couponsPending = cc.couponsPending.value;

    return Row(
      children: [
        // Infos boutique
        if (isBoutique) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: 4,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      color: CustomTheme.lightScheme().primary,
                      size: isSmallScreen ? 14 : 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$coupons',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                if (couponsPending > 0)
                  Text(
                    isSmallScreen
                        ? '$couponsPending attente'
                        : '$couponsPending bons en attente',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Points
        InkWell(
          onTap: () => Get.toNamed(Routes.clientHistory),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: 4,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: isSmallScreen ? 14 : 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$realPoints',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ],
                ),
                if (pendingPoints > 0)
                  Text(
                    isSmallScreen
                        ? '$pendingPoints attente'
                        : '$pendingPoints points en attente',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
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

  // Méthodes pour récupérer les données utilisateur
  Stream<String> _getUserNameStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return Stream.value('Utilisateur');

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 'Utilisateur';
      final data = doc.data()!;
      final firstName = data['firstName'] ?? '';
      final lastName = data['lastName'] ?? '';
      return '$firstName $lastName'.trim().isNotEmpty
          ? '$firstName $lastName'.trim()
          : 'Utilisateur';
    });
  }

  Stream<String> _getUserImageStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return Stream.value('');

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return '';
      final data = doc.data()!;
      return data['profileImageUrl'] ?? '';
    });
  }
}
