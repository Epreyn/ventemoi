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
      final list = cc.filteredRequests ?? cc.requests;

      return CustomScrollView(
        slivers: [
          // Header moderne
          SliverToBoxAdapter(
            child: ModernPageHeader(
              title: "Demandes de Bons",
              subtitle: "Validez les demandes de points",
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
                    child: _buildCompactRequestCard(list[index], cc),
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
                      child: _buildListRequestCard(list[index], cc, isTablet),
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

  Widget _buildMinimalStats(AdminPointsRequestsScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Obx(() {
        final stats = cc.requestStats;
        return Row(
          children: [
            _buildStatChip(
              label: 'Total',
              value: stats['total'] ?? 0,
              color: Colors.grey[800]!,
              icon: Icons.receipt_long,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Bons demandés',
              value: stats['totalCoupons'] ?? 0,
              color: Colors.blue[600]!,
              icon: Icons.confirmation_number,
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
                      '${cc.filteredRequests?.length ?? cc.requests.length} résultats',
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
            'Aucune demande de bons',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les demandes apparaîtront ici',
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
}
