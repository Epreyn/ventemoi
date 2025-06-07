import 'package:cloud_firestore/cloud_firestore.dart';

class Sponsorship {
  final String? id;
  final String userId;
  final List<String> sponsoredEmails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Sponsorship({
    this.id,
    required this.userId,
    required this.sponsoredEmails,
    this.createdAt,
    this.updatedAt,
  });

  factory Sponsorship.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Sponsorship(
      id: doc.id,
      userId: data['user_id'] ?? '',
      sponsoredEmails: List<String>.from(data['sponsored_emails'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'sponsored_emails': sponsoredEmails,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sponsorship(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sponsoredEmails: sponsoredEmails ?? this.sponsoredEmails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
