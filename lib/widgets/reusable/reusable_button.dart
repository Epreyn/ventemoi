import 'package:flutter/material.dart';

/// Enum for button types
enum ReusableButtonType {
  filled,
  outlined,
  text,
  elevated,
  icon,
  floatingAction,
}

/// Enum for button sizes
enum ReusableButtonSize {
  small,
  medium,
  large,
  custom,
}

/// A highly customizable button widget that can be styled in various ways
class ReusableButton extends StatefulWidget {
  // Core properties
  final String? text;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final ReusableButtonType type;
  final ReusableButtonSize size;
  
  // Icons
  final IconData? icon;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Widget? leadingWidget;
  final Widget? trailingWidget;
  final Widget? child;
  final double? iconSize;
  final double? iconSpacing;
  final bool iconOnTop;
  
  // Loading & State
  final bool isLoading;
  final bool isDisabled;
  final Widget? loadingWidget;
  final String? loadingText;
  final bool showLoadingText;
  
  // Dimensions
  final double? width;
  final double? height;
  final double? minWidth;
  final double? minHeight;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  // Styling - Colors
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final Color? hoverColor;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? focusColor;
  final Color? shadowColor;
  final Gradient? gradient;
  final Gradient? hoverGradient;
  final List<Color>? gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  
  // Styling - Text
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final TextOverflow? textOverflow;
  final int? maxLines;
  final double? fontSize;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final double? letterSpacing;
  final double? wordSpacing;
  final TextDecoration? textDecoration;
  
  // Styling - Border
  final BorderSide? borderSide;
  final Color? borderColor;
  final double? borderWidth;
  final BorderStyle? borderStyle;
  final double? borderRadius;
  final BorderRadiusGeometry? customBorderRadius;
  final OutlinedBorder? shape;
  
  // Styling - Shadow & Elevation
  final double? elevation;
  final double? hoverElevation;
  final double? highlightElevation;
  final double? disabledElevation;
  final List<BoxShadow>? boxShadow;
  
  // Animation
  final Duration? animationDuration;
  final Curve? animationCurve;
  final bool enableAnimation;
  final bool enableRipple;
  final bool enableHoverAnimation;
  final double? hoverScale;
  final double? pressScale;
  
  // Interaction
  final MouseCursor? mouseCursor;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool canRequestFocus;
  final String? tooltip;
  final Clip clipBehavior;
  final MaterialTapTargetSize? tapTargetSize;
  final VisualDensity? visualDensity;
  final bool enableFeedback;
  
  // Alignment
  final AlignmentGeometry? alignment;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisSize? mainAxisSize;
  
  // Badge
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final bool showBadge;
  final AlignmentGeometry? badgeAlignment;
  
  // Custom builders
  final Widget Function(BuildContext, bool isHovered, bool isPressed)? customBuilder;
  final ButtonStyle? style;
  final MaterialStatesController? statesController;
  
  const ReusableButton({
    super.key,
    this.text,
    this.onPressed,
    this.onLongPress,
    this.onDoubleTap,
    this.type = ReusableButtonType.filled,
    this.size = ReusableButtonSize.medium,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    this.leadingWidget,
    this.trailingWidget,
    this.child,
    this.iconSize,
    this.iconSpacing,
    this.iconOnTop = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.loadingWidget,
    this.loadingText,
    this.showLoadingText = false,
    this.width,
    this.height,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.hoverColor,
    this.splashColor,
    this.highlightColor,
    this.focusColor,
    this.shadowColor,
    this.gradient,
    this.hoverGradient,
    this.gradientColors,
    this.gradientBegin = Alignment.centerLeft,
    this.gradientEnd = Alignment.centerRight,
    this.textStyle,
    this.textAlign,
    this.textOverflow,
    this.maxLines,
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.letterSpacing,
    this.wordSpacing,
    this.textDecoration,
    this.borderSide,
    this.borderColor,
    this.borderWidth,
    this.borderStyle,
    this.borderRadius,
    this.customBorderRadius,
    this.shape,
    this.elevation,
    this.hoverElevation,
    this.highlightElevation,
    this.disabledElevation,
    this.boxShadow,
    this.animationDuration,
    this.animationCurve,
    this.enableAnimation = true,
    this.enableRipple = true,
    this.enableHoverAnimation = true,
    this.hoverScale,
    this.pressScale,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.tooltip,
    this.clipBehavior = Clip.none,
    this.tapTargetSize,
    this.visualDensity,
    this.enableFeedback = true,
    this.alignment,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.mainAxisSize,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.showBadge = false,
    this.badgeAlignment,
    this.customBuilder,
    this.style,
    this.statesController,
  });

  @override
  State<ReusableButton> createState() => _ReusableButtonState();
}

class _ReusableButtonState extends State<ReusableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale ?? 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve ?? Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Size _getButtonSize() {
    switch (widget.size) {
      case ReusableButtonSize.small:
        return Size(widget.width ?? 80, widget.height ?? 36);
      case ReusableButtonSize.medium:
        return Size(widget.width ?? 120, widget.height ?? 48);
      case ReusableButtonSize.large:
        return Size(widget.width ?? 160, widget.height ?? 56);
      case ReusableButtonSize.custom:
        return Size(widget.width ?? double.infinity, widget.height ?? 48);
    }
  }

  EdgeInsetsGeometry _getButtonPadding() {
    if (widget.padding != null) return widget.padding!;
    
    switch (widget.size) {
      case ReusableButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ReusableButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case ReusableButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
      case ReusableButtonSize.custom:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = widget.textStyle ?? theme.textTheme.labelLarge ?? const TextStyle();
    
    return baseStyle.copyWith(
      fontSize: widget.fontSize ?? (widget.size == ReusableButtonSize.small ? 14 : 
                                   widget.size == ReusableButtonSize.large ? 18 : 16),
      fontWeight: widget.fontWeight ?? FontWeight.w600,
      fontFamily: widget.fontFamily,
      letterSpacing: widget.letterSpacing,
      wordSpacing: widget.wordSpacing,
      decoration: widget.textDecoration,
      color: widget.foregroundColor,
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (widget.customBuilder != null) {
      return widget.customBuilder!(context, _isHovered, _isPressed);
    }

    if (widget.isLoading) {
      return _buildLoadingContent(context);
    }

    if (widget.child != null) {
      return widget.child!;
    }

    final List<Widget> children = [];
    
    // Leading widget/icon
    if (widget.leadingWidget != null) {
      children.add(widget.leadingWidget!);
      if (widget.text != null) {
        children.add(SizedBox(width: widget.iconSpacing ?? 8));
      }
    } else if (widget.leadingIcon != null) {
      children.add(Icon(
        widget.leadingIcon,
        size: widget.iconSize ?? 20,
        color: widget.foregroundColor,
      ));
      if (widget.text != null) {
        children.add(SizedBox(width: widget.iconSpacing ?? 8));
      }
    } else if (widget.icon != null && !widget.iconOnTop) {
      children.add(Icon(
        widget.icon,
        size: widget.iconSize ?? 20,
        color: widget.foregroundColor,
      ));
      if (widget.text != null) {
        children.add(SizedBox(width: widget.iconSpacing ?? 8));
      }
    }
    
    // Text
    if (widget.text != null) {
      children.add(
        Flexible(
          child: Text(
            widget.text!,
            style: _getTextStyle(context),
            textAlign: widget.textAlign,
            overflow: widget.textOverflow ?? TextOverflow.ellipsis,
            maxLines: widget.maxLines,
          ),
        ),
      );
    }
    
    // Trailing widget/icon
    if (widget.trailingWidget != null) {
      if (widget.text != null) {
        children.add(SizedBox(width: widget.iconSpacing ?? 8));
      }
      children.add(widget.trailingWidget!);
    } else if (widget.trailingIcon != null) {
      if (widget.text != null) {
        children.add(SizedBox(width: widget.iconSpacing ?? 8));
      }
      children.add(Icon(
        widget.trailingIcon,
        size: widget.iconSize ?? 20,
        color: widget.foregroundColor,
      ));
    }

    if (widget.iconOnTop && widget.icon != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: widget.mainAxisAlignment ?? MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            size: widget.iconSize ?? 24,
            color: widget.foregroundColor,
          ),
          if (widget.text != null) ...[
            SizedBox(height: widget.iconSpacing ?? 4),
            Text(
              widget.text!,
              style: _getTextStyle(context),
              textAlign: widget.textAlign,
            ),
          ],
        ],
      );
    }

    if (children.length == 1) {
      return children.first;
    }

    return Row(
      mainAxisSize: widget.mainAxisSize ?? MainAxisSize.min,
      mainAxisAlignment: widget.mainAxisAlignment ?? MainAxisAlignment.center,
      crossAxisAlignment: widget.crossAxisAlignment ?? CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    final List<Widget> children = [
      SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    ];

    if (widget.showLoadingText && (widget.loadingText ?? widget.text) != null) {
      children.add(const SizedBox(width: 8));
      children.add(
        Text(
          widget.loadingText ?? widget.text!,
          style: _getTextStyle(context),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildButton(BuildContext context) {
    final isDisabled = widget.isDisabled || widget.isLoading || widget.onPressed == null;
    final size = _getButtonSize();
    final theme = Theme.of(context);

    Widget button;

    switch (widget.type) {
      case ReusableButtonType.filled:
        button = FilledButton(
          onPressed: isDisabled ? null : widget.onPressed,
          onLongPress: isDisabled ? null : widget.onLongPress,
          style: widget.style ?? FilledButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            disabledBackgroundColor: widget.disabledBackgroundColor,
            disabledForegroundColor: widget.disabledForegroundColor,
            shadowColor: widget.shadowColor,
            elevation: widget.elevation,
            padding: _getButtonPadding(),
            minimumSize: Size(widget.minWidth ?? 0, widget.minHeight ?? 0),
            maximumSize: Size(widget.maxWidth ?? double.infinity, widget.maxHeight ?? double.infinity),
            shape: widget.shape ?? (widget.customBorderRadius != null
                ? RoundedRectangleBorder(borderRadius: widget.customBorderRadius!)
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                  )),
            tapTargetSize: widget.tapTargetSize,
            visualDensity: widget.visualDensity,
            enableFeedback: widget.enableFeedback,
            alignment: widget.alignment,
          ),
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          clipBehavior: widget.clipBehavior,
          statesController: widget.statesController,
          child: _buildButtonContent(context),
        );
        break;

      case ReusableButtonType.outlined:
        button = OutlinedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          onLongPress: isDisabled ? null : widget.onLongPress,
          style: widget.style ?? OutlinedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor ?? theme.primaryColor,
            disabledForegroundColor: widget.disabledForegroundColor,
            shadowColor: widget.shadowColor,
            elevation: widget.elevation,
            padding: _getButtonPadding(),
            minimumSize: Size(widget.minWidth ?? 0, widget.minHeight ?? 0),
            maximumSize: Size(widget.maxWidth ?? double.infinity, widget.maxHeight ?? double.infinity),
            side: widget.borderSide ?? BorderSide(
              color: widget.borderColor ?? widget.foregroundColor ?? theme.primaryColor,
              width: widget.borderWidth ?? 1.5,
              style: widget.borderStyle ?? BorderStyle.solid,
            ),
            shape: widget.shape ?? (widget.customBorderRadius != null
                ? RoundedRectangleBorder(borderRadius: widget.customBorderRadius!)
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                  )),
            tapTargetSize: widget.tapTargetSize,
            visualDensity: widget.visualDensity,
            enableFeedback: widget.enableFeedback,
            alignment: widget.alignment,
          ),
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          clipBehavior: widget.clipBehavior,
          statesController: widget.statesController,
          child: _buildButtonContent(context),
        );
        break;

      case ReusableButtonType.text:
        button = TextButton(
          onPressed: isDisabled ? null : widget.onPressed,
          onLongPress: isDisabled ? null : widget.onLongPress,
          style: widget.style ?? TextButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor ?? theme.primaryColor,
            disabledForegroundColor: widget.disabledForegroundColor,
            shadowColor: widget.shadowColor,
            elevation: widget.elevation,
            padding: _getButtonPadding(),
            minimumSize: Size(widget.minWidth ?? 0, widget.minHeight ?? 0),
            maximumSize: Size(widget.maxWidth ?? double.infinity, widget.maxHeight ?? double.infinity),
            shape: widget.shape ?? (widget.customBorderRadius != null
                ? RoundedRectangleBorder(borderRadius: widget.customBorderRadius!)
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                  )),
            tapTargetSize: widget.tapTargetSize,
            visualDensity: widget.visualDensity,
            enableFeedback: widget.enableFeedback,
            alignment: widget.alignment,
          ),
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          clipBehavior: widget.clipBehavior,
          statesController: widget.statesController,
          child: _buildButtonContent(context),
        );
        break;

      case ReusableButtonType.elevated:
        button = ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          onLongPress: isDisabled ? null : widget.onLongPress,
          style: widget.style ?? ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? theme.primaryColor,
            foregroundColor: widget.foregroundColor,
            disabledBackgroundColor: widget.disabledBackgroundColor,
            disabledForegroundColor: widget.disabledForegroundColor,
            shadowColor: widget.shadowColor,
            elevation: widget.elevation ?? 2,
            padding: _getButtonPadding(),
            minimumSize: Size(widget.minWidth ?? 0, widget.minHeight ?? 0),
            maximumSize: Size(widget.maxWidth ?? double.infinity, widget.maxHeight ?? double.infinity),
            shape: widget.shape ?? (widget.customBorderRadius != null
                ? RoundedRectangleBorder(borderRadius: widget.customBorderRadius!)
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                  )),
            tapTargetSize: widget.tapTargetSize,
            visualDensity: widget.visualDensity,
            enableFeedback: widget.enableFeedback,
            alignment: widget.alignment,
          ),
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          clipBehavior: widget.clipBehavior,
          statesController: widget.statesController,
          child: _buildButtonContent(context),
        );
        break;

      case ReusableButtonType.icon:
        button = IconButton(
          onPressed: isDisabled ? null : widget.onPressed,
          icon: widget.isLoading 
              ? SizedBox(
                  width: widget.iconSize ?? 24,
                  height: widget.iconSize ?? 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor ?? theme.primaryColor,
                    ),
                  ),
                )
              : Icon(
                  widget.icon ?? Icons.add,
                  size: widget.iconSize ?? 24,
                  color: widget.foregroundColor,
                ),
          iconSize: widget.iconSize ?? 24,
          padding: widget.padding ?? const EdgeInsets.all(8),
          alignment: widget.alignment ?? Alignment.center,
          splashRadius: widget.borderRadius,
          color: widget.foregroundColor,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          highlightColor: widget.highlightColor,
          splashColor: widget.splashColor,
          disabledColor: widget.disabledForegroundColor,
          mouseCursor: widget.mouseCursor,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          tooltip: widget.tooltip,
          enableFeedback: widget.enableFeedback,
          visualDensity: widget.visualDensity,
        );
        break;

      case ReusableButtonType.floatingAction:
        button = FloatingActionButton(
          onPressed: isDisabled ? null : widget.onPressed,
          backgroundColor: widget.backgroundColor ?? theme.primaryColor,
          foregroundColor: widget.foregroundColor,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          splashColor: widget.splashColor,
          elevation: widget.elevation ?? 6,
          focusElevation: widget.hoverElevation ?? 8,
          hoverElevation: widget.hoverElevation ?? 8,
          highlightElevation: widget.highlightElevation ?? 12,
          disabledElevation: widget.disabledElevation ?? 0,
          mini: widget.size == ReusableButtonSize.small,
          shape: widget.shape ?? (widget.customBorderRadius != null
              ? RoundedRectangleBorder(borderRadius: widget.customBorderRadius!)
              : const CircleBorder()),
          clipBehavior: widget.clipBehavior,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          materialTapTargetSize: widget.tapTargetSize,
          tooltip: widget.tooltip,
          enableFeedback: widget.enableFeedback,
          child: _buildButtonContent(context),
        );
        break;
    }

    // Apply size constraints
    if (widget.width != null || widget.height != null) {
      button = SizedBox(
        width: widget.width,
        height: widget.height,
        child: button,
      );
    }

    // Apply gradient
    if (widget.gradient != null || widget.gradientColors != null) {
      button = Container(
        decoration: BoxDecoration(
          gradient: widget.gradient ?? LinearGradient(
            colors: widget.gradientColors ?? [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            begin: widget.gradientBegin,
            end: widget.gradientEnd,
          ),
          borderRadius: widget.customBorderRadius ?? BorderRadius.circular(widget.borderRadius ?? 12),
          boxShadow: widget.boxShadow,
        ),
        child: button,
      );
    }

    // Apply animations
    if (widget.enableAnimation) {
      button = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: button,
      );
    }

    // Apply hover effects
    if (widget.enableHoverAnimation) {
      button = MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        cursor: widget.mouseCursor ?? (isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click),
        child: button,
      );
    }

    // Apply gesture detection
    button = GestureDetector(
      onTapDown: (_) {
        if (!isDisabled && widget.enableAnimation) {
          _animationController.forward();
          setState(() {
            _isPressed = true;
          });
        }
      },
      onTapUp: (_) {
        if (!isDisabled && widget.enableAnimation) {
          _animationController.reverse();
          setState(() {
            _isPressed = false;
          });
        }
      },
      onTapCancel: () {
        if (!isDisabled && widget.enableAnimation) {
          _animationController.reverse();
          setState(() {
            _isPressed = false;
          });
        }
      },
      onDoubleTap: isDisabled ? null : widget.onDoubleTap,
      child: button,
    );

    // Apply badge
    if (widget.showBadge && widget.badgeText != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
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
            ),
          ),
        ],
      );
    }

    // Apply tooltip
    if (widget.tooltip != null && widget.type != ReusableButtonType.icon && widget.type != ReusableButtonType.floatingAction) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    // Apply margin
    if (widget.margin != null) {
      button = Padding(
        padding: widget.margin!,
        child: button,
      );
    }

    return button;
  }

  @override
  Widget build(BuildContext context) {
    return _buildButton(context);
  }
}