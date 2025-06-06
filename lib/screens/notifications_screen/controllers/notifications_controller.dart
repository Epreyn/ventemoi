import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/notification.dart' as app;

class NotificationsController extends GetxController with ControllerMixin {
  RxList<app.Notification> notifications = <app.Notification>[].obs;
  RxInt unreadCount = 0.obs;

  StreamSubscription<QuerySnapshot>? _notificationsSub;

  @override
  void onInit() {
    super.onInit();
    _listenToNotifications();
  }

  @override
  void onClose() {
    _notificationsSub?.cancel();
    super.onClose();
  }

  void _listenToNotifications() {
    final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (userId == null) return;

    _notificationsSub = UniquesControllers()
        .data
        .firebaseFirestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      notifications.value = snapshot.docs
          .map((doc) => app.Notification.fromDocument(doc))
          .toList();

      // Compter les non lues
      unreadCount.value = notifications.where((n) => !n.read).length;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (userId == null) return;

    try {
      final batch = UniquesControllers().data.firebaseFirestore.batch();

      final unreadNotifications = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (userId == null) return;

    try {
      final batch = UniquesControllers().data.firebaseFirestore.batch();

      final userNotifications = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .get();

      for (final doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // Helper pour créer une notification
  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? senderId,
    String? purchaseId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('notifications')
          .add({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'sender_id': senderId,
        'purchase_id': purchaseId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
        'metadata': metadata,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }
}
