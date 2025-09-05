import 'package:cloud_firestore/cloud_firestore.dart';

class EnterpriseSubcategoryOption {
  final String id;
  final String subcategoryId; // ID de la sous-catégorie parente
  final String name;
  final int index;
  final bool isActive;

  EnterpriseSubcategoryOption({
    required this.id,
    required this.subcategoryId,
    required this.name,
    required this.index,
    this.isActive = true,
  });

  factory EnterpriseSubcategoryOption.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnterpriseSubcategoryOption(
      id: doc.id,
      subcategoryId: data['subcategory_id'] ?? '',
      name: data['name'] ?? '',
      index: data['index'] ?? 0,
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subcategory_id': subcategoryId,
      'name': name,
      'index': index,
      'is_active': isActive,
    };
  }
}