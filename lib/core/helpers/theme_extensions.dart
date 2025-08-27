import 'package:flutter/material.dart';
import '../config/app_theme_config.dart';

/// Extensions pour faciliter l'accès au thème et aux styles
extension ThemeExtension on BuildContext {
  // Accès rapide au thème
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Couleurs principales
  Color get primaryColor => AppThemeConfig.primaryColor;
  Color get secondaryColor => AppThemeConfig.secondaryColor;
  Color get backgroundColor => AppThemeConfig.backgroundColor;
  Color get surfaceColor => AppThemeConfig.surfaceColor;
  Color get errorColor => AppThemeConfig.errorColor;
  Color get successColor => AppThemeConfig.successColor;
  Color get warningColor => AppThemeConfig.warningColor;
  Color get infoColor => AppThemeConfig.infoColor;
  
  // Couleurs de texte
  Color get textPrimary => AppThemeConfig.textPrimary;
  Color get textSecondary => AppThemeConfig.textSecondary;
  Color get textHint => AppThemeConfig.textHint;
  Color get textDisabled => AppThemeConfig.textDisabled;
  Color get textOnPrimary => AppThemeConfig.textOnPrimary;
  
  // Dimensions
  double get spaceXS => AppThemeConfig.spaceXS;
  double get spaceSM => AppThemeConfig.spaceSM;
  double get spaceMD => AppThemeConfig.spaceMD;
  double get spaceLG => AppThemeConfig.spaceLG;
  double get spaceXL => AppThemeConfig.spaceXL;
  double get spaceXXL => AppThemeConfig.spaceXXL;
  double get spaceXXXL => AppThemeConfig.spaceXXXL;
  
  // Responsive helpers
  bool get isMobile => AppThemeConfig.isMobile(this);
  bool get isTablet => AppThemeConfig.isTablet(this);
  bool get isDesktop => AppThemeConfig.isDesktop(this);
  
  EdgeInsets get adaptivePadding => AppThemeConfig.getAdaptivePadding(this);
  double get maxContentWidth => AppThemeConfig.getMaxContentWidth(this);
}

/// Extension pour les widgets avec des styles communs
extension WidgetStyling on Widget {
  /// Ajoute un padding uniforme
  Widget withPadding([double? padding]) => Padding(
    padding: EdgeInsets.all(padding ?? AppThemeConfig.spaceLG),
    child: this,
  );
  
  /// Ajoute un padding personnalisé
  Widget withCustomPadding({
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) => Padding(
    padding: EdgeInsets.only(
      left: left ?? horizontal ?? 0,
      right: right ?? horizontal ?? 0,
      top: top ?? vertical ?? 0,
      bottom: bottom ?? vertical ?? 0,
    ),
    child: this,
  );
  
  /// Centre le widget
  Widget centered() => Center(child: this);
  
  /// Ajoute une marge
  Widget withMargin([double? margin]) => Container(
    margin: EdgeInsets.all(margin ?? AppThemeConfig.spaceLG),
    child: this,
  );
  
  /// Limite la largeur maximale
  Widget withMaxWidth(double maxWidth) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: this,
  );
  
  /// Ajoute une carte avec ombre
  Widget inCard({
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) => Container(
    padding: padding ?? const EdgeInsets.all(AppThemeConfig.cardPadding),
    margin: margin,
    decoration: BoxDecoration(
      color: color ?? AppThemeConfig.backgroundColor,
      borderRadius: borderRadius ?? AppThemeConfig.radiusLG,
      boxShadow: shadows ?? AppThemeConfig.shadowMD,
    ),
    child: this,
  );
  
  /// Ajoute une animation de fade in
  Widget withFadeIn({
    Duration? duration,
    Curve? curve,
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: duration ?? AppThemeConfig.animationNormal,
    curve: curve ?? AppThemeConfig.animationCurve,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: child,
    ),
    child: this,
  );
  
  /// Ajoute une animation de scale
  Widget withScaleAnimation({
    Duration? duration,
    Curve? curve,
    double? begin,
    double? end,
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: begin ?? 0.8, end: end ?? 1.0),
    duration: duration ?? AppThemeConfig.animationNormal,
    curve: curve ?? AppThemeConfig.animationCurve,
    builder: (context, value, child) => Transform.scale(
      scale: value,
      child: child,
    ),
    child: this,
  );
}

/// Extension pour les styles de texte
extension TextStyleExtension on TextStyle {
  /// Change la couleur du texte
  TextStyle withColor(Color color) => copyWith(color: color);
  
  /// Change la taille du texte
  TextStyle withSize(double size) => copyWith(fontSize: size);
  
  /// Change le poids du texte
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
  
  /// Rend le texte gras
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  
  /// Rend le texte semi-gras
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  
  /// Rend le texte medium
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  
  /// Ajoute une opacité
  TextStyle withOpacity(double opacity) => copyWith(
    color: (color ?? AppThemeConfig.textPrimary).withOpacity(opacity),
  );
}