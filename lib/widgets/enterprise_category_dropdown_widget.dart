// 4. Widget de sélection des catégories avec hiérarchie
// lib/widgets/enterprise_category_dropdown_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/models/enterprise_category.dart';

class EnterpriseCategoryDropdownWidget extends StatelessWidget {
  final String? value;
  final List<EnterpriseCategory> categories;
  final Function(String?)? onChanged; // Pour sélection simple
  final Function(List<String>)? onMultipleChanged; // Pour sélection multiple
  final String? labelText;
  final bool allowMultipleSelection;
  final List<String>? selectedIds; // Pour la sélection multiple

  const EnterpriseCategoryDropdownWidget({
    Key? key,
    this.value,
    required this.categories,
    this.onChanged,
    this.onMultipleChanged,
    this.labelText,
    this.allowMultipleSelection = false,
    this.selectedIds,
  })  : assert(
          (allowMultipleSelection && onMultipleChanged != null) ||
              (!allowMultipleSelection && onChanged != null),
          'Vous devez fournir onChanged pour la sélection simple ou onMultipleChanged pour la sélection multiple',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (allowMultipleSelection) {
      return _buildMultiSelectDropdown(context);
    } else {
      return _buildSingleSelectDropdown(context);
    }
  }

  Widget _buildSingleSelectDropdown(BuildContext context) {
    // Organiser les catégories de manière hiérarchique
    final items = _buildHierarchicalItems();

    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText ?? 'Catégorie entreprise',
        prefixIcon: Icon(Icons.business_center_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('-- Sélectionner --'),
        ),
        ...items,
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelectDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText ?? 'Catégories entreprise',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Afficher les catégories sélectionnées
              if (selectedIds != null && selectedIds!.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedIds!.map((id) {
                      final cat =
                          categories.firstWhereOrNull((c) => c.id == id);
                      if (cat == null) return SizedBox.shrink();
                      return Chip(
                        label: Text(
                          cat.getFullName(categories),
                          style: TextStyle(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          final newList = List<String>.from(selectedIds!)
                            ..remove(id);
                          onMultipleChanged?.call(newList);
                        },
                      );
                    }).toList(),
                  ),
                ),
              // Bouton pour ouvrir le sélecteur
              ListTile(
                leading: Icon(Icons.add_circle_outline),
                title: Text('Ajouter une catégorie'),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: () => _showCategorySelector(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildHierarchicalItems() {
    final List<DropdownMenuItem<String>> items = [];

    // Obtenir les catégories principales triées
    final mainCategories = categories.where((c) => c.isMainCategory).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    for (final mainCat in mainCategories) {
      // Ajouter la catégorie principale
      items.add(DropdownMenuItem<String>(
        value: mainCat.id,
        child: Text(
          mainCat.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ));

      // Ajouter ses sous-catégories
      final subcategories = categories
          .where((c) => c.parentId == mainCat.id)
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));

      for (final subcat in subcategories) {
        items.add(DropdownMenuItem<String>(
          value: subcat.id,
          child: Padding(
            padding: EdgeInsets.only(left: 24),
            child: Row(
              children: [
                Icon(Icons.subdirectory_arrow_right,
                    size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(subcat.name),
              ],
            ),
          ),
        ));
      }
    }

    return items;
  }

  void _showCategorySelector(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 500,
          height: 600,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Sélectionner les catégories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              // Liste des catégories
              Expanded(
                child: _buildCategoryTree(),
              ),
              // Actions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Fermer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTree() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: _buildTreeItems(),
    );
  }

  List<Widget> _buildTreeItems() {
    final List<Widget> items = [];
    final currentSelectedIds = selectedIds ?? [];

    // Obtenir les catégories principales
    final mainCategories = categories.where((c) => c.isMainCategory).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    for (final mainCat in mainCategories) {
      // Catégorie principale
      items.add(_buildCategoryTile(mainCat, currentSelectedIds, 0));

      // Sous-catégories
      final subcategories = categories
          .where((c) => c.parentId == mainCat.id)
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));

      for (final subcat in subcategories) {
        items.add(_buildCategoryTile(subcat, currentSelectedIds, 1));
      }
    }

    return items;
  }

  Widget _buildCategoryTile(
    EnterpriseCategory category,
    List<String> currentSelectedIds,
    int level,
  ) {
    final isSelected = currentSelectedIds.contains(category.id);

    return Container(
      margin: EdgeInsets.only(
        left: level * 24.0,
        bottom: 4,
      ),
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected ? Colors.orange[50] : null,
        child: ListTile(
          leading: Icon(
            level == 0 ? Icons.category : Icons.subdirectory_arrow_right,
            color: isSelected ? Colors.orange : Colors.grey,
          ),
          title: Text(
            category.name,
            style: TextStyle(
              fontWeight: level == 0 ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.orange[800] : null,
            ),
          ),
          trailing: Checkbox(
            value: isSelected,
            activeColor: Colors.orange,
            onChanged: (bool? value) {
              List<String> newList = List<String>.from(currentSelectedIds);
              if (value == true) {
                newList.add(category.id);
              } else {
                newList.remove(category.id);
              }
              onMultipleChanged?.call(newList);
              Get.back();
              _showCategorySelector(
                  Get.context!); // Réouvrir pour voir les changements
            },
          ),
          onTap: () {
            List<String> newList = List<String>.from(currentSelectedIds);
            if (isSelected) {
              newList.remove(category.id);
            } else {
              newList.add(category.id);
            }
            onMultipleChanged?.call(newList);
            Get.back();
            _showCategorySelector(Get.context!);
          },
        ),
      ),
    );
  }
}

// 5. Utilisation dans ProEstablishmentProfileScreen
// Exemple d'utilisation dans le formulaire de profil établissement

// Exemple pour sélection SIMPLE
class SingleSelectionExample extends StatelessWidget {
  final List<EnterpriseCategory> enterpriseCategories;
  final String? selectedCategoryId;
  final Function(String?) onCategoryChanged;

  const SingleSelectionExample({
    Key? key,
    required this.enterpriseCategories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EnterpriseCategoryDropdownWidget(
      categories: enterpriseCategories,
      value: selectedCategoryId,
      onChanged: onCategoryChanged,
      labelText: 'Catégorie principale',
      allowMultipleSelection: false,
    );
  }
}

// Exemple pour sélection MULTIPLE
class MultipleSelectionExample extends StatelessWidget {
  final List<EnterpriseCategory> enterpriseCategories;
  final List<String> selectedCategoryIds;
  final Function(List<String>) onCategoriesChanged;

  const MultipleSelectionExample({
    Key? key,
    required this.enterpriseCategories,
    required this.selectedCategoryIds,
    required this.onCategoriesChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Autres champs du formulaire...

        // Widget de sélection des catégories entreprise
        EnterpriseCategoryDropdownWidget(
          categories: enterpriseCategories,
          selectedIds: selectedCategoryIds,
          onMultipleChanged: onCategoriesChanged,
          labelText: 'Métiers / Services',
          allowMultipleSelection: true,
        ),

        SizedBox(height: 16),

        // Affichage hiérarchique des catégories sélectionnées
        if (selectedCategoryIds.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catégories sélectionnées :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 8),
                ...selectedCategoryIds.map((id) {
                  final cat =
                      enterpriseCategories.firstWhereOrNull((c) => c.id == id);
                  if (cat == null) return SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(left: cat.level * 16.0, top: 4),
                    child: Row(
                      children: [
                        Icon(
                          cat.isSubCategory
                              ? Icons.subdirectory_arrow_right
                              : Icons.category,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        SizedBox(width: 8),
                        Text(cat.getFullName(enterpriseCategories)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }
}
