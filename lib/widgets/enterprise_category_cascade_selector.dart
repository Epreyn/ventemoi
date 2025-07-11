// lib/widgets/enterprise_category_cascading_selector.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/models/enterprise_category.dart';

class EnterpriseCategoryCascadingSelector extends StatelessWidget {
  final List<EnterpriseCategory> categories;
  final RxList<String> selectedIds;
  final Function(String) onToggle;
  final Function(String) onRemove;
  final int maxSelections;
  final String? labelText;

  const EnterpriseCategoryCascadingSelector({
    Key? key,
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    required this.onRemove,
    this.maxSelections = 5,
    this.labelText,
  }) : super(key: key);

  List<EnterpriseCategory> get mainCategories {
    return categories.where((c) => c.isMainCategory).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  List<EnterpriseCategory> getSubcategories(String parentId) {
    return categories.where((c) => c.parentId == parentId).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              labelText!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),

        // Afficher les sélections actuelles
        Obx(() {
          if (selectedIds.isEmpty) {
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  'Aucun métier sélectionné',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          }

          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildSelectedCategories(),
            ),
          );
        }),

        SizedBox(height: 12),

        // Bouton pour ouvrir le sélecteur
        Obx(() => ElevatedButton.icon(
              onPressed: selectedIds.length >= maxSelections
                  ? null
                  : () => _showCategorySelector(context),
              icon: Icon(Icons.add_business,
                  color: selectedIds.length >= maxSelections
                      ? Colors.grey
                      : Colors.white),
              label: Text(
                selectedIds.length >= maxSelections
                    ? 'Maximum atteint ($maxSelections)'
                    : 'Ajouter un métier',
                style: TextStyle(
                  color: selectedIds.length >= maxSelections
                      ? Colors.grey
                      : Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )),

        if (maxSelections > 1)
          Obx(() => Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '${selectedIds.length} / $maxSelections sélectionnés',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              )),
      ],
    );
  }

  List<Widget> _buildSelectedCategories() {
    final Map<String?, List<EnterpriseCategory>> grouped = {};

    for (final id in selectedIds) {
      final cat = categories.firstWhereOrNull((c) => c.id == id);
      if (cat == null) continue;

      final parentId = cat.isMainCategory ? cat.id : cat.parentId;
      grouped.putIfAbsent(parentId, () => []).add(cat);
    }

    return grouped.entries.map((entry) {
      final mainCat = categories.firstWhereOrNull((c) => c.id == entry.key);

      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.category, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mainCat?.name ?? 'Catégorie',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (entry.value.length == 1 &&
                            entry.value.first.isMainCategory)
                          InkWell(
                            onTap: () => onRemove(entry.value.first.id),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    ...entry.value
                        .where((c) => c.isSubCategory)
                        .map((subcat) => Padding(
                              padding: EdgeInsets.only(left: 16, top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.subdirectory_arrow_right,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      subcat.name,
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => onRemove(subcat.id),
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.close,
                                          size: 16, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showCategorySelector(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.business_center, color: Colors.orange),
                  SizedBox(width: 12),
                  Text(
                    'Sélectionner vos métiers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Fermer'),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: mainCategories.length,
                itemBuilder: (context, index) {
                  final mainCat = mainCategories[index];
                  return _buildMainCategoryTile(mainCat);
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildMainCategoryTile(EnterpriseCategory mainCategory) {
    final subcategories = getSubcategories(mainCategory.id);

    return Obx(() {
      final hasSelection = selectedIds.contains(mainCategory.id) ||
          subcategories.any((sub) => selectedIds.contains(sub.id));

      return ExpansionTile(
        initiallyExpanded: hasSelection,
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasSelection
                ? Colors.orange.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.category,
            color: hasSelection ? Colors.orange : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          mainCategory.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: hasSelection ? Colors.orange[800] : null,
          ),
        ),
        subtitle: subcategories.isNotEmpty
            ? Text('${subcategories.length} sous-catégories')
            : null,
        trailing: subcategories.isEmpty
            ? Obx(() => Checkbox(
                  value: selectedIds.contains(mainCategory.id),
                  activeColor: Colors.orange,
                  onChanged: (_) => onToggle(mainCategory.id),
                ))
            : null,
        children: subcategories.map((subcat) {
          return Obx(() => ListTile(
                contentPadding: EdgeInsets.only(left: 56, right: 16),
                leading: Icon(Icons.subdirectory_arrow_right, size: 20),
                title: Text(subcat.name, style: TextStyle(fontSize: 14)),
                trailing: Checkbox(
                  value: selectedIds.contains(subcat.id),
                  activeColor: Colors.orange,
                  onChanged: (_) => onToggle(subcat.id),
                ),
                onTap: () => onToggle(subcat.id),
              ));
        }).toList(),
      );
    });
  }
}
