import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_space/view/custom_space.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/user_type.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_app_bar/widgets/custom_app_bar_actions.dart';
import '../../../features/custom_bottom_app_bar/view/custom_bottom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_profile_leading/view/custom_profile_leading.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_user_types_screen_controller.dart';

class AdminUserTypesScreen extends StatelessWidget {
  const AdminUserTypesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminUserTypesScreenController(),
        tag: 'admin-user-types-screen');
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
      fabText: const Text('Nouveau Type'),
      body: _buildBody(context, cc, isDesktop, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, AdminUserTypesScreenController cc,
      bool isDesktop, bool isTablet) {
    return Obx(() {
      final list = cc.filteredUserTypes;

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
            // Vue unifiée : liste réorganisable pour tous les écrans
            SliverPadding(
              padding: EdgeInsets.all(isDesktop
                  ? 24
                  : isTablet
                      ? 24
                      : 16),
              sliver: SliverReorderableList(
                itemBuilder: (context, index) {
                  final userType = list[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(userType.id),
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _buildListUserTypeCard(
                          context, userType, cc, isTablet || isDesktop),
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

  Widget _buildMinimalStats(AdminUserTypesScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Obx(() {
        final totalTypes = cc.userTypes.length;
        final activeTypes = cc.userTypes.where((u) => u.index > 0).length;

        return Row(
          children: [
            _buildStatChip(
              label: 'Total',
              value: totalTypes,
              color: Colors.grey[800]!,
              icon: Icons.category,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Actifs',
              value: activeTypes,
              color: Colors.green[600]!,
              icon: Icons.check_circle,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Ordre max',
              value: cc.userTypes.isEmpty
                  ? 0
                  : cc.userTypes
                      .map((u) => u.index)
                      .reduce((a, b) => a > b ? a : b),
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
                      '${cc.filteredUserTypes.length} résultats',
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

  Widget _buildSearchBar(AdminUserTypesScreenController cc) {
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
                  hintText: 'Rechercher par nom ou description...',
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

  Widget _buildSortMenu(AdminUserTypesScreenController cc) {
    final sortOptions = [
      {'label': 'Ordre', 'value': 'index'},
      {'label': 'Nom', 'value': 'name'},
      {'label': 'Description', 'value': 'description'},
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
      case 'description':
        return Icons.description;
      default:
        return Icons.sort;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  // Vue liste pour mobile/tablette
  Widget _buildListUserTypeCard(BuildContext context, UserType userType,
      AdminUserTypesScreenController cc, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple[200]!,
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
          onTap: () => _showUserTypeDetails(context, userType, cc),
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
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${userType.index}',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple[700],
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
                        userType.name,
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      if (userType.description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          userType.description,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
                          _showCreateEditDialog(context, cc, userType),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20),
                      color: Colors.red[600],
                      onPressed: () => cc.openDeleteAlertDialog(userType),
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

  Widget _buildEmptyState(AdminUserTypesScreenController cc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.purple[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_outlined,
              size: 60,
              color: Colors.purple[300],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Aucun type d\'utilisateur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Créez votre premier type d\'utilisateur',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateEditDialog(Get.context!, cc, null),
            icon: Icon(Icons.add),
            label: Text('Créer un type'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
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

  void _showUserTypeDetails(BuildContext context, UserType userType,
      AdminUserTypesScreenController cc) {
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
                      Colors.purple[600]!,
                      Colors.purple[400]!,
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
                          '${userType.index}',
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
                            userType.name,
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
                            'Type d\'utilisateur',
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

              // Contenu scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection(
                        title: 'Description',
                        content: userType.description.isEmpty
                            ? 'Aucune description fournie'
                            : userType.description,
                        isEmpty: userType.description.isEmpty,
                      ),
                      SizedBox(height: 24),
                      _buildDetailSection(
                        title: 'Informations',
                        child: Column(
                          children: [
                            _buildInfoRow('Position', '${userType.index}'),
                            SizedBox(height: 12),
                            _buildInfoRow('ID', userType.id),
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
                              cc.openDeleteAlertDialog(userType);
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
                              _showCreateEditDialog(context, cc, userType);
                            },
                            icon: Icon(Icons.edit, size: 18),
                            label: Text('Modifier'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[600],
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
    bool isEmpty = false,
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
                  color: isEmpty ? Colors.grey[500] : Colors.grey[800],
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
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
      AdminUserTypesScreenController cc, UserType? userType) {
    cc.isEditMode.value = userType != null;
    cc.tempUserType = userType;
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
                  color: Colors.purple[600],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      userType != null ? Icons.edit : Icons.add_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      userType != null
                          ? 'Modifier le type d\'utilisateur'
                          : 'Nouveau type d\'utilisateur',
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

              // Formulaire scrollable
              Flexible(
                child: SingleChildScrollView(
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
                            labelText: 'Nom du type',
                            hintText: 'Ex: Vendeur, Client, Partenaire...',
                            prefixIcon: Icon(Icons.label_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.purple[600]!,
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
                        SizedBox(height: 20),

                        // Champ description
                        TextFormField(
                          controller: cc.descCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description (optionnel)',
                            hintText:
                                'Décrivez le rôle de ce type d\'utilisateur...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.description_outlined),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.purple[600]!,
                                width: 2,
                              ),
                            ),
                          ),
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
                                userType != null ? Icons.save : Icons.check,
                                size: 18,
                              ),
                              label: Text(
                                userType != null ? 'Enregistrer' : 'Créer',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[600],
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
