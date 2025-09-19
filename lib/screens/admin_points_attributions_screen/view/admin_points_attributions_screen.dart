import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/point_attribution.dart';
import '../../../core/widgets/modern_page_header.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_points_attributions_screen_controller.dart';

class AdminPointsAttributionsScreen extends StatelessWidget {
  const AdminPointsAttributionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminPointsAttributionsScreenController());
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
      fabIcon: const Icon(Icons.add),
      fabText: const Text('Attribuer des Points'),
      fabOnPressed: () => _showAttributionBottomSheet(context, cc),
      body: _buildBody(context, cc, isDesktop, isTablet),
    );
  }

  Widget _buildBody(
      BuildContext context,
      AdminPointsAttributionsScreenController cc,
      bool isDesktop,
      bool isTablet) {
    return Obx(() {
      final list = cc.filteredAttributions;

      return CustomScrollView(
        slivers: [
          // Header moderne
          SliverToBoxAdapter(
            child: ModernPageHeader(
              title: "Gestion des Points",
              subtitle: "Administrez les attributions",
              icon: Icons.star,
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
              child: _buildEmptyState(),
            )
          else if (isDesktop)
            // Vue desktop : grille
            SliverPadding(
              padding: EdgeInsets.all(24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => CustomCardAnimation(
                    index: index,
                    child:
                        _buildCompactAttributionCard(list[index], cc, context),
                  ),
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
                    child: CustomCardAnimation(
                      index: index,
                      child: _buildListAttributionCard(
                          list[index], cc, isTablet, context),
                    ),
                  ),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildMinimalStats(AdminPointsAttributionsScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Obx(() {
        final stats = cc.attributionStats;
        return Row(
          children: [
            _buildStatChip(
              label: 'Total',
              value: stats['total'] ?? 0,
              color: Colors.grey[800]!,
              icon: Icons.point_of_sale,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Points',
              value: stats['totalPoints'] ?? 0,
              color: Colors.blue[600]!,
              icon: Icons.star,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Validées',
              value: stats['validated'] ?? 0,
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
                      '${cc.filteredAttributions.length} résultats',
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

  Widget _buildSearchBar(AdminPointsAttributionsScreenController cc) {
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
                  hintText: 'Rechercher par email, nom, date...',
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
          // Filtre validé/non validé
          _buildValidatedFilter(cc),
        ],
      ),
    );
  }

  Widget _buildSortMenu(AdminPointsAttributionsScreenController cc) {
    final sortLabels = ['Date', 'Points', 'Coût', 'Commission'];

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

  Widget _buildValidatedFilter(AdminPointsAttributionsScreenController cc) {
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
                _getFilterIcon(cc.filterValidated.value),
                size: 16,
                color: _getFilterColor(cc.filterValidated.value),
              ),
              SizedBox(width: 6),
              Text(
                _getFilterLabel(cc.filterValidated.value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getFilterColor(cc.filterValidated.value),
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
            value: 'validated',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                SizedBox(width: 12),
                Text('Validées'),
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
          cc.filterValidated.value = value;
        },
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'validated':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.all_inclusive;
    }
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'validated':
        return Colors.green[600]!;
      case 'pending':
        return Colors.orange[600]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'validated':
        return 'Validées';
      case 'pending':
        return 'En attente';
      default:
        return 'Toutes';
    }
  }

  // Vue compacte pour desktop (grille)
  Widget _buildCompactAttributionCard(PointAttribution attribution,
      AdminPointsAttributionsScreenController cc, BuildContext context) {
    final isValidated = attribution.validated;
    final primaryColor = isValidated ? Colors.green[600]! : Colors.orange[600]!;

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
          onTap: () => _showAttributionDetails(attribution, cc, context),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
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
                          Icons.point_of_sale,
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
                            '${attribution.points} points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _formatDate(attribution.date),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildParticipantRow(
                      icon: Icons.card_giftcard,
                      label: 'Attribué par',
                      value: cc.getUserName(attribution.giverId),
                      color: Colors.blue[600]!,
                    ),
                    SizedBox(height: 8),
                    _buildParticipantRow(
                      icon: Icons.person,
                      label: 'Cible',
                      value:
                          '${cc.getUserName(attribution.targetId)}\n${cc.getUserEmail(attribution.targetId)}',
                      color: Colors.purple[600]!,
                    ),
                  ],
                ),

                Spacer(),

                // Footer avec statut et validation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                            isValidated ? Icons.check_circle : Icons.pending,
                            size: 14,
                            color: primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isValidated ? 'Validée' : 'En attente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bouton de validation si nécessaire
                    if (!isValidated)
                      IconButton(
                        onPressed: () => cc.showValidationDialog(attribution),
                        icon: Icon(Icons.check_circle_outline),
                        color: Colors.green[600],
                        tooltip: 'Valider',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Vue liste pour mobile/tablette
  Widget _buildListAttributionCard(
      PointAttribution attribution,
      AdminPointsAttributionsScreenController cc,
      bool isTablet,
      BuildContext context) {
    final isValidated = attribution.validated;
    final primaryColor = isValidated ? Colors.green[600]! : Colors.orange[600]!;

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
          onTap: () => _showAttributionDetails(attribution, cc, context),
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
                      Icons.point_of_sale,
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
                              '${attribution.points} points',
                              style: TextStyle(
                                fontSize: isTablet ? 17 : 16,
                                fontWeight: FontWeight.w700,
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
                                  isValidated
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  size: 12,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isValidated ? 'Validée' : 'En attente',
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
                      Text(
                        'Pour: ${cc.getUserName(attribution.targetId)} (${cc.getUserEmail(attribution.targetId)})',
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            _formatDate(attribution.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (attribution.cost > 0) ...[
                            SizedBox(width: 16),
                            // Coût
                            Icon(
                              Icons.euro,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${attribution.cost.toStringAsFixed(2)}€',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action
                if (!isValidated)
                  IconButton(
                    onPressed: () => cc.showValidationDialog(attribution),
                    icon: Icon(Icons.check_circle_outline),
                    color: Colors.green[600],
                  )
                else
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
              Icons.point_of_sale,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Aucune attribution trouvée',
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAttributionDetails(PointAttribution attribution,
      AdminPointsAttributionsScreenController cc, BuildContext context) {
    final isValidated = attribution.validated;
    final primaryColor = isValidated ? Colors.green[600]! : Colors.orange[600]!;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 500,
          constraints: BoxConstraints(maxHeight: 700),
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
                          Icons.point_of_sale,
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
                            'Attribution de ${attribution.points} points',
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
                                isValidated
                                    ? Icons.check_circle
                                    : Icons.pending,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              SizedBox(width: 4),
                              Text(
                                isValidated ? 'Validée' : 'En attente',
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
                          _buildDetailRow(
                            'Attribué par',
                            cc.getUserName(attribution.giverId),
                            icon: Icons.card_giftcard,
                            iconColor: Colors.blue[600]!,
                          ),
                          _buildDetailRow(
                            'Bénéficiaire',
                            cc.getUserName(attribution.targetId),
                            icon: Icons.person,
                            iconColor: Colors.purple[600]!,
                            topPadding: 12,
                          ),
                          _buildDetailRow(
                            'Email bénéficiaire',
                            cc.getUserEmail(attribution.targetId),
                            icon: Icons.email,
                            iconColor: Colors.grey[600]!,
                            topPadding: 12,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Section Détails
                      _buildSection(
                        title: 'Détails de l\'attribution',
                        icon: Icons.info,
                        children: [
                          _buildDetailRow(
                            'Points attribués',
                            '${attribution.points}',
                            icon: Icons.star,
                            iconColor: Colors.amber[600]!,
                          ),
                          _buildDetailRow(
                            'Coût',
                            '${attribution.cost.toStringAsFixed(2)} €',
                            icon: Icons.euro,
                            iconColor: Colors.green[600]!,
                            topPadding: 12,
                          ),
                          _buildDetailRow(
                            'Commission',
                            '${attribution.commissionPercent.toStringAsFixed(2)}% (${attribution.commissionCost.toStringAsFixed(2)} €)',
                            icon: Icons.percent,
                            iconColor: Colors.blue[600]!,
                            topPadding: 12,
                          ),
                          _buildDetailRow(
                            'Date',
                            _formatDate(attribution.date),
                            icon: Icons.calendar_today,
                            iconColor: Colors.grey[600]!,
                            topPadding: 12,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Actions
                      if (!isValidated)
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.back();
                              cc.showValidationDialog(attribution);
                            },
                            icon: Icon(Icons.check_circle),
                            label: Text('Valider cette attribution'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
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
            width: 140,
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

  void _showAttributionBottomSheet(
      BuildContext context, AdminPointsAttributionsScreenController cc) {
    cc.resetAttributionForm();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            // Header
            Container(
              padding: EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[100]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Icône retour
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Get.back(),
                        customBorder: CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Titre et sous-titre
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attribuer des Points',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Envoyez une invitation avec des points',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenu scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: cc.attributionFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: cc.emailController,
                          style: TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Email du bénéficiaire',
                            labelStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            hintText: 'exemple@email.com',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: cc.onEmailChanged,
                          validator: cc.validateEmail,
                        ),
                      ),

                      // Suggestions de recherche
                      Obx(() {
                        if (cc.emailSearchResults.isEmpty) {
                          return SizedBox.shrink();
                        }
                        return Container(
                          margin: EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: cc.emailSearchResults.map((user) {
                              final isLast = user == cc.emailSearchResults.last;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => cc.selectUser(user),
                                  borderRadius: isLast
                                      ? BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        )
                                      : BorderRadius.zero,
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: !isLast
                                          ? Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[100]!,
                                                width: 1,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(
                                              (user['name'] ?? 'U')[0]
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'] ?? 'Sans nom',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                user['email'] ?? '',
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
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),

                      SizedBox(height: 16),

                      // Points field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: cc.pointsController,
                          style: TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Nombre de points',
                            labelStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.star_outline,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: cc.validatePoints,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Message d'information
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comment ça marche ?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Un email d\'invitation sera envoyé avec les points. '
                                    'Les points seront crédités automatiquement lors de la création du compte.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                      height: 1.4,
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
                ),
              ),
            ),

            // Actions en bas
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Bouton Annuler
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => Get.back(),
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),

                      // Bouton principal
                      Expanded(
                        flex: 2,
                        child: Obx(() => Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: cc.isProcessing.value
                                      ? null
                                      : () => cc.attributePoints(),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Center(
                                    child: cc.isProcessing.value
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Envoyer l\'invitation',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }
}
