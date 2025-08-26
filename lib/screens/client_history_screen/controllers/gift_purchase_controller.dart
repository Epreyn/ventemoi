import 'dart:math' as math;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/email_templates.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';
import '../../notifications_screen/controllers/notifications_controller.dart';

// Dans lib/screens/client_history_screen/controllers/gift_purchase_controller.dart

class GiftPurchaseController extends GetxController with ControllerMixin {
  final Purchase purchase;

  GiftPurchaseController({required this.purchase});

  final RxString searchQuery = ''.obs;
  final RxBool isTransferring = false.obs;
  final Rxn<Map<String, dynamic>> selectedUser = Rxn<Map<String, dynamic>>();

  // Cache pour les établissements
  final Map<String, String> establishmentNameCache = {};

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
        .asyncMap((snapshot) async {
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
          // Récupérer le nom d'établissement si existe
          final establishmentName = await _getEstablishmentName(doc.id);
          data['establishment_name'] = establishmentName;

          users.add(data);
        }

        if (users.length >= 10) break;
      }

      return users;
    });
  }

  // Récupérer le nom d'établissement
  Future<String?> _getEstablishmentName(String userId) async {
    if (establishmentNameCache.containsKey(userId)) {
      return establishmentNameCache[userId];
    }

    try {
      final estabQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        final establishmentName =
            estabQuery.docs.first.data()['name'] as String?;
        establishmentNameCache[userId] = establishmentName ?? '';
        return establishmentName;
      }
    } catch (e) {
    }

    establishmentNameCache[userId] = '';
    return null;
  }

  // Afficher Prénom Nom en priorité
  String getUserDisplayName(Map<String, dynamic> userData) {
    // Construire le nom complet avec prénom et nom
    final firstName = userData['first_name'] ?? '';
    final lastName = userData['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    // Si pas de prénom/nom, utiliser display_name
    if (userData['display_name'] != null &&
        userData['display_name'].toString().isNotEmpty) {
      return userData['display_name'];
    }

    // Si pas de display_name, utiliser company_name
    if (userData['company_name'] != null &&
        userData['company_name'].toString().isNotEmpty) {
      return userData['company_name'];
    }

    // En dernier recours, partie avant @ de l'email
    if (userData['email'] != null) {
      final email = userData['email'].toString();
      if (email.contains('@')) {
        return email.split('@')[0];
      }
      return email;
    }

    return 'Utilisateur';
  }

  // Afficher Établissement (si existe)
  String getUserSubtitle(Map<String, dynamic> userData) {
    final establishmentName = userData['establishment_name'] as String?;

    // Si l'utilisateur a un établissement, l'afficher
    if (establishmentName != null && establishmentName.isNotEmpty) {
      return establishmentName;
    }

    // Sinon, afficher son type d'utilisateur ou son email
    final userType = userData['user_type'] as String?;
    if (userType != null && userType.isNotEmpty) {
      return userType;
    }

    // En dernier recours, afficher l'email
    final email = userData['email'] ?? '';
    return email;
  }

  // Obtenir les initiales depuis prénom/nom
  String getInitials(Map<String, dynamic> userData) {
    final firstName = userData['first_name'] ?? '';
    final lastName = userData['last_name'] ?? '';

    // Si on a prénom et nom, prendre les initiales
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }

    // Si seulement prénom ou nom
    if (firstName.isNotEmpty) {
      final length = firstName.length;
      return firstName.substring(0, length >= 2 ? 2 : length).toUpperCase();
    }
    if (lastName.isNotEmpty) {
      final length = lastName.length;
      return lastName.substring(0, length >= 2 ? 2 : length).toUpperCase();
    }

    // Sinon utiliser le display name ou email
    final displayName = getUserDisplayName(userData);
    final words = displayName.split(' ').where((w) => w.isNotEmpty).toList();

    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      final length = words[0].length;
      return words[0].substring(0, length >= 2 ? 2 : length).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  void selectUser(Map<String, dynamic> userData) {
    if (selectedUser.value?['id'] == userData['id']) {
      selectedUser.value = null;
    } else {
      selectedUser.value = userData;
    }
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
        'reclamationPassword': newCode,
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
      UniquesControllers().data.snackbar(
            'Bon cadeau offert !',
            'Le bon a été envoyé à ${getUserDisplayName(selectedUser.value!)}',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible d\'offrir le bon cadeau',
            true,
          );
    } finally {
      isTransferring.value = false;
    }
  }
}
