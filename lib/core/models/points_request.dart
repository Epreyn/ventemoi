// core/models/points_request.dart

class PointsRequest {
  final String id;
  final String userId;
  final String walletId;
  final String establishmentId;
  final int couponsCount;
  final bool isValidated;
  final DateTime createdAt;

  PointsRequest({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.establishmentId,
    required this.couponsCount,
    required this.isValidated,
    required this.createdAt,
  });

  factory PointsRequest.fromDocument(String id, Map<String, dynamic> data) {
    return PointsRequest(
      id: id,
      userId: data['user_id'] ?? '',
      walletId: data['wallet_id'] ?? '',
      establishmentId: data['establishment_id'] ?? '',
      couponsCount: data['coupons_count'] ?? 0,
      isValidated: data['isValidated'] ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'wallet_id': walletId,
      'establishment_id': establishmentId,
      'coupons_count': couponsCount,
      'isValidated': isValidated,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
