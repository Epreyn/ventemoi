import 'package:flutter/material.dart';

class AdminCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final bool showHoverEffect;
  
  const AdminCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.boxShadow,
    this.width,
    this.height,
    this.showHoverEffect = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: showHoverEffect ? Colors.grey[50] : null,
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: boxShadow ??
                  [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AdminCompactCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final List<AdminCardInfo>? infoItems;
  final Color? accentColor;
  
  const AdminCompactCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingIconColor,
    this.trailing,
    this.onTap,
    this.infoItems,
    this.accentColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (leadingIconColor ?? Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    leadingIcon,
                    size: 20,
                    color: leadingIconColor ?? Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (infoItems != null && infoItems!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: infoItems!.map((info) => _buildInfoItem(info)).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(AdminCardInfo info) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info.icon != null) ...[
          Icon(
            info.icon,
            size: 14,
            color: info.color ?? Colors.grey[600],
          ),
          const SizedBox(width: 4),
        ],
        Text(
          info.label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          info.value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: info.color ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

class AdminCardInfo {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  
  const AdminCardInfo({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });
}