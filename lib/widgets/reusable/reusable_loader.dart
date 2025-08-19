import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enum for loader types
enum ReusableLoaderType {
  circular,
  linear,
  dots,
  pulse,
  wave,
  cube,
  ring,
  ripple,
  bounce,
  fade,
  custom,
}

/// A highly customizable loader/spinner widget
class ReusableLoader extends StatefulWidget {
  // Core properties
  final ReusableLoaderType type;
  final double? size;
  final double? strokeWidth;
  final Color? color;
  final List<Color>? colors;
  final Gradient? gradient;
  
  // Animation
  final Duration? animationDuration;
  final Curve? animationCurve;
  final bool animate;
  
  // Progress
  final double? value;
  final double? minHeight;
  final String? label;
  final bool showLabel;
  final TextStyle? labelStyle;
  final String? semanticsLabel;
  final String? semanticsValue;
  
  // Container
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;
  
  // Custom
  final Widget? custom;
  final int itemCount;
  final double spacing;
  final Widget Function(BuildContext, int)? itemBuilder;
  
  // Overlay
  final bool showOverlay;
  final Color? overlayColor;
  final double? overlayOpacity;
  final bool dismissible;
  final VoidCallback? onDismiss;
  
  const ReusableLoader({
    super.key,
    this.type = ReusableLoaderType.circular,
    this.size,
    this.strokeWidth,
    this.color,
    this.colors,
    this.gradient,
    this.animationDuration,
    this.animationCurve,
    this.animate = true,
    this.value,
    this.minHeight,
    this.label,
    this.showLabel = false,
    this.labelStyle,
    this.semanticsLabel,
    this.semanticsValue,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
    this.width,
    this.height,
    this.custom,
    this.itemCount = 3,
    this.spacing = 8.0,
    this.itemBuilder,
    this.showOverlay = false,
    this.overlayColor,
    this.overlayOpacity,
    this.dismissible = false,
    this.onDismiss,
  });

  @override
  State<ReusableLoader> createState() => _ReusableLoaderState();
}

class _ReusableLoaderState extends State<ReusableLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<AnimationController>? _dotControllers;
  List<Animation<double>>? _dotAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final duration = widget.animationDuration ?? const Duration(milliseconds: 1500);
    
    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve ?? Curves.linear,
    );
    
    if (widget.animate) {
      if (widget.type == ReusableLoaderType.dots || 
          widget.type == ReusableLoaderType.bounce ||
          widget.type == ReusableLoaderType.wave) {
        _initializeDotAnimations();
      } else {
        _controller.repeat();
      }
    }
  }

  void _initializeDotAnimations() {
    _dotControllers = List.generate(
      widget.itemCount,
      (index) => AnimationController(
        duration: widget.animationDuration ?? const Duration(milliseconds: 1500),
        vsync: this,
      ),
    );
    
    _dotAnimations = _dotControllers!.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: widget.animationCurve ?? Curves.easeInOut,
        ),
      );
    }).toList();
    
    // Start animations with delay
    for (int i = 0; i < _dotControllers!.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _dotControllers![i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotControllers?.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Widget _buildLoader() {
    switch (widget.type) {
      case ReusableLoaderType.circular:
        return _buildCircularLoader();
      case ReusableLoaderType.linear:
        return _buildLinearLoader();
      case ReusableLoaderType.dots:
        return _buildDotsLoader();
      case ReusableLoaderType.pulse:
        return _buildPulseLoader();
      case ReusableLoaderType.wave:
        return _buildWaveLoader();
      case ReusableLoaderType.cube:
        return _buildCubeLoader();
      case ReusableLoaderType.ring:
        return _buildRingLoader();
      case ReusableLoaderType.ripple:
        return _buildRippleLoader();
      case ReusableLoaderType.bounce:
        return _buildBounceLoader();
      case ReusableLoaderType.fade:
        return _buildFadeLoader();
      case ReusableLoaderType.custom:
        return widget.custom ?? const SizedBox();
    }
  }

  Widget _buildCircularLoader() {
    final size = widget.size ?? 40.0;
    final strokeWidth = widget.strokeWidth ?? 4.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: widget.value,
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: color.withOpacity(0.2),
        semanticsLabel: widget.semanticsLabel,
        semanticsValue: widget.semanticsValue,
      ),
    );
  }

  Widget _buildLinearLoader() {
    final height = widget.minHeight ?? 4.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return SizedBox(
      height: height,
      child: LinearProgressIndicator(
        value: widget.value,
        minHeight: height,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: color.withOpacity(0.2),
        semanticsLabel: widget.semanticsLabel,
        semanticsValue: widget.semanticsValue,
      ),
    );
  }

  Widget _buildDotsLoader() {
    final size = widget.size ?? 12.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.itemCount, (index) {
        return AnimatedBuilder(
          animation: _dotAnimations?[index] ?? _animation,
          builder: (context, child) {
            final scale = 0.5 + (_dotAnimations?[index].value ?? 0) * 0.5;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3 + (_dotAnimations?[index].value ?? 0) * 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildPulseLoader() {
    final size = widget.size ?? 40.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(1.0 - _animation.value),
          ),
          child: Transform.scale(
            scale: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(1.0 - _animation.value),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveLoader() {
    final size = widget.size ?? 8.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.itemCount, (index) {
        return AnimatedBuilder(
          animation: _dotAnimations?[index] ?? _animation,
          builder: (context, child) {
            final height = size + (size * (_dotAnimations?[index].value ?? 0) * 2);
            return Container(
              width: size,
              height: height,
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size / 2),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildCubeLoader() {
    final size = widget.size ?? 40.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..rotateY(_animation.value * 2 * math.pi)
            ..rotateX(_animation.value * 2 * math.pi),
          alignment: Alignment.center,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRingLoader() {
    final size = widget.size ?? 40.0;
    final strokeWidth = widget.strokeWidth ?? 4.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.transparent,
                width: strokeWidth,
              ),
              gradient: SweepGradient(
                colors: [
                  color,
                  color.withOpacity(0.5),
                  color.withOpacity(0.1),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRippleLoader() {
    final size = widget.size ?? 60.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return Stack(
      alignment: Alignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final delay = index * 0.3;
            final progress = ((_animation.value + delay) % 1.0);
            return Container(
              width: size * progress,
              height: size * progress,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(1.0 - progress),
                  width: 2.0,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBounceLoader() {
    final size = widget.size ?? 12.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.itemCount, (index) {
        return AnimatedBuilder(
          animation: _dotAnimations?[index] ?? _animation,
          builder: (context, child) {
            final bounce = math.sin((_dotAnimations?[index].value ?? 0) * math.pi);
            return Transform.translate(
              offset: Offset(0, -bounce * 20),
              child: Container(
                width: size,
                height: size,
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFadeLoader() {
    final size = widget.size ?? 40.0;
    final color = widget.color ?? Theme.of(context).primaryColor;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_animation.value * 0.7),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget loader = _buildLoader();
    
    // Add label if needed
    if (widget.showLabel && widget.label != null) {
      loader = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 16),
          Text(
            widget.label!,
            style: widget.labelStyle ?? Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }
    
    // Apply container properties
    if (widget.width != null || widget.height != null || widget.decoration != null) {
      loader = Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        margin: widget.margin,
        alignment: widget.alignment ?? Alignment.center,
        decoration: widget.decoration,
        child: loader,
      );
    } else if (widget.padding != null || widget.margin != null) {
      loader = Container(
        padding: widget.padding,
        margin: widget.margin,
        alignment: widget.alignment,
        child: loader,
      );
    }
    
    // Apply overlay if needed
    if (widget.showOverlay) {
      loader = Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: widget.dismissible ? widget.onDismiss : null,
            child: Container(
              color: (widget.overlayColor ?? Colors.black)
                  .withOpacity(widget.overlayOpacity ?? 0.5),
            ),
          ),
          Center(child: loader),
        ],
      );
    }
    
    return loader;
  }
}

/// A convenient method to show a loading overlay
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  
  static void show(
    BuildContext context, {
    ReusableLoaderType type = ReusableLoaderType.circular,
    String? label,
    Color? color,
    Color? overlayColor,
    double? overlayOpacity,
    bool dismissible = false,
    VoidCallback? onDismiss,
  }) {
    _overlayEntry = OverlayEntry(
      builder: (context) => ReusableLoader(
        type: type,
        label: label,
        showLabel: label != null,
        color: color,
        showOverlay: true,
        overlayColor: overlayColor,
        overlayOpacity: overlayOpacity,
        dismissible: dismissible,
        onDismiss: () {
          hide();
          onDismiss?.call();
        },
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}