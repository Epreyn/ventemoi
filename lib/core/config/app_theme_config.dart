import 'package:flutter/material.dart';

/// Configuration centralisée du thème de l'application
/// Cette classe contient toutes les constantes de style pour garantir
/// une cohérence visuelle dans toute l'application
class AppThemeConfig {
  // ============================================================================
  // COULEURS PRINCIPALES
  // ============================================================================
  
  static const Color primaryColor = Color(0xfff8b02a); // Orange Ventemoi
  static const Color secondaryColor = Color(0xff000000);
  static const Color backgroundColor = Color(0xffffffff);
  static const Color surfaceColor = Color(0xffffffff);
  static const Color errorColor = Color(0xffEF5350);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF29B6F6);
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xff000000);
  static const Color textSecondary = Color(0xff666666);
  static const Color textHint = Color(0xff999999);
  static const Color textDisabled = Color(0xffCCCCCC);
  static const Color textOnPrimary = Color(0xffffffff);
  
  // Greys
  static final Color grey50 = Colors.grey[50]!;
  static final Color grey100 = Colors.grey[100]!;
  static final Color grey200 = Colors.grey[200]!;
  static final Color grey300 = Colors.grey[300]!;
  static final Color grey400 = Colors.grey[400]!;
  static final Color grey500 = Colors.grey[500]!;
  static final Color grey600 = Colors.grey[600]!;
  static final Color grey700 = Colors.grey[700]!;
  static final Color grey800 = Colors.grey[800]!;
  static final Color grey900 = Colors.grey[900]!;
  
  // ============================================================================
  // DIMENSIONS
  // ============================================================================
  
  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double spaceXXXL = 32.0;
  
  // Button sizes
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  
  // Input sizes
  static const double inputHeight = 48.0;
  static const double inputBorderRadius = 24.0;
  
  // Card dimensions
  static const double cardBorderRadius = 16.0;
  static const double cardPadding = 20.0;
  static const double cardElevation = 2.0;
  
  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;
  
  // Avatar sizes
  static const double avatarSizeMini = 24.0;
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXLarge = 96.0;
  
  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  
  static const BorderRadius radiusXS = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXXL = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusRound = BorderRadius.all(Radius.circular(90));
  
  // ============================================================================
  // SHADOWS
  // ============================================================================
  
  static final List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static final List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static final List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
  
  static final List<BoxShadow> shadowXL = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  // ============================================================================
  // TEXT STYLES
  // ============================================================================
  
  // Headers
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    color: textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle h5 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle h6 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textSecondary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textSecondary,
  );
  
  // Buttons
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: textOnPrimary,
  );
  
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: textOnPrimary,
  );
  
  // ============================================================================
  // GRADIENTS
  // ============================================================================
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xffffc85a)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xff333333), Color(0xff000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============================================================================
  // ANIMATIONS
  // ============================================================================
  
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 600);
  static const Curve animationCurve = Curves.easeInOut;
  
  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================
  
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;
  static const double breakpointWide = 1800;
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Retourne true si l'écran est mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointMobile;
  }
  
  /// Retourne true si l'écran est tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointMobile && width < breakpointDesktop;
  }
  
  /// Retourne true si l'écran est desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointDesktop;
  }
  
  /// Retourne le padding adaptatif selon la taille de l'écran
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(spaceLG);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(spaceXL);
    } else {
      return const EdgeInsets.all(spaceXXL);
    }
  }
  
  /// Retourne la largeur maximale pour le contenu
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 600;
    } else {
      return 1200;
    }
  }
}