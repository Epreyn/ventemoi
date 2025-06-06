import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String userId;
  final String
      type; // gift_received, purchase_confirmation, points_received, etc.
  final String title;
  final String message;
  final String? senderId;
  final String? purchaseId;
  final String? imageUrl;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic>? metadata;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.senderId,
    this.purchaseId,
    this.imageUrl,
    required this.createdAt,
    required this.read,
    this.metadata,
  });

  factory Notification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notification(
      id: doc.id,
      userId: data['user_id'] ?? '',
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      senderId: data['sender_id'],
      purchaseId: data['purchase_id'],
      imageUrl: data['image_url'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'sender_id': senderId,
      'purchase_id': purchaseId,
      'image_url': imageUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'read': read,
      'metadata': metadata,
    };
  }
}
