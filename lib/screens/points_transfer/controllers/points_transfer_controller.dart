import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/classes/email_templates.dart';
import '../../notifications_screen/controllers/notifications_controller.dart';

class PointsTransferController extends GetxController with ControllerMixin {
  final RxString searchQuery = ''.obs;
  final RxBool isTransferring = false.obs;
  final Rxn<Map<String, dynamic>> selectedUser = Rxn<Map<String, dynamic>>();
  final RxInt pointsToTransfer = 0.obs;
  final RxInt availablePoints = 0.obs;
  
  final TextEditingController pointsController = TextEditingController();
  
  // Cache pour les établissements
  final Map<String, String> establishmentNameCache = {};

  @override
  void onInit() {
    super.onInit();
    _loadAvailablePoints();
    
    // Listener pour le champ de points
    pointsController.addListener(() {
      final value = int.tryParse(pointsController.text) ?? 0;
      pointsToTransfer.value = value;
    });
  }

  @override
  void onClose() {
    pointsController.dispose();
    super.onClose();
  }

  Future<void> _loadAvailablePoints() async {
    final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (userId == null) return;

    final walletQuery = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    if (walletQuery.docs.isNotEmpty) {
      final wallet = walletQuery.docs.first.data();
      availablePoints.value = wallet['points'] ?? 0;
    }
  }

  Stream<List<Map<String, dynamic>>> searchUsers() {
    final currentUserId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
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

        final name = (data['name'] ?? '').toString().toLowerCase();
        final displayName = (data['display_name'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final companyName = (data['company_name'] ?? '').toString().toLowerCase();
        final firstName = (data['first_name'] ?? '').toString().toLowerCase();
        final lastName = (data['last_name'] ?? '').toString().toLowerCase();

        if (name.contains(query) ||
            displayName.contains(query) ||
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
        final establishmentName = estabQuery.docs.first.data()['name'] as String?;
        establishmentNameCache[userId] = establishmentName ?? '';
        return establishmentName;
      }
    } catch (e) {
      // Erreur récupération établissement: $e
    }

    establishmentNameCache[userId] = '';
    return null;
  }

  String getUserDisplayName(Map<String, dynamic> userData) {
    // D'abord essayer le champ 'name'
    final name = userData['name'] ?? '';
    if (name.isNotEmpty) return name;
    
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

  String getInitials(Map<String, dynamic> userData) {
    final name = (userData['name'] ?? '').toString();
    if (name.isNotEmpty) {
      final words = name.split(' ').where((String w) => w.isNotEmpty).toList();
      if (words.isNotEmpty) {
        if (words.length == 1) {
          return words[0].substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
        }
        return '${words.first[0]}${words.last[0]}'.toUpperCase();
      }
    }
    
    final firstName = (userData['first_name'] ?? '').toString();
    final lastName = (userData['last_name'] ?? '').toString();

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
    final words = displayName.split(' ').where((String w) => w.isNotEmpty).toList();

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

  bool get canTransfer {
    return selectedUser.value != null && 
           pointsToTransfer.value > 0 && 
           pointsToTransfer.value <= availablePoints.value;
  }

  Future<void> transferPoints() async {
    if (!canTransfer) return;

    isTransferring.value = true;

    try {
      final currentUserId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (currentUserId == null) throw Exception('Utilisateur non connecté');

      final batch = UniquesControllers().data.firebaseFirestore.batch();

      // 1. Récupérer les wallets
      final senderWalletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (senderWalletQuery.docs.isEmpty) {
        throw Exception('Portefeuille expéditeur introuvable');
      }

      final recipientWalletQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: selectedUser.value!['id'])
          .limit(1)
          .get();

      // Créer le wallet du destinataire s'il n'existe pas
      DocumentReference recipientWalletRef;
      int currentRecipientPoints = 0;
      
      if (recipientWalletQuery.docs.isEmpty) {
        recipientWalletRef = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .doc();
        
        batch.set(recipientWalletRef, {
          'user_id': selectedUser.value!['id'],
          'points': pointsToTransfer.value,
          'coupons': 0,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        recipientWalletRef = recipientWalletQuery.docs.first.reference;
        currentRecipientPoints = recipientWalletQuery.docs.first.data()['points'] ?? 0;
        
        batch.update(recipientWalletRef, {
          'points': currentRecipientPoints + pointsToTransfer.value,
        });
      }

      // 2. Déduire les points de l'expéditeur
      final senderWalletRef = senderWalletQuery.docs.first.reference;
      final currentSenderPoints = senderWalletQuery.docs.first.data()['points'] ?? 0;
      
      batch.update(senderWalletRef, {
        'points': currentSenderPoints - pointsToTransfer.value,
      });

      // 3. Créer un enregistrement de transfert
      final transferRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_transfers')
          .doc();
      
      batch.set(transferRef, {
        'sender_id': currentUserId,
        'recipient_id': selectedUser.value!['id'],
        'points': pointsToTransfer.value,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // 4. Exécuter la transaction
      await batch.commit();

      // 5. Envoyer une notification
      await NotificationsController.createNotification(
        userId: selectedUser.value!['id'],
        type: 'points_received',
        title: 'Vous avez reçu des points !',
        message: '${getUserDisplayName(selectedUser.value!)} vous a envoyé ${pointsToTransfer.value} points',
        senderId: currentUserId,
      );

      // 6. Envoyer un email si possible
      final currentUser = UniquesControllers().data.firebaseAuth.currentUser;
      final senderName = await _getCurrentUserName();
      final recipientEmail = selectedUser.value!['email'];
      final recipientName = getUserDisplayName(selectedUser.value!);

      if (recipientEmail != null && recipientEmail.toString().isNotEmpty) {
        // TODO: Créer un template email pour le transfert de points
        // await sendPointsReceivedEmail(
        //   toEmail: recipientEmail,
        //   recipientName: recipientName,
        //   senderName: senderName,
        //   points: pointsToTransfer.value,
        // );
      }

      Get.back();
      UniquesControllers().data.snackbar(
        'Points transférés !',
        '${pointsToTransfer.value} points ont été envoyés à ${getUserDisplayName(selectedUser.value!)}',
        false,
      );

      // Recharger les points disponibles
      await _loadAvailablePoints();
      
    } catch (e) {
      // Erreur transfert points: $e
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible de transférer les points: ${e.toString()}',
        true,
      );
    } finally {
      isTransferring.value = false;
    }
  }

  Future<String> _getCurrentUserName() async {
    final userId = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (userId == null) return 'Un utilisateur';

    final userDoc = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      return data['name'] ?? 
             data['display_name'] ?? 
             '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim() ??
             'Un utilisateur';
    }

    return 'Un utilisateur';
  }
}