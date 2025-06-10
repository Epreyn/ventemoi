import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventemoi/core/models/nameable.dart';

class UserType implements Nameable {
  @override
  final String id;
  @override
  final String name;
  final String description;
  final int index;

  UserType({
    required this.id,
    required this.name,
    required this.description,
    required this.index,
  });

  factory UserType.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserType(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      index: data['index'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'index': index,
    };
  }
}
