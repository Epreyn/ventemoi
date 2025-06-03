// Ce fichier remplace complètement votre fichier actuel
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart'; // À ajouter dans pubspec.yaml

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/shop_establishment_screen_controller.dart';
import '../widgets/modern_establishment_card.dart'; // Nouveau widget
import '../widgets/empty_state_widget.dart'; // Nouveau widget

class ShopEstablishmentScreen extends StatelessWidget {
  const ShopEstablishmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ShopEstablishmentScreenController());

    return ScreenLayout(
      noFAB: true,
      body: Column(
        children: [
          // Sections 1 et 2 du code vont ici
          _buildUserHeader(cc),
          _buildSearchBar(cc),
          _buildModernTabs(cc),
          Expanded(
            child: _buildContent(cc),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(ShopEstablishmentScreenController cc) {
    return Container(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
      decoration: BoxDecoration(
        color: CustomTheme.lightScheme().primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Avatar utilisateur
          StreamBuilder<String>(
            stream: _getUserImageStream(),
            builder: (context, snapshot) {
              return CircleAvatar(
                radius: 24,
                backgroundImage:
                    snapshot.hasData ? NetworkImage(snapshot.data!) : null,
                child: !snapshot.hasData
                    ? Icon(Icons.person, color: Colors.white)
                    : null,
              );
            },
          ),
          const SizedBox(width: 12),

          // Nom et type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                StreamBuilder<String>(
                  stream: _getUserNameStream(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Widget points animé
          Obx(() => _buildPointsWidget(cc.buyerPoints.value)),
        ],
      ),
    );
  }

  Widget _buildPointsWidget(int points) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 2,
        vertical: UniquesControllers().data.baseSpace,
      ),
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
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '$points',
              key: ValueKey(points),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'pts',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ShopEstablishmentScreenController cc) {
    return Container(
      height: 56,
      margin: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 2,
        vertical: UniquesControllers().data.baseSpace,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône de recherche
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              Icons.search,
              color: Colors.grey[600],
            ),
          ),

          // Champ de recherche
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un établissement...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: cc.setSearchText,
            ),
          ),

          // Bouton filtre avec badge
          Obx(() {
            final filterCount = cc.selectedTabIndex.value == 2
                ? cc.selectedEnterpriseCatIds.length
                : cc.selectedCatIds.length;

            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: filterCount > 0
                        ? CustomTheme.lightScheme().primary
                        : Colors.grey[600],
                  ),
                  onPressed: () => _showFilterBottomSheet(cc),
                ),
                if (filterCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CustomTheme.lightScheme().primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildModernTabs(ShopEstablishmentScreenController cc) {
    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 2,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Indicateur animé
          Obx(() => AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                left: cc.selectedTabIndex.value * (Get.width - 32) / 3,
                child: Container(
                  width: (Get.width - 32) / 3,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              )),

          // Boutons des onglets
          Row(
            children: [
              _buildTabButton(cc, 0, 'Boutiques', Icons.store),
              _buildTabButton(cc, 1, 'Associations', Icons.volunteer_activism),
              _buildTabButton(cc, 2, 'Entreprises', Icons.business),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    ShopEstablishmentScreenController cc,
    int index,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => cc.selectedTabIndex.value = index,
        child: Container(
          height: 48,
          color: Colors.transparent,
          child: Obx(() {
            final isSelected = cc.selectedTabIndex.value == index;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? CustomTheme.lightScheme().primary
                      : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? CustomTheme.lightScheme().primary
                        : Colors.grey[600],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(ShopEstablishmentScreenController cc) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Titre
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Filtrer par catégorie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      cc.selectedCatIds.clear();
                      cc.selectedEnterpriseCatIds.clear();
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),

            // Catégories en chips
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildCategoryChips(cc),
                    )),
              ),
            ),

            // Bouton appliquer
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    cc.filterEstablishments();
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Appliquer les filtres',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Animation de chargement skeleton
  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  // Transition entre états
  Widget _buildContent(ShopEstablishmentScreenController cc) {
    return Obx(() {
      if (cc.allEstablishments.isEmpty) {
        return _buildSkeletonLoader();
      }

      final establishments = cc.displayedEstablishments;

      if (establishments.isEmpty) {
        return _buildEmptyState();
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildGrid(establishments, cc),
      );
    });
  }

  // Ajouter ces méthodes helper
  Stream<String> _getUserImageStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data()?['image_url'] ?? '');
  }

  Stream<String> _getUserNameStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data()?['name'] ?? 'Utilisateur');
  }

  Widget _buildGrid(List establishments, ShopEstablishmentScreenController cc) {
    return GridView.builder(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 0.8,
        crossAxisSpacing: UniquesControllers().data.baseSpace * 2,
        mainAxisSpacing: UniquesControllers().data.baseSpace * 2,
      ),
      itemCount: establishments.length,
      itemBuilder: (context, index) {
        final establishment = establishments[index];
        final tabIndex = cc.selectedTabIndex.value;

        return ModernEstablishmentCard(
          establishment: establishment,
          onTap: () =>
              tabIndex == 2 ? null : cc.buyEstablishment(establishment),
          index: index,
          isEnterprise: tabIndex == 2,
        );
      },
    );
  }

  List<Widget> _buildCategoryChips(ShopEstablishmentScreenController cc) {
    final isEnterprise = cc.selectedTabIndex.value == 2;
    final categories =
        isEnterprise ? cc.enterpriseCategoriesMap : cc.categoriesMap;
    final selectedIds =
        isEnterprise ? cc.selectedEnterpriseCatIds : cc.selectedCatIds;

    return categories.entries.map((entry) {
      final isSelected = selectedIds.contains(entry.key);
      return FilterChip(
        label: Text(entry.value),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            selectedIds.add(entry.key);
          } else {
            selectedIds.remove(entry.key);
          }
        },
        selectedColor: CustomTheme.lightScheme().primary.withOpacity(0.2),
        checkmarkColor: CustomTheme.lightScheme().primary,
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(); // Défini plus bas
  }
}
