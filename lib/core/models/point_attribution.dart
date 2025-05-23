import 'package:cloud_firestore/cloud_firestore.dart';

class PointAttribution {
  final String id;
  final String giverId;
  final String targetId;
  final String targetEmail;
  final double cost;
  final int points;
  final DateTime date;
  final bool validated;

  // AJOUT
  final double commissionPercent; // ex: 2.5
  final int commissionCost; // ex: 12 (floor)

  PointAttribution({
    required this.id,
    required this.giverId,
    required this.targetId,
    required this.targetEmail,
    required this.cost,
    required this.points,
    required this.date,
    required this.validated,
    required this.commissionPercent, // NOUVEAU
    required this.commissionCost, // NOUVEAU
  });

  factory PointAttribution.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PointAttribution(
      id: doc.id,
      giverId: data['giver_id'] ?? '',
      targetId: data['target_id'] ?? '',
      targetEmail: data['target_email'] ?? '',
      cost: data['cost'] ?? 0.0,
      points: data['points'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      validated: data['validated'] ?? false,

      // On lit les deux nouveaux champs
      commissionPercent: (data['commission_percent'] ?? 0).toDouble(),
      commissionCost: data['commission_cost'] ?? 0,
    );
  }
}
