import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../controllers/points_summary_screen_controller.dart';

class PointsSummaryScreen extends StatelessWidget {
  const PointsSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PointsSummaryScreenController());
    final isTablet = MediaQuery.of(context).size.width > 600;

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
      ),
      noFAB: true,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec titre
                _buildHeader(),
                const SizedBox(height: 24),
                
                // Cartes de résumé des points
                _buildPointsSummaryCards(controller, isTablet),
                const SizedBox(height: 24),

                // Section des bons d'achat - IMPORTANTE
                _buildVouchersSection(controller),
                const SizedBox(height: 24),

                // Graphique des tendances supprimé
                // _buildTrendsSection(controller),
                // const SizedBox(height: 24),

                // Section des filtres
                _buildFiltersSection(controller),
                const SizedBox(height: 16),

                // Liste des transactions
                _buildTransactionsList(controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 32,
              color: CustomTheme.lightScheme().primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Mon Portefeuille',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Toutes vos transactions au même endroit',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsSummaryCards(PointsSummaryScreenController controller, bool isTablet) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return isTablet
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildPointCard(
                    title: 'Points disponibles',
                    points: controller.currentPoints.value,
                    color: CustomTheme.lightScheme().primary,
                    icon: Icons.account_balance_wallet,
                    subtitle: 'Utilisables immédiatement',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPointCard(
                    title: 'Points en attente',
                    points: controller.pendingPoints.value,
                    color: Colors.orange,
                    icon: Icons.hourglass_empty,
                    subtitle: 'Validation en cours',
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildPointCard(
                  title: 'Points disponibles',
                  points: controller.currentPoints.value,
                  color: CustomTheme.lightScheme().primary,
                  icon: Icons.account_balance_wallet,
                  subtitle: 'Utilisables immédiatement',
                ),
                const SizedBox(height: 16),
                _buildPointCard(
                  title: 'Points en attente',
                  points: controller.pendingPoints.value,
                  color: Colors.orange,
                  icon: Icons.hourglass_empty,
                  subtitle: 'Validation en cours',
                ),
              ],
            );
    });
  }

  Widget _buildPointCard({
    required String title,
    required int points,
    required Color color,
    required IconData icon,
    required String subtitle,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: compact ? 20 : 24,
                ),
              ),
              const Spacer(),
              if (!compact)
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat('#,###').format(points),
                style: TextStyle(
                  fontSize: compact ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'pts',
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendsSection(PointsSummaryScreenController controller) {
    return Obx(() {
      if (controller.monthlyStats.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: CustomTheme.lightScheme().primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tendances mensuelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: controller.monthlyStats.entries.map((entry) {
                  final maxValue = controller.monthlyStats.values.reduce((a, b) => a > b ? a : b);
                  final height = maxValue > 0 ? (entry.value / maxValue) * 80 : 0.0;
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: CustomTheme.lightScheme().primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CustomTheme.lightScheme().primary,
                              CustomTheme.lightScheme().primary.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.key.split('/').first,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFiltersSection(PointsSummaryScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique des transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Obx(() => _buildFilterChip(
                label: 'Tout',
                value: 'all',
                selected: controller.selectedFilter.value == 'all',
                onSelected: () => controller.setFilter('all'),
              )),
              const SizedBox(width: 8),
              Obx(() => _buildFilterChip(
                label: 'Gains',
                value: 'earned',
                selected: controller.selectedFilter.value == 'earned',
                onSelected: () => controller.setFilter('earned'),
                color: Colors.green,
              )),
              const SizedBox(width: 8),
              Obx(() => _buildFilterChip(
                label: 'Dépenses',
                value: 'spent',
                selected: controller.selectedFilter.value == 'spent',
                onSelected: () => controller.setFilter('spent'),
                color: Colors.red,
              )),
              const SizedBox(width: 8),
              Obx(() => _buildFilterChip(
                label: 'En attente',
                value: 'pending',
                selected: controller.selectedFilter.value == 'pending',
                onSelected: () => controller.setFilter('pending'),
                color: Colors.orange,
              )),
              const SizedBox(width: 24),
              // Période
              Obx(() => _buildPeriodChip(
                label: '7j',
                value: '7',
                selected: controller.selectedPeriod.value == '7',
                onSelected: () => controller.setPeriod('7'),
              )),
              const SizedBox(width: 8),
              Obx(() => _buildPeriodChip(
                label: '30j',
                value: '30',
                selected: controller.selectedPeriod.value == '30',
                onSelected: () => controller.setPeriod('30'),
              )),
              const SizedBox(width: 8),
              Obx(() => _buildPeriodChip(
                label: 'Tout',
                value: 'all',
                selected: controller.selectedPeriod.value == 'all',
                onSelected: () => controller.setPeriod('all'),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    final chipColor = color ?? CustomTheme.lightScheme().primary;
    
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      side: BorderSide(
        color: selected ? chipColor : Colors.grey[300]!,
        width: selected ? 2 : 1,
      ),
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: CustomTheme.lightScheme().primary.withOpacity(0.2),
    );
  }

  Widget _buildTransactionsList(PointsSummaryScreenController controller) {
    return Obx(() {
      final transactions = controller.filteredTransactions;
      
      if (transactions.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune transaction',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos transactions apparaîtront ici',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: transactions.map((transaction) {
            return _buildTransactionItem(transaction, controller);
          }).toList(),
        ),
      );
    });
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction, PointsSummaryScreenController controller) {
    final type = transaction['type'] ?? '';
    final points = transaction['points'] ?? 0;
    final description = transaction['description'] ?? '';
    final date = transaction['date'] as Timestamp?;
    final status = transaction['status'] ?? 'completed';
    final recipientName = transaction['recipient_name'] ?? '';
    final senderName = transaction['sender_name'] ?? '';

    final color = controller.getTransactionColorDetailed(transaction);
    final icon = controller.getTransactionIcon(transaction);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (type == 'spent' && recipientName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.store, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Chez: $recipientName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else if (type == 'earned' && senderName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'De: $senderName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      date != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(date.toDate())
                          : 'Date inconnue',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    type == 'spent' ? '-' : '+',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    NumberFormat('#,###').format(points),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    ' pts',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              if (status == 'pending')
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 10, color: Colors.orange),
                      const SizedBox(width: 4),
                      const Text(
                        'En attente',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVouchersSection(PointsSummaryScreenController controller) {
    return Obx(() {
      if (controller.vouchers.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun bon d\'achat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vos bons apparaîtront ici après vos achats',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CustomTheme.lightScheme().primary.withOpacity(0.05),
              CustomTheme.lightScheme().primary.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CustomTheme.lightScheme().primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.confirmation_number,
                    color: CustomTheme.lightScheme().primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes bons d\'achat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    Text(
                      'Cliquez sur un bon pour voir le code',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CustomTheme.lightScheme().primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${controller.vouchers.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.vouchers.length,
                itemBuilder: (context, index) {
                  final voucher = controller.vouchers[index];
                  return _buildVoucherCard(voucher);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final establishmentName = voucher['establishment_name'] ?? 'Établissement';
    final pointsValue = voucher['points_value'] ?? 0;
    final status = voucher['status'] ?? 'active';
    final voucherCode = voucher['voucher_code'] ?? '';
    final expiryDate = voucher['expiry_date'];
    final createdAt = voucher['created_at'];

    return GestureDetector(
      onTap: () => _showVoucherDetails(voucher),
      child: Container(
        width: 220,
        height: 160, // Hauteur augmentée pour éviter l'overflow
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: status == 'used'
                ? [Colors.grey[400]!, Colors.grey[600]!]
                : [
                    CustomTheme.lightScheme().primary,
                    CustomTheme.lightScheme().primary.withOpacity(0.8),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: status == 'used'
                  ? Colors.grey.withOpacity(0.3)
                  : CustomTheme.lightScheme().primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.store,
                      color: Colors.white.withOpacity(0.9),
                      size: 24,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BON',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  establishmentName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (voucherCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    voucherCode,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$pointsValue',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'points',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                if (status == 'used')
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Utilisé',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (expiryDate != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Text(
                      _getExpiryText(expiryDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getExpiryText(String expiryDate) {
    try {
      final expiry = DateTime.parse(expiryDate);
      final daysRemaining = expiry.difference(DateTime.now()).inDays;
      if (daysRemaining <= 0) return 'Expiré';
      if (daysRemaining == 1) return 'Expire dans 1 jour';
      if (daysRemaining <= 7) return 'Expire dans $daysRemaining jours';
      if (daysRemaining <= 30) return 'Expire dans ${(daysRemaining / 7).round()} sem.';
      return 'Expire le ${DateFormat('dd/MM').format(expiry)}';
    } catch (e) {
      return '';
    }
  }

  void _showVoucherDetails(Map<String, dynamic> voucher) {
    final establishmentName = voucher['establishment_name'] ?? 'Établissement';
    final pointsValue = voucher['points_value'] ?? 0;
    final status = voucher['status'] ?? 'active';
    final voucherCode = voucher['voucher_code'] ?? '';
    final expiryDate = voucher['expiry_date'];
    final createdAt = voucher['created_at'];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bon d\'achat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Code du bon
              if (voucherCode.isNotEmpty && status == 'active') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CustomTheme.lightScheme().primary.withOpacity(0.1),
                        CustomTheme.lightScheme().primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        size: 48,
                        color: CustomTheme.lightScheme().primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CODE DU BON',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          voucherCode,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: CustomTheme.lightScheme().primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Informations
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.store, 'Établissement', establishmentName),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.confirmation_number, 'Valeur', '$pointsValue points'),
                    const SizedBox(height: 12),
                    if (createdAt != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Date d\'achat',
                        DateFormat('dd/MM/yyyy').format((createdAt as Timestamp).toDate()),
                      ),
                    const SizedBox(height: 12),
                    if (expiryDate != null)
                      _buildInfoRow(
                        Icons.event_busy,
                        'Date d\'expiration',
                        DateFormat('dd/MM/yyyy').format(DateTime.parse(expiryDate)),
                      ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.info_outline,
                      'Statut',
                      status == 'active' ? 'Actif' : 'Utilisé',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CustomTheme.lightScheme().primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CustomTheme.lightScheme().primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: CustomTheme.lightScheme().primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Comment utiliser ce bon ?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CustomTheme.lightScheme().primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Présentez-vous dans la boutique\n'
                      '2. Donnez votre code au commerçant\n'
                      '3. Le commerçant validera votre bon\n'
                      '4. Profitez de votre réduction !',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}