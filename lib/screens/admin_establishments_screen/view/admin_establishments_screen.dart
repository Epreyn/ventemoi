import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/establishement.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/widgets/modern_page_header.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_establishments_screen_controller.dart';

class AdminEstablishmentsScreen extends StatelessWidget {
  const AdminEstablishmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminEstablishmentsScreenController(),
        tag: 'admin-establishments-screen');
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
      noFAB: true,
      body: _buildBody(context, cc, isDesktop, isTablet),
    );
  }

  Widget _buildBody(BuildContext context,
      AdminEstablishmentsScreenController cc, bool isDesktop, bool isTablet) {
    return Obx(() {
      final list = cc.filteredEstablishments;

      return CustomScrollView(
        slivers: [
          // Header moderne
          SliverToBoxAdapter(
            child: ModernPageHeader(
              title: "Gestion Établissements",
              subtitle: "Administrez les commerces",
              icon: Icons.store,
            ),
          ),
          // Header fixe avec stats et recherche
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Stats minimalistes
                _buildMinimalStats(cc),
                // Barre de recherche et filtres
                _buildSearchBar(cc),
              ],
            ),
          ),

          // Contenu principal
          if (list.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else if (isDesktop)
            // Vue desktop : grille
            SliverPadding(
              padding: EdgeInsets.all(24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildCompactEstablishmentCard(list[index], cc),
                  childCount: list.length,
                ),
              ),
            )
          else
            // Vue mobile/tablette : liste
            SliverPadding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child:
                        _buildListEstablishmentCard(list[index], cc, isTablet),
                  ),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildMinimalStats(AdminEstablishmentsScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Obx(() {
        final statsByType = cc.statsByType;
        return Row(
          children: [
            _buildStatChip(
              label: 'Total',
              value: cc.allEstablishments.length,
              color: Colors.grey[800]!,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Particuliers',
              value: statsByType['particulier'] ?? 0,
              color: Colors.blue[600]!,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Partenaires',
              value: statsByType['partenaire'] ?? 0,
              color: Colors.green[600]!,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Entreprises',
              value: statsByType['entreprise'] ?? 0,
              color: Colors.orange[600]!,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Boutiques',
              value: statsByType['boutique'] ?? 0,
              color: Colors.purple[600]!,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Associations',
              value: statsByType['association'] ?? 0,
              color: Colors.teal[600]!,
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
                      '${cc.filteredEstablishments.length} résultats',
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
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AdminEstablishmentsScreenController cc) {
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
                  hintText: 'Rechercher un établissement...',
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

  Widget _buildSortMenu(AdminEstablishmentsScreenController cc) {
    final sortLabels = ['Nom', 'Propriétaire', 'Email'];

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
                cc.sortAscending.value
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
                color: Colors.grey[700],
              ),
              SizedBox(width: 6),
              Text(
                sortLabels[cc.sortColumnIndex.value],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: '0_true',
            child: Row(
              children: [
                Icon(Icons.arrow_upward, size: 16),
                SizedBox(width: 12),
                Text('${sortLabels[0]} (A-Z)'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: '0_false',
            child: Row(
              children: [
                Icon(Icons.arrow_downward, size: 16),
                SizedBox(width: 12),
                Text('${sortLabels[0]} (Z-A)'),
              ],
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '1_true',
            child: Row(
              children: [
                Icon(Icons.arrow_upward, size: 16),
                SizedBox(width: 12),
                Text('${sortLabels[1]} (A-Z)'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: '1_false',
            child: Row(
              children: [
                Icon(Icons.arrow_downward, size: 16),
                SizedBox(width: 12),
                Text('${sortLabels[1]} (Z-A)'),
              ],
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '2_true',
            child: Row(
              children: [
                Icon(Icons.arrow_upward, size: 16),
                SizedBox(width: 12),
                Text('${sortLabels[2]} (A-Z)'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: '2_false',
            child: Row(
              children: [
                Icon(Icons.arrow_downward, size: 16),
                SizedBox(width: 12),
                Text('${sortLabels[2]} (Z-A)'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          final parts = value.split('_');
          cc.onSortData(int.parse(parts[0]), parts[1] == 'true');
        },
      ),
    );
  }

  // Vue compacte pour desktop (grille)
  Widget _buildCompactEstablishmentCard(
      Establishment est, AdminEstablishmentsScreenController cc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
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
          onTap: () => _showEstablishmentDetails(est, cc),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    // Logo ou Icône établissement
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: est.logoUrl != null && est.logoUrl!.isNotEmpty
                            ? Colors.transparent
                            : _getEstablishmentColor(est.name),
                        borderRadius: BorderRadius.circular(12),
                        border: est.logoUrl != null && est.logoUrl!.isNotEmpty
                            ? Border.all(color: Colors.grey[200]!, width: 1)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: est.logoUrl != null && est.logoUrl!.isNotEmpty
                            ? Image.network(
                                est.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.store,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.store,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            est.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          FutureBuilder<String>(
                            future: cc.getOwnerName(est.userId),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Chargement...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Catégorie
                FutureBuilder<String>(
                  future: cc.getCategoryName(
                      est.categoryId, est.enterpriseCategoryIds),
                  builder: (context, snapshot) {
                    final categoryName = snapshot.data ?? 'Chargement...';
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(categoryName).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(categoryName),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),

                Spacer(),

                // Type du propriétaire et actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Type propriétaire
                    FutureBuilder<String>(
                      future: cc.getOwnerType(est.userId),
                      builder: (context, snapshot) {
                        final type = snapshot.data ?? '';
                        if (type.isEmpty) return SizedBox.shrink();
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getTypeColor(type),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              type,
                              style: TextStyle(
                                fontSize: 13,
                                color: _getTypeColor(type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    // Bouton détails
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
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

  // Vue liste pour mobile/tablette
  Widget _buildListEstablishmentCard(Establishment est,
      AdminEstablishmentsScreenController cc, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          onTap: () => _showEstablishmentDetails(est, cc),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo ou Icône
                Container(
                  width: isTablet ? 56 : 48,
                  height: isTablet ? 56 : 48,
                  decoration: BoxDecoration(
                    color: _getEstablishmentColor(est.name),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: est.logoUrl != null && est.logoUrl!.isNotEmpty
                      ? Image.network(
                          est.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.store,
                                color: Colors.white,
                                size: isTablet ? 28 : 24,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.store,
                            color: Colors.white,
                            size: isTablet ? 28 : 24,
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
                        est.name,
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: cc.getOwnerName(est.userId),
                        builder: (context, snapshot) {
                          return Text(
                            'Propriétaire: ${snapshot.data ?? '...'}',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 14,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Catégorie
                          Expanded(
                            child: FutureBuilder<String>(
                              future: cc.getCategoryName(
                                  est.categoryId, est.enterpriseCategoryIds),
                              builder: (context, snapshot) {
                                final categoryName = snapshot.data ?? '...';
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(categoryName)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getCategoryColor(categoryName),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          // Type propriétaire
                          FutureBuilder<String>(
                            future: cc.getOwnerType(est.userId),
                            builder: (context, snapshot) {
                              final type = snapshot.data ?? '';
                              if (type.isEmpty) return SizedBox.shrink();
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(type).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getTypeColor(type),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.store_mall_directory,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Aucun établissement trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Modifiez vos critères de recherche',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Color _getEstablishmentColor(String name) {
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.pink[600]!,
      Colors.teal[600]!,
      Colors.indigo[600]!,
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildCashbackSection(Establishment est, AdminEstablishmentsScreenController cc) {
    final TextEditingController cashbackController = TextEditingController(
      text: est.cashbackPercentage.toStringAsFixed(0),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.savings, size: 20, color: Colors.blue[700]),
            SizedBox(width: 8),
            Text(
              'Cashback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pourcentage de cashback',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          child: TextField(
                            controller: cashbackController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                            decoration: InputDecoration(
                              suffixText: '%',
                              suffixStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue[500]!, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final newPercentage = double.tryParse(cashbackController.text);
                            if (newPercentage != null && newPercentage >= 0 && newPercentage <= 100) {
                              await cc.updateCashbackPercentage(est.id, newPercentage);
                              Get.snackbar(
                                'Succès',
                                'Cashback mis à jour à ${newPercentage.toStringAsFixed(0)}%',
                                backgroundColor: Colors.green[100],
                                colorText: Colors.green[800],
                                duration: Duration(seconds: 2),
                              );
                            } else {
                              Get.snackbar(
                                'Erreur',
                                'Veuillez entrer un pourcentage valide (0-100)',
                                backgroundColor: Colors.red[100],
                                colorText: Colors.red[800],
                              );
                            }
                          },
                          icon: Icon(Icons.save, size: 18),
                          label: Text('Sauvegarder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Les clients gagneront ${est.cashbackPercentage.toStringAsFixed(0)}% de leurs achats en points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    // Adapter selon vos catégories
    if (category.toLowerCase().contains('restaurant'))
      return Colors.orange[700]!;
    if (category.toLowerCase().contains('sport')) return Colors.blue[700]!;
    if (category.toLowerCase().contains('beauté')) return Colors.pink[700]!;
    if (category.toLowerCase().contains('santé')) return Colors.green[700]!;
    return Colors.grey[700]!;
  }

  Color _getTypeColor(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'particulier':
        return Colors.blue[700]!;
      case 'partenaire':
        return Colors.green[700]!;
      case 'entreprise':
        return Colors.orange[700]!;
      case 'professionnel':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  void _showEstablishmentDetails(
      Establishment est, AdminEstablishmentsScreenController cc) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 500,
          constraints: BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec gradient
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getEstablishmentColor(est.name),
                      _getEstablishmentColor(est.name).withOpacity(0.8),
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
                        child: Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            est.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          FutureBuilder<String>(
                            future: cc.getCategoryName(
                                est.categoryId, est.enterpriseCategoryIds),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? '...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              );
                            },
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
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Propriétaire
                      _buildSection(
                        title: 'Propriétaire',
                        icon: Icons.person,
                        children: [
                          FutureBuilder<String>(
                            future: cc.getOwnerName(est.userId),
                            builder: (context, snapshot) {
                              return _buildDetailRow(
                                  'Nom', snapshot.data ?? 'Chargement...');
                            },
                          ),
                          FutureBuilder<String>(
                            future: cc.getOwnerType(est.userId),
                            builder: (context, snapshot) {
                              final type = snapshot.data ?? '';
                              if (type.isEmpty) return SizedBox.shrink();
                              return Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: _buildDetailRow('Type', ''),
                              );
                            },
                          ),
                          FutureBuilder<String>(
                            future: cc.getOwnerType(est.userId),
                            builder: (context, snapshot) {
                              final type = snapshot.data ?? '';
                              if (type.isEmpty) return SizedBox.shrink();
                              return Padding(
                                padding: EdgeInsets.only(left: 80, top: 4),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(type).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _getTypeColor(type),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Section Contact
                      _buildSection(
                        title: 'Contact',
                        icon: Icons.contact_mail,
                        children: [
                          if (est.email.isNotEmpty)
                            _buildDetailRow('Email', est.email),
                          if (est.telephone.isNotEmpty)
                            _buildDetailRow('Téléphone', est.telephone,
                                topPadding: 8),
                          if (est.address.isNotEmpty)
                            _buildDetailRow('Adresse', est.address,
                                topPadding: 8),
                        ],
                      ),

                      if (est.description.isNotEmpty) ...[
                        SizedBox(height: 24),
                        // Section Description
                        _buildSection(
                          title: 'Description',
                          icon: Icons.description,
                          children: [
                            Text(
                              est.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: 24),

                      // Section Cashback (seulement pour les entreprises)
                      if (est.enterpriseCategoryIds != null && est.enterpriseCategoryIds!.isNotEmpty) ...[
                        _buildCashbackSection(est, cc),
                        SizedBox(height: 24),
                      ],

                      // Section Infos techniques
                      _buildSection(
                        title: 'Informations techniques',
                        icon: Icons.info_outline,
                        children: [
                          _buildDetailRow('ID', est.id),
                          _buildDetailRow('User ID', est.userId, topPadding: 8),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {double topPadding = 0}) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
