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
    this.showDrawerButton = true,
    this.scaffoldKey,
    this.backgroundColor,
    this.height = 80,
    this.showGreeting = true,
    this.modernStyle = true,
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
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: UniquesControllers().data.baseSpace * 2,
            vertical: UniquesControllers().data.baseSpace,
          ),
          child: modernStyle
              ? _buildModernContent(cc, context)
              : _buildClassicContent(cc, context),
        ),
      ),
    );
  }

  Widget _buildModernContent(
      CustomAppBarActionsController cc, BuildContext context) {
    return Row(
      children: [
        // Avatar utilisateur ou leading personnalisé
        if (leading != null)
          CustomAnimation(
            duration: UniquesControllers().data.baseAnimationDuration,
            delay: UniquesControllers().data.baseAnimationDuration,
            curve: Curves.easeOutQuart,
            xStartPosition: -UniquesControllers().data.baseAppBarHeight / 2,
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
                xStartPosition: -20,
                isOpacity: true,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: CustomTheme.lightScheme().primary,
                  backgroundImage: snapshot.hasData && snapshot.data!.isNotEmpty
                      ? NetworkImage(snapshot.data!)
                      : null,
                  child: !snapshot.hasData || snapshot.data!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              );
            },
          ),

        if (showUserInfo || leading != null) const SizedBox(width: 12),

        // Titre et sous-titre ou widget titre personnalisé
        Expanded(
          child: title != null
              ? CustomAnimation(
                  duration: UniquesControllers().data.baseAnimationDuration,
                  delay: UniquesControllers().data.baseAnimationDuration * 1.2,
                  curve: Curves.easeOutQuart,
                  yStartPosition: -10,
                  isOpacity: true,
                  child: title!,
                )
              : showUserInfo && showGreeting
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomAnimation(
                          duration:
                              UniquesControllers().data.baseAnimationDuration,
                          delay:
                              UniquesControllers().data.baseAnimationDuration *
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

        // Actions personnalisées ou points et drawer
        if (actions != null)
          ...actions!.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return CustomAnimation(
              duration: UniquesControllers().data.baseAnimationDuration,
              delay:
                  UniquesControllers().data.baseAnimationDuration * (index + 2),
              curve: Curves.easeOutQuart,
              xStartPosition: 20,
              isOpacity: true,
              child: action,
            );
          }).toList()
        else ...[
          // Widget points moderne
          if (showPoints)
            Obx(() => CustomAnimation(
                  duration: UniquesControllers().data.baseAnimationDuration,
                  delay: UniquesControllers().data.baseAnimationDuration * 2,
                  curve: Curves.easeOutQuart,
                  xStartPosition: 20,
                  isOpacity: true,
                  child: _buildModernPointsWidget(cc),
                )),

          if (showPoints) const SizedBox(width: 12),

          // Menu drawer moderne
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
                    padding:
                        EdgeInsets.all(UniquesControllers().data.baseSpace),
                    decoration: BoxDecoration(
                      color: CustomTheme.lightScheme().primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
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
    );
  }

  Widget _buildModernPointsWidget(CustomAppBarActionsController cc) {
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
        // Infos boutique (moderne)
        if (isBoutique) ...[
          _buildModernInfoBadge(
            value: coupons,
            label: 'Bons',
            pending: couponsPending,
            icon: Icons.confirmation_number,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
        ],

        // Points (sauf admin)
        if (!isAdmin)
          _buildModernInfoBadge(
            value: realPoints,
            label: 'pts',
            pending: pendingPoints,
            icon: Icons.stars_rounded,
            color: CustomTheme.lightScheme().primary,
          ),
      ],
    );
  }

  Widget _buildModernInfoBadge({
    required int value,
    required String label,
    required int pending,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 2,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
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
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicContent(
      CustomAppBarActionsController cc, BuildContext context) {
    // Ancien style pour la compatibilité
    return Row(
      children: [
        // Leading
        if (leading != null)
          CustomAnimation(
            duration: UniquesControllers().data.baseAnimationDuration,
            delay: UniquesControllers().data.baseAnimationDuration,
            curve: Curves.easeOutQuart,
            xStartPosition: -UniquesControllers().data.baseAppBarHeight / 2,
            isOpacity: true,
            child: leading!,
          ),

        // Title
        if (title != null)
          Expanded(
            child: CustomAnimation(
              duration: UniquesControllers().data.baseAnimationDuration,
              delay: UniquesControllers().data.baseAnimationDuration,
              curve: Curves.easeOutQuart,
              yStartPosition: -UniquesControllers().data.baseAppBarHeight / 2,
              isOpacity: true,
              child: title!,
            ),
          ),

        // Actions classiques
        if (actions != null)
          ...actions!
        else ...[
          // Points widget classique
          if (showPoints) Obx(() => _buildClassicPointsWidget(cc)),

          const SizedBox(width: 12),

          // Menu button classique
          if (showDrawerButton)
            IconButton(
              icon: Icon(
                Icons.menu,
                color: CustomTheme.lightScheme().primary,
              ),
              onPressed: () {
                if (scaffoldKey != null) {
                  scaffoldKey!.currentState?.openDrawer();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            ),
        ],
      ],
    );
  }

  Widget _buildClassicPointsWidget(CustomAppBarActionsController cc) {
    final real = cc.realPoints.value;
    final pending = cc.pendingPoints.value;
    final isBoutique = cc.isBoutique.value;
    final coupons = cc.couponsRestants.value;
    final couponsPending = cc.couponsPending.value;
    final isAdmin = cc.isAdmin.value;

    return Row(
      children: [
        if (isBoutique)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$coupons Bons',
                style: TextStyle(
                  fontSize: UniquesControllers().data.baseSpace * 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (couponsPending > 0)
                Text(
                  '$couponsPending en attente',
                  style: TextStyle(
                    fontSize: UniquesControllers().data.baseSpace * 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        if (isBoutique) const SizedBox(width: 16),
        if (!isAdmin)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$real Points',
                style: TextStyle(
                  fontSize: UniquesControllers().data.baseSpace * 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pending > 0)
                Text(
                  '$pending en attente',
                  style: TextStyle(
                    fontSize: UniquesControllers().data.baseSpace * 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
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
