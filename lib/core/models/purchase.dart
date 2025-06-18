// core/models/purchase.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String id;
  final String buyerId;
  final String sellerId;
  final int couponsCount;
  final String reclamationPassword;
  final bool isReclaimed;
  final DateTime date;

  Purchase({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.couponsCount,
    required this.reclamationPassword,
    required this.isReclaimed,
    required this.date,
  });

  factory Purchase.fromDocument(String id, Map<String, dynamic> data) {
    return Purchase(
      id: id,
      buyerId: data['buyer_id'] ?? '',
      sellerId: data['seller_id'] ?? '',
      couponsCount: data['coupons_count'] ?? 0,
      reclamationPassword: data['reclamationPassword'] ?? '',
      isReclaimed: data['isReclaimed'] ?? false,
      date:
          data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
    );
  }

  // Alternative constructor pour compatibilité
  factory Purchase.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Purchase.fromDocument(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'coupons_count': couponsCount,
      'reclamationPassword': reclamationPassword,
      'isReclaimed': isReclaimed,
      'date': date.toIso8601String(),
    };
  }
}
