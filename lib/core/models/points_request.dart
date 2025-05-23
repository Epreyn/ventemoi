import 'package:cloud_firestore/cloud_firestore.dart';

class PointsRequest {
  final String id; // <-- we store the doc id
  final String userId;
  final String establishmentId;
  final String walletId;
  final int couponsCount;
  final bool isValidated;
  final DateTime createdAt;

  PointsRequest({
    required this.id,
    required this.userId,
    required this.establishmentId,
    required this.walletId,
    required this.couponsCount,
    required this.isValidated,
    required this.createdAt,
  });

  factory PointsRequest.fromDocument(String docId, Map<String, dynamic> map) {
    // Convert 'createdAt' from Timestamp if necessary
    final rawCreated = map['createdAt'];
    DateTime dt;
    if (rawCreated is Timestamp) {
      dt = rawCreated.toDate();
    } else {
      dt = DateTime.now();
    }

    return PointsRequest(
      id: docId,
      userId: map['user_id'] ?? '',
      establishmentId: map['establishment_id'] ?? '',
      walletId: map['wallet_id'] ?? '',
      couponsCount: map['coupons_count'] ?? 0,
      isValidated: map['isValidated'] ?? false,
      createdAt: dt,
    );
  }
}
