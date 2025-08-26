import 'package:flutter/material.dart';
import '../../core/config/app_theme_config.dart';

/// Énumération des types de boutons de l'application
enum AppButtonType {
  primary,    // Bouton principal orange
  secondary,  // Bouton secondaire noir
  outlined,   // Bouton avec bordure
  text,       // Bouton texte
  danger,     // Bouton rouge
  success,    // Bouton vert
}

/// Énumération des tailles de boutons
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Bouton de l'application avec la charte graphique
class AppButton extends StatelessWidget {
  final String tag;
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final Widget? child;
  
  const AppButton({
    super.key,
    required this.tag,
    this.text,
    this.icon,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.margin,
    this.child,
  });
  
  Color _getBackgroundColor() {
    if (isDisabled) return AppThemeConfig.grey300;
    
    switch (type) {
      case AppButtonType.primary:
        return AppThemeConfig.primaryColor;
      case AppButtonType.secondary:
        return AppThemeConfig.secondaryColor;
      case AppButtonType.outlined:
      case AppButtonType.text:
        return Colors.transparent;
      case AppButtonType.danger:
        return AppThemeConfig.errorColor;
      case AppButtonType.success:
        return AppThemeConfig.successColor;
    }
  }
  
  Color _getForegroundColor() {
    if (isDisabled) {
      return type == AppButtonType.outlined || type == AppButtonType.text
          ? AppThemeConfig.textDisabled
          : AppThemeConfig.textOnPrimary;
    }
    
    switch (type) {
      case AppButtonType.primary:
        return AppThemeConfig.textOnPrimary;
      case AppButtonType.secondary:
        return AppThemeConfig.textOnPrimary;
      case AppButtonType.outlined:
        return AppThemeConfig.primaryColor;
      case AppButtonType.text:
        return AppThemeConfig.primaryColor;
      case AppButtonType.danger:
        return AppThemeConfig.textOnPrimary;
      case AppButtonType.success:
        return AppThemeConfig.textOnPrimary;
    }
  }
  
  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppThemeConfig.buttonHeightSmall;
      case AppButtonSize.medium:
        return AppThemeConfig.buttonHeightMedium;
      case AppButtonSize.large:
        return AppThemeConfig.buttonHeightLarge;
    }
  }
  
  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppThemeConfig.spaceLG,
          vertical: AppThemeConfig.spaceSM,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppThemeConfig.spaceXL,
          vertical: AppThemeConfig.spaceMD,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppThemeConfig.spaceXXL,
          vertical: AppThemeConfig.spaceLG,
        );
    }
  }
  
  double _getFontSize() {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final foregroundColor = _getForegroundColor();
    
    Widget buttonChild;
    
    if (isLoading) {
      buttonChild = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else if (child != null) {
      buttonChild = child!;
    } else {
      final List<Widget> children = [];
      
      if (icon != null) {
        children.add(Icon(
          icon,
          size: _getFontSize() + 2,
          color: foregroundColor,
        ));
      }
      
      if (text != null) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(width: 8));
        }
        children.add(Text(
          text!,
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
            color: foregroundColor,
            letterSpacing: 0.5,
          ),
        ));
      }
      
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }
    
    Widget button;
    
    if (type == AppButtonType.text) {
      button = TextButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          padding: _getPadding(),
          minimumSize: Size(0, _getHeight()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          ),
        ),
        child: buttonChild,
      );
    } else if (type == AppButtonType.outlined) {
      button = OutlinedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: isDisabled ? AppThemeConfig.grey300 : AppThemeConfig.primaryColor,
            width: 2,
          ),
          padding: _getPadding(),
          minimumSize: Size(0, _getHeight()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          ),
        ),
        child: buttonChild,
      );
    } else {
      button = ElevatedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: _getPadding(),
          minimumSize: Size(0, _getHeight()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          ),
        ),
        child: buttonChild,
      );
    }
    
    if (width != null) {
      button = SizedBox(
        width: width,
        child: button,
      );
    }
    
    if (margin != null) {
      button = Padding(
        padding: margin!,
        child: button,
      );
    }
    
    return button;
  }
}

/// Bouton flottant de l'application
class AppFloatingButton extends StatelessWidget {
  final String tag;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool mini;
  final String? tooltip;
  
  const AppFloatingButton({
    super.key,
    required this.tag,
    required this.icon,
    this.onPressed,
    this.mini = false,
    this.tooltip,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: AppThemeConfig.primaryColor,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: mini ? 40 : 56,
          height: mini ? 40 : 56,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppThemeConfig.textOnPrimary,
            size: mini ? 20 : 24,
          ),
        ),
      ),
    );
    
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}