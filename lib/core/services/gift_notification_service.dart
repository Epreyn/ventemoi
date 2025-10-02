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

  factory GiftNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftNotification(
      id: doc.id,
      type: data['type'] ?? 'points',
      fromName: data['fromName'] ?? 'Anonyme',
      fromEmail: data['fromEmail'] ?? '',
      pointsAmount: data['pointsAmount'],
      voucherData: data['voucherData'],
      receivedAt: (data['receivedAt'] as Timestamp).toDate(),
      hasBeenShown: data['hasBeenShown'] ?? false,
    );
  }
}

class GiftNotificationService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final RxList<GiftNotification> pendingNotifications = <GiftNotification>[].obs;

  Future<GiftNotificationService> init() async {
    return this;
  }

  Future<List<GiftNotification>> checkForNewGifts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      List<GiftNotification> notifications = [];

      // Check for recent point transfers
      try {
        final pointsQuery = await _firestore
            .collection('pointsTransfers')
            .where('toUserId', isEqualTo: user.uid)
            .where('hasBeenShown', isEqualTo: false)
            .where('status', isEqualTo: 'completed')
            .orderBy('createdAt', descending: true)
            .get();

        // Process point transfers
        for (var doc in pointsQuery.docs) {
          final data = doc.data();
          
          // Get sender info
          String senderName = 'Anonyme';
          String senderEmail = '';
          try {
            final senderDoc = await _firestore
                .collection('users')
                .doc(data['fromUserId'])
                .get();
            
            if (senderDoc.exists) {
              final senderData = senderDoc.data() ?? {};
              senderName = senderData['name'] ?? 'Anonyme';
              senderEmail = senderData['email'] ?? '';
            }
          } catch (e) {
          }
          
          notifications.add(GiftNotification(
            id: doc.id,
            type: 'points',
            fromName: senderName,
            fromEmail: senderEmail,
            pointsAmount: data['amount'] ?? 0,
            receivedAt: (data['createdAt'] as Timestamp).toDate(),
            hasBeenShown: false,
          ));
        }
      } catch (e) {
        // Si l'index n'existe pas ou autre erreur, on continue
        if (e.toString().contains('index')) {
        }
      }

      // Check for recent voucher purchases - séparément pour éviter l'erreur d'index
      try {
        final vouchersQuery = await _firestore
            .collection('voucherPurchases')
            .where('recipientId', isEqualTo: user.uid)
            .where('hasBeenShown', isEqualTo: false)
            .where('status', isEqualTo: 'completed')
            .orderBy('purchasedAt', descending: true)
            .get();

        // Process vouchers
        for (var doc in vouchersQuery.docs) {
          final data = doc.data();
          
          // Get purchaser info
          String purchaserName = 'Anonyme';
          String purchaserEmail = '';
          try {
            final purchaserDoc = await _firestore
                .collection('users')
                .doc(data['purchaserId'])
                .get();
            
            if (purchaserDoc.exists) {
              final purchaserData = purchaserDoc.data() ?? {};
              purchaserName = purchaserData['name'] ?? 'Anonyme';
              purchaserEmail = purchaserData['email'] ?? '';
            }
          } catch (e) {
          }
          
          notifications.add(GiftNotification(
            id: doc.id,
            type: 'voucher',
            fromName: purchaserName,
            fromEmail: purchaserEmail,
            voucherData: {
              'amount': data['amount'],
              'establishmentName': data['establishmentName'],
              'voucherCode': data['voucherCode'],
            },
            receivedAt: (data['purchasedAt'] as Timestamp).toDate(),
            hasBeenShown: false,
          ));
        }
      } catch (e) {
        // Si l'index n'existe pas ou autre erreur, on continue
        if (e.toString().contains('index')) {
        }
      }

      pendingNotifications.value = notifications;
      return notifications;
    } catch (e) {
      return [];
    }
  }

  Future<void> markNotificationAsShown(String notificationId, String type) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (type == 'points') {
        await _firestore
            .collection('pointsTransfers')
            .doc(notificationId)
            .update({'hasBeenShown': true});
      } else if (type == 'voucher') {
        await _firestore
            .collection('voucherPurchases')
            .doc(notificationId)
            .update({'hasBeenShown': true});
      }
    } catch (e) {
    }
  }

  Future<void> markAllAsShown() async {
    for (var notification in pendingNotifications) {
      await markNotificationAsShown(notification.id, notification.type);
    }
    pendingNotifications.clear();
  }
}