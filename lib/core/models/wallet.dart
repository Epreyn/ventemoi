import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String userId;
  final int points;
  final int coupons;
  final Map<String, dynamic>? bankDetails;

  Wallet({
    required this.id,
    required this.userId,
    required this.points,
    this.coupons = 0,
    this.bankDetails,
  });

  factory Wallet.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Wallet(
      id: doc.id,
      userId: data['user_id'] ?? '',
      points: data['points'] ?? 0,
      coupons: data['coupons'] ?? 0,
      bankDetails: data['bank_details'],
    );
  }
}
