import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/client_history_screen_controller.dart';
import '../widgets/purchase_ticket_card.dart';

class ClientHistoryScreen extends StatelessWidget {
  const ClientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc =
        Get.put(ClientHistoryScreenController(), tag: 'client-history-screen');
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
        showGreeting: true,
      ),
      noFAB: true,
      body: Column(
        children: [
          // Header avec filtres et tri
          Container(
            padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de la section
                CustomCardAnimation(
                  index: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes achats',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const CustomSpace(heightMultiplier: 0.5),
                          Obx(() => Text(
                                '${cc.purchases.length} transaction${cc.purchases.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              )),
                        ],
                      ),
                      // Bouton de tri glassmorphique
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showSortOptions(context, cc),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        UniquesControllers().data.baseSpace * 2,
                                    vertical:
                                        UniquesControllers().data.baseSpace,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sort_rounded,
                                        size: 20,
                                        color:
                                            CustomTheme.lightScheme().primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Trier',
                                        style: TextStyle(
                                          color:
                                              CustomTheme.lightScheme().primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const CustomSpace(heightMultiplier: 2),
                // Chips de filtre rapide
                CustomCardAnimation(
                  index: 1,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(() => Row(
                          children: [
                            _buildFilterChip(
                                'Tous',
                                cc.selectedFilter.value == 'all',
                                () => cc.setFilter('all')),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                                'En attente',
                                cc.selectedFilter.value == 'pending',
                                () => cc.setFilter('pending')),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                                'Récupérés',
                                cc.selectedFilter.value == 'claimed',
                                () => cc.setFilter('claimed')),
                          ],
                        )),
                  ),
                ),
              ],
            ),
          ),
          // Liste des tickets
          Expanded(
            child: Obx(() {
              final filteredList = cc.filteredPurchases;
              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CustomTheme.lightScheme()
                              .primary
                              .withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 50,
                          color: CustomTheme.lightScheme()
                              .primary
                              .withOpacity(0.5),
                        ),
                      ),
                      const CustomSpace(heightMultiplier: 2),
                      Text(
                        cc.selectedFilter.value == 'all'
                            ? 'Aucun achat pour l\'instant'
                            : 'Aucun résultat pour ce filtre',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(
                  left: UniquesControllers().data.baseSpace * 2,
                  right: UniquesControllers().data.baseSpace * 2,
                  bottom: UniquesControllers().data.baseSpace * 4,
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  return CustomCardAnimation(
                    index: index,
                    delayGap:
                        UniquesControllers().data.baseArrayDelayGapAnimation,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: UniquesControllers().data.baseSpace * 2,
                      ),
                      child: PurchaseTicketCard(
                        purchase: filteredList[index],
                        isTablet: isTablet,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? CustomTheme.lightScheme().primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? CustomTheme.lightScheme().primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: UniquesControllers().data.baseSpace * 2,
                  vertical: UniquesControllers().data.baseSpace * 0.8,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? CustomTheme.lightScheme().primary
                        : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSortOptions(
      BuildContext context, ClientHistoryScreenController cc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: CustomTheme.lightScheme().surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trier par',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                  Obx(() => Column(
                        children: [
                          _buildSortOption(
                            'Date (plus récent)',
                            Icons.calendar_today,
                            cc.sortBy.value == 'date' &&
                                !cc.sortAscending.value,
                            () {
                              cc.setSortBy('date', false);
                              Navigator.pop(context);
                            },
                          ),
                          _buildSortOption(
                            'Date (plus ancien)',
                            Icons.calendar_today,
                            cc.sortBy.value == 'date' && cc.sortAscending.value,
                            () {
                              cc.setSortBy('date', true);
                              Navigator.pop(context);
                            },
                          ),
                          _buildSortOption(
                            'Montant (croissant)',
                            Icons.arrow_upward,
                            cc.sortBy.value == 'amount' &&
                                cc.sortAscending.value,
                            () {
                              cc.setSortBy('amount', true);
                              Navigator.pop(context);
                            },
                          ),
                          _buildSortOption(
                            'Montant (décroissant)',
                            Icons.arrow_downward,
                            cc.sortBy.value == 'amount' &&
                                !cc.sortAscending.value,
                            () {
                              cc.setSortBy('amount', false);
                              Navigator.pop(context);
                            },
                          ),
                          _buildSortOption(
                            'Établissement (A-Z)',
                            Icons.store,
                            cc.sortBy.value == 'seller' &&
                                cc.sortAscending.value,
                            () {
                              cc.setSortBy('seller', true);
                              Navigator.pop(context);
                            },
                          ),
                          _buildSortOption(
                            'Statut',
                            Icons.flag,
                            cc.sortBy.value == 'status',
                            () {
                              cc.setSortBy('status', true);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      )),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: UniquesControllers().data.baseSpace * 2,
            horizontal: UniquesControllers().data.baseSpace * 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? CustomTheme.lightScheme().primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? CustomTheme.lightScheme().primary
                    : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? CustomTheme.lightScheme().primary
                        : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: CustomTheme.lightScheme().primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
