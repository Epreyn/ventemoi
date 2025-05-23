import 'package:cloud_firestore/cloud_firestore.dart';

import 'nameable.dart';

class User implements Nameable {
  @override
  final String id;
  @override
  final String name;
  final String email;
  final String userTypeID;
  final String imageUrl;
  final bool isEnable;
  final bool isVisible;

  /// Adresse complète
  final String personalAddress;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.userTypeID,
    required this.imageUrl,
    required this.isEnable,
    required this.isVisible,
    this.personalAddress = '',
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      userTypeID: data['user_type_id'] ?? '',
      imageUrl: data['image_url'] ?? '',
      isEnable: data['isEnable'] ?? true,
      isVisible: data['isVisible'] ?? true,
      personalAddress: data['personal_address'] ?? '',
    );
  }
}
