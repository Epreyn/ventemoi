// 3. Vue mise à jour pour AdminEnterpriseCategoriesScreen
// lib/screens/admin_enterprise_categories_screen/view/admin_enterprise_categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_enterprise_categories_screen_controller.dart';

class AdminEnterpriseCategoriesScreen extends StatelessWidget {
  const AdminEnterpriseCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminEnterpriseCategoriesScreenController(),
        tag: 'admin-enterprise-categories-screen');
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
      ),
      fabOnPressed: () => _showCreateEditDialog(context, cc, null, null),
      fabIcon: const Icon(Icons.add, size: 20),
      fabText: const Text('Nouvelle Catégorie'),
      body: _buildBody(context, cc, isDesktop, isTablet),
    );
  }

  Widget _buildBody(
      BuildContext context,
      AdminEnterpriseCategoriesScreenController cc,
      bool isDesktop,
      bool isTablet) {
    return Obx(() {
      final list = cc.filteredCategories;

      return CustomScrollView(
        slivers: [
          // Header avec stats et recherche
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildMinimalStats(cc),
                _buildSearchBar(cc),
              ],
            ),
          ),

          // Contenu principal
          if (list.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(cc),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(isDesktop
                  ? 24
                  : isTablet
                      ? 16
                      : 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = list[index];
                    return _buildCategoryItem(context, cc, category, index);
                  },
                  childCount: list.length,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildMinimalStats(AdminEnterpriseCategoriesScreenController cc) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Obx(() {
        final total = cc.categories.length;
        final mainCount = cc.mainCategories.length;
        final subCount = total - mainCount;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatChip('Total', total.toString(), Colors.blue),
            SizedBox(width: 16),
            _buildStatChip('Principales', mainCount.toString(), Colors.orange),
            SizedBox(width: 16),
            _buildStatChip(
                'Sous-catégories', subCount.toString(), Colors.green),
          ],
        );
      }),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AdminEnterpriseCategoriesScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: cc.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher une catégorie...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          SizedBox(width: 16),
          Obx(() => DropdownButton<String>(
                value: cc.sortBy.value,
                items: [
                  DropdownMenuItem(
                    value: 'hierarchy',
                    child: Text('Hiérarchie'),
                  ),
                  DropdownMenuItem(
                    value: 'index',
                    child: Text('Ordre'),
                  ),
                  DropdownMenuItem(
                    value: 'name',
                    child: Text('Nom'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) cc.sortBy.value = value;
                },
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
      BuildContext context,
      AdminEnterpriseCategoriesScreenController cc,
      EnterpriseCategory category,
      int index) {
    final isSubcategory = category.isSubCategory;

    return CustomCardAnimation(
      index: index,
      child: Container(
        margin: EdgeInsets.only(
          left: isSubcategory ? 32 : 0,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSubcategory
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSubcategory ? Icons.subdirectory_arrow_right : Icons.category,
              color: isSubcategory ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          title: Text(
            category.name,
            style: TextStyle(
              fontWeight: isSubcategory ? FontWeight.normal : FontWeight.bold,
              fontSize: isSubcategory ? 14 : 16,
            ),
          ),
          subtitle: category.parentId != null
              ? Text(
                  'Sous-catégorie de: ${cc.categories.firstWhereOrNull((c) => c.id == category.parentId)?.name ?? ""}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category.isMainCategory)
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: () =>
                      _showCreateEditDialog(context, cc, null, category.id),
                  tooltip: 'Ajouter une sous-catégorie',
                ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () =>
                    _showCreateEditDialog(context, cc, category, null),
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => cc.openDeleteAlertDialog(category),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AdminEnterpriseCategoriesScreenController cc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'Aucune catégorie trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            cc.searchText.value.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés'
                : 'Commencez par créer une catégorie',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEditDialog(
      BuildContext context,
      AdminEnterpriseCategoriesScreenController cc,
      EnterpriseCategory? category,
      String? parentId) {
    cc.isEditMode.value = category != null;
    cc.tempCategory = category;
    cc.selectedParentId.value = parentId ?? category?.parentId;
    cc.variablesToResetToBottomSheet();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      category != null ? Icons.edit : Icons.add_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      category != null
                          ? 'Modifier la catégorie'
                          : parentId != null
                              ? 'Nouvelle sous-catégorie'
                              : 'Nouvelle catégorie',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Contenu
              Padding(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: cc.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Champ nom
                      TextFormField(
                        controller: cc.nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nom de la catégorie',
                          hintText: 'Ex: Plomberie, Électricité...',
                          prefixIcon: Icon(Icons.label_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Dropdown pour la catégorie parente
                      Obx(() => DropdownButtonFormField<String?>(
                            value: cc.selectedParentId.value,
                            decoration: InputDecoration(
                              labelText: 'Catégorie parente (optionnel)',
                              prefixIcon: Icon(Icons.account_tree_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Aucune (catégorie principale)'),
                              ),
                              ...cc.mainCategories
                                  .map((cat) => DropdownMenuItem<String?>(
                                        value: cat.id,
                                        child: Text(cat.name),
                                      )),
                            ],
                            onChanged: (value) {
                              cc.selectedParentId.value = value;
                            },
                            validator: (val) {
                              // Vérifier qu'on ne sélectionne pas la catégorie elle-même comme parent
                              if (category != null && val == category.id) {
                                return 'Une catégorie ne peut pas être son propre parent';
                              }
                              return null;
                            },
                          )),

                      if (category != null &&
                          cc.getSubcategories(category.id).isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 16),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cette catégorie contient des sous-catégories',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.orange[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
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
                      child: Text('Annuler'),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: cc.actionBottomSheet,
                      child: Text(category != null ? 'Modifier' : 'Créer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
}
