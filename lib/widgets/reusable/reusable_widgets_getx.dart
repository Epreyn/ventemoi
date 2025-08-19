import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'dart:io';

// ============================================================================
// CONTROLLERS
// ============================================================================

/// Controller for ReusableButtonX
class ReusableButtonController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  
  final RxBool isHovered = false.obs;
  final RxBool isPressed = false.obs;
  final double pressScale;
  
  ReusableButtonController({this.pressScale = 0.95});
  
  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    scaleAnimation = Tween<double>(
      begin: 1.0,
      end: pressScale,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
  
  void animatePress() {
    animationController.forward();
  }
  
  void animateRelease() {
    animationController.reverse();
  }
}

/// Controller for ReusableLoaderX
class ReusableLoaderController extends GetxController with GetTickerProviderStateMixin {
  late AnimationController mainController;
  late Animation<double> mainAnimation;
  List<AnimationController> dotControllers = [];
  List<Animation<double>> dotAnimations = [];
  
  final int itemCount;
  final Duration duration;
  
  ReusableLoaderController({
    this.itemCount = 3,
    this.duration = const Duration(milliseconds: 1500),
  });
  
  @override
  void onInit() {
    super.onInit();
    mainController = AnimationController(duration: duration, vsync: this);
    mainAnimation = CurvedAnimation(parent: mainController, curve: Curves.linear);
    mainController.repeat();
  }
  
  void initDotAnimations() {
    for (int i = 0; i < itemCount; i++) {
      final controller = AnimationController(duration: duration, vsync: this);
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
      dotControllers.add(controller);
      dotAnimations.add(animation);
      
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (!controller.isDisposed) {
          controller.repeat(reverse: true);
        }
      });
    }
  }
  
  @override
  void onClose() {
    mainController.dispose();
    for (var controller in dotControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}

/// Controller for ReusableAvatarX
class ReusableAvatarController extends GetxController with GetTickerProviderStateMixin {
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;
  late AnimationController scaleController;
  late Animation<double> scaleAnimation;
  
  final RxBool isHovered = false.obs;
  final RxBool hasError = false.obs;
  final bool enablePulse;
  final double hoverScale;
  
  ReusableAvatarController({
    this.enablePulse = true,
    this.hoverScale = 1.05,
  });
  
  @override
  void onInit() {
    super.onInit();
    
    pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );
    
    if (enablePulse) {
      pulseController.repeat(reverse: true);
    }
    
    scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    scaleAnimation = Tween<double>(begin: 1.0, end: hoverScale).animate(
      CurvedAnimation(parent: scaleController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void onClose() {
    pulseController.dispose();
    scaleController.dispose();
    super.onClose();
  }
  
  void setHovered(bool value) {
    isHovered.value = value;
    if (value) {
      scaleController.forward();
    } else {
      scaleController.reverse();
    }
  }
}

/// Controller for ReusableSearchBarX
class ReusableSearchBarController extends GetxController with GetSingleTickerProviderStateMixin {
  late TextEditingController textController;
  late FocusNode focusNode;
  late AnimationController animationController;
  late Animation<double> animation;
  
  final RxBool isFocused = false.obs;
  final RxBool hasText = false.obs;
  final RxList<String> filteredSuggestions = <String>[].obs;
  final LayerLink layerLink = LayerLink();
  OverlayEntry? overlayEntry;
  
  final List<String>? suggestions;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSuggestionSelected;
  
  ReusableSearchBarController({
    TextEditingController? controller,
    FocusNode? focusNode,
    this.suggestions,
    this.onChanged,
    this.onSuggestionSelected,
  }) {
    textController = controller ?? TextEditingController();
    this.focusNode = focusNode ?? FocusNode();
  }
  
  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    animation = CurvedAnimation(parent: animationController, curve: Curves.easeInOut);
    
    textController.addListener(_onTextChanged);
    this.focusNode.addListener(_onFocusChanged);
    
    if (suggestions != null) {
      filteredSuggestions.value = suggestions!;
    }
  }
  
  @override
  void onClose() {
    animationController.dispose();
    removeOverlay();
    super.onClose();
  }
  
  void _onTextChanged() {
    hasText.value = textController.text.isNotEmpty;
    
    if (suggestions != null) {
      final query = textController.text.toLowerCase();
      filteredSuggestions.value = suggestions!
          .where((s) => s.toLowerCase().contains(query))
          .toList();
    }
    
    onChanged?.call(textController.text);
  }
  
  void _onFocusChanged() {
    isFocused.value = focusNode.hasFocus;
    if (isFocused.value) {
      animationController.forward();
    } else {
      animationController.reverse();
      removeOverlay();
    }
  }
  
  void clearText() {
    textController.clear();
  }
  
  void selectSuggestion(String suggestion) {
    textController.text = suggestion;
    onSuggestionSelected?.call(suggestion);
    removeOverlay();
  }
  
  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }
}

/// Controller for ReusableStatCardX
class ReusableStatCardController extends GetxController with GetTickerProviderStateMixin {
  late AnimationController valueController;
  late Animation<double> valueAnimation;
  late AnimationController progressController;
  late Animation<double> progressAnimation;
  
  final double? progressValue;
  final bool animateValue;
  final bool animateProgress;
  
  ReusableStatCardController({
    this.progressValue,
    this.animateValue = true,
    this.animateProgress = true,
  });
  
  @override
  void onInit() {
    super.onInit();
    
    valueController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    valueAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: valueController, curve: Curves.easeOutCubic),
    );
    
    progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    progressAnimation = Tween<double>(begin: 0, end: progressValue ?? 0).animate(
      CurvedAnimation(parent: progressController, curve: Curves.easeOutCubic),
    );
    
    if (animateValue) valueController.forward();
    if (animateProgress && progressValue != null) progressController.forward();
  }
  
  @override
  void onClose() {
    valueController.dispose();
    progressController.dispose();
    super.onClose();
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

/// Optimized GetX Button Widget
class ReusableButtonX extends StatelessWidget {
  final String tag;
  final String? text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool isLoading;
  final bool isDisabled;
  final bool filled;
  final bool outlined;
  final Widget? child;
  
  const ReusableButtonX({
    super.key,
    required this.tag,
    this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.isDisabled = false,
    this.filled = true,
    this.outlined = false,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ReusableButtonController(), tag: tag);
    final theme = Theme.of(context);
    final effectiveDisabled = isDisabled || isLoading || onPressed == null;
    
    Widget content = child ?? Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? Colors.white,
              ),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: foregroundColor),
        if ((icon != null || isLoading) && text != null)
          const SizedBox(width: 8),
        if (text != null)
          Text(
            text!,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
    
    return GestureDetector(
      onTapDown: effectiveDisabled ? null : (_) => cc.animatePress(),
      onTapUp: effectiveDisabled ? null : (_) {
        cc.animateRelease();
        onPressed?.call();
      },
      onTapCancel: effectiveDisabled ? null : cc.animateRelease,
      child: AnimatedBuilder(
        animation: cc.scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: cc.scaleAnimation.value,
          child: Container(
            width: width,
            height: height ?? 48,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: outlined ? Colors.transparent : (backgroundColor ?? theme.primaryColor),
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
              border: outlined ? Border.all(
                color: backgroundColor ?? theme.primaryColor,
                width: 1.5,
              ) : null,
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

/// Optimized GetX Loader Widget
class ReusableLoaderX extends StatelessWidget {
  final String tag;
  final double? size;
  final Color? color;
  final String? label;
  
  const ReusableLoaderX({
    super.key,
    required this.tag,
    this.size,
    this.color,
    this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ReusableLoaderController(), tag: tag);
    final effectiveColor = color ?? Theme.of(context).primaryColor;
    final effectiveSize = size ?? 40.0;
    
    Widget loader = AnimatedBuilder(
      animation: cc.mainAnimation,
      builder: (context, child) => Transform.rotate(
        angle: cc.mainAnimation.value * 2 * math.pi,
        child: Container(
          width: effectiveSize,
          height: effectiveSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.transparent,
              width: 4,
            ),
            gradient: SweepGradient(
              colors: [
                effectiveColor,
                effectiveColor.withOpacity(0.5),
                effectiveColor.withOpacity(0.1),
                Colors.transparent,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
    
    if (label != null) {
      loader = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 16),
          Text(label!),
        ],
      );
    }
    
    return loader;
  }
}

/// Optimized GetX Avatar Widget
class ReusableAvatarX extends StatelessWidget {
  final String tag;
  final String? imageUrl;
  final String? text;
  final IconData? icon;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showStatus;
  final Color? statusColor;
  final VoidCallback? onTap;
  
  const ReusableAvatarX({
    super.key,
    required this.tag,
    this.imageUrl,
    this.text,
    this.icon,
    this.size,
    this.backgroundColor,
    this.foregroundColor,
    this.showStatus = false,
    this.statusColor,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ReusableAvatarController(), tag: tag);
    final theme = Theme.of(context);
    final effectiveSize = size ?? 48.0;
    final effectiveBackgroundColor = backgroundColor ?? theme.primaryColor;
    final effectiveForegroundColor = foregroundColor ?? Colors.white;
    
    Widget content;
    if (imageUrl != null) {
      content = ClipOval(
        child: Image.network(
          imageUrl!,
          width: effectiveSize,
          height: effectiveSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            cc.hasError.value = true;
            return Icon(
              Icons.error_outline,
              size: effectiveSize * 0.5,
              color: Colors.red,
            );
          },
        ),
      );
    } else if (text != null) {
      final initials = text!.split(' ')
          .take(2)
          .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
          .join();
      content = Text(
        initials,
        style: TextStyle(
          fontSize: effectiveSize * 0.4,
          fontWeight: FontWeight.w600,
          color: effectiveForegroundColor,
        ),
      );
    } else {
      content = Icon(
        icon ?? Icons.person,
        size: effectiveSize * 0.6,
        color: effectiveForegroundColor,
      );
    }
    
    Widget avatar = Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        color: imageUrl != null ? null : effectiveBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: content),
    );
    
    if (showStatus) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: cc.pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: cc.pulseAnimation.value,
                child: Container(
                  width: effectiveSize * 0.25,
                  height: effectiveSize * 0.25,
                  decoration: BoxDecoration(
                    color: statusColor ?? Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    if (onTap != null) {
      avatar = MouseRegion(
        onEnter: (_) => cc.setHovered(true),
        onExit: (_) => cc.setHovered(false),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedBuilder(
            animation: cc.scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: cc.scaleAnimation.value,
              child: avatar,
            ),
          ),
        ),
      );
    }
    
    return avatar;
  }
}

/// Optimized GetX Search Bar Widget
class ReusableSearchBarX extends StatelessWidget {
  final String tag;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<String>? suggestions;
  final bool showClearButton;
  final Color? backgroundColor;
  final double? borderRadius;
  
  const ReusableSearchBarX({
    super.key,
    required this.tag,
    this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.suggestions,
    this.showClearButton = true,
    this.backgroundColor,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final cc = Get.put(
      ReusableSearchBarController(
        controller: controller,
        focusNode: focusNode,
        suggestions: suggestions,
        onChanged: onChanged,
      ),
      tag: tag,
    );
    
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
      ),
      child: TextField(
        controller: cc.textController,
        focusNode: cc.focusNode,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: cc.hasText.value && showClearButton
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: cc.clearText,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onSubmitted: onSubmitted,
      ),
    ));
  }
}

/// Optimized GetX Stat Card Widget
class ReusableStatCardX extends StatelessWidget {
  final String tag;
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final double? changeValue;
  final Color? changeColor;
  final double? progressValue;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? borderRadius;
  
  const ReusableStatCardX({
    super.key,
    required this.tag,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.changeValue,
    this.changeColor,
    this.progressValue,
    this.onTap,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final cc = Get.put(
      ReusableStatCardController(
        progressValue: progressValue,
        animateValue: true,
        animateProgress: progressValue != null,
      ),
      tag: tag,
    );
    
    final theme = Theme.of(context);
    
    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor ?? theme.primaryColor),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: cc.valueAnimation,
            builder: (context, child) {
              if (double.tryParse(value) != null) {
                final targetValue = double.parse(value);
                final currentValue = targetValue * cc.valueAnimation.value;
                return Text(
                  currentValue.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                );
              }
              return Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              );
            },
          ),
          if (changeValue != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  changeValue! > 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: changeColor ?? (changeValue! > 0 ? Colors.green : Colors.red),
                ),
                const SizedBox(width: 4),
                Text(
                  '${changeValue!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: changeColor ?? (changeValue! > 0 ? Colors.green : Colors.red),
                  ),
                ),
              ],
            ),
          ],
          if (progressValue != null) ...[
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: cc.progressAnimation,
              builder: (context, child) => LinearProgressIndicator(
                value: cc.progressAnimation.value / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
    
    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        child: card,
      );
    }
    
    return card;
  }
}

/// Optimized GetX Empty State Widget
class ReusableEmptyStateX extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double? iconSize;
  final Color? iconColor;
  
  const ReusableEmptyStateX({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize,
    this.iconColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize ?? 80,
            height: iconSize ?? 80,
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.grey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.inbox,
              size: (iconSize ?? 80) * 0.5,
              color: iconColor ?? Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}