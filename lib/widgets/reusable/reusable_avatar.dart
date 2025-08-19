import 'package:flutter/material.dart';
import 'dart:io';

/// Enum for avatar types
enum ReusableAvatarType {
  image,
  text,
  icon,
  custom,
}

/// Enum for avatar shapes
enum ReusableAvatarShape {
  circle,
  square,
  rounded,
  custom,
}

/// Enum for avatar sizes
enum ReusableAvatarSize {
  mini,
  small,
  medium,
  large,
  xlarge,
  custom,
}

/// A highly customizable avatar widget
class ReusableAvatar extends StatefulWidget {
  // Core properties
  final ReusableAvatarType type;
  final ReusableAvatarShape shape;
  final ReusableAvatarSize size;
  final double? customSize;
  
  // Content
  final String? imageUrl;
  final String? assetPath;
  final File? imageFile;
  final String? text;
  final IconData? icon;
  final Widget? child;
  final String? heroTag;
  
  // Styling
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? backgroundGradient;
  final List<Color>? gradientColors;
  final TextStyle? textStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? iconSize;
  
  // Border
  final double? borderWidth;
  final Color? borderColor;
  final List<Color>? borderGradientColors;
  final double? borderRadius;
  final BoxBorder? customBorder;
  
  // Shadow
  final List<BoxShadow>? boxShadow;
  final double? elevation;
  
  // Badge
  final Widget? badge;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final AlignmentGeometry? badgeAlignment;
  final bool showBadge;
  final double? badgeSize;
  final EdgeInsetsGeometry? badgePadding;
  
  // Status indicator
  final bool showStatus;
  final Color? statusColor;
  final double? statusSize;
  final AlignmentGeometry? statusAlignment;
  final bool statusPulse;
  
  // Loading
  final bool isLoading;
  final Widget? loadingWidget;
  final Color? loadingColor;
  
  // Error
  final Widget? errorWidget;
  final IconData? errorIcon;
  final Color? errorColor;
  
  // Interaction
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final bool enableRipple;
  final Color? splashColor;
  final Color? highlightColor;
  
  // Animation
  final Duration? animationDuration;
  final Curve? animationCurve;
  final bool enableAnimation;
  final bool enableHoverEffect;
  final double? hoverScale;
  
  // Misc
  final String? tooltip;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  final String? semanticsLabel;
  final BoxFit? imageFit;
  final FilterQuality? imageFilterQuality;
  final BlendMode? imageColorBlendMode;
  final Color? imageColor;
  final bool gaplessPlayback;
  final ImageErrorWidgetBuilder? imageErrorBuilder;
  final String? fallbackText;
  final bool autoGenerateInitials;
  final int maxInitials;
  
  const ReusableAvatar({
    super.key,
    this.type = ReusableAvatarType.text,
    this.shape = ReusableAvatarShape.circle,
    this.size = ReusableAvatarSize.medium,
    this.customSize,
    this.imageUrl,
    this.assetPath,
    this.imageFile,
    this.text,
    this.icon,
    this.child,
    this.heroTag,
    this.backgroundColor,
    this.foregroundColor,
    this.backgroundGradient,
    this.gradientColors,
    this.textStyle,
    this.fontSize,
    this.fontWeight,
    this.iconSize,
    this.borderWidth,
    this.borderColor,
    this.borderGradientColors,
    this.borderRadius,
    this.customBorder,
    this.boxShadow,
    this.elevation,
    this.badge,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.badgeAlignment,
    this.showBadge = false,
    this.badgeSize,
    this.badgePadding,
    this.showStatus = false,
    this.statusColor,
    this.statusSize,
    this.statusAlignment,
    this.statusPulse = true,
    this.isLoading = false,
    this.loadingWidget,
    this.loadingColor,
    this.errorWidget,
    this.errorIcon,
    this.errorColor,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.enableRipple = true,
    this.splashColor,
    this.highlightColor,
    this.animationDuration,
    this.animationCurve,
    this.enableAnimation = true,
    this.enableHoverEffect = false,
    this.hoverScale,
    this.tooltip,
    this.margin,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
    this.semanticsLabel,
    this.imageFit,
    this.imageFilterQuality,
    this.imageColorBlendMode,
    this.imageColor,
    this.gaplessPlayback = false,
    this.imageErrorBuilder,
    this.fallbackText,
    this.autoGenerateInitials = true,
    this.maxInitials = 2,
  });

  @override
  State<ReusableAvatar> createState() => _ReusableAvatarState();
}

class _ReusableAvatarState extends State<ReusableAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Pulse animation for status indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.statusPulse && widget.showStatus) {
      _pulseController.repeat(reverse: true);
    }
    
    // Scale animation for hover/press
    _scaleController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale ?? 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: widget.animationCurve ?? Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  double _getAvatarSize() {
    if (widget.customSize != null) return widget.customSize!;
    
    switch (widget.size) {
      case ReusableAvatarSize.mini:
        return 24;
      case ReusableAvatarSize.small:
        return 32;
      case ReusableAvatarSize.medium:
        return 48;
      case ReusableAvatarSize.large:
        return 64;
      case ReusableAvatarSize.xlarge:
        return 96;
      case ReusableAvatarSize.custom:
        return widget.customSize ?? 48;
    }
  }

  BorderRadius _getBorderRadius(double size) {
    switch (widget.shape) {
      case ReusableAvatarShape.circle:
        return BorderRadius.circular(size);
      case ReusableAvatarShape.square:
        return BorderRadius.zero;
      case ReusableAvatarShape.rounded:
        return BorderRadius.circular(widget.borderRadius ?? size * 0.2);
      case ReusableAvatarShape.custom:
        return BorderRadius.circular(widget.borderRadius ?? 0);
    }
  }

  BoxShape _getBoxShape() {
    return widget.shape == ReusableAvatarShape.circle
        ? BoxShape.circle
        : BoxShape.rectangle;
  }

  String _generateInitials(String? text) {
    if (text == null || text.isEmpty) return '';
    
    final words = text.trim().split(' ');
    final initials = words
        .take(widget.maxInitials)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
    
    return initials;
  }

  Widget _buildContent(double size) {
    if (widget.isLoading) {
      return _buildLoadingContent(size);
    }
    
    if (_hasError) {
      return _buildErrorContent(size);
    }
    
    if (widget.child != null) {
      return widget.child!;
    }
    
    switch (widget.type) {
      case ReusableAvatarType.image:
        return _buildImageContent(size);
      case ReusableAvatarType.text:
        return _buildTextContent(size);
      case ReusableAvatarType.icon:
        return _buildIconContent(size);
      case ReusableAvatarType.custom:
        return widget.child ?? const SizedBox();
    }
  }

  Widget _buildLoadingContent(double size) {
    return widget.loadingWidget ??
        SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.loadingColor ?? widget.foregroundColor ?? Colors.white,
            ),
          ),
        );
  }

  Widget _buildErrorContent(double size) {
    return widget.errorWidget ??
        Icon(
          widget.errorIcon ?? Icons.error_outline,
          size: size * 0.5,
          color: widget.errorColor ?? Colors.red,
        );
  }

  Widget _buildImageContent(double size) {
    Widget? imageWidget;
    
    if (widget.imageUrl != null) {
      imageWidget = Image.network(
        widget.imageUrl!,
        fit: widget.imageFit ?? BoxFit.cover,
        width: size,
        height: size,
        color: widget.imageColor,
        colorBlendMode: widget.imageColorBlendMode,
        filterQuality: widget.imageFilterQuality ?? FilterQuality.medium,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: widget.imageErrorBuilder ??
            (context, error, stackTrace) {
              setState(() {
                _hasError = true;
              });
              return _buildFallbackContent(size);
            },
      );
    } else if (widget.assetPath != null) {
      imageWidget = Image.asset(
        widget.assetPath!,
        fit: widget.imageFit ?? BoxFit.cover,
        width: size,
        height: size,
        color: widget.imageColor,
        colorBlendMode: widget.imageColorBlendMode,
        filterQuality: widget.imageFilterQuality ?? FilterQuality.medium,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: widget.imageErrorBuilder ??
            (context, error, stackTrace) {
              setState(() {
                _hasError = true;
              });
              return _buildFallbackContent(size);
            },
      );
    } else if (widget.imageFile != null) {
      imageWidget = Image.file(
        widget.imageFile!,
        fit: widget.imageFit ?? BoxFit.cover,
        width: size,
        height: size,
        color: widget.imageColor,
        colorBlendMode: widget.imageColorBlendMode,
        filterQuality: widget.imageFilterQuality ?? FilterQuality.medium,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: widget.imageErrorBuilder ??
            (context, error, stackTrace) {
              setState(() {
                _hasError = true;
              });
              return _buildFallbackContent(size);
            },
      );
    }
    
    return imageWidget ?? _buildFallbackContent(size);
  }

  Widget _buildTextContent(double size) {
    final text = widget.autoGenerateInitials
        ? _generateInitials(widget.text ?? widget.fallbackText)
        : (widget.text ?? widget.fallbackText ?? '');
    
    return Text(
      text,
      style: widget.textStyle ??
          TextStyle(
            fontSize: widget.fontSize ?? size * 0.4,
            fontWeight: widget.fontWeight ?? FontWeight.w600,
            color: widget.foregroundColor ?? Colors.white,
          ),
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }

  Widget _buildIconContent(double size) {
    return Icon(
      widget.icon ?? Icons.person,
      size: widget.iconSize ?? size * 0.6,
      color: widget.foregroundColor ?? Colors.white,
    );
  }

  Widget _buildFallbackContent(double size) {
    if (widget.fallbackText != null) {
      return _buildTextContent(size);
    }
    return _buildIconContent(size);
  }

  Widget _buildStatusIndicator(double size) {
    final statusSize = widget.statusSize ?? size * 0.25;
    
    Widget indicator = Container(
      width: statusSize,
      height: statusSize,
      decoration: BoxDecoration(
        color: widget.statusColor ?? Colors.green,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
    
    if (widget.statusPulse) {
      indicator = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: indicator,
      );
    }
    
    return indicator;
  }

  Widget _buildBadge() {
    if (widget.badge != null) {
      return widget.badge!;
    }
    
    if (widget.badgeText != null) {
      return Container(
        padding: widget.badgePadding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: widget.badgeColor ?? Colors.red,
          borderRadius: BorderRadius.circular(widget.badgeSize ?? 10),
        ),
        constraints: BoxConstraints(
          minWidth: widget.badgeSize ?? 20,
          minHeight: widget.badgeSize ?? 20,
        ),
        child: Text(
          widget.badgeText!,
          style: TextStyle(
            color: widget.badgeTextColor ?? Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = _getAvatarSize();
    final borderRadius = _getBorderRadius(size);
    final boxShape = _getBoxShape();
    
    // Default colors
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;
    final foregroundColor = widget.foregroundColor ?? Colors.white;
    
    // Build the main avatar content
    Widget avatar = Container(
      width: size,
      height: size,
      padding: widget.padding,
      clipBehavior: widget.clipBehavior,
      decoration: BoxDecoration(
        color: widget.backgroundGradient == null && widget.gradientColors == null
            ? backgroundColor
            : null,
        gradient: widget.backgroundGradient ??
            (widget.gradientColors != null
                ? LinearGradient(colors: widget.gradientColors!)
                : null),
        shape: boxShape,
        borderRadius: boxShape == BoxShape.rectangle ? borderRadius : null,
        border: widget.customBorder ??
            (widget.borderWidth != null
                ? Border.all(
                    color: widget.borderColor ?? foregroundColor,
                    width: widget.borderWidth!,
                  )
                : null),
        boxShadow: widget.boxShadow ??
            (widget.elevation != null
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: widget.elevation!,
                      offset: Offset(0, widget.elevation! / 2),
                    ),
                  ]
                : null),
      ),
      child: ClipRRect(
        borderRadius: boxShape == BoxShape.rectangle ? borderRadius : BorderRadius.zero,
        child: Center(
          child: _buildContent(size),
        ),
      ),
    );
    
    // Add hero animation if tag is provided
    if (widget.heroTag != null) {
      avatar = Hero(
        tag: widget.heroTag!,
        child: avatar,
      );
    }
    
    // Add status indicator
    if (widget.showStatus) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildStatusIndicator(size),
          ),
        ],
      );
    }
    
    // Add badge
    if (widget.showBadge && (widget.badge != null || widget.badgeText != null)) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            top: -4,
            right: -4,
            child: _buildBadge(),
          ),
        ],
      );
    }
    
    // Add interaction
    if (widget.onTap != null || widget.onLongPress != null || widget.onDoubleTap != null) {
      avatar = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onDoubleTap: widget.onDoubleTap,
          customBorder: boxShape == BoxShape.circle ? const CircleBorder() : null,
          borderRadius: boxShape == BoxShape.rectangle ? borderRadius : null,
          splashColor: widget.splashColor,
          highlightColor: widget.highlightColor,
          child: avatar,
        ),
      );
    }
    
    // Add hover effect
    if (widget.enableHoverEffect) {
      avatar = MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
          if (widget.enableAnimation) {
            _scaleController.forward();
          }
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
          if (widget.enableAnimation) {
            _scaleController.reverse();
          }
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: avatar,
        ),
      );
    }
    
    // Add tooltip
    if (widget.tooltip != null) {
      avatar = Tooltip(
        message: widget.tooltip!,
        child: avatar,
      );
    }
    
    // Add margin
    if (widget.margin != null) {
      avatar = Padding(
        padding: widget.margin!,
        child: avatar,
      );
    }
    
    // Add semantics
    if (widget.semanticsLabel != null) {
      avatar = Semantics(
        label: widget.semanticsLabel,
        child: avatar,
      );
    }
    
    return avatar;
  }
}