import 'package:cloud_firestore/cloud_firestore.dart';

class Sponsorship {
  final String id;
  final String userId;
  final List<String> sponsoredEmails;

  Sponsorship({
    required this.id,
    required this.userId,
    required this.sponsoredEmails,
  });

  factory Sponsorship.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sponsorship(
      id: doc.id,
      userId: data['user_id'] ?? '',
      sponsoredEmails: List<String>.from(data['sponsored_emails'] ?? []),
    );
  }
}
