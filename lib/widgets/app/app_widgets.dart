import 'package:flutter/material.dart';
import '../../core/config/app_theme_config.dart';
import '../reusable/reusable_widgets_getx.dart';

// Import for internal use
import 'app_button.dart';

// Export all app widgets
export 'app_button.dart';
export 'app_text_field.dart';

// ============================================================================
// APP LOADER
// ============================================================================

/// Loader de l'application avec la charte graphique
class AppLoader extends StatelessWidget {
  final String tag;
  final String? label;
  final double? size;
  final bool showOverlay;
  
  const AppLoader({
    super.key,
    required this.tag,
    this.label,
    this.size,
    this.showOverlay = false,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget loader = ReusableLoaderX(
      tag: tag,
      size: size ?? 40,
      color: AppThemeConfig.primaryColor,
      label: label,
    );
    
    if (showOverlay) {
      return Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(child: loader),
      );
    }
    
    return loader;
  }
  
  /// Affiche un loader en overlay
  static void show(BuildContext context, {String? label}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppThemeConfig.spaceXXL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppThemeConfig.radiusLG,
              boxShadow: AppThemeConfig.shadowXL,
            ),
            child: AppLoader(
              tag: 'overlay-loader',
              label: label,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Cache le loader overlay
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

// ============================================================================
// APP AVATAR
// ============================================================================

/// Avatar de l'application avec la charte graphique
class AppAvatar extends StatelessWidget {
  final String tag;
  final String? imageUrl;
  final String? text;
  final IconData? icon;
  final double? size;
  final bool showStatus;
  final bool isOnline;
  final VoidCallback? onTap;
  
  const AppAvatar({
    super.key,
    required this.tag,
    this.imageUrl,
    this.text,
    this.icon,
    this.size,
    this.showStatus = false,
    this.isOnline = false,
    this.onTap,
  });
  
  double _getSize() {
    if (size != null) return size!;
    return AppThemeConfig.avatarSizeMedium;
  }
  
  @override
  Widget build(BuildContext context) {
    return ReusableAvatarX(
      tag: tag,
      imageUrl: imageUrl,
      text: text,
      icon: icon ?? Icons.person,
      size: _getSize(),
      backgroundColor: AppThemeConfig.primaryColor,
      foregroundColor: AppThemeConfig.textOnPrimary,
      showStatus: showStatus,
      statusColor: isOnline ? AppThemeConfig.successColor : AppThemeConfig.grey400,
      onTap: onTap,
    );
  }
}

// ============================================================================
// APP SEARCH BAR
// ============================================================================

/// Barre de recherche de l'application avec la charte graphique
class AppSearchBar extends StatelessWidget {
  final String tag;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<String>? suggestions;
  final EdgeInsetsGeometry? margin;
  
  const AppSearchBar({
    super.key,
    required this.tag,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.suggestions,
    this.margin,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget searchBar = ReusableSearchBarX(
      tag: tag,
      hintText: hintText ?? 'Rechercher...',
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      suggestions: suggestions,
      backgroundColor: AppThemeConfig.grey100,
      borderRadius: AppThemeConfig.inputBorderRadius,
      showClearButton: true,
    );
    
    if (margin != null) {
      searchBar = Padding(
        padding: margin!,
        child: searchBar,
      );
    }
    
    return searchBar;
  }
}

// ============================================================================
// APP STAT CARD
// ============================================================================

/// Carte de statistiques de l'application avec la charte graphique
class AppStatCard extends StatelessWidget {
  final String tag;
  final String title;
  final String value;
  final IconData? icon;
  final double? changeValue;
  final double? progressValue;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  
  const AppStatCard({
    super.key,
    required this.tag,
    required this.title,
    required this.value,
    this.icon,
    this.changeValue,
    this.progressValue,
    this.onTap,
    this.margin,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget card = ReusableStatCardX(
      tag: tag,
      title: title,
      value: value,
      icon: icon,
      iconColor: AppThemeConfig.primaryColor,
      changeValue: changeValue,
      changeColor: changeValue != null
          ? (changeValue! > 0 ? AppThemeConfig.successColor : AppThemeConfig.errorColor)
          : null,
      progressValue: progressValue,
      onTap: onTap,
      backgroundColor: Colors.white,
      borderRadius: AppThemeConfig.cardBorderRadius,
      padding: const EdgeInsets.all(AppThemeConfig.cardPadding),
    );
    
    if (margin != null) {
      card = Padding(
        padding: margin!,
        child: card,
      );
    }
    
    return card;
  }
}

// ============================================================================
// APP EMPTY STATE
// ============================================================================

/// État vide de l'application avec la charte graphique
class AppEmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  
  const AppEmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return ReusableEmptyStateX(
      icon: icon ?? Icons.inbox,
      title: title,
      subtitle: subtitle,
      iconSize: 80,
      iconColor: AppThemeConfig.grey400,
      action: actionText != null && onAction != null
          ? AppButton(
              tag: 'empty-state-action',
              text: actionText,
              onPressed: onAction,
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
            )
          : null,
    );
  }
}

// ============================================================================
// APP CARD
// ============================================================================

/// Carte de l'application avec la charte graphique
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
    this.width,
    this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppThemeConfig.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? AppThemeConfig.cardBorderRadius),
        boxShadow: boxShadow ?? AppThemeConfig.shadowMD,
      ),
      child: child,
    );
    
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppThemeConfig.cardBorderRadius),
          child: card,
        ),
      );
    }
    
    if (margin != null) {
      card = Padding(
        padding: margin!,
        child: card,
      );
    }
    
    return card;
  }
}

// ============================================================================
// APP DIVIDER
// ============================================================================

/// Divider de l'application avec la charte graphique
class AppDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  
  const AppDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.margin,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget divider = Divider(
      height: height ?? 1,
      thickness: thickness ?? 1,
      color: color ?? AppThemeConfig.grey200,
    );
    
    if (margin != null) {
      divider = Padding(
        padding: margin!,
        child: divider,
      );
    }
    
    return divider;
  }
}

// ============================================================================
// APP BADGE
// ============================================================================

/// Badge de l'application avec la charte graphique
class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;
  
  const AppBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.size,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppThemeConfig.spaceSM,
        vertical: AppThemeConfig.spaceXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppThemeConfig.errorColor,
        borderRadius: BorderRadius.circular(size ?? 12),
      ),
      constraints: BoxConstraints(
        minWidth: size ?? 20,
        minHeight: size ?? 20,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}