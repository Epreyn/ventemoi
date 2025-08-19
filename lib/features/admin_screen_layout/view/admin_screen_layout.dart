import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../custom_app_bar/view/custom_app_bar.dart';
import '../../screen_layout/view/screen_layout.dart';

class AdminScreenLayout<T> extends StatelessWidget {
  final String title;
  final List<AdminStatChip> stats;
  final Widget Function(BuildContext context, bool isDesktop, bool isTablet)
      bodyBuilder;
  final Widget? floatingActionButton;
  final Color? primaryColor;
  final bool showSearch;
  final Function(String)? onSearchChanged;
  final List<AdminSortOption>? sortOptions;
  final AdminSortOption? selectedSortOption;
  final Function(AdminSortOption)? onSortChanged;
  final Widget? emptyStateWidget;
  final List<T>? items;

  const AdminScreenLayout({
    super.key,
    required this.title,
    required this.stats,
    required this.bodyBuilder,
    this.floatingActionButton,
    this.primaryColor,
    this.showSearch = true,
    this.onSearchChanged,
    this.sortOptions,
    this.selectedSortOption,
    this.onSortChanged,
    this.emptyStateWidget,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;

    return ScreenLayout(
      appBar: const CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
      ),
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildMinimalStats(context),
                if (showSearch) _buildSearchBar(context),
              ],
            ),
          ),
          if (items?.isEmpty ?? false)
            SliverFillRemaining(
              child: emptyStateWidget ?? _buildDefaultEmptyState(context),
            )
          else
            SliverToBoxAdapter(
              child: bodyBuilder(context, isDesktop, isTablet),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildMinimalStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 24),
            _buildStatChip(stats[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(AdminStatChip stat) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: stat.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            stat.icon,
            size: 16,
            color: stat.color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: stat.color,
              ),
            ),
            Text(
              stat.label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          if (sortOptions != null && sortOptions!.isNotEmpty) ...[
            const SizedBox(width: 12),
            _buildSortMenu(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSortMenu(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: PopupMenuButton<AdminSortOption>(
        icon: Icon(
          Icons.sort,
          color: primaryColor ?? Colors.blue[700],
          size: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: onSortChanged,
        itemBuilder: (context) => sortOptions!.map((option) {
          return PopupMenuItem<AdminSortOption>(
            value: option,
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 18,
                  color: selectedSortOption == option
                      ? primaryColor ?? Colors.blue[700]
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedSortOption == option
                        ? primaryColor ?? Colors.blue[700]
                        : Colors.grey[800],
                    fontWeight: selectedSortOption == option
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultEmptyState(BuildContext context) {
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
              Icons.inbox_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun élément trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les éléments apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminStatChip {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const AdminStatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class AdminSortOption {
  final String label;
  final IconData icon;
  final String value;

  const AdminSortOption({
    required this.label,
    required this.icon,
    required this.value,
  });
}
