import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String id;
  final String buyerId;
  final String sellerId;
  final int couponsCount;
  final DateTime date;
  final bool isReclaimed;
  final String reclamationPassword;

  Purchase({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.couponsCount,
    required this.date,
    required this.isReclaimed,
    required this.reclamationPassword,
  });

  factory Purchase.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Purchase(
      id: doc.id,
      buyerId: data['buyer_id'] ?? '',
      sellerId: data['seller_id'] ?? '',
      couponsCount: data['coupons_count'] ?? 0,
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      isReclaimed: data['isReclaimed'] ?? false,
      reclamationPassword: data['reclamationPassword'] ?? '',
    );
  }
}
