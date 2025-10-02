import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enterprise_category.dart';
import '../models/enterprise_subcategory_option.dart';
import '../classes/unique_controllers.dart';

class CategoryDisplayHelper {
  static Future<String> getFormattedCategoryWithOptions(
    String categoryId,
    List<String>? optionIds,
  ) async {
    try {
      // Récupérer la catégorie
      final categoryDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('enterprise_categories')
          .doc(categoryId)
          .get();
      
      if (!categoryDoc.exists) return '';
      
      final category = EnterpriseCategory.fromDocument(categoryDoc);
      String displayName = category.name;
      
      // Si c'est une sous-catégorie avec des options
      if (category.level > 0 && optionIds != null && optionIds.isNotEmpty) {
        // Récupérer les options
        final optionsSnapshot = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('enterprise_subcategory_options')
            .where('subcategory_id', isEqualTo: categoryId)
            .where(FieldPath.documentId, whereIn: optionIds)
            .get();
        
        final options = optionsSnapshot.docs
            .map((doc) => EnterpriseSubcategoryOption.fromDocument(doc))
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        
        if (options.isNotEmpty) {
          final optionNames = options.map((o) => o.name).join(', ');
          displayName = '$displayName ($optionNames)';
        }
      }
      
      return displayName;
    } catch (e) {
      return '';
    }
  }
  
  static Future<List<String>> getFormattedCategoriesWithOptions(
    List<String> categoryIds,
    Map<String, List<String>>? subcategoryOptions,
  ) async {
    final formattedCategories = <String>[];
    
    for (final categoryId in categoryIds) {
      final options = subcategoryOptions?[categoryId];
      final formatted = await getFormattedCategoryWithOptions(categoryId, options);
      if (formatted.isNotEmpty) {
        formattedCategories.add(formatted);
      }
    }
    
    return formattedCategories;
  }
}