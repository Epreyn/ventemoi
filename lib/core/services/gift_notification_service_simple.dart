import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class GiftNotification {
  final String id;
  final String type; // 'points' or 'voucher'
  final String fromName;
  final String fromEmail;
  final int? pointsAmount;
  final Map<String, dynamic>? voucherData;
  final DateTime receivedAt;
  final bool hasBeenShown;

  GiftNotification({
    required this.id,
    required this.type,
    required this.fromName,
    required this.fromEmail,
    this.pointsAmount,
    this.voucherData,
    required this.receivedAt,
    this.hasBeenShown = false,
  });
}

class GiftNotificationServiceSimple extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final RxList<GiftNotification> pendingNotifications = <GiftNotification>[].obs;

  Future<GiftNotificationServiceSimple> init() async {
    return this;
  }

  // Version simplifiée sans index composites
  Future<List<GiftNotification>> checkForNewGiftsSimple() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      List<GiftNotification> notifications = [];

      // Récupérer TOUS les transferts de points pour cet utilisateur
      // La collection s'appelle 'points_transfers' avec un underscore !
      try {
        final pointsQuery = await _firestore
            .collection('points_transfers') // Avec underscore !
            .where('recipient_id', isEqualTo: user.uid) // recipient_id, pas toUserId !
            .get();

        
        // Debug : afficher tous les documents
        for (var doc in pointsQuery.docs) {
          final data = doc.data();
        }

        // Filtrer côté client
        final recentTransfers = pointsQuery.docs.where((doc) {
          final data = doc.data();
          final hasBeenShown = data['hasBeenShown'] ?? false;
          final status = data['status'] ?? '';
          
          // Debug
          if (!hasBeenShown && status == 'completed') {
          }
          
          return !hasBeenShown && status == 'completed';
        }).toList();


        // Trier par date
        recentTransfers.sort((a, b) {
          final dateA = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateB = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return dateB.compareTo(dateA); // Ordre décroissant
        });

        // Process point transfers
        for (var doc in recentTransfers) {
          final data = doc.data();
          
          String senderName = 'Anonyme';
          String senderEmail = '';
          
          // Récupérer les infos de l'expéditeur si possible
          // Le champ s'appelle 'sender_id' pas 'fromUserId' !
          if (data['sender_id'] != null) {
            try {
              final senderDoc = await _firestore
                  .collection('users')
                  .doc(data['sender_id'])
                  .get();
              
              if (senderDoc.exists) {
                final senderData = senderDoc.data() ?? {};
                senderName = senderData['name'] ?? senderData['firstName'] ?? 'Anonyme';
                senderEmail = senderData['email'] ?? '';
              }
            } catch (e) {
            }
          }
          
          notifications.add(GiftNotification(
            id: doc.id,
            type: 'points',
            fromName: senderName,
            fromEmail: senderEmail,
            pointsAmount: data['points'] ?? 0, // Le champ s'appelle 'points' pas 'amount' !
            receivedAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(), // created_at pas createdAt !
            hasBeenShown: false,
          ));
          
        }
      } catch (e) {
      }

      // Pour les bons cadeaux - même approche
      try {
        final vouchersQuery = await _firestore
            .collection('voucherPurchases')
            .where('recipientId', isEqualTo: user.uid)
            .get();

        // Filtrer côté client
        final recentVouchers = vouchersQuery.docs.where((doc) {
          final data = doc.data();
          final hasBeenShown = data['hasBeenShown'] ?? false;
          final status = data['status'] ?? '';
          return !hasBeenShown && status == 'completed';
        }).toList();

        // Trier par date
        recentVouchers.sort((a, b) {
          final dateA = (a.data()['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateB = (b.data()['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return dateB.compareTo(dateA);
        });

        // Process vouchers
        for (var doc in recentVouchers) {
          final data = doc.data();
          
          String purchaserName = 'Anonyme';
          String purchaserEmail = '';
          
          if (data['purchaserId'] != null) {
            try {
              final purchaserDoc = await _firestore
                  .collection('users')
                  .doc(data['purchaserId'])
                  .get();
              
              if (purchaserDoc.exists) {
                final purchaserData = purchaserDoc.data() ?? {};
                purchaserName = purchaserData['name'] ?? purchaserData['firstName'] ?? 'Anonyme';
                purchaserEmail = purchaserData['email'] ?? '';
              }
            } catch (e) {
            }
          }
          
          notifications.add(GiftNotification(
            id: doc.id,
            type: 'voucher',
            fromName: purchaserName,
            fromEmail: purchaserEmail,
            voucherData: {
              'amount': data['amount'],
              'establishmentName': data['establishmentName'] ?? '',
              'voucherCode': data['voucherCode'] ?? '',
            },
            receivedAt: (data['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            hasBeenShown: false,
          ));
        }
      } catch (e) {
      }

      pendingNotifications.value = notifications;
      return notifications;
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationAsShown(String notificationId, String type) async {
    try {
      // Ne pas essayer de marquer les notifications de test
      if (notificationId.startsWith('test-')) {
        return;
      }
      
      final user = _auth.currentUser;
      if (user == null) return;

      if (type == 'points') {
        await _firestore
            .collection('points_transfers') // Avec underscore !
            .doc(notificationId)
            .update({'hasBeenShown': true});
      } else if (type == 'voucher') {
        await _firestore
            .collection('voucherPurchases')
            .doc(notificationId)
            .update({'hasBeenShown': true});
      }
      
    } catch (e) {
      // Ne PAS créer de documents pour les notifications de test
      if (!notificationId.startsWith('test-')) {
        try {
          if (type == 'points') {
            await _firestore
                .collection('points_transfers') // Avec underscore !
                .doc(notificationId)
                .set({'hasBeenShown': true}, SetOptions(merge: true));
          } else if (type == 'voucher') {
            await _firestore
                .collection('voucherPurchases')
                .doc(notificationId)
                .set({'hasBeenShown': true}, SetOptions(merge: true));
          }
        } catch (e2) {
        }
      }
    }
  }

  Future<void> markAllAsShown() async {
    for (var notification in pendingNotifications) {
      await markNotificationAsShown(notification.id, notification.type);
    }
    pendingNotifications.clear();
  }
  
  // Méthode pour nettoyer les documents de test
  Future<void> cleanTestDocuments() async {
    try {
      
      // Supprimer les documents de test dans les deux collections possibles
      final collections = ['points_transfers', 'pointsTransfers'];
      
      for (var collectionName in collections) {
        try {
          // Récupérer tous les docs pour identifier ceux de test
          final allDocs = await _firestore
              .collection(collectionName)
              .get();
          
          for (var doc in allDocs.docs) {
            if (doc.id.startsWith('test-')) {
              await doc.reference.delete();
            }
          }
        } catch (e) {
        }
      }
      
    } catch (e) {
    }
  }
  
  // Version de test qui affiche TOUS les transferts (même ceux déjà montrés)
  Future<List<GiftNotification>> checkForNewGiftsTest() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      List<GiftNotification> notifications = [];

      // Récupérer les derniers transferts de points (même ceux déjà montrés)
      // Essayons plusieurs collections possibles
      try {
        // Essai 1: pointsTransfers
        var pointsQuery = await _firestore
            .collection('pointsTransfers')
            .where('toUserId', isEqualTo: user.uid)
            .limit(5)
            .get();
            
        
        // Si vide, essayons avec d'autres champs
        if (pointsQuery.docs.isEmpty) {
          pointsQuery = await _firestore
              .collection('pointsTransfers')
              .where('recipientId', isEqualTo: user.uid)
              .limit(5)
              .get();
        }
        
        // Si toujours vide, essayons transfers
        if (pointsQuery.docs.isEmpty) {
          pointsQuery = await _firestore
              .collection('transfers')
              .where('toUserId', isEqualTo: user.uid)
              .limit(5)
              .get();
        }
        
        // Si toujours vide, récupérons TOUS les documents pour voir la structure
        if (pointsQuery.docs.isEmpty) {
          final allDocs = await _firestore
              .collection('pointsTransfers')
              .limit(10)
              .get();
          
          for (var doc in allDocs.docs) {
            final data = doc.data();
            
            // Chercher des documents qui pourraient être pour cet utilisateur
            if (data.values.any((v) => v.toString().contains(user.uid))) {
            }
          }
          
          // Essayons aussi de chercher dans les sous-collections ou d'autres patterns
          
          // Pattern 1: peut-être que l'UID est stocké différemment
          final userEmail = user.email;
          if (userEmail != null) {
            final byEmail = await _firestore
                .collection('pointsTransfers')
                .where('toEmail', isEqualTo: userEmail)
                .limit(5)
                .get();
            
            if (byEmail.docs.isNotEmpty) {
              pointsQuery = byEmail;
            }
          }
        }


        for (var doc in pointsQuery.docs) {
          final data = doc.data();
          
          String senderName = 'Test User';
          
          if (data['fromUserId'] != null) {
            try {
              final senderDoc = await _firestore
                  .collection('users')
                  .doc(data['fromUserId'])
                  .get();
              
              if (senderDoc.exists) {
                final senderData = senderDoc.data() ?? {};
                senderName = senderData['name'] ?? senderData['firstName'] ?? 'Test User';
              }
            } catch (e) {
              // Ignore
            }
          }
          
          notifications.add(GiftNotification(
            id: doc.id,
            type: 'points',
            fromName: senderName,
            fromEmail: 'test@example.com',
            pointsAmount: data['amount'] ?? 100,
            receivedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            hasBeenShown: false,
          ));
        }
      } catch (e) {
      }

      // Si aucun transfert trouvé, créer une notification de test
      if (notifications.isEmpty) {
        notifications.add(GiftNotification(
          id: 'test-${DateTime.now().millisecondsSinceEpoch}',
          type: 'points',
          fromName: 'Système de Test',
          fromEmail: 'test@ventemoi.com',
          pointsAmount: 50,
          receivedAt: DateTime.now(),
          hasBeenShown: false,
        ));
      }

      pendingNotifications.value = notifications;
      return notifications;
    } catch (e) {
      
      // Retourner une notification de test même en cas d'erreur
      return [
        GiftNotification(
          id: 'test-error',
          type: 'points',
          fromName: 'Système',
          fromEmail: 'system@ventemoi.com',
          pointsAmount: 25,
          receivedAt: DateTime.now(),
          hasBeenShown: false,
        )
      ];
    }
  }
}