import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';

// Imports internes
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/points_request.dart';
import '../../../core/widgets/modern_page_header.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_points_requests_screen_controller.dart';

class AdminPointsRequestsScreen extends StatelessWidget {
  const AdminPointsRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminPointsRequestsScreenController());
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
      fabText: const Text('Attribuer des bons'),
      fabOnPressed: () {
        cc.openBottomSheet(
          'Attribuer des Bons à une Boutique',
          actionName: 'Créer',
          actionIcon: Icons.check,
        );
      },
      body: _buildBody(context, cc, isDesktop, isTablet),
    );
  }

  Widget _buildBody(BuildContext context,
      AdminPointsRequestsScreenController cc, bool isDesktop, bool isTablet) {
    return Obx(() {
      // Utiliser la liste filtrée de bons achetés et renouvelés
      final list = cc.filteredVouchers;

      return CustomScrollView(
        slivers: [
          // Header moderne
          SliverToBoxAdapter(
            child: ModernPageHeader(
              title: "Gestion des Bons Cadeaux",
              subtitle: "Suivi des bons achetés et renouvelés",
              icon: Icons.card_giftcard,
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

          // Contenu principal - Toujours en liste de tiles
          if (list.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: _buildVoucherTile(list[index], cc, isDesktop),
                  ),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildMinimalStats(AdminPointsRequestsScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Obx(() {
        final totalVouchers = cc.filteredVouchers.length;
        final totalOwed = cc.totalOwed;
        final totalPaid = cc.totalPaid;

        return Row(
          children: [
            _buildStatChip(
              label: 'Bons renouvelés vendus',
              value: totalVouchers,
              color: Colors.purple[600]!,
              icon: Icons.refresh,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Montant dû',
              value: '${totalOwed.toStringAsFixed(0)}€',
              color: Colors.orange[600]!,
              icon: Icons.euro,
              isString: true,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Montant payé',
              value: '${totalPaid.toStringAsFixed(0)}€',
              color: Colors.green[600]!,
              icon: Icons.check_circle,
              isString: true,
            ),
            Spacer(),
            // Indicateur de recherche
            if (cc.searchText.isNotEmpty)
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
                      '${cc.filteredVouchers.length} résultats',
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
    required dynamic value,
    required Color color,
    required IconData icon,
    bool isString = false,
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
              isString ? value.toString() : '$value',
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

  Widget _buildSearchBar(AdminPointsRequestsScreenController cc) {
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
                  hintText: 'Rechercher par nom, email, établissement...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  suffixIcon: cc.searchText.isNotEmpty
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
          _buildValidationFilter(cc),
        ],
      ),
    );
  }

  Widget _buildSortMenu(AdminPointsRequestsScreenController cc) {
    final sortLabels = ['Date', 'Nom', 'Email', 'Bons'];

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

  Widget _buildValidationFilter(AdminPointsRequestsScreenController cc) {
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
  Widget _buildCompactRequestCard(
      PointsRequest request, AdminPointsRequestsScreenController cc) {
    final isValidated = request.isValidated;
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
          onTap: isValidated ? null : () => _showRequestDetails(request, cc),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône et date
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
                          Icons.request_page,
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
                            _formatDate(request.createdAt),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _formatTime(request.createdAt),
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

                // Infos utilisateur et établissement
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.person,
                      label: cc.getUserName(request.userId),
                      sublabel: cc.getUserEmail(request.userId),
                      color: Colors.blue[600]!,
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.store,
                      label: cc.getEstabName(request.establishmentId),
                      color: Colors.purple[600]!,
                    ),
                  ],
                ),

                Spacer(),

                // Footer avec nombre de bons et bouton/statut
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
                            '${request.couponsCount} bons',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Switch ou statut
                    if (isValidated)
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
                              Icons.check_circle,
                              size: 14,
                              color: primaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Validée',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          thumbColor: WidgetStateProperty.all(Colors.white),
                          activeColor: primaryColor,
                          value: false,
                          onChanged: (val) {
                            cc.tempPointsRequest = request;
                            cc.openAlertDialog(
                              '${request.couponsCount} bons pour ${cc.getUserName(request.userId)}',
                              confirmText: 'Valider',
                            );
                          },
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? sublabel,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sublabel != null)
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Vue liste pour mobile/tablette
  Widget _buildListRequestCard(PointsRequest request,
      AdminPointsRequestsScreenController cc, bool isTablet) {
    final isValidated = request.isValidated;
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
          onTap: isValidated ? null : () => _showRequestDetails(request, cc),
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
                      Icons.request_page,
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
                              cc.getUserName(request.userId),
                              style: TextStyle(
                                fontSize: isTablet ? 17 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge statut ou switch
                          if (isValidated)
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
                                    Icons.check_circle,
                                    size: 12,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Validée',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                thumbColor:
                                    WidgetStateProperty.all(Colors.white),
                                activeColor: primaryColor,
                                value: false,
                                onChanged: (val) {
                                  cc.tempPointsRequest = request;
                                  cc.openAlertDialog(
                                    '${request.couponsCount} bons pour ${cc.getUserName(request.userId)}',
                                    confirmText: 'Valider',
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        cc.getEstabName(request.establishmentId),
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
                            _formatDate(request.createdAt),
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
                            '${request.couponsCount} bons',
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

                // Chevron pour les non validées
                if (!isValidated)
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
              Icons.request_page,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Aucun bon renouvelé vendu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les bons renouvelés vendus apparaîtront ici',
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

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showRequestDetails(
      PointsRequest request, AdminPointsRequestsScreenController cc) {
    final isValidated = request.isValidated;
    final primaryColor = isValidated ? Colors.green[600]! : Colors.orange[600]!;

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
                          Icons.request_page,
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
                            'Demande de bons',
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
                      // Section Demandeur
                      _buildSection(
                        title: 'Demandeur',
                        icon: Icons.person,
                        children: [
                          _buildDetailRow(
                            'Nom',
                            cc.getUserName(request.userId),
                            icon: Icons.person,
                            iconColor: Colors.blue[600]!,
                          ),
                          _buildDetailRow(
                            'Email',
                            cc.getUserEmail(request.userId),
                            icon: Icons.email,
                            iconColor: Colors.blue[600]!,
                            topPadding: 12,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Section Établissement
                      _buildSection(
                        title: 'Établissement',
                        icon: Icons.store,
                        children: [
                          _buildDetailRow(
                            'Nom',
                            cc.getEstabName(request.establishmentId),
                            icon: Icons.business,
                            iconColor: Colors.purple[600]!,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Section Détails de la demande
                      _buildSection(
                        title: 'Détails de la demande',
                        icon: Icons.receipt,
                        children: [
                          _buildDetailRow(
                            'Nombre de bons',
                            '${request.couponsCount}',
                            icon: Icons.confirmation_number,
                            iconColor: Colors.blue[600]!,
                          ),
                          _buildDetailRow(
                            'Date de demande',
                            '${_formatDate(request.createdAt)} à ${_formatTime(request.createdAt)}',
                            icon: Icons.calendar_today,
                            iconColor: Colors.grey[600]!,
                            topPadding: 12,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Section Actions (si non validée)
                      if (!isValidated)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    size: 20,
                                    color: Colors.orange[700],
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Action requise',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Cette demande est en attente de validation. Validez-la pour créditer les bons sur le wallet de la boutique.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[900],
                                ),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Get.back();
                                    cc.tempPointsRequest = request;
                                    cc.openAlertDialog(
                                      '${request.couponsCount} bons pour ${cc.getUserName(request.userId)}',
                                      confirmText: 'Valider',
                                    );
                                  },
                                  icon: Icon(Icons.check_circle),
                                  label: Text('Valider la demande'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Section Identifiants techniques
                      SizedBox(height: 24),
                      _buildSection(
                        title: 'Identifiants techniques',
                        icon: Icons.code,
                        children: [
                          _buildDetailRow(
                            'ID Demande',
                            request.id,
                            icon: Icons.tag,
                            iconColor: Colors.grey[600]!,
                          ),
                          _buildDetailRow(
                            'ID Utilisateur',
                            request.userId,
                            icon: Icons.person,
                            iconColor: Colors.grey[600]!,
                            topPadding: 8,
                          ),
                          _buildDetailRow(
                            'ID Wallet',
                            request.walletId,
                            icon: Icons.account_balance_wallet,
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

  // Nouvelle méthode pour afficher un tile de bon cadeau avec toutes les infos
  Widget _buildVoucherTile(
      Map<String, dynamic> voucher, AdminPointsRequestsScreenController cc, bool isDesktop) {
    final isRenewed = voucher['is_renewed'] ?? false;
    final status = voucher['status'] ?? 'active';
    final isPaid = voucher['payment_status'] == 'paid';
    final establishmentId = voucher['establishment_id'] ?? '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getEstablishmentBankDetails(establishmentId),
      builder: (context, snapshot) {
        final bankDetails = snapshot.data;

        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isRenewed ? Colors.purple.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRenewed ? Colors.purple[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isRenewed ? Icons.refresh : Icons.card_giftcard,
                  color: isRenewed ? Colors.purple[700] : Colors.blue[700],
                  size: 24,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            voucher['establishment_name'] ?? 'Boutique',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          if (isRenewed)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'RENOUVELÉ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.tag, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            voucher['code'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 16),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'used' ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status == 'used' ? 'Utilisé' : 'Actif',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: status == 'used' ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Montant
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${voucher['value'] ?? 50}€',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    // Montant dû (toujours 35€ pour les bons renouvelés vendus)
                    Text(
                      'Dû: ${voucher['ventemoi_owes'] ?? 35}€',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Switch pour marquer comme payé (pour tous les bons où on doit payer la boutique)
                ...[
                  SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        isPaid ? 'Payé' : 'À payer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPaid ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isPaid,
                          onChanged: (value) {
                            if (value && !isPaid) {
                              // Confirmation dialog
                              Get.dialog(
                                AlertDialog(
                                  title: Text('Confirmer le paiement'),
                                  content: Text(
                                    'Marquer ce virement de ${voucher['ventemoi_owes'] ?? 35}€ à ${voucher['establishment_name']} comme effectué ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: Text('Annuler'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Get.back();
                                        cc.markAsPaid(voucher['id']);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[600],
                                      ),
                                      child: Text('Confirmer'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          activeColor: Colors.green[600],
                          inactiveThumbColor: Colors.orange[600],
                          inactiveTrackColor: Colors.orange[200],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            children: [
              // Détails supplémentaires dans l'expansion
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  SizedBox(height: 8),
                  // Informations du bon
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INFORMATIONS DU BON',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildVoucherInfoRow('Date création',
                              _formatVoucherDate(voucher['created_at'])),
                            _buildVoucherInfoRow('Statut', voucher['status'] ?? 'active'),
                            if (voucher['buyer_id'] != null)
                              FutureBuilder<String>(
                                future: _getUserName(voucher['buyer_id']),
                                builder: (context, snap) => _buildVoucherInfoRow(
                                  'Acheteur',
                                  snap.data ?? 'Chargement...'
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Données bancaires (pour tous les bons où on doit payer)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COORDONNÉES BANCAIRES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              if (bankDetails != null) ...[
                                _buildVoucherInfoRow('Titulaire', bankDetails['holder'] ?? 'N/A'),
                                _buildVoucherInfoRow('IBAN', _maskIban(bankDetails['iban'] ?? 'N/A')),
                                _buildVoucherInfoRow('BIC', bankDetails['bic'] ?? 'N/A'),
                              ] else
                                Text(
                                  'Chargement...',
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
                  if (isRenewed) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.purple[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bon renouvelé : Coût boutique ${voucher['renewal_cost'] ?? 15}€ - VenteMoi doit ${voucher['ventemoi_owes'] ?? 35}€',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper pour récupérer les données bancaires
  Future<Map<String, dynamic>?> _getEstablishmentBankDetails(String establishmentId) async {
    if (establishmentId.isEmpty) return null;

    try {
      // D'abord essayer de récupérer par ID d'établissement
      final estDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(establishmentId)
          .get();

      if (estDoc.exists) {
        final userId = estDoc.data()?['user_id'];
        if (userId != null) {
          // Récupérer le wallet pour avoir les données bancaires
          final walletQuery = await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('wallets')
              .where('user_id', isEqualTo: userId)
              .limit(1)
              .get();

          if (walletQuery.docs.isNotEmpty) {
            return walletQuery.docs.first.data()['bank_details'];
          }
        }
      }
    } catch (e) {
      print('Erreur récupération données bancaires: $e');
    }
    return null;
  }

  // Helper pour récupérer le nom d'un utilisateur
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? userDoc.data()?['email'] ?? 'Inconnu';
      }
    } catch (e) {
      print('Erreur récupération nom utilisateur: $e');
    }
    return 'Inconnu';
  }

  // Helper pour formater une date (version voucher)
  String _formatVoucherDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else {
        return 'N/A';
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper pour masquer l'IBAN
  String _maskIban(String iban) {
    if (iban.length <= 8) return iban;
    return '${iban.substring(0, 4)}...${iban.substring(iban.length - 4)}';
  }

  // Helper pour construire une ligne d'info
  Widget _buildVoucherInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
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
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Ancienne méthode pour afficher une carte de bon cadeau (vue grille)
  Widget _buildVoucherCard(
      Map<String, dynamic> voucher, AdminPointsRequestsScreenController cc) {
    final isRenewed = voucher['is_renewed'] ?? false;
    final status = voucher['status'] ?? 'active';
    final primaryColor = isRenewed
        ? Colors.purple[600]!
        : (status == 'used' ? Colors.green[600]! : Colors.blue[600]!);

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
          onTap: () => _showVoucherDetails(voucher, cc),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec type de bon
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
                          isRenewed ? Icons.refresh : Icons.card_giftcard,
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
                            isRenewed ? 'Bon Renouvelé' : 'Bon Normal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                          Text(
                            'Code: ${voucher['code'] ?? 'N/A'}',
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

                // Boutique
                Text(
                  voucher['establishment_name'] ?? 'Boutique inconnue',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 8),

                // Valeur
                Text(
                  '${voucher['value'] ?? 50}€',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                Spacer(),

                // Footer avec statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Statut
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == 'used' ? 'Utilisé' : 'Actif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    // Si renouvelé, afficher le montant dû
                    if (isRenewed)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: voucher['payment_status'] == 'paid'
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              voucher['payment_status'] == 'paid'
                                  ? Icons.check
                                  : Icons.euro,
                              size: 14,
                              color: voucher['payment_status'] == 'paid'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                            SizedBox(width: 4),
                            Text(
                              voucher['payment_status'] == 'paid'
                                  ? 'Payé'
                                  : '${voucher['ventemoi_owes']}€ dû',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: voucher['payment_status'] == 'paid'
                                    ? Colors.green[700]
                                    : Colors.orange[700],
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

  // Nouvelle méthode pour afficher une carte de bon cadeau (vue liste)
  Widget _buildVoucherListCard(Map<String, dynamic> voucher,
      AdminPointsRequestsScreenController cc, bool isTablet) {
    final isRenewed = voucher['is_renewed'] ?? false;
    final status = voucher['status'] ?? 'active';
    final primaryColor = isRenewed
        ? Colors.purple[600]!
        : (status == 'used' ? Colors.green[600]! : Colors.blue[600]!);

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
          onTap: () => _showVoucherDetails(voucher, cc),
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
                      isRenewed ? Icons.refresh : Icons.card_giftcard,
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
                              voucher['establishment_name'] ?? 'Boutique',
                              style: TextStyle(
                                fontSize: isTablet ? 17 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                          // Valeur
                          Text(
                            '${voucher['value'] ?? 50}€',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text(
                            voucher['code'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 16),
                          if (isRenewed)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'RENOUVELÉ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.purple[700],
                                ),
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

  // Méthode pour afficher les détails d'un bon
  void _showVoucherDetails(
      Map<String, dynamic> voucher, AdminPointsRequestsScreenController cc) {
    final isRenewed = voucher['is_renewed'] ?? false;

    Get.dialog(
      AlertDialog(
        title: Text('Détails du Bon'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVoucherDetailRow('Code', voucher['code'] ?? 'N/A'),
              _buildVoucherDetailRow('Boutique', voucher['establishment_name'] ?? 'Inconnue'),
              _buildVoucherDetailRow('Valeur', '${voucher['value'] ?? 50}€'),
              _buildVoucherDetailRow('Statut', voucher['status'] ?? 'active'),
              if (isRenewed) ...[
                Divider(height: 20),
                _buildVoucherDetailRow('Type', 'Bon Renouvelé'),
                _buildVoucherDetailRow('Coût boutique', '${voucher['renewal_cost'] ?? 15}€'),
                _buildVoucherDetailRow('VenteMoi doit', '${voucher['ventemoi_owes'] ?? 35}€'),
                _buildVoucherDetailRow('Statut paiement', voucher['payment_status'] ?? 'pending'),
              ],
            ],
          ),
        ),
        actions: [
          if (isRenewed && voucher['payment_status'] != 'paid')
            TextButton(
              onPressed: () {
                Get.back();
                cc.markAsPaid(voucher['id']);
              },
              child: Text('Marquer comme payé'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
