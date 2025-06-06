import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/notification.dart' as app;
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationsController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: false,
        showPoints: false,
        showNotifications: false,
        showDrawerButton: true,
        modernStyle: true,
        showGreeting: false,
      ),
      noFAB: true,
      body: Obx(() {
        final notifications = controller.notifications;

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 50,
                    color: Colors.orange.withOpacity(0.5),
                  ),
                ),
                const CustomSpace(heightMultiplier: 2),
                Text(
                  'Aucune notification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const CustomSpace(heightMultiplier: 1),
                Text(
                  'Vous recevrez ici vos notifications',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];

            return CustomCardAnimation(
              index: index,
              delayGap: UniquesControllers().data.baseArrayDelayGapAnimation,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: UniquesControllers().data.baseSpace * 2,
                ),
                child: _NotificationCard(
                  notification: notification,
                  isTablet: isTablet,
                  onTap: () => controller.markAsRead(notification.id),
                  onDismiss: () =>
                      controller.deleteNotification(notification.id),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final app.Notification notification;
  final bool isTablet;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.isTablet,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding:
            EdgeInsets.only(right: UniquesControllers().data.baseSpace * 2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: Colors.red,
          size: 28,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(notification.read ? 0.3 : 0.5),
                    Colors.white.withOpacity(notification.read ? 0.2 : 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: notification.read
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.4),
                  width: notification.read ? 1 : 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding:
                        EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icône du type de notification
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getIconColor().withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(),
                            color: _getIconColor(),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Contenu
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: notification.read
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!notification.read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(notification.createdAt),
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'gift_received':
        return Icons.card_giftcard;
      case 'purchase_confirmation':
        return Icons.shopping_bag;
      case 'points_received':
        return Icons.stars;
      case 'donation_received':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'gift_received':
        return Colors.green;
      case 'purchase_confirmation':
        return Colors.blue;
      case 'points_received':
        return Colors.orange;
      case 'donation_received':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
    }
  }
}
