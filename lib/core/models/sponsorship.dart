import 'package:cloud_firestore/cloud_firestore.dart';

class Sponsorship {
  final String? id;
  final String userId;
  final List<String> sponsoredEmails;
  final Map<String, SponsorshipDetail> sponsorshipDetails; // Nouveau
  final int totalEarnings; // Nouveau - total des gains en points
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Sponsorship({
    this.id,
    required this.userId,
    required this.sponsoredEmails,
    Map<String, SponsorshipDetail>? sponsorshipDetails,
    this.totalEarnings = 0,
    this.createdAt,
    this.updatedAt,
  }) : sponsorshipDetails = sponsorshipDetails ?? {};

  factory Sponsorship.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convertir les détails de parrainage
    final Map<String, SponsorshipDetail> details = {};
    if (data['sponsorship_details'] != null) {
      final detailsMap = data['sponsorship_details'] as Map<String, dynamic>;
      detailsMap.forEach((email, detail) {
        if (detail is Map<String, dynamic>) {
          details[email] = SponsorshipDetail.fromMap(detail);
        }
      });
    }

    return Sponsorship(
      id: doc.id,
      userId: data['user_id'] ?? '',
      sponsoredEmails: List<String>.from(data['sponsored_emails'] ?? []),
      sponsorshipDetails: details,
      totalEarnings: data['total_earnings'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    // Convertir les détails en Map
    final Map<String, dynamic> detailsMap = {};
    sponsorshipDetails.forEach((email, detail) {
      detailsMap[email] = detail.toMap();
    });

    return {
      'user_id': userId,
      'sponsored_emails': sponsoredEmails,
      'sponsorship_details': detailsMap,
      'total_earnings': totalEarnings,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Sponsorship copyWith({
    String? id,
    String? userId,
    List<String>? sponsoredEmails,
    Map<String, SponsorshipDetail>? sponsorshipDetails,
    int? totalEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sponsorship(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sponsoredEmails: sponsoredEmails ?? this.sponsoredEmails,
      sponsorshipDetails: sponsorshipDetails ?? this.sponsorshipDetails,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Classe pour stocker les détails de chaque filleul
class SponsorshipDetail {
  final String userId;
  final String userType;
  final bool isActive;
  final int totalEarnings;
  final DateTime? joinDate;
  final bool hasPaid; // Pour les non-particuliers
  final bool hasAcceptedCGU; // Pour les non-particuliers
  final List<EarningHistory> earningsHistory;

  SponsorshipDetail({
    required this.userId,
    required this.userType,
    this.isActive = false,
    this.totalEarnings = 0,
    this.joinDate,
    this.hasPaid = false,
    this.hasAcceptedCGU = false,
    List<EarningHistory>? earningsHistory,
  }) : earningsHistory = earningsHistory ?? [];

  factory SponsorshipDetail.fromMap(Map<String, dynamic> map) {
    final List<EarningHistory> history = [];
    if (map['earnings_history'] != null) {
      final historyList = map['earnings_history'] as List<dynamic>;
      for (var item in historyList) {
        if (item is Map<String, dynamic>) {
          history.add(EarningHistory.fromMap(item));
        }
      }
    }

    return SponsorshipDetail(
      userId: map['user_id'] ?? '',
      userType: map['user_type'] ?? '',
      isActive: map['is_active'] ?? false,
      totalEarnings: map['total_earnings'] ?? 0,
      joinDate: (map['join_date'] as Timestamp?)?.toDate(),
      hasPaid: map['has_paid'] ?? false,
      hasAcceptedCGU: map['has_accepted_cgu'] ?? false,
      earningsHistory: history,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_type': userType,
      'is_active': isActive,
      'total_earnings': totalEarnings,
      'join_date': joinDate != null ? Timestamp.fromDate(joinDate!) : null,
      'has_paid': hasPaid,
      'has_accepted_cgu': hasAcceptedCGU,
      'earnings_history': earningsHistory.map((e) => e.toMap()).toList(),
    };
  }
}

// Classe pour l'historique des gains
class EarningHistory {
  final DateTime date;
  final int points;
  final String reason; // "attribution_40_percent" ou "signup_bonus"
  final String?
      sourceUserId; // Pour les attributions, l'ID de qui a donné les points

  EarningHistory({
    required this.date,
    required this.points,
    required this.reason,
    this.sourceUserId,
  });

  factory EarningHistory.fromMap(Map<String, dynamic> map) {
    return EarningHistory(
      date: (map['date'] as Timestamp).toDate(),
      points: map['points'] ?? 0,
      reason: map['reason'] ?? '',
      sourceUserId: map['source_user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'points': points,
      'reason': reason,
      'source_user_id': sourceUserId,
    };
  }
}
