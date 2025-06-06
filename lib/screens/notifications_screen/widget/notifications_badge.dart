import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/notifications_controller.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  final Color? badgeColor;
  final TextStyle? textStyle;

  const NotificationBadge({
    super.key,
    required this.child,
    this.showBadge = true,
    this.badgeColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    // Essayer de récupérer le contrôleur existant, sinon le créer
    NotificationsController controller;
    try {
      controller = Get.find<NotificationsController>();
    } catch (e) {
      controller = Get.put(NotificationsController());
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Obx(() {
          final count = controller.unreadCount.value;
          if (count == 0) return const SizedBox.shrink();

          return Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (badgeColor ?? Colors.red).withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: textStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Widget pour l'icône de notification avec badge intégré
class NotificationIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double iconSize;
  final Color? iconColor;

  const NotificationIconButton({
    super.key,
    required this.onPressed,
    this.iconSize = 24,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.notifications_outlined,
          size: iconSize,
          color: iconColor ?? Colors.grey[700],
        ),
      ),
    );
  }
}
