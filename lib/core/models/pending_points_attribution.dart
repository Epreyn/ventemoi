import 'package:cloud_firestore/cloud_firestore.dart';

class PendingPointsAttribution {
  final String id;
  final String email;
  final int points;
  final String giverId;
  final DateTime createdAt;
  final bool claimed;
  final String? claimedByUserId;
  final DateTime? claimedAt;
  final String? invitationToken;

  PendingPointsAttribution({
    required this.id,
    required this.email,
    required this.points,
    required this.giverId,
    required this.createdAt,
    required this.claimed,
    this.claimedByUserId,
    this.claimedAt,
    this.invitationToken,
  });

  factory PendingPointsAttribution.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PendingPointsAttribution(
      id: doc.id,
      email: data['email'] ?? '',
      points: data['points'] ?? 0,
      giverId: data['giver_id'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      claimed: data['claimed'] ?? false,
      claimedByUserId: data['claimed_by_user_id'],
      claimedAt: data['claimed_at'] != null
          ? (data['claimed_at'] as Timestamp).toDate()
          : null,
      invitationToken: data['invitation_token'],
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'points': points,
        'giver_id': giverId,
        'created_at': Timestamp.fromDate(createdAt),
        'claimed': claimed,
        'claimed_by_user_id': claimedByUserId,
        'claimed_at': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
        'invitation_token': invitationToken,
      };
}
