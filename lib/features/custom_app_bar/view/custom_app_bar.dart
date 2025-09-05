import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventemoi/core/routes/app_routes.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_animation/view/custom_animation.dart';
import '../../../features/custom_logo/view/custom_logo.dart';
import '../../../screens/notifications_screen/view/notifications_screen.dart';
import '../../../screens/notifications_screen/widget/notifications_badge.dart';
import '../../../screens/points_transfer/points_transfer.dart';
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
    this.height = 75, // Réduit de 90 à 75
    this.showGreeting = true,
    this.modernStyle = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(CustomAppBarActionsController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 350;
    final isSmallScreen = screenWidth < 550;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFf2d8a1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20), // Réduit de 24 à 20
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Ombre plus légère
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen
                ? UniquesControllers().data.baseSpace *
                    1.5 // Moins de padding sur mobile
                : UniquesControllers().data.baseSpace * 2,
            vertical: UniquesControllers().data.baseSpace * 0.8,
          ),
          child: isSmallScreen
              ? _buildMobileLayout(cc, context)
              : _buildDesktopLayout(cc, context),
        ),
      ),
    );
  }

  // Layout simplifié pour mobile
  Widget _buildMobileLayout(
      CustomAppBarActionsController cc, BuildContext context) {
    return Row(
      children: [
        // Menu button
        if (showDrawerButton)
          CustomAnimation(
            duration: UniquesControllers().data.baseAnimationDuration,
            delay: UniquesControllers().data.baseAnimationDuration,
            curve: Curves.easeOutQuart,
            xStartPosition: -20,
            isOpacity: true,
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: CustomTheme.lightScheme().primary,
                  size: 26,
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

        // Logo/Titre centré comme sur la page login
        Expanded(
          child: CustomAnimation(
            duration: UniquesControllers().data.baseAnimationDuration,
            delay: UniquesControllers().data.baseAnimationDuration * 1.2,
            curve: Curves.easeOutQuart,
            yStartPosition: -10,
            isOpacity: true,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  SizedBox(
                    height: 35,
                    child: const CustomLogo(),
                  ),
                  const SizedBox(height: 2),
                  // Titre
                  const Text(
                    'VENTE MOI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Widget combiné points/user sur mobile
        CustomAnimation(
          duration: UniquesControllers().data.baseAnimationDuration,
          delay: UniquesControllers().data.baseAnimationDuration * 1.5,
          curve: Curves.easeOutQuart,
          xStartPosition: 20,
          isOpacity: true,
          child: _buildMobileInfoWidget(cc, context),
        ),
      ],
    );
  }

  // Widget combiné pour mobile avec PopupMenu
  Widget _buildMobileInfoWidget(
      CustomAppBarActionsController cc, BuildContext context) {
    return Obx(() {
      final realPoints = cc.realPoints.value;
      final pendingPoints = cc.pendingPoints.value;
      final isBoutique = cc.isBoutique.value;
      final isAdmin = cc.isAdmin.value;
      final coupons = cc.couponsRestants.value;

      // Badge simple pour mobile
      return PopupMenuButton<String>(
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CustomTheme.lightScheme().primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône principale
              Icon(
                isBoutique
                    ? Icons.store
                    : isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.stars_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              // Valeur principale
              Text(
                isBoutique
                    ? '$coupons'
                    : isAdmin
                        ? 'Admin'
                        : '$realPoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              // Indicateur de transfert pour les points
              if (!isAdmin && !isBoutique && realPoints > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
        onSelected: (value) {
          switch (value) {
            case 'wallet':
              Get.toNamed(Routes.pointsSummary);
              break;
            case 'transfer':
              Get.dialog(
                const PointsTransferDialog(),
                barrierDismissible: false,
              );
              break;
            case 'profile':
              Get.toNamed(Routes.profile);
              break;
            case 'history':
              Get.toNamed(Routes.clientHistory);
              break;
            case 'logout':
              cc.logout();
              break;
          }
        },
        itemBuilder: (context) => [
          // En-tête avec info utilisateur
          PopupMenuItem<String>(
            enabled: false,
            child: StreamBuilder<Map<String, String>>(
              stream: _getUserInfoStream(),
              builder: (context, snapshot) {
                final info =
                    snapshot.data ?? {'name': 'Utilisateur', 'image': ''};
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: CustomTheme.lightScheme().primary,
                        child: ClipOval(
                          child: info['image']!.isNotEmpty
                              ? Image.network(
                                  info['image']!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isAdmin && !isBoutique)
                              Text(
                                '$realPoints points',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (isBoutique)
                              Text(
                                '$coupons bons disponibles',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Points en attente
          if (pendingPoints > 0 && !isAdmin)
            PopupMenuItem<String>(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pendingPoints points en attente',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bons en attente (boutique)
          if (isBoutique && cc.couponsPending.value > 0)
            PopupMenuItem<String>(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${cc.couponsPending.value} bons en attente',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const PopupMenuDivider(),

          // Mon Portefeuille (pour tous sauf admin)
          if (!isAdmin)
            PopupMenuItem<String>(
              value: 'wallet',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 18,
                      color: CustomTheme.lightScheme().primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Mon Portefeuille',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),

          // Transfert de points (si l'utilisateur a des points)
          if (!isAdmin && !isBoutique && realPoints > 0)
            PopupMenuItem<String>(
              value: 'transfer',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 20, color: CustomTheme.lightScheme().primary),
                  const SizedBox(width: 12),
                  Text('Transférer des points', style: TextStyle(color: CustomTheme.lightScheme().primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Actions
          const PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 20),
                SizedBox(width: 12),
                Text('Mon profil'),
              ],
            ),
          ),

          if (!isAdmin)
            const PopupMenuItem<String>(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history, size: 20),
                  SizedBox(width: 12),
                  Text('Historique'),
                ],
              ),
            ),

          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Déconnexion', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      );
    });
  }

  // Layout desktop (écrans larges)
  Widget _buildDesktopLayout(
      CustomAppBarActionsController cc, BuildContext context) {
    return Row(
      children: [
        // Partie gauche : Menu + Titre
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      padding: const EdgeInsets.all(8),
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

            const SizedBox(width: 16),

            // Titre et sous-titre (sans logo pour desktop)
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
                  const Text(
                    'Vente Moi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Le Don des Affaires',
                    style: TextStyle(
                      fontSize: 14,
                      color: CustomTheme.lightScheme().onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Spacer(),

        // Partie droite : Infos utilisateur et points
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nom utilisateur
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
                      onTap: () => Get.toNamed(Routes.profile),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
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
                                color: Colors.black87,
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

            const SizedBox(width: 16),

            // Avatar
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
                        child: ClipOval(
                          child: snapshot.hasData && snapshot.data!.isNotEmpty
                              ? Image.network(
                                  snapshot.data!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(width: 16),

            // Points et coupons
            if (showPoints)
              Obx(() {
                final isAdmin = cc.isAdmin.value;
                final isBoutique = cc.isBoutique.value;

                if (isAdmin && !isBoutique) {
                  return const SizedBox.shrink();
                }

                return CustomAnimation(
                  duration: UniquesControllers().data.baseAnimationDuration,
                  delay: UniquesControllers().data.baseAnimationDuration * 2,
                  curve: Curves.easeOutQuart,
                  xStartPosition: 20,
                  isOpacity: true,
                  child: _buildDesktopPointsWidget(cc),
                );
              }),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopPointsWidget(CustomAppBarActionsController cc) {
    final realPoints = cc.realPoints.value;
    final pendingPoints = cc.pendingPoints.value;
    final isBoutique = cc.isBoutique.value;
    final coupons = cc.couponsRestants.value;
    final couponsPending = cc.couponsPending.value;

    return Row(
      children: [
        // Boutique info
        if (isBoutique) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$coupons',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (couponsPending > 0)
                  Text(
                    '$couponsPending en attente',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Points (avec transfert)
        Tooltip(
          message: realPoints > 0 
            ? 'Cliquez pour transférer des points' 
            : 'Voir l\'historique',
          child: InkWell(
            onTap: realPoints > 0 
              ? () {
                  // Ouvrir le dialog de transfert de points
                  Get.dialog(
                    const PointsTransferDialog(),
                    barrierDismissible: false,
                  );
                }
              : () => Get.toNamed(Routes.clientHistory),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: realPoints > 0 
                  ? LinearGradient(
                      colors: [
                        CustomTheme.lightScheme().primary,
                        CustomTheme.lightScheme().primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: realPoints > 0 ? null : CustomTheme.lightScheme().primary,
                borderRadius: BorderRadius.circular(16),
                border: realPoints > 0 
                  ? Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
                boxShadow: [
                  BoxShadow(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$realPoints',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (pendingPoints > 0)
                      Text(
                        '$pendingPoints en attente',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                if (realPoints > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ), // Fermeture de Tooltip
      ],
    );
  }

  // Stream pour récupérer nom et image ensemble
  Stream<Map<String, String>> _getUserInfoStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return Stream.value({'name': 'Utilisateur', 'image': ''});

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {'name': 'Utilisateur', 'image': ''};
      final data = doc.data()!;
      // Le nom est directement stocké dans le champ 'name'
      final name = data['name'] ?? 'Utilisateur';
      final image = data['image_url'] ?? '';
      return {'name': name, 'image': image};
    });
  }

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
      // Le nom est directement stocké dans le champ 'name'
      final name = data['name'];
      return (name != null && name.toString().trim().isNotEmpty)
          ? name.toString()
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
      return data['image_url'] ?? '';
    });
  }
}
