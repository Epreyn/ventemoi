import 'package:cloud_firestore/cloud_firestore.dart';

import 'nameable.dart';

class EstablishmentCategory implements Nameable {
  @override
  final String id;
  final int index;
  @override
  final String name;

  EstablishmentCategory({
    required this.id,
    required this.index,
    required this.name,
  });

  factory EstablishmentCategory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EstablishmentCategory(
      id: doc.id,
      index: data['index'] ?? 0,
      name: data['name'] ?? '',
    );
  }
}
