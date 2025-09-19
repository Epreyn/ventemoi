import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishment_category.dart';
import '../../../core/widgets/modern_page_header.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_categories_screen_controller.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminCategoriesScreenController(),
        tag: 'admin-categories-screen');
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
      fabOnPressed: () => _showCreateEditDialog(context, cc, null),
      fabIcon: const Icon(Icons.add, size: 20),
      fabText: const Text('Nouvelle Catégorie'),
      body: _buildBody(context, cc, isDesktop, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, AdminCategoriesScreenController cc,
      bool isDesktop, bool isTablet) {
    return Obx(() {
      final list = cc.filteredCategories;

      return CustomScrollView(
        slivers: [
          // Header moderne
          SliverToBoxAdapter(
            child: ModernPageHeader(
              title: "Gestion Catégories",
              subtitle: "Organisez les catégories",
              icon: Icons.category,
            ),
          ),
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
            // Vue unifiée : liste réorganisable pour tous les écrans
            SliverPadding(
              padding: EdgeInsets.all(isDesktop
                  ? 24
                  : isTablet
                      ? 24
                      : 16),
              sliver: SliverReorderableList(
                itemBuilder: (context, index) {
                  final category = list[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(category.id),
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _buildListCategoryCard(
                          context, category, cc, isTablet || isDesktop),
                    ),
                  );
                },
                itemCount: list.length,
                onReorder: cc.onReorder,
              ),
            ),
        ],
      );
    });
  }

  Widget _buildMinimalStats(AdminCategoriesScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Obx(() {
        final totalCategories = cc.categories.length;
        final maxOrder = cc.categories.isEmpty
            ? 0
            : cc.categories.map((c) => c.index).reduce((a, b) => a > b ? a : b);

        return Row(
          children: [
            _buildStatChip(
              label: 'Total',
              value: totalCategories,
              color: Colors.grey[800]!,
              icon: Icons.category,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Ordre max',
              value: maxOrder,
              color: Colors.blue[600]!,
              icon: Icons.format_list_numbered,
            ),
            Spacer(),
            // Indicateur de recherche
            if (cc.searchText.value.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt, size: 16, color: Colors.blue[700]),
                    SizedBox(width: 6),
                    Text(
                      '${cc.filteredCategories.length} résultats',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(AdminCategoriesScreenController cc) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          // Champ de recherche
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: cc.onSearchChanged,
                style: TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Rechercher une catégorie...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  suffixIcon: cc.searchText.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18),
                          onPressed: () {
                            cc.searchText.value = '';
                            cc.onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Menu de tri
          _buildSortMenu(cc),
        ],
      ),
    );
  }

  Widget _buildSortMenu(AdminCategoriesScreenController cc) {
    final sortOptions = [
      {'label': 'Ordre', 'value': 'index'},
      {'label': 'Nom', 'value': 'name'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        offset: Offset(0, 40),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort,
                size: 16,
                color: Colors.grey[700],
              ),
              SizedBox(width: 6),
              Text(
                'Trier',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => sortOptions.map((option) {
          return PopupMenuItem<String>(
            value: option['value'] as String,
            child: Row(
              children: [
                Icon(
                  _getSortIcon(option['value'] as String),
                  size: 16,
                ),
                SizedBox(width: 12),
                Text(option['label'] as String),
              ],
            ),
          );
        }).toList(),
        onSelected: (value) {
          cc.sortBy.value = value;
        },
      ),
    );
  }

  IconData _getSortIcon(String sortBy) {
    switch (sortBy) {
      case 'index':
        return Icons.format_list_numbered;
      case 'name':
        return Icons.sort_by_alpha;
      default:
        return Icons.sort;
    }
  }

  // Vue liste pour mobile/tablette
  Widget _buildListCategoryCard(
      BuildContext context,
      EstablishmentCategory category,
      AdminCategoriesScreenController cc,
      bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCategoryDetails(context, category, cc),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Handle de réorganisation
                Icon(
                  Icons.drag_indicator,
                  color: Colors.grey[400],
                  size: 24,
                ),
                SizedBox(width: 12),

                // Index
                Container(
                  width: isTablet ? 48 : 40,
                  height: isTablet ? 48 : 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${category.index}',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Catégorie d\'établissement',
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      color: Colors.blue[600],
                      onPressed: () =>
                          _showCreateEditDialog(context, cc, category),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20),
                      color: Colors.red[600],
                      onPressed: () => cc.openDeleteAlertDialog(category),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AdminCategoriesScreenController cc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_outlined,
              size: 60,
              color: Colors.blue[300],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Aucune catégorie',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Créez votre première catégorie',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateEditDialog(Get.context!, cc, null),
            icon: Icon(Icons.add),
            label: Text('Créer une catégorie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(BuildContext context,
      EstablishmentCategory category, AdminCategoriesScreenController cc) {
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
              // Header avec gradient
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[400]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${category.index}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Catégorie d\'établissement',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenu
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      title: 'Informations',
                      child: Column(
                        children: [
                          _buildInfoRow('Position', '${category.index}'),
                          SizedBox(height: 12),
                          _buildInfoRow('ID', category.id),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.back();
                            cc.openDeleteAlertDialog(category);
                          },
                          child: Text('Supprimer'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[600],
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            _showCreateEditDialog(context, cc, category);
                          },
                          icon: Icon(Icons.edit, size: 18),
                          label: Text('Modifier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailSection({
    required String title,
    String? content,
    Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: child ??
              Text(
                content!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateEditDialog(BuildContext context,
      AdminCategoriesScreenController cc, EstablishmentCategory? category) {
    cc.isEditMode.value = category != null;
    cc.tempCategory = category;
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
                  color: Colors.blue[600],
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
                          : 'Nouvelle catégorie',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Formulaire
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
                          hintText: 'Ex: Restaurant, Bar, Boutique...',
                          prefixIcon: Icon(Icons.label_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue[600]!,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Annuler'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => cc.actionBottomSheet(),
                            icon: Icon(
                              category != null ? Icons.save : Icons.check,
                              size: 18,
                            ),
                            label: Text(
                              category != null ? 'Enregistrer' : 'Créer',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
