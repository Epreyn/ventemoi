import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/email_templates.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';
import '../../notifications_screen/controllers/notifications_controller.dart';

class GiftPurchaseController extends GetxController with ControllerMixin {
  final Purchase purchase;

  GiftPurchaseController({required this.purchase});

  final RxString searchQuery = ''.obs;
  final RxBool isTransferring = false.obs;
  final Rxn<Map<String, dynamic>> selectedUser = Rxn<Map<String, dynamic>>();

  Stream<List<Map<String, dynamic>>> searchUsers() {
    final currentUserId =
        UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (currentUserId == null || searchQuery.value.length < 2) {
      return Stream.value([]);
    }

    final query = searchQuery.value.toLowerCase();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      final users = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;

        final data = doc.data();
        data['id'] = doc.id;

        final displayName =
            (data['display_name'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final companyName =
            (data['company_name'] ?? '').toString().toLowerCase();
        final firstName = (data['first_name'] ?? '').toString().toLowerCase();
        final lastName = (data['last_name'] ?? '').toString().toLowerCase();

        if (displayName.contains(query) ||
            email.contains(query) ||
            companyName.contains(query) ||
            firstName.contains(query) ||
            lastName.contains(query)) {
          users.add(data);
        }

        if (users.length >= 10) break;
      }

      return users;
    });
  }

  String getUserDisplayName(Map<String, dynamic> userData) {
    if (userData['display_name'] != null &&
        userData['display_name'].toString().isNotEmpty) {
      return userData['display_name'];
    }
    if (userData['company_name'] != null &&
        userData['company_name'].toString().isNotEmpty) {
      return userData['company_name'];
    }
    if (userData['first_name'] != null || userData['last_name'] != null) {
      final firstName = userData['first_name'] ?? '';
      final lastName = userData['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) return fullName;
    }
    if (userData['email'] != null) {
      return userData['email'];
    }
    return 'Utilisateur';
  }

  String getUserSubtitle(Map<String, dynamic> userData) {
    if (userData['company_name'] != null &&
        userData['company_name'].toString().isNotEmpty) {
      return userData['email'] ?? '';
    }
    return userData['email'] ?? userData['user_type'] ?? '';
  }

  String getInitials(Map<String, dynamic> userData) {
    final displayName = getUserDisplayName(userData);
    final words = displayName.split(' ').where((w) => w.isNotEmpty).toList();

    if (words.isEmpty) return 'U';
    if (words.length == 1) return words[0][0].toUpperCase();

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Future<void> transferPurchase() async {
    if (selectedUser.value == null) return;

    isTransferring.value = true;

    try {
      final random = math.Random();
      final newCode = List.generate(6, (_) => random.nextInt(10)).join();

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('purchases')
          .doc(purchase.id)
          .update({
        'buyer_id': selectedUser.value!['id'],
        'reclamation_password': newCode,
        'gifted_at': FieldValue.serverTimestamp(),
        'gifted_by': UniquesControllers().data.firebaseAuth.currentUser?.uid,
      });

      await NotificationsController.createNotification(
        userId: selectedUser.value!['id'],
        type: 'gift_received',
        title: 'Vous avez reçu un bon cadeau !',
        message:
            'Un bon d\'achat de ${purchase.couponsCount * 50}€ vous a été offert',
        senderId: UniquesControllers().data.firebaseAuth.currentUser?.uid,
        purchaseId: purchase.id,
      );

      final currentUser = UniquesControllers().data.firebaseAuth.currentUser;
      final senderName =
          currentUser?.displayName ?? currentUser?.email ?? 'Un utilisateur';
      final recipientEmail = selectedUser.value!['email'];
      final recipientName = getUserDisplayName(selectedUser.value!);

      if (recipientEmail != null && recipientEmail.toString().isNotEmpty) {
        await sendGiftReceivedEmail(
          toEmail: recipientEmail,
          recipientName: recipientName,
          senderName: senderName,
          amount: purchase.couponsCount * 50,
          reclamationCode: newCode,
        );
      }

      Get.back();
      Get.snackbar(
        'Bon cadeau offert !',
        'Le bon a été envoyé à ${getUserDisplayName(selectedUser.value!)}',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
        borderRadius: 16,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'offrir le bon cadeau',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
        borderRadius: 16,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isTransferring.value = false;
    }
  }

  void selectUser(Map<String, dynamic> userData) {
    if (selectedUser.value?['id'] == userData['id']) {
      selectedUser.value = null;
    } else {
      selectedUser.value = userData;
    }
  }
}
