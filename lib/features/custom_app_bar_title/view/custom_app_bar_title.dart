import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';

class CustomAppBarTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const CustomAppBarTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon optionnelle
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).primaryColor,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: UniquesControllers().data.baseSpace * 1.5),
        ],

        // Title et subtitle
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: titleStyle ??
                    TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: subtitleStyle ??
                      TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
