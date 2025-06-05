import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';

class CustomFABButton extends StatelessWidget {
  final String tag;
  final String text;
  final IconData? iconData;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const CustomFABButton({
    super.key,
    required this.tag,
    required this.text,
    this.iconData,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? CustomTheme.lightScheme().primary;
    final fgColor = foregroundColor ?? CustomTheme.lightScheme().onPrimary;

    return SizedBox(
      width: width ?? UniquesControllers().data.baseMaxWidth,
      height: 56,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: UniquesControllers().data.baseSpace * 3,
              vertical: UniquesControllers().data.baseSpace * 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null) ...[
                  Icon(
                    iconData,
                    color: fgColor,
                    size: 24,
                  ),
                  SizedBox(width: UniquesControllers().data.baseSpace),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
}
