import 'package:flutter/material.dart';

class AdminDetailDialog extends StatelessWidget {
  final String title;
  final Color primaryColor;
  final IconData? headerIcon;
  final List<AdminDetailSection> sections;
  final List<Widget>? actions;
  final double maxWidth;
  
  const AdminDetailDialog({
    super.key,
    required this.title,
    required this.primaryColor,
    this.headerIcon,
    required this.sections,
    this.actions,
    this.maxWidth = 500,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: maxWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: maxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var section in sections) _buildSection(section),
                  ],
                ),
              ),
            ),
            if (actions != null && actions!.isNotEmpty) _buildActions(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          if (headerIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                headerIcon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(AdminDetailSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title != null) ...[
            Row(
              children: [
                if (section.icon != null) ...[
                  Icon(
                    section.icon,
                    size: 18,
                    color: section.iconColor ?? Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  section.title!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...section.children,
        ],
      ),
    );
  }
  
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < actions!.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            actions![i],
          ],
        ],
      ),
    );
  }
  
  static Widget buildDetailRow(
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
    double topPadding = 0,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: iconColor ?? Colors.grey[600],
            ),
            const SizedBox(width: 8),
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
              style: valueStyle ??
                  TextStyle(
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
}

class AdminDetailSection {
  final String? title;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget> children;
  
  const AdminDetailSection({
    this.title,
    this.icon,
    this.iconColor,
    required this.children,
  });
}