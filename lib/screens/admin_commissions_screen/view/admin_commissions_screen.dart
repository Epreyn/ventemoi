import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/commission.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/admin_commissions_screen_controller.dart';

class AdminCommissionsScreen extends StatelessWidget {
  const AdminCommissionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(AdminCommissionsScreenController());
    final theme = Theme.of(context);

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
      ),
      fabOnPressed: cc.openCreateBottomSheet,
      fabIcon: const Icon(Icons.add_chart),
      fabText: const Text('Nouvelle commission'),
      body: CustomScrollView(
        slivers: [
          // Header avec graphique de visualisation
          SliverToBoxAdapter(
            child: Container(
              height: 250,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    theme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visualisation des commissions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: cc.openCommissionSimulator,
                        icon: const Icon(Icons.calculate),
                        tooltip: 'Simulateur',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() => _buildCommissionChart(cc, theme)),
                  ),
                ],
              ),
            ),
          ),

          // Statistiques
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() => _buildStatistics(cc, theme)),
            ),
          ),

          // Liste des commissions
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Obx(() {
              final list = cc.commissionsList;
              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(theme),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCommissionCard(
                    cc,
                    list[index],
                    theme,
                    index,
                  ),
                  childCount: list.length,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionChart(
      AdminCommissionsScreenController cc, ThemeData theme) {
    if (cc.commissionsList.isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée à afficher',
          style: TextStyle(color: theme.disabledColor),
        ),
      );
    }

    // Création des données pour le graphique
    final spots = <FlSpot>[];
    final commissions = cc.commissionsList;

    for (var comm in commissions) {
      spots.add(FlSpot(comm.minAmount, comm.percentage));
      if (!comm.isInfinite && comm.maxAmount > comm.minAmount) {
        spots.add(FlSpot(comm.maxAmount, comm.percentage));
      }
    }

    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.dividerColor.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: theme.dividerColor.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}€',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: theme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: theme.cardColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(
      AdminCommissionsScreenController cc, ThemeData theme) {
    final stats = cc.getCommissionStatistics();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            '${stats['total']}',
            Icons.dashboard,
            theme.primaryColor,
            theme,
          ),
          _buildStatItem(
            'Moyenne',
            '${stats['average'].toStringAsFixed(1)}%',
            Icons.percent,
            Colors.orange,
            theme,
          ),
          _buildStatItem(
            'Exceptions',
            '${stats['exceptions']}',
            Icons.person_outline,
            Colors.purple,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commission configurée',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première règle de commission',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionCard(
    AdminCommissionsScreenController cc,
    Commission comm,
    ThemeData theme,
    int index,
  ) {
    final hasException = comm.emailException.isNotEmpty;
    final color = hasException ? Colors.purple : theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasException ? color.withOpacity(0.3) : theme.dividerColor,
          width: hasException ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => cc.openEditBottomSheet(comm),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header avec indicateurs visuels
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${comm.percentage}%',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.euro,
                                  size: 16,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${comm.minAmount.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: theme.hintColor,
                                  ),
                                ),
                                if (comm.isInfinite) ...[
                                  Icon(
                                    Icons.all_inclusive,
                                    size: 20,
                                    color: theme.primaryColor,
                                  ),
                                ] else ...[
                                  Text(
                                    '${comm.maxAmount.toStringAsFixed(0)}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (hasException) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_pin,
                                    size: 14,
                                    color: color,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      comm.emailException,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (comm.associationPercentage > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.volunteer_activism,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comm.associationPercentage}%',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => cc.openEditBottomSheet(comm),
                            color: theme.primaryColor,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => cc.deleteCommission(comm.id),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Barre de progression visuelle
                  if (!hasException) ...[
                    const SizedBox(height: 12),
                    _buildRangeVisualization(comm, theme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeVisualization(Commission comm, ThemeData theme) {
    final maxDisplay = comm.isInfinite ? comm.minAmount * 2 : comm.maxAmount;
    final progress =
        comm.isInfinite ? 1.0 : (comm.maxAmount - comm.minAmount) / maxDisplay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.dividerColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.primaryColor.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Plage de montants',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            Text(
              comm.isInfinite
                  ? 'Illimitée'
                  : '${(comm.maxAmount - comm.minAmount).toStringAsFixed(0)}€',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
