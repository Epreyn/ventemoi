import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_users_screen_controller.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminUsersScreenController(), tag: 'admin-users-screen');
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
      fabIcon: Icon(Icons.add_rounded, size: 24),
      fabText: Text('Ajouter un utilisateur'),
      fabOnPressed: cc.openCreateUserBottomSheet,
      body: _buildBody(context, cc, isDesktop, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, AdminUsersScreenController cc,
      bool isDesktop, bool isTablet) {
    return Obx(() {
      final list = cc.filteredUsers;
      final stats = _calculateStats(cc);

      return CustomScrollView(
        slivers: [
          // Header fixe avec stats et recherche
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Stats minimalistes
                _buildMinimalStats(stats, cc),
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
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCompactUserCard(list[index], cc),
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
                    child: _buildListUserCard(list[index], cc, isTablet),
                  ),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      );
    });
  }

  Map<String, int> _calculateStats(AdminUsersScreenController cc) {
    final nonAdminUsers = cc.allUsers
        .where((u) => u.userTypeID != AdminUsersScreenController.adminTypeDocId)
        .toList();

    return {
      'total': nonAdminUsers.length,
      'active': nonAdminUsers.where((u) => u.isEnable).length,
      'inactive': nonAdminUsers.where((u) => !u.isEnable).length,
    };
  }

  Widget _buildMinimalStats(
      Map<String, int> stats, AdminUsersScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStatChip(
            label: 'Total',
            value: stats['total']!,
            color: Colors.grey[800]!,
          ),
          SizedBox(width: 16),
          _buildStatChip(
            label: 'Actifs',
            value: stats['active']!,
            color: Colors.green[600]!,
          ),
          SizedBox(width: 16),
          _buildStatChip(
            label: 'Inactifs',
            value: stats['inactive']!,
            color: Colors.orange[600]!,
          ),
          Spacer(),
          // Indicateur de recherche
          Obx(() {
            if (cc.searchText.value.isNotEmpty) {
              return Container(
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
                      '${cc.filteredUsers.length} résultats',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
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

  Widget _buildSearchBar(AdminUsersScreenController cc) {
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
                  hintText: 'Rechercher un utilisateur...',
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

  Widget _buildSortMenu(AdminUsersScreenController cc) {
    final sortLabels = ['Nom', 'Email', 'Type'];

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
  Widget _buildCompactUserCard(dynamic user, AdminUsersScreenController cc) {
    final isActive = user.isEnable;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.orange[200]! : Colors.grey[200]!,
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
          onTap: () => _showUserDetails(user, cc),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getUserColor(user.email),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getUserInitials(user),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
                            user.name.isEmpty ? 'Sans nom' : user.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Type d'utilisateur
                StreamBuilder<String>(
                  stream: _getUserTypeName(user.userTypeID),
                  builder: (context, snapshot) {
                    final typeName = snapshot.data ?? 'Chargement...';
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(typeName).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(typeName),
                        ),
                      ),
                    );
                  },
                ),

                Spacer(),

                // Actions rapides
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Statut
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isActive ? Colors.green[700] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Switch
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        onChanged: (val) => cc.onSwitchEnabled(user, val),
                        activeColor: Colors.green,
                      ),
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
  Widget _buildListUserCard(
      dynamic user, AdminUsersScreenController cc, bool isTablet) {
    final isActive = user.isEnable;
    final isVisible = user.isVisible;

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
          onTap: () => _showUserDetails(user, cc),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: isTablet ? 56 : 48,
                  height: isTablet ? 56 : 48,
                  decoration: BoxDecoration(
                    color: _getUserColor(user.email),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _getUserInitials(user),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 20 : 18,
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
                        user.name.isEmpty ? 'Sans nom' : user.name,
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Type
                          StreamBuilder<String>(
                            stream: _getUserTypeName(user.userTypeID),
                            builder: (context, snapshot) {
                              final typeName = snapshot.data ?? '...';
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      _getTypeColor(typeName).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getTypeColor(typeName),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 8),
                          // Badges de statut
                          if (!isActive)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Inactif',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          if (!isVisible) ...[
                            SizedBox(width: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Masqué',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    IconButton(
                      onPressed: () => cc.onSwitchEnabled(user, !isActive),
                      icon: Icon(
                        isActive ? Icons.toggle_on : Icons.toggle_off,
                        size: 32,
                        color: isActive ? Colors.green : Colors.grey[400],
                      ),
                    ),
                    Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? Colors.green[700] : Colors.grey[500],
                      ),
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
              Icons.person_search,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouvé',
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
  Color _getUserColor(String email) {
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.pink[600]!,
      Colors.teal[600]!,
      Colors.indigo[600]!,
    ];
    return colors[email.hashCode % colors.length];
  }

  String _getUserInitials(dynamic user) {
    if (user.name.isNotEmpty) {
      final parts = user.name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return user.name.substring(0, 2).toUpperCase();
    }
    return user.email.substring(0, 2).toUpperCase();
  }

  Stream<String> _getUserTypeName(String typeId) async* {
    if (typeId.isEmpty) {
      yield 'Non défini';
      return;
    }

    final stream = FirebaseFirestore.instance
        .collection('user_types')
        .doc(typeId)
        .snapshots();

    await for (final snap in stream) {
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        yield data['name'] ?? 'Inconnu';
      } else {
        yield 'Inconnu';
      }
    }
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

  void _showUserDetails(dynamic user, AdminUsersScreenController cc) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 400,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getUserColor(user.email),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getUserInitials(user),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
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
                          user.name.isEmpty ? 'Sans nom' : user.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Infos détaillées
              _buildDetailRow('ID', user.id),
              SizedBox(height: 16),
              _buildDetailRow('Type', ''),
              StreamBuilder<String>(
                stream: _getUserTypeName(user.userTypeID),
                builder: (context, snapshot) {
                  return Padding(
                    padding: EdgeInsets.only(left: 80, top: 4),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            _getTypeColor(snapshot.data ?? '').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        snapshot.data ?? 'Chargement...',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(snapshot.data ?? ''),
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 24),

              // Switches
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Obx(() => _buildSwitchRow(
                          'Compte activé',
                          'L\'utilisateur peut se connecter',
                          cc.allUsers
                              .firstWhere((u) => u.id == user.id)
                              .isEnable,
                          (val) => cc.onSwitchEnabled(user, val),
                          Colors.green,
                        )),
                    SizedBox(height: 16),
                    Obx(() => _buildSwitchRow(
                          'Profil visible',
                          'Le profil est visible publiquement',
                          cc.allUsers
                              .firstWhere((u) => u.id == user.id)
                              .isVisible,
                          (val) => cc.onSwitchVisible(user, val),
                          Colors.blue,
                        )),
                    SizedBox(height: 16),

                    // Remplacez le FutureBuilder par un simple Obx :

                    // Afficher les infos d'affiliation SEULEMENT pour les associations
                    Obx(() {
                      final userTypeName =
                          cc.getUserTypeName(user.userTypeID).toLowerCase();

                      // Si c'est une association, afficher les infos d'affiliation
                      if (userTypeName == 'association') {
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: cc.getAssociationEstablishmentInfo(user.id),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                              return SizedBox.shrink();
                            }

                            final info = snapshot.data!;
                            final sponsorCount = info['sponsorCount'] as int;
                            final isVisible = info['isVisible'] as bool;
                            final forceVisible =
                                info['forceVisibleOverride'] as bool;
                            final establishmentId =
                                info['establishmentId'] as String;

                            return Column(
                              children: [
                                Divider(height: 32),
                                // Section Association
                                Row(
                                  children: [
                                    Icon(Icons.group, color: Colors.green[700]),
                                    SizedBox(width: 8),
                                    Text(
                                      'Informations Association',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Nombre d'affiliés
                                cc.buildInfoRow(
                                  'Affiliés',
                                  '$sponsorCount / 15',
                                  icon: Icons.people,
                                  color: sponsorCount >= 15
                                      ? Colors.green
                                      : Colors.orange,
                                ),

                                // Statut de visibilité
                                if (sponsorCount < 15)
                                  Column(
                                    children: [
                                      SizedBox(height: 12),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: forceVisible
                                              ? Colors.purple[50]
                                              : Colors.orange[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              forceVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: forceVisible
                                                  ? Colors.purple[700]
                                                  : Colors.orange[700],
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                forceVisible
                                                    ? 'Visibilité forcée activée'
                                                    : 'Non visible (moins de 15 affiliés)',
                                                style: TextStyle(
                                                  color: forceVisible
                                                      ? Colors.purple[700]
                                                      : Colors.orange[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      _buildSwitchRow(
                                        'Forcer la visibilité',
                                        'Rendre visible même avec moins de 15 affiliés',
                                        forceVisible,
                                        (val) => cc
                                            .toggleAssociationVisibilityOverride(
                                                establishmentId, val),
                                        Colors.purple,
                                      ),
                                    ],
                                  ),
                              ],
                            );
                          },
                        );
                      }

                      // Pour les autres types, ne rien afficher
                      return SizedBox.shrink();
                    }),
                  ],
                ),
              ),

              // Section Abonnement / Accès gratuit
              FutureBuilder<Map<String, dynamic>>(
                future: cc.getUserPaymentInfo(user.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final paymentInfo = snapshot.data!;
                  final hasFreeAccess = paymentInfo['has_free_access'] ?? false;
                  final subscriptionType =
                      paymentInfo['free_subscription_type'] ?? 'standard';
                  final hasActiveSubscription =
                      paymentInfo['has_active_subscription'] ?? false;

                  return Column(
                    children: [
                      Divider(height: 32),
                      Row(
                        children: [
                          Icon(
                            hasFreeAccess
                                ? Icons.card_giftcard
                                : Icons.credit_card,
                            color: hasFreeAccess
                                ? Colors.purple[700]
                                : Colors.blue[700],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Abonnement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Statut actuel
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasFreeAccess
                              ? Colors.purple[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasFreeAccess
                                ? Colors.purple[200]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasFreeAccess ? Icons.verified : Icons.payment,
                              color: hasFreeAccess
                                  ? Colors.purple[700]
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasFreeAccess
                                        ? 'Accès gratuit activé'
                                        : hasActiveSubscription
                                            ? 'Abonnement payant actif'
                                            : 'Aucun abonnement actif',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: hasFreeAccess
                                          ? Colors.purple[700]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  if (hasFreeAccess &&
                                      paymentInfo['free_access_granted_by'] !=
                                          null)
                                    Text(
                                      'Accordé par: ${paymentInfo['free_access_granted_by']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (subscriptionType != null)
                                    Text(
                                      'Type: ${subscriptionType.toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Toggle accès gratuit
                      StatefulBuilder(
                        builder: (context, setState) {
                          bool localFreeAccess = hasFreeAccess;
                          String localSubscriptionType = subscriptionType;

                          return Column(
                            children: [
                              _buildSwitchRow(
                                'Accès gratuit',
                                'Activer toutes les fonctionnalités premium gratuitement',
                                localFreeAccess,
                                (val) {
                                  setState(() {
                                    localFreeAccess = val;
                                  });

                                  if (val) {
                                    // Afficher un dialog pour choisir le type
                                    Get.dialog(
                                      AlertDialog(
                                        title: Text(
                                            'Choisir le type d\'abonnement'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            RadioListTile<String>(
                                              title:
                                                  Text('Basic (2 catégories)'),
                                              value: 'basic',
                                              groupValue: localSubscriptionType,
                                              onChanged: (value) {
                                                Get.back();
                                                cc.toggleFreeAccess(
                                                    user.id, true, value!);
                                              },
                                            ),
                                            RadioListTile<String>(
                                              title: Text(
                                                  'Standard (3 catégories)'),
                                              value: 'standard',
                                              groupValue: localSubscriptionType,
                                              onChanged: (value) {
                                                Get.back();
                                                cc.toggleFreeAccess(
                                                    user.id, true, value!);
                                              },
                                            ),
                                            RadioListTile<String>(
                                              title: Text(
                                                  'Premium (5 catégories)'),
                                              value: 'premium',
                                              groupValue: localSubscriptionType,
                                              onChanged: (value) {
                                                Get.back();
                                                cc.toggleFreeAccess(
                                                    user.id, true, value!);
                                              },
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(),
                                            child: Text('Annuler'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    // Confirmer la désactivation
                                    Get.dialog(
                                      AlertDialog(
                                        title:
                                            Text('Désactiver l\'accès gratuit'),
                                        content: Text(
                                          'Êtes-vous sûr de vouloir désactiver l\'accès gratuit ?\n\n'
                                          'L\'utilisateur devra payer pour continuer à utiliser les fonctionnalités premium.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(),
                                            child: Text('Annuler'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Get.back();
                                              cc.toggleFreeAccess(
                                                  user.id, false, '');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: Text('Désactiver'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                Colors.purple,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
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
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    Color activeColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }
}
