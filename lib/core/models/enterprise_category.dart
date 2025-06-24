import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'nameable.dart';

class EnterpriseCategory implements Nameable {
  @override
  final String id;
  final int index;
  @override
  final String name;
  final String?
      parentId; // ID de la catégorie parente (null si c'est une catégorie principale)
  final int level; // 0 pour catégorie principale, 1 pour sous-catégorie, etc.

  EnterpriseCategory({
    required this.id,
    required this.index,
    required this.name,
    this.parentId,
    this.level = 0,
  });

  factory EnterpriseCategory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnterpriseCategory(
      id: doc.id,
      index: data['index'] ?? 0,
      name: data['name'] ?? '',
      parentId: data['parent_id'],
      level: data['level'] ?? 0,
    );
  }

  // Méthode pour convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'name': name,
      'parent_id': parentId,
      'level': level,
    };
  }

  // Méthode pour obtenir le nom complet avec hiérarchie
  String getFullName(List<EnterpriseCategory> allCategories) {
    if (parentId == null) return name;

    final parent = allCategories.firstWhereOrNull((c) => c.id == parentId);
    if (parent == null) return name;

    return '${parent.getFullName(allCategories)} > $name';
  }

  // Vérifier si c'est une catégorie principale
  bool get isMainCategory => parentId == null;

  // Vérifier si c'est une sous-catégorie
  bool get isSubCategory => parentId != null;
}
