import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/purchase.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_sells_screen_controller.dart';

class AdminSellsScreen extends StatelessWidget {
  const AdminSellsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminSellsScreenController());
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

  Widget _buildBody(BuildContext context, AdminSellsScreenController cc,
      bool isDesktop, bool isTablet) {
    return Obx(() {
      final list = cc.filteredPurchases;

      return CustomScrollView(
        slivers: [
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
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildCompactPurchaseCard(list[index], cc),
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
                    child: _buildListPurchaseCard(list[index], cc, isTablet),
                  ),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildMinimalStats(AdminSellsScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Obx(() {
        final stats = cc.purchaseStats;
        return Row(
          children: [
            _buildStatChip(
              label: 'Total',
              value: stats['total'] ?? 0,
              color: Colors.grey[800]!,
              icon: Icons.shopping_cart,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Bons',
              value: stats['totalCoupons'] ?? 0,
              color: Colors.blue[600]!,
              icon: Icons.confirmation_number,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Réclamées',
              value: stats['reclaimed'] ?? 0,
              color: Colors.green[600]!,
              icon: Icons.check_circle,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'En attente',
              value: stats['pending'] ?? 0,
              color: Colors.orange[600]!,
              icon: Icons.pending,
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
                      '${cc.filteredPurchases.length} résultats',
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

  Widget _buildSearchBar(AdminSellsScreenController cc) {
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
                  hintText: 'Rechercher par code, date, nom...',
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
          SizedBox(width: 12),
          // Filtre réclamé/non réclamé
          _buildReclaimedFilter(cc),
        ],
      ),
    );
  }

  Widget _buildSortMenu(AdminSellsScreenController cc) {
    final sortLabels = ['Acheteur', 'Vendeur', 'Bons', 'Date'];

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
        itemBuilder: (context) => List.generate(
          sortLabels.length * 2,
          (index) {
            final colIndex = index ~/ 2;
            final ascending = index % 2 == 0;
            return PopupMenuItem<String>(
              value: '${colIndex}_$ascending',
              child: Row(
                children: [
                  Icon(
                    ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                  ),
                  SizedBox(width: 12),
                  Text(
                      '${sortLabels[colIndex]} (${ascending ? 'Croissant' : 'Décroissant'})'),
                ],
              ),
            );
          },
        ),
        onSelected: (value) {
          final parts = value.split('_');
          cc.onSortData(int.parse(parts[0]), parts[1] == 'true');
        },
      ),
    );
  }

  Widget _buildReclaimedFilter(AdminSellsScreenController cc) {
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
                _getFilterIcon(cc.filterReclaimed.value),
                size: 16,
                color: _getFilterColor(cc.filterReclaimed.value),
              ),
              SizedBox(width: 6),
              Text(
                _getFilterLabel(cc.filterReclaimed.value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getFilterColor(cc.filterReclaimed.value),
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'all',
            child: Row(
              children: [
                Icon(Icons.all_inclusive, size: 16),
                SizedBox(width: 12),
                Text('Toutes'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'reclaimed',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                SizedBox(width: 12),
                Text('Réclamées'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'pending',
            child: Row(
              children: [
                Icon(Icons.pending, size: 16, color: Colors.orange[600]),
                SizedBox(width: 12),
                Text('En attente'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          cc.filterReclaimed.value = value;
        },
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'reclaimed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.all_inclusive;
    }
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'reclaimed':
        return Colors.green[600]!;
      case 'pending':
        return Colors.orange[600]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'reclaimed':
        return 'Réclamées';
      case 'pending':
        return 'En attente';
      default:
        return 'Toutes';
    }
  }

  // Vue compacte pour desktop (grille)
  Widget _buildCompactPurchaseCard(
      Purchase purchase, AdminSellsScreenController cc) {
    final isReclaimed = purchase.isReclaimed;
    final primaryColor = isReclaimed ? Colors.green[600]! : Colors.orange[600]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
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
          onTap: () => _showPurchaseDetails(purchase, cc),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec code
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.receipt_long,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code: ${purchase.reclamationPassword}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            _formatDate(purchase.date),
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

                SizedBox(height: 16),

                // Participants
                FutureBuilder<Map<String, String>>(
                  future: cc.getParticipantNames(
                      purchase.buyerId, purchase.sellerId),
                  builder: (context, snapshot) {
                    final names = snapshot.data ??
                        {'buyer': 'Chargement...', 'seller': 'Chargement...'};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildParticipantRow(
                          icon: Icons.shopping_bag,
                          label: 'Acheteur',
                          value: names['buyer']!,
                          color: Colors.blue[600]!,
                        ),
                        SizedBox(height: 8),
                        _buildParticipantRow(
                          icon: Icons.store,
                          label: 'Vendeur',
                          value: names['seller']!,
                          color: Colors.purple[600]!,
                        ),
                      ],
                    );
                  },
                ),

                Spacer(),

                // Footer avec bons et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nombre de bons
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${purchase.couponsCount} bons',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Statut
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isReclaimed ? Icons.check_circle : Icons.pending,
                            size: 14,
                            color: primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isReclaimed ? 'Réclamée' : 'En attente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
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

  Widget _buildParticipantRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Vue liste pour mobile/tablette
  Widget _buildListPurchaseCard(
      Purchase purchase, AdminSellsScreenController cc, bool isTablet) {
    final isReclaimed = purchase.isReclaimed;
    final primaryColor = isReclaimed ? Colors.green[600]! : Colors.orange[600]!;

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
          onTap: () => _showPurchaseDetails(purchase, cc),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône
                Container(
                  width: isTablet ? 56 : 48,
                  height: isTablet ? 56 : 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long,
                      color: primaryColor,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Code: ${purchase.reclamationPassword}',
                              style: TextStyle(
                                fontSize: isTablet ? 17 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                          // Badge statut
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isReclaimed
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  size: 12,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isReclaimed ? 'Réclamée' : 'En attente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      FutureBuilder<Map<String, String>>(
                        future: cc.getParticipantNames(
                            purchase.buyerId, purchase.sellerId),
                        builder: (context, snapshot) {
                          final names = snapshot.data ??
                              {'buyer': '...', 'seller': '...'};
                          return Text(
                            '${names['buyer']} → ${names['seller']}',
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Date
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(purchase.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 16),
                          // Nombre de bons
                          Icon(
                            Icons.confirmation_number,
                            size: 14,
                            color: Colors.blue[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${purchase.couponsCount} bons',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[600],
                            ),
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
              Icons.receipt_long,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Aucune vente trouvée',
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showPurchaseDetails(Purchase purchase, AdminSellsScreenController cc) {
    final isReclaimed = purchase.isReclaimed;
    final primaryColor = isReclaimed ? Colors.green[600]! : Colors.orange[600]!;

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
                      primaryColor,
                      primaryColor.withOpacity(0.8),
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
                          Icons.receipt_long,
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
                            'Vente #${purchase.reclamationPassword}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isReclaimed
                                    ? Icons.check_circle
                                    : Icons.pending,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              SizedBox(width: 4),
                              Text(
                                isReclaimed ? 'Réclamée' : 'En attente',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
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
                      // Section Participants
                      _buildSection(
                        title: 'Participants',
                        icon: Icons.people,
                        children: [
                          FutureBuilder<Map<String, String>>(
                            future: cc.getParticipantNames(
                                purchase.buyerId, purchase.sellerId),
                            builder: (context, snapshot) {
                              final names = snapshot.data ??
                                  {
                                    'buyer': 'Chargement...',
                                    'seller': 'Chargement...'
                                  };
                              return Column(
                                children: [
                                  _buildDetailRow(
                                    'Acheteur',
                                    names['buyer']!,
                                    icon: Icons.shopping_bag,
                                    iconColor: Colors.blue[600]!,
                                  ),
                                  _buildDetailRow(
                                    'Vendeur',
                                    names['seller']!,
                                    icon: Icons.store,
                                    iconColor: Colors.purple[600]!,
                                    topPadding: 12,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Section Détails de la transaction
                      _buildSection(
                        title: 'Détails de la transaction',
                        icon: Icons.receipt,
                        children: [
                          _buildDetailRow(
                            'Nombre de bons',
                            '${purchase.couponsCount}',
                            icon: Icons.confirmation_number,
                            iconColor: Colors.blue[600]!,
                          ),
                          _buildDetailRow(
                            'Date',
                            _formatDateTime(purchase.date),
                            icon: Icons.calendar_today,
                            iconColor: Colors.grey[600]!,
                            topPadding: 12,
                          ),
                          _buildDetailRow(
                            'Code de réclamation',
                            purchase.reclamationPassword,
                            icon: Icons.key,
                            iconColor: Colors.orange[600]!,
                            topPadding: 12,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Section Statut
                      _buildSection(
                        title: 'Statut',
                        icon: Icons.info_outline,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isReclaimed
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  color: primaryColor,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isReclaimed
                                            ? 'Transaction réclamée'
                                            : 'En attente de réclamation',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        isReclaimed
                                            ? 'Les bons ont été réclamés par le vendeur'
                                            : 'Le vendeur n\'a pas encore réclamé les bons',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Section Identifiants techniques
                      _buildSection(
                        title: 'Identifiants techniques',
                        icon: Icons.code,
                        children: [
                          _buildDetailRow(
                            'ID Transaction',
                            purchase.id,
                            icon: Icons.tag,
                            iconColor: Colors.grey[600]!,
                          ),
                          _buildDetailRow(
                            'ID Acheteur',
                            purchase.buyerId,
                            icon: Icons.person,
                            iconColor: Colors.grey[600]!,
                            topPadding: 8,
                          ),
                          _buildDetailRow(
                            'ID Vendeur',
                            purchase.sellerId,
                            icon: Icons.business,
                            iconColor: Colors.grey[600]!,
                            topPadding: 8,
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

  Widget _buildDetailRow(
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
    double topPadding = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? Colors.grey[600]),
            SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
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

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
