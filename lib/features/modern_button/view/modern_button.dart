import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/custom_theme.dart';

enum ModernButtonType { primary, secondary, text, outlined, gradient }

enum ModernButtonSize { small, medium, large }

class ModernButtonController extends GetxController {
  final RxBool isPressed = false.obs;
  final RxBool isHovered = false.obs;

  void onTapDown() {
    isPressed.value = true;
    HapticFeedback.lightImpact();
  }

  void onTapUp() {
    isPressed.value = false;
  }

  void onHover(bool hover) {
    isHovered.value = hover;
  }
}

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonType type;
  final ModernButtonSize size;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? textColor;
  final List<Color>? gradientColors;
  final bool enableHapticFeedback;
  final double? elevation;
  final String? heroTag;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ModernButtonType.primary,
    this.size = ModernButtonSize.medium,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.width,
    this.padding,
    this.borderRadius,
    this.color,
    this.textColor,
    this.gradientColors,
    this.enableHapticFeedback = true,
    this.elevation,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ModernButtonController(), tag: UniqueKey().toString());
    final colorScheme = CustomTheme.lightScheme();
    final isDisabled = onPressed == null || isLoading;

    // Dimensions selon la taille
    final dimensions = _getButtonDimensions();

    // Couleurs et styles selon le type
    final styles = _getButtonStyles(colorScheme, isDisabled);

    return Obx(() {
      final isPressed = cc.isPressed.value;
      final scale = isPressed && !isDisabled ? 0.96 : 1.0;

      Widget button = GestureDetector(
        onTapDown: isDisabled ? null : (_) => cc.onTapDown(),
        onTapUp: isDisabled ? null : (_) => cc.onTapUp(),
        onTapCancel: () => cc.onTapUp(),
        onTap: isDisabled
            ? null
            : () {
                if (enableHapticFeedback) {
                  HapticFeedback.selectionClick();
                }
                onPressed?.call();
              },
        child: MouseRegion(
          cursor: isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) => cc.onHover(true),
          onExit: (_) => cc.onHover(false),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width,
              height: dimensions['height'],
              decoration: BoxDecoration(
                gradient:
                    type == ModernButtonType.gradient && gradientColors != null
                        ? LinearGradient(
                            colors: isDisabled
                                ? [Colors.grey[400]!, Colors.grey[300]!]
                                : gradientColors!,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                color: type != ModernButtonType.gradient
                    ? styles['backgroundColor']
                    : null,
                borderRadius: borderRadius ??
                    BorderRadius.circular(dimensions['radius']!),
                border: Border.all(
                  color: styles['borderColor']!,
                  width: type == ModernButtonType.outlined ? 2 : 0,
                ),
                boxShadow: _getBoxShadow(styles, isPressed, isDisabled),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled ? null : onPressed,
                  borderRadius: borderRadius ??
                      BorderRadius.circular(dimensions['radius']!),
                  splashColor: styles['foregroundColor']!.withOpacity(0.1),
                  highlightColor: styles['foregroundColor']!.withOpacity(0.05),
                  child: Padding(
                    padding: padding ??
                        EdgeInsets.symmetric(
                          horizontal: dimensions['paddingH']!,
                          vertical: dimensions['paddingV']!,
                        ),
                    child: Center(
                      child: _buildButtonContent(
                        styles['foregroundColor']!,
                        dimensions,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (heroTag != null) {
        button = Hero(
          tag: heroTag!,
          child: button,
        );
      }

      return button;
    });
  }

  Widget _buildButtonContent(
      Color foregroundColor, Map<String, double> dimensions) {
    if (isLoading) {
      return SizedBox(
        width: dimensions['iconSize'],
        height: dimensions['iconSize'],
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: TextStyle(
        color: foregroundColor,
        fontSize: dimensions['fontSize'],
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    if (icon == null && suffixIcon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: foregroundColor,
            size: dimensions['iconSize'],
          ),
          SizedBox(width: dimensions['spacing']),
        ],
        Flexible(child: textWidget),
        if (suffixIcon != null) ...[
          SizedBox(width: dimensions['spacing']),
          Icon(
            suffixIcon,
            color: foregroundColor,
            size: dimensions['iconSize'],
          ),
        ],
      ],
    );
  }

  Map<String, double> _getButtonDimensions() {
    switch (size) {
      case ModernButtonSize.small:
        return {
          'height': 36,
          'fontSize': 14,
          'paddingH': 16,
          'paddingV': 8,
          'iconSize': 18,
          'radius': 18,
          'spacing': 6,
        };
      case ModernButtonSize.large:
        return {
          'height': 56,
          'fontSize': 18,
          'paddingH': 32,
          'paddingV': 16,
          'iconSize': 24,
          'radius': 28,
          'spacing': 12,
        };
      case ModernButtonSize.medium:
      default:
        return {
          'height': 48,
          'fontSize': 16,
          'paddingH': 24,
          'paddingV': 12,
          'iconSize': 20,
          'radius': 24,
          'spacing': 8,
        };
    }
  }

  Map<String, Color> _getButtonStyles(
      ColorScheme colorScheme, bool isDisabled) {
    switch (type) {
      case ModernButtonType.primary:
        return {
          'backgroundColor':
              isDisabled ? Colors.grey[300]! : (color ?? colorScheme.primary),
          'foregroundColor':
              isDisabled ? Colors.grey[600]! : (textColor ?? Colors.white),
          'borderColor':
              isDisabled ? Colors.grey[300]! : (color ?? colorScheme.primary),
        };
      case ModernButtonType.secondary:
        return {
          'backgroundColor':
              isDisabled ? Colors.grey[200]! : (color ?? Colors.grey[900]!),
          'foregroundColor':
              isDisabled ? Colors.grey[500]! : (textColor ?? Colors.white),
          'borderColor':
              isDisabled ? Colors.grey[200]! : (color ?? Colors.grey[900]!),
        };
      case ModernButtonType.outlined:
        return {
          'backgroundColor': Colors.transparent,
          'foregroundColor':
              isDisabled ? Colors.grey[400]! : (color ?? colorScheme.primary),
          'borderColor':
              isDisabled ? Colors.grey[300]! : (color ?? colorScheme.primary),
        };
      case ModernButtonType.text:
        return {
          'backgroundColor': Colors.transparent,
          'foregroundColor':
              isDisabled ? Colors.grey[400]! : (color ?? colorScheme.primary),
          'borderColor': Colors.transparent,
        };
      case ModernButtonType.gradient:
        return {
          'backgroundColor': Colors.transparent,
          'foregroundColor':
              isDisabled ? Colors.grey[600]! : (textColor ?? Colors.white),
          'borderColor': Colors.transparent,
        };
    }
  }

  List<BoxShadow>? _getBoxShadow(
      Map<String, Color> styles, bool isPressed, bool isDisabled) {
    if (type == ModernButtonType.text ||
        type == ModernButtonType.outlined ||
        isDisabled) {
      return null;
    }

    final shadowColor =
        type == ModernButtonType.gradient && gradientColors != null
            ? gradientColors!.first
            : styles['backgroundColor']!;

    return [
      BoxShadow(
        color: shadowColor.withOpacity(isPressed ? 0.2 : 0.3),
        blurRadius: isPressed ? 4 : 12,
        offset: Offset(0, isPressed ? 2 : 4),
        spreadRadius: isPressed ? 0 : 1,
      ),
    ];
  }
}

// Widget pour bouton icon seulement
class ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ModernButtonSize size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isLoading;
  final String? tooltip;
  final double? customSize;
  final bool enableHapticFeedback;

  const ModernIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = ModernButtonSize.medium,
    this.backgroundColor,
    this.iconColor,
    this.isLoading = false,
    this.tooltip,
    this.customSize,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ModernButtonController(), tag: UniqueKey().toString());
    final colorScheme = CustomTheme.lightScheme();
    final isDisabled = onPressed == null || isLoading;

    final dimensions = _getDimensions();
    final bgColor = backgroundColor ?? colorScheme.primary;
    final fgColor = iconColor ?? Colors.white;

    return Obx(() {
      final isPressed = cc.isPressed.value;
      final scale = isPressed && !isDisabled ? 0.9 : 1.0;

      Widget button = GestureDetector(
        onTapDown: isDisabled ? null : (_) => cc.onTapDown(),
        onTapUp: isDisabled ? null : (_) => cc.onTapUp(),
        onTapCancel: () => cc.onTapUp(),
        onTap: isDisabled
            ? null
            : () {
                if (enableHapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                onPressed?.call();
              },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: customSize ?? dimensions['size'],
            height: customSize ?? dimensions['size'],
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey[300] : bgColor,
              shape: BoxShape.circle,
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: bgColor.withOpacity(isPressed ? 0.2 : 0.3),
                        blurRadius: isPressed ? 4 : 12,
                        offset: Offset(0, isPressed ? 2 : 4),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isDisabled ? null : onPressed,
                customBorder: const CircleBorder(),
                splashColor: fgColor.withOpacity(0.2),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: dimensions['iconSize']! * 0.8,
                          height: dimensions['iconSize']! * 0.8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDisabled ? Colors.grey[600]! : fgColor,
                            ),
                          ),
                        )
                      : Icon(
                          icon,
                          size: dimensions['iconSize'],
                          color: isDisabled ? Colors.grey[600] : fgColor,
                        ),
                ),
              ),
            ),
          ),
        ),
      );

      if (tooltip != null) {
        button = Tooltip(
          message: tooltip!,
          preferBelow: false,
          verticalOffset: 20,
          child: button,
        );
      }

      return button;
    });
  }

  Map<String, double> _getDimensions() {
    switch (size) {
      case ModernButtonSize.small:
        return {'size': 36, 'iconSize': 18};
      case ModernButtonSize.large:
        return {'size': 56, 'iconSize': 28};
      case ModernButtonSize.medium:
      default:
        return {'size': 44, 'iconSize': 22};
    }
  }
}
