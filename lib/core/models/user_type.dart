import 'package:cloud_firestore/cloud_firestore.dart';

import 'nameable.dart';

class UserType implements Nameable {
  @override
  final String name;
  @override
  final String id;
  final int index;
  final String description;

  UserType({
    required this.id,
    required this.name,
    required this.index,
    required this.description,
  });

  factory UserType.fromDocument(DocumentSnapshot doc) {
    return UserType(
      id: doc.id,
      name: doc['name'],
      index: doc['index'],
      description: doc['description'],
    );
  }

  UserType copyWith({
    String? id,
    String? name,
    int? index,
    String? description,
  }) {
    return UserType(
      id: id ?? this.id,
      name: name ?? this.name,
      index: this.index,
      description: this.description,
    );
  }

  @override
  String toString() {
    return 'UserType(id: $id, name: $name, index: $index, description: $description)';
  }
}
