// 3. Vue mise à jour pour AdminEnterpriseCategoriesScreen
// lib/screens/admin_enterprise_categories_screen/view/admin_enterprise_categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../core/models/enterprise_subcategory_option.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
// import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart'; // Non nécessaire
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
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

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!cc.isLoadingMore.value &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            cc.loadMoreItems();
          }
          return false;
        },
        child: CustomScrollView(
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
          else ...[
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
                    return _buildCategoryItem(context, cc, category, index, list: list);
                  },
                  childCount: list.length,
                ),
              ),
            ),
            // Bouton pour charger plus d'éléments
            SliverToBoxAdapter(
              child: Obx(() {
                final allCategories = cc.categories.where((category) {
                  if (cc.searchText.value.isEmpty) return true;
                  final search = cc.searchText.value.toLowerCase();
                  return category.name.toLowerCase().contains(search) ||
                      category.getFullName(cc.categories).toLowerCase().contains(search);
                }).toList();
                
                final hasMore = allCategories.length > cc.itemsToShow.value;
                
                if (!hasMore) {
                  return SizedBox.shrink();
                }
                
                return Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: cc.isLoadingMore.value
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: cc.loadMoreItems,
                            icon: Icon(Icons.expand_more),
                            label: Text('Charger plus (${allCategories.length - list.length} restants)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                  ),
                );
              }),
            ),
          ],
        ],
        ),
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
      int index, {List<EnterpriseCategory>? list}) {
    final isSubcategory = category.isSubCategory;

    return Container(
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
              // Boutons de réorganisation
              IconButton(
                icon: Icon(Icons.arrow_upward, color: Colors.grey),
                onPressed: index > 0
                    ? () => cc.moveCategory(category, -1)
                    : null,
                tooltip: 'Déplacer vers le haut',
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, color: Colors.grey),
                onPressed: list != null && index < list.length - 1
                    ? () => cc.moveCategory(category, 1)
                    : null,
                tooltip: 'Déplacer vers le bas',
              ),
              if (category.isMainCategory)
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: () =>
                      _showCreateEditDialog(context, cc, null, category.id),
                  tooltip: 'Ajouter une sous-catégorie',
                ),
              if (category.isSubCategory)
                IconButton(
                  icon: Icon(Icons.list_alt, color: Colors.purple),
                  onPressed: () =>
                      _showManageOptionsDialog(context, cc, category),
                  tooltip: 'Gérer les options',
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
                            isExpanded: true,
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
                                child: Text(
                                  'Aucune (catégorie principale)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...cc.mainCategories
                                  .map((cat) => DropdownMenuItem<String?>(
                                        value: cat.id,
                                        child: Text(
                                          cat.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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

  // Nouvelle méthode pour gérer les options des sous-catégories
  void _showManageOptionsDialog(BuildContext context,
      AdminEnterpriseCategoriesScreenController cc, EnterpriseCategory subcategory) {
    
    final TextEditingController optionController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            constraints: BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[600]!, Colors.purple[700]!],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gérer les options',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              subcategory.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Champ pour ajouter une nouvelle option
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionController,
                                decoration: InputDecoration(
                                  labelText: 'Nouvelle option',
                                  hintText: 'Ex: Piscine coque, Piscine projetée...',
                                  prefixIcon: Icon(Icons.add_box),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    cc.addSubcategoryOption(subcategory.id, value);
                                    optionController.clear();
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (optionController.text.isNotEmpty) {
                                  cc.addSubcategoryOption(subcategory.id, optionController.text);
                                  optionController.clear();
                                }
                              },
                              icon: Icon(Icons.add),
                              label: Text('Ajouter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[600],
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Liste des options existantes
                        Expanded(
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: cc.getSubcategoryOptions(subcategory.id),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(child: CircularProgressIndicator());
                              }
                              
                              final options = snapshot.data!;
                              
                              if (options.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                                      SizedBox(height: 12),
                                      Text(
                                        'Aucune option pour le moment',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ajoutez des options pour permettre\nla sélection multiple',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options[index];
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.purple[100],
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: Colors.purple[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(option['name'] as String),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Boutons de réorganisation
                                          IconButton(
                                            icon: Icon(Icons.arrow_upward, size: 20),
                                            onPressed: index > 0
                                                ? () => cc.moveSubcategoryOption(subcategory.id, option['id'] as String, -1)
                                                : null,
                                            tooltip: 'Monter',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.arrow_downward, size: 20),
                                            onPressed: index < options.length - 1
                                                ? () => cc.moveSubcategoryOption(subcategory.id, option['id'] as String, 1)
                                                : null,
                                            tooltip: 'Descendre',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _confirmDeleteOption(context, cc, subcategory.id, option),
                                            tooltip: 'Supprimer',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Info
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Les entreprises pourront sélectionner plusieurs options pour cette sous-catégorie',
                                  style: TextStyle(fontSize: 13, color: Colors.blue[900]),
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
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Fermer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        );
      },
    );
  }
  
  void _confirmDeleteOption(BuildContext context,
      AdminEnterpriseCategoriesScreenController cc,
      String subcategoryId,
      Map<String, dynamic> option) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer l\'option'),
          content: Text('Êtes-vous sûr de vouloir supprimer l\'option "${option['name']}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                cc.deleteSubcategoryOption(subcategoryId, option['id'] as String);
                Navigator.of(context).pop();
              },
              child: Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}
