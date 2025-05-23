import 'package:cloud_firestore/cloud_firestore.dart';

import 'nameable.dart';

class EnterpriseCategory implements Nameable {
  @override
  final String id;
  final int index;
  @override
  final String name;

  EnterpriseCategory({
    required this.id,
    required this.index,
    required this.name,
  });

  factory EnterpriseCategory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnterpriseCategory(
      id: doc.id,
      index: data['index'] ?? 0,
      name: data['name'] ?? '',
    );
  }
}
