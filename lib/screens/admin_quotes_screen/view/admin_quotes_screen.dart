import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/quote_request.dart';
import '../../../core/widgets/modern_page_header.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_quotes_screen_controller.dart';

class AdminQuotesScreen extends GetView<AdminQuotesScreenController> {
  const AdminQuotesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminQuotesScreenController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return ScreenLayout(
      appBar: CustomAppBar(title: Text(cc.pageTitle)),
      body: _buildBody(context, cc, isDesktop, isTablet),
    );
  }

  Widget _buildBody(BuildContext context,
      AdminQuotesScreenController cc, bool isDesktop, bool isTablet) {
    return Obx(() {
      final list = cc.filteredQuotes;

      return CustomScrollView(
        slivers: [
          // Header moderne
          SliverToBoxAdapter(
            child: ModernPageHeader(
              title: "Gestion des Devis",
              subtitle: "Suivi et attribution des demandes de devis",
              icon: Icons.description,
            ),
          ),
          // Stats et recherche
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatistics(cc),
                _buildSearchAndFilters(cc),
              ],
            ),
          ),
          // Liste des devis
          if (list.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildQuoteCard(list[index], cc, isDesktop),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildStatistics(AdminQuotesScreenController cc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Obx(() {
        final stats = cc.quoteStats;
        return Row(
          children: [
            _buildStatChip(
              label: 'Total',
              value: stats['total'],
              color: Colors.grey[800]!,
              icon: Icons.description,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'En attente',
              value: stats['pending'],
              color: Colors.orange[600]!,
              icon: Icons.pending,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Assignés',
              value: stats['assigned'],
              color: Colors.blue[600]!,
              icon: Icons.assignment,
            ),
            SizedBox(width: 16),
            _buildStatChip(
              label: 'Terminés',
              value: stats['completed'],
              color: Colors.green[600]!,
              icon: Icons.check_circle,
            ),
            Spacer(),
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
                      '${cc.filteredQuotes.length} résultats',
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

  Widget _buildSearchAndFilters(AdminQuotesScreenController cc) {
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
                  hintText: 'Rechercher par client, type, description...',
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
          // Filtre par statut
          _buildStatusFilter(cc),
          SizedBox(width: 12),
          // Filtre par type
          _buildTypeFilter(cc),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(AdminQuotesScreenController cc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Obx(() => DropdownButton<String>(
            value: cc.filterStatus.value,
            underline: SizedBox(),
            borderRadius: BorderRadius.circular(12),
            padding: EdgeInsets.symmetric(horizontal: 12),
            items: [
              DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
              DropdownMenuItem(value: 'pending', child: Text('En attente')),
              DropdownMenuItem(value: 'assigned', child: Text('Assignés')),
              DropdownMenuItem(value: 'completed', child: Text('Terminés')),
              DropdownMenuItem(value: 'cancelled', child: Text('Annulés')),
            ],
            onChanged: (value) {
              if (value != null) cc.onStatusFilterChanged(value);
            },
          )),
    );
  }

  Widget _buildTypeFilter(AdminQuotesScreenController cc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Obx(() => DropdownButton<String>(
            value: cc.filterType.value,
            underline: SizedBox(),
            borderRadius: BorderRadius.circular(12),
            padding: EdgeInsets.symmetric(horizontal: 12),
            items: [
              DropdownMenuItem(value: 'all', child: Text('Tous les types')),
              DropdownMenuItem(value: 'renovation', child: Text('Rénovation')),
              DropdownMenuItem(value: 'construction', child: Text('Construction')),
              DropdownMenuItem(value: 'plomberie', child: Text('Plomberie')),
              DropdownMenuItem(value: 'electricite', child: Text('Électricité')),
              DropdownMenuItem(value: 'autre', child: Text('Autre')),
            ],
            onChanged: (value) {
              if (value != null) cc.onTypeFilterChanged(value);
            },
          )),
    );
  }

  Widget _buildQuoteCard(QuoteRequest quote, AdminQuotesScreenController cc, bool isDesktop) {
    final statusColor = cc.getStatusColor(quote.status);
    final statusLabel = cc.getStatusLabel(quote.status);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showQuoteDetails(quote, cc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cc.getUserName(quote.userId),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          quote.projectType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Description
              Text(
                quote.projectDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              // Infos supplémentaires
              Row(
                children: [
                  Icon(Icons.euro, size: 16, color: Colors.green[600]),
                  SizedBox(width: 4),
                  Text(
                    '${quote.estimatedBudget ?? 'Non défini'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(quote.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (quote.assignedTo != null) ...[
                    SizedBox(width: 16),
                    Icon(Icons.business, size: 16, color: Colors.blue[600]),
                    SizedBox(width: 4),
                    Text(
                      cc.getEnterpriseName(quote.assignedTo!),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
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
              Icons.description,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Aucune demande de devis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les demandes de devis apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuoteDetails(QuoteRequest quote, AdminQuotesScreenController cc) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 600,
          constraints: BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cc.getStatusColor(quote.status),
                      cc.getStatusColor(quote.status).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails du devis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'ID: ${quote.id}',
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
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection(
                        title: 'Informations client',
                        children: [
                          _buildDetailRow('Nom', quote.userName ?? cc.getUserName(quote.userId)),
                          _buildDetailRow('Email', quote.userEmail ?? 'Non fourni'),
                          _buildDetailRow('Téléphone', quote.userPhone ?? 'Non fourni'),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildDetailSection(
                        title: 'Détails du projet',
                        children: [
                          _buildDetailRow('Type', quote.projectType),
                          _buildDetailRow('Budget estimé', quote.estimatedBudget ?? 'Non défini'),
                          _buildDetailRow('Description', quote.projectDescription),
                          _buildDetailRow('Date de création', _formatDateTime(quote.createdAt)),
                        ],
                      ),
                      if (quote.assignedTo != null) ...[
                        SizedBox(height: 20),
                        _buildDetailSection(
                          title: 'Attribution',
                          children: [
                            _buildDetailRow('Entreprise', cc.getEnterpriseName(quote.assignedTo!)),
                            if (quote.assignedAt != null)
                              _buildDetailRow('Date d\'attribution', _formatDateTime(quote.assignedAt!)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (quote.status == 'pending')
                      ElevatedButton.icon(
                        onPressed: () => _showAssignDialog(quote, cc),
                        icon: Icon(Icons.assignment),
                        label: Text('Assigner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                        ),
                      ),
                    SizedBox(width: 8),
                    if (quote.status != 'completed')
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          cc.updateQuoteStatus(quote.id, 'completed');
                        },
                        icon: Icon(Icons.check),
                        label: Text('Marquer terminé'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                        ),
                      ),
                    SizedBox(width: 8),
                    if (quote.status != 'cancelled')
                      ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          cc.updateQuoteStatus(quote.id, 'cancelled');
                        },
                        icon: Icon(Icons.cancel),
                        label: Text('Annuler'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
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

  void _showAssignDialog(QuoteRequest quote, AdminQuotesScreenController cc) {
    // TODO: Implémenter le dialogue d'attribution à une entreprise
    Get.snackbar('TODO', 'Dialogue d\'attribution à implémenter');
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
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
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}