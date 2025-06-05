import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_animation/view/custom_animation.dart';
import '../controllers/custom_app_bar_actions_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final double? leadingWidgetNumber;
  final Widget? title;
  final List<Widget>? actions;
  final bool showUserInfo;
  final bool showPoints;
  final bool showDrawerButton;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Color? backgroundColor;
  final double height;

  const CustomAppBar({
    super.key,
    this.leading,
    this.leadingWidgetNumber,
    this.title,
    this.actions,
    this.showUserInfo = true,
    this.showPoints = true,
    this.showDrawerButton = true,
    this.scaffoldKey,
    this.backgroundColor,
    this.height = 80,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(CustomAppBarActionsController());

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            CustomTheme.lightScheme().primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(
            horizontal: UniquesControllers().data.baseSpace * 2,
            vertical: UniquesControllers().data.baseSpace,
          ),
          child: Row(
            children: [
              // Leading section (Avatar ou widget personnalisé)
              if (leading != null)
                CustomAnimation(
                  duration: UniquesControllers().data.baseAnimationDuration,
                  delay: UniquesControllers().data.baseAnimationDuration,
                  curve: Curves.easeOutQuart,
                  xStartPosition:
                      -UniquesControllers().data.baseAppBarHeight / 2,
                  isOpacity: true,
                  child: leading!,
                )
              else if (showUserInfo)
                StreamBuilder<String>(
                  stream: _getUserImageStream(),
                  builder: (context, snapshot) {
                    return CustomAnimation(
                      duration: UniquesControllers().data.baseAnimationDuration,
                      delay: UniquesControllers().data.baseAnimationDuration,
                      curve: Curves.easeOutQuart,
                      xStartPosition:
                          -UniquesControllers().data.baseAppBarHeight / 2,
                      isOpacity: true,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.8),
                              CustomTheme.lightScheme().primary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: snapshot.hasData && snapshot.data!.isNotEmpty
                              ? Image.network(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    );
                  },
                ),

              if (showUserInfo || leading != null) const SizedBox(width: 12),

              // Title section
              Expanded(
                child: title != null
                    ? CustomAnimation(
                        duration:
                            UniquesControllers().data.baseAnimationDuration,
                        delay: UniquesControllers().data.baseAnimationDuration,
                        curve: Curves.easeOutQuart,
                        yStartPosition:
                            -UniquesControllers().data.baseAppBarHeight / 2,
                        isOpacity: true,
                        child: title!,
                      )
                    : showUserInfo
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomAnimation(
                                duration: UniquesControllers()
                                    .data
                                    .baseAnimationDuration,
                                delay: UniquesControllers()
                                        .data
                                        .baseAnimationDuration *
                                    1.2,
                                curve: Curves.easeOutQuart,
                                yStartPosition: -10,
                                isOpacity: true,
                                child: Text(
                                  'Bonjour,',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              StreamBuilder<String>(
                                stream: _getUserNameStream(),
                                builder: (context, snapshot) {
                                  return CustomAnimation(
                                    duration: UniquesControllers()
                                        .data
                                        .baseAnimationDuration,
                                    delay: UniquesControllers()
                                            .data
                                            .baseAnimationDuration *
                                        1.4,
                                    curve: Curves.easeOutQuart,
                                    yStartPosition: -10,
                                    isOpacity: true,
                                    child: Text(
                                      snapshot.data ?? 'Utilisateur',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
              ),

              // Actions section
              if (actions != null)
                ...actions!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  return CustomAnimation(
                    duration: UniquesControllers().data.baseAnimationDuration,
                    delay: UniquesControllers().data.baseAnimationDuration *
                        (index + 1),
                    curve: Curves.easeOutQuart,
                    xStartPosition:
                        UniquesControllers().data.baseAppBarHeight / 2,
                    isOpacity: true,
                    child: action,
                  );
                }).toList()
              else ...[
                // Points widget (si activé)
                if (showPoints)
                  Obx(() {
                    final realPoints = cc.realPoints.value;
                    final pendingPoints = cc.pendingPoints.value;
                    final isBoutique = cc.isBoutique.value;
                    final coupons = cc.couponsRestants.value;
                    final couponsPending = cc.couponsPending.value;
                    final isAdmin = cc.isAdmin.value;

                    return CustomAnimation(
                      duration: UniquesControllers().data.baseAnimationDuration,
                      delay:
                          UniquesControllers().data.baseAnimationDuration * 2,
                      curve: Curves.easeOutQuart,
                      xStartPosition: 20,
                      isOpacity: true,
                      child: Row(
                        children: [
                          // Infos boutique
                          if (isBoutique) ...[
                            _buildInfoWidget(
                              icon: Icons.confirmation_number,
                              value: coupons,
                              label: 'Bons',
                              pending: couponsPending,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Points (sauf admin)
                          if (!isAdmin)
                            _buildInfoWidget(
                              icon: Icons.stars_rounded,
                              value: realPoints,
                              label: 'pts',
                              pending: pendingPoints,
                              color: CustomTheme.lightScheme().primary,
                            ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(width: 12),

                // Bouton menu drawer
                if (showDrawerButton)
                  CustomAnimation(
                    duration: UniquesControllers().data.baseAnimationDuration,
                    delay: UniquesControllers().data.baseAnimationDuration * 3,
                    curve: Curves.easeOutQuart,
                    xStartPosition: 20,
                    isOpacity: true,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(
                              UniquesControllers().data.baseSpace),
                          decoration: BoxDecoration(
                            color: CustomTheme.lightScheme().primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CustomTheme.lightScheme()
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 20,
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoWidget({
    required IconData icon,
    required int value,
    required String label,
    required int pending,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 1.5,
        vertical: UniquesControllers().data.baseSpace,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '$value',
                  key: ValueKey(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 2),
            Text(
              '+$pending en attente',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
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
