import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Imports internes
import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/widgets/modern_page_header.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/pro_sells_screen_controller.dart';
import '../widgets/pro_sells_buyer_email_cell.dart';
import '../widgets/pro_sells_buyer_name_cell.dart';

// Widget personnalisé pour l'animation d'apparition qui ne se rejoue pas
class InitialFadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final String uniqueKey;

  const InitialFadeAnimation({
    Key? key,
    required this.child,
    required this.delay,
    required this.uniqueKey,
  }) : super(key: key);

  @override
  State<InitialFadeAnimation> createState() => _InitialFadeAnimationState();
}

class _InitialFadeAnimationState extends State<InitialFadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  static final Set<String> _animatedKeys = {};

  // Méthode statique pour réinitialiser toutes les animations
  static void resetAllAnimations() {
    _animatedKeys.clear();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Ne jouer l'animation qu'une seule fois par key
    if (!_animatedKeys.contains(widget.uniqueKey)) {
      _animatedKeys.add(widget.uniqueKey);
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class ProSellsScreen extends StatelessWidget {
  const ProSellsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ProSellsScreenController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 400;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ScreenLayout(
      noFAB: true,
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
      ),
      body: Obx(() {
        final list = cc.filteredPurchases;

        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 700 : 500,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header moderne
                    const ModernPageHeader(
                      title: "Mes Ventes",
                      subtitle: "Suivez vos transactions",
                      icon: Icons.shopping_cart_rounded,
                    ),
                    const CustomSpace(heightMultiplier: 2),
                    
                    // Section Statistiques
                    _buildStatisticsSection(cc, isMobile),
                    const CustomSpace(heightMultiplier: 3),

                    // Section Filtres et Tri
                    _buildFiltersSection(cc, list, isTablet, isMobile),
                    const CustomSpace(heightMultiplier: 3),

                    // Titre de section avec compteur
                    _buildSectionTitle(list),
                    const CustomSpace(heightMultiplier: 2),

                    // Liste des ventes
                    if (list.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        key: const ValueKey('purchases-list'),
                        children: list
                            .asMap()
                            .entries
                            .map((entry) =>
                                _buildPurchaseCard(entry.key, entry.value, cc))
                            .toList(),
                      ),

                    const CustomSpace(heightMultiplier: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatisticsSection(ProSellsScreenController cc, bool isMobile) {
    return CustomCardAnimation(
      key: const ValueKey('statistics-section'),
      index: 0,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          UniquesControllers().data.baseSpace * (isMobile ? 2 : 3),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.35),
              Colors.white.withOpacity(0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: CustomTheme.lightScheme().primary.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: isMobile
            ? Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.shopping_cart_rounded,
                      label: 'Total des ventes',
                      value: '${cc.purchases.length}',
                      bgColor: CustomTheme.lightScheme().primary.withOpacity(0.1),
                      iconColor: CustomTheme.lightScheme().primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.euro_rounded,
                      label: 'Valeur totale',
                      value:
                          '${cc.purchases.fold(0, (sum, p) => sum + (p.couponsCount * 50))}€',
                      bgColor: CustomTheme.lightScheme()
                          .primary
                          .withOpacity(0.1),
                      iconColor: CustomTheme.lightScheme().primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.check_circle_rounded,
                      label: 'Récupérées',
                      value:
                          '${cc.purchases.where((p) => p.isReclaimed).length}',
                      bgColor: CustomTheme.lightScheme()
                          .primary
                          .withOpacity(0.3),
                      iconColor: CustomTheme.lightScheme().primary,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Total des ventes',
                    value: '${cc.purchases.length}',
                    bgColor: CustomTheme.lightScheme().primary.withOpacity(0.1),
                    iconColor: CustomTheme.lightScheme().primary,
                  ),
                  _buildStatItem(
                    icon: Icons.euro_rounded,
                    label: 'Valeur totale',
                    value:
                        '${cc.purchases.fold(0, (sum, p) => sum + (p.couponsCount * 50))}€',
                    bgColor: CustomTheme.lightScheme().primary.withOpacity(0.1),
                    iconColor: CustomTheme.lightScheme().primary,
                  ),
                  _buildStatItem(
                    icon: Icons.check_circle_rounded,
                    label: 'Récupérées',
                    value: '${cc.purchases.where((p) => p.isReclaimed).length}',
                    bgColor: CustomTheme.lightScheme().primary.withOpacity(0.1),
                    iconColor: CustomTheme.lightScheme().primary,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFiltersSection(
      ProSellsScreenController cc, List list, bool isTablet, bool isMobile) {
    return CustomCardAnimation(
      key: const ValueKey('filters-section'),
      index: 1,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          UniquesControllers().data.baseSpace * 2.5,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.35),
              Colors.white.withOpacity(0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche
            TextField(
              controller: cc.searchController,
              onChanged: (_) => cc.applyFilters(),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou email...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                ),
                suffixIcon: cc.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          cc.searchController.clear();
                          cc.applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: UniquesControllers().data.baseSpace * 2,
                  vertical: UniquesControllers().data.baseSpace * 1.5,
                ),
              ),
            ),
            const CustomSpace(heightMultiplier: 2),

            // Version mobile : tout en colonne
            if (isMobile) ...[
              // Filtres de statut
              Text(
                'Statut',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: UniquesControllers().data.baseSpace,
                runSpacing: UniquesControllers().data.baseSpace,
                children: [
                  _buildFilterChip(
                    label: 'Toutes',
                    isSelected: cc.filterStatus.value == 'all',
                    onTap: () => cc.setFilter('all'),
                  ),
                  _buildFilterChip(
                    label: 'Non récupérées',
                    isSelected: cc.filterStatus.value == 'pending',
                    onTap: () => cc.setFilter('pending'),
                    icon: Icons.schedule,
                  ),
                  _buildFilterChip(
                    label: 'Récupérées',
                    isSelected: cc.filterStatus.value == 'reclaimed',
                    onTap: () => cc.setFilter('reclaimed'),
                    icon: Icons.check_circle,
                  ),
                ],
              ),
              const CustomSpace(heightMultiplier: 2),
              // Filtres de période
              Text(
                'Période',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: UniquesControllers().data.baseSpace,
                runSpacing: UniquesControllers().data.baseSpace,
                children: [
                  _buildFilterChip(
                    label: 'Toute période',
                    isSelected: cc.periodFilter.value == 'all',
                    onTap: () => cc.setPeriodFilter('all'),
                  ),
                  _buildFilterChip(
                    label: 'Aujourd\'hui',
                    isSelected: cc.periodFilter.value == 'today',
                    onTap: () => cc.setPeriodFilter('today'),
                  ),
                  _buildFilterChip(
                    label: 'Cette semaine',
                    isSelected: cc.periodFilter.value == 'week',
                    onTap: () => cc.setPeriodFilter('week'),
                  ),
                  _buildFilterChip(
                    label: 'Ce mois',
                    isSelected: cc.periodFilter.value == 'month',
                    onTap: () => cc.setPeriodFilter('month'),
                  ),
                ],
              ),
              const CustomSpace(heightMultiplier: 2),
              // Boutons d'action
              Row(
                children: [
                  if (list.isNotEmpty) Expanded(child: _buildExportButton()),
                  if (list.isNotEmpty) const SizedBox(width: 12),
                  Expanded(child: _buildSortButton(cc)),
                ],
              ),
            ] else ...[
              // Version tablette/desktop
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtres de statut et période
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filtres de statut
                        Wrap(
                          spacing: UniquesControllers().data.baseSpace,
                          runSpacing: UniquesControllers().data.baseSpace,
                          children: [
                            _buildFilterChip(
                              label: 'Toutes',
                              isSelected: cc.filterStatus.value == 'all',
                              onTap: () => cc.setFilter('all'),
                            ),
                            _buildFilterChip(
                              label: 'Non récupérées',
                              isSelected: cc.filterStatus.value == 'pending',
                              onTap: () => cc.setFilter('pending'),
                              icon: Icons.schedule,
                            ),
                            _buildFilterChip(
                              label: 'Récupérées',
                              isSelected: cc.filterStatus.value == 'reclaimed',
                              onTap: () => cc.setFilter('reclaimed'),
                              icon: Icons.check_circle,
                            ),
                          ],
                        ),
                        const CustomSpace(heightMultiplier: 1.5),
                        // Filtres de période
                        Wrap(
                          spacing: UniquesControllers().data.baseSpace,
                          runSpacing: UniquesControllers().data.baseSpace,
                          children: [
                            _buildFilterChip(
                              label: 'Toute période',
                              isSelected: cc.periodFilter.value == 'all',
                              onTap: () => cc.setPeriodFilter('all'),
                            ),
                            _buildFilterChip(
                              label: 'Aujourd\'hui',
                              isSelected: cc.periodFilter.value == 'today',
                              onTap: () => cc.setPeriodFilter('today'),
                            ),
                            _buildFilterChip(
                              label: 'Cette semaine',
                              isSelected: cc.periodFilter.value == 'week',
                              onTap: () => cc.setPeriodFilter('week'),
                            ),
                            _buildFilterChip(
                              label: 'Ce mois',
                              isSelected: cc.periodFilter.value == 'month',
                              onTap: () => cc.setPeriodFilter('month'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Boutons d'action
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (list.isNotEmpty) _buildExportButton(),
                          if (list.isNotEmpty) const SizedBox(width: 12),
                          _buildSortButton(cc),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // Bouton pour effacer les filtres si actifs
            Obx(() {
              if (cc.hasActiveFilters) {
                return Column(
                  children: [
                    const CustomSpace(heightMultiplier: 2),
                    Center(
                      child: TextButton.icon(
                        onPressed: cc.clearFilters,
                        icon: Icon(
                          Icons.clear_all,
                          size: 20,
                          color: Colors.red[400],
                        ),
                        label: Text(
                          'Réinitialiser les filtres',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: UniquesControllers().data.baseSpace * 2,
                            vertical: UniquesControllers().data.baseSpace,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.red[400]!.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(List list) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Historique des ventes',
          style: TextStyle(
            fontSize: UniquesControllers().data.baseSpace * 2.5,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        if (list.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: UniquesControllers().data.baseSpace * 1.5,
              vertical: UniquesControllers().data.baseSpace * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${list.length} résultat${list.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: UniquesControllers().data.baseSpace * 1.6,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomCardAnimation(
      key: const ValueKey('empty-state'),
      index: 2,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          UniquesControllers().data.baseSpace * 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.35),
              Colors.white.withOpacity(0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const CustomSpace(heightMultiplier: 2),
            Text(
              'Aucune vente pour le moment',
              style: TextStyle(
                fontSize: UniquesControllers().data.baseSpace * 2,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(
      int index, dynamic purchase, ProSellsScreenController cc) {
    final isDonation = purchase.couponsCount == 0;
    final dateFr =
        DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(purchase.date);

    return InitialFadeAnimation(
      uniqueKey: 'purchase-${purchase.id}',
      delay: Duration(milliseconds: math.min(50 + (30 * index), 300)),
      child: Padding(
        key: ValueKey('purchase-${purchase.id}'),
        padding: EdgeInsets.only(
          bottom: UniquesControllers().data.baseSpace * 2,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            UniquesControllers().data.baseSpace * 2.5,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: purchase.isReclaimed
                  ? [
                      CustomTheme.lightScheme().primary.withOpacity(0.08),
                      CustomTheme.lightScheme().primary.withOpacity(0.04),
                    ]
                  : [
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.25),
                    ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: purchase.isReclaimed
                  ? CustomTheme.lightScheme().primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: purchase.isReclaimed
                    ? CustomTheme.lightScheme().primary.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // En-tête avec statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Info principale
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isDonation ? Colors.black87 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            isDonation
                                ? Icons.volunteer_activism
                                : Icons.confirmation_number,
                            color: isDonation ? Colors.white : Colors.black87,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDonation
                                    ? 'Don'
                                    : '${purchase.couponsCount} bon${purchase.couponsCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 2.2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFr,
                                style: TextStyle(
                                  fontSize:
                                      UniquesControllers().data.baseSpace * 1.5,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Montant
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 2,
                      vertical: UniquesControllers().data.baseSpace * 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${purchase.couponsCount * 50}€',
                      style: TextStyle(
                        fontSize: UniquesControllers().data.baseSpace * 2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const CustomSpace(heightMultiplier: 2),

              // Infos acheteur
              Container(
                padding: EdgeInsets.all(
                  UniquesControllers().data.baseSpace * 1.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProSellsBuyerNameCell(
                            buyerId: purchase.buyerId,
                          ),
                          const SizedBox(height: 4),
                          ProSellsBuyerEmailCell(
                            buyerId: purchase.buyerId,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const CustomSpace(heightMultiplier: 2),

              // Statut / Action
              if (purchase.isReclaimed)
                _buildReclaimedStatus()
              else
                _buildValidateButton(purchase, cc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReclaimedStatus() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 2,
        vertical: UniquesControllers().data.baseSpace * 1.5,
      ),
      decoration: BoxDecoration(
        color: CustomTheme.lightScheme().primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: CustomTheme.lightScheme().primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: CustomTheme.lightScheme().primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Récupéré',
            style: TextStyle(
              color: CustomTheme.lightScheme().primary,
              fontWeight: FontWeight.w600,
              fontSize: UniquesControllers().data.baseSpace * 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidateButton(dynamic purchase, ProSellsScreenController cc) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CustomTheme.lightScheme().primary,
            CustomTheme.lightScheme().primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CustomTheme.lightScheme().primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            cc.editingPurchase.value = purchase;
            cc.openReclaimDialog();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: UniquesControllers().data.baseSpace * 3,
              vertical: UniquesControllers().data.baseSpace * 1.5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'VALIDER LA RÉCUPÉRATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Implémenter l'export CSV
            UniquesControllers().data.snackbar(
                  'Export',
                  'Fonctionnalité d\'export en cours de développement',
                  false,
                );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: UniquesControllers().data.baseSpace * 2,
              vertical: UniquesControllers().data.baseSpace * 1.2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download,
                  color: Colors.grey[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Export',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton(ProSellsScreenController cc) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      offset: const Offset(0, 40),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 2,
          vertical: UniquesControllers().data.baseSpace * 1.2,
        ),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sort,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Trier',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'date_desc',
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text('Plus récentes'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'date_asc',
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text('Plus anciennes'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'amount_desc',
          child: Row(
            children: [
              Icon(Icons.euro, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text('Montant décroissant'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'amount_asc',
          child: Row(
            children: [
              Icon(Icons.euro, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text('Montant croissant'),
            ],
          ),
        ),
      ],
      onSelected: (value) => cc.setSortOrder(value),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color iconColor,
    Color? textColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
        ),
        const CustomSpace(heightMultiplier: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: UniquesControllers().data.baseSpace * 2.5,
            fontWeight: FontWeight.w700,
            color: textColor ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: UniquesControllers().data.baseSpace * 1.5,
            color: textColor?.withOpacity(0.7) ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: UniquesControllers().data.baseSpace * 1.5,
          vertical: UniquesControllers().data.baseSpace * 0.8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? CustomTheme.lightScheme().primary.withOpacity(0.3)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? CustomTheme.lightScheme().primary
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? CustomTheme.lightScheme().primary
                    : Colors.grey[600],
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? CustomTheme.lightScheme().primary
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: UniquesControllers().data.baseSpace * 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
