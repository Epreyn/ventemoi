import 'package:flutter/material.dart';

/// Enum for stat card styles
enum ReusableStatCardStyle {
  minimal,
  detailed,
  compact,
  expanded,
  gradient,
  custom,
}

/// Enum for stat card layouts
enum ReusableStatCardLayout {
  horizontal,
  vertical,
  grid,
  stacked,
}

/// Enum for trend directions
enum TrendDirection {
  up,
  down,
  neutral,
}

/// A highly customizable statistics card widget
class ReusableStatCard extends StatefulWidget {
  // Core properties
  final String title;
  final String value;
  final String? subtitle;
  final String? description;
  final ReusableStatCardStyle style;
  final ReusableStatCardLayout layout;
  
  // Icon
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? iconSize;
  final double? iconContainerSize;
  final BorderRadius? iconBorderRadius;
  final bool showIconBackground;
  
  // Trend/Change
  final double? changeValue;
  final String? changeText;
  final TrendDirection? trendDirection;
  final Color? trendColor;
  final Color? positiveColor;
  final Color? negativeColor;
  final Color? neutralColor;
  final IconData? trendUpIcon;
  final IconData? trendDownIcon;
  final IconData? trendNeutralIcon;
  final bool showTrendIcon;
  final bool showChangeAsPercentage;
  
  // Progress
  final double? progressValue;
  final double? maxProgressValue;
  final Color? progressColor;
  final Color? progressBackgroundColor;
  final double? progressHeight;
  final bool showProgressBar;
  final bool showProgressPercentage;
  final BorderRadius? progressBorderRadius;
  
  // Chart
  final List<double>? chartData;
  final Color? chartColor;
  final double? chartHeight;
  final bool showChart;
  final Widget? customChart;
  
  // Styling
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  
  // Text Styling
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? descriptionStyle;
  final TextStyle? changeTextStyle;
  final TextAlign? textAlign;
  final int? titleMaxLines;
  final int? valueMaxLines;
  final TextOverflow? textOverflow;
  
  // Animation
  final Duration? animationDuration;
  final Curve? animationCurve;
  final bool enableAnimation;
  final bool animateValue;
  final bool animateProgress;
  
  // Interaction
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final bool enableRipple;
  final Color? splashColor;
  final Color? highlightColor;
  final MouseCursor? mouseCursor;
  
  // Actions
  final Widget? trailing;
  final List<Widget>? actions;
  final PopupMenuButton? menu;
  final bool showMoreButton;
  final VoidCallback? onMoreTap;
  
  // Badge
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final bool showBadge;
  
  // Misc
  final String? tooltip;
  final String? semanticsLabel;
  final bool isLoading;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final bool isEmpty;
  final Clip clipBehavior;
  
  const ReusableStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.description,
    this.style = ReusableStatCardStyle.minimal,
    this.layout = ReusableStatCardLayout.vertical,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.iconBackgroundColor,
    this.iconSize,
    this.iconContainerSize,
    this.iconBorderRadius,
    this.showIconBackground = true,
    this.changeValue,
    this.changeText,
    this.trendDirection,
    this.trendColor,
    this.positiveColor,
    this.negativeColor,
    this.neutralColor,
    this.trendUpIcon,
    this.trendDownIcon,
    this.trendNeutralIcon,
    this.showTrendIcon = true,
    this.showChangeAsPercentage = true,
    this.progressValue,
    this.maxProgressValue,
    this.progressColor,
    this.progressBackgroundColor,
    this.progressHeight,
    this.showProgressBar = false,
    this.showProgressPercentage = false,
    this.progressBorderRadius,
    this.chartData,
    this.chartColor,
    this.chartHeight,
    this.showChart = false,
    this.customChart,
    this.backgroundColor,
    this.backgroundGradient,
    this.gradientColors,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.elevation,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.titleStyle,
    this.valueStyle,
    this.subtitleStyle,
    this.descriptionStyle,
    this.changeTextStyle,
    this.textAlign,
    this.titleMaxLines,
    this.valueMaxLines,
    this.textOverflow,
    this.animationDuration,
    this.animationCurve,
    this.enableAnimation = true,
    this.animateValue = true,
    this.animateProgress = true,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.enableRipple = true,
    this.splashColor,
    this.highlightColor,
    this.mouseCursor,
    this.trailing,
    this.actions,
    this.menu,
    this.showMoreButton = false,
    this.onMoreTap,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.showBadge = false,
    this.tooltip,
    this.semanticsLabel,
    this.isLoading = false,
    this.loadingWidget,
    this.emptyWidget,
    this.isEmpty = false,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  State<ReusableStatCard> createState() => _ReusableStatCardState();
}

class _ReusableStatCardState extends State<ReusableStatCard>
    with TickerProviderStateMixin {
  late AnimationController _valueController;
  late Animation<double> _valueAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    final duration = widget.animationDuration ?? const Duration(milliseconds: 1000);
    final curve = widget.animationCurve ?? Curves.easeOutCubic;
    
    _valueController = AnimationController(
      duration: duration,
      vsync: this,
    );
    _valueAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _valueController,
      curve: curve,
    ));
    
    _progressController = AnimationController(
      duration: duration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progressValue ?? 0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: curve,
    ));
    
    if (widget.enableAnimation) {
      if (widget.animateValue) {
        _valueController.forward();
      }
      if (widget.animateProgress && widget.showProgressBar) {
        _progressController.forward();
      }
    }
  }
  
  @override
  void dispose() {
    _valueController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  Color _getTrendColor() {
    if (widget.trendColor != null) return widget.trendColor!;
    
    switch (widget.trendDirection) {
      case TrendDirection.up:
        return widget.positiveColor ?? Colors.green;
      case TrendDirection.down:
        return widget.negativeColor ?? Colors.red;
      case TrendDirection.neutral:
        return widget.neutralColor ?? Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getTrendIcon() {
    switch (widget.trendDirection) {
      case TrendDirection.up:
        return widget.trendUpIcon ?? Icons.trending_up;
      case TrendDirection.down:
        return widget.trendDownIcon ?? Icons.trending_down;
      case TrendDirection.neutral:
        return widget.trendNeutralIcon ?? Icons.trending_flat;
      default:
        return Icons.trending_flat;
    }
  }
  
  Widget _buildIcon() {
    final iconWidget = widget.iconWidget ??
        (widget.icon != null
            ? Icon(
                widget.icon,
                size: widget.iconSize ?? 24,
                color: widget.iconColor ?? Colors.white,
              )
            : null);
    
    if (iconWidget == null) return const SizedBox();
    
    if (widget.showIconBackground) {
      return Container(
        width: widget.iconContainerSize ?? 48,
        height: widget.iconContainerSize ?? 48,
        decoration: BoxDecoration(
          color: widget.iconBackgroundColor ?? widget.iconColor?.withOpacity(0.1),
          borderRadius: widget.iconBorderRadius ?? BorderRadius.circular(12),
        ),
        child: Center(child: iconWidget),
      );
    }
    
    return iconWidget;
  }
  
  Widget _buildTrend() {
    if (widget.changeValue == null && widget.changeText == null) {
      return const SizedBox();
    }
    
    final trendColor = _getTrendColor();
    final changeText = widget.changeText ??
        (widget.showChangeAsPercentage
            ? '${widget.changeValue?.toStringAsFixed(1)}%'
            : widget.changeValue?.toStringAsFixed(2) ?? '');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTrendIcon)
          Icon(
            _getTrendIcon(),
            size: 16,
            color: trendColor,
          ),
        if (widget.showTrendIcon) const SizedBox(width: 4),
        Text(
          changeText,
          style: widget.changeTextStyle ??
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
        ),
      ],
    );
  }
  
  Widget _buildProgressBar() {
    final progress = widget.progressValue ?? 0;
    final maxProgress = widget.maxProgressValue ?? 100;
    final percentage = (progress / maxProgress).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showProgressPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        Container(
          height: widget.progressHeight ?? 4,
          decoration: BoxDecoration(
            color: widget.progressBackgroundColor ?? Colors.grey[200],
            borderRadius: widget.progressBorderRadius ?? BorderRadius.circular(2),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                widthFactor: widget.animateProgress
                    ? _progressAnimation.value / maxProgress
                    : percentage,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.progressColor ?? Theme.of(context).primaryColor,
                    borderRadius: widget.progressBorderRadius ?? BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildChart() {
    if (widget.customChart != null) {
      return widget.customChart!;
    }
    
    if (widget.chartData == null || widget.chartData!.isEmpty) {
      return const SizedBox();
    }
    
    // Simple line chart representation
    return SizedBox(
      height: widget.chartHeight ?? 40,
      child: CustomPaint(
        painter: _SimpleChartPainter(
          data: widget.chartData!,
          color: widget.chartColor ?? Theme.of(context).primaryColor,
        ),
        size: Size.infinite,
      ),
    );
  }
  
  Widget _buildContent() {
    if (widget.isLoading) {
      return Center(
        child: widget.loadingWidget ??
            const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    if (widget.isEmpty && widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }
    
    switch (widget.layout) {
      case ReusableStatCardLayout.horizontal:
        return _buildHorizontalLayout();
      case ReusableStatCardLayout.vertical:
        return _buildVerticalLayout();
      case ReusableStatCardLayout.grid:
        return _buildGridLayout();
      case ReusableStatCardLayout.stacked:
        return _buildStackedLayout();
    }
  }
  
  Widget _buildVerticalLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icon != null || widget.iconWidget != null) ...[
              _buildIcon(),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: widget.titleStyle ??
                        TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                    maxLines: widget.titleMaxLines ?? 1,
                    overflow: widget.textOverflow ?? TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: widget.subtitleStyle ??
                          TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
            if (widget.showMoreButton)
              IconButton(
                icon: const Icon(Icons.more_vert, size: 18),
                onPressed: widget.onMoreTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _valueAnimation,
          builder: (context, child) {
            if (widget.animateValue && double.tryParse(widget.value) != null) {
              final targetValue = double.parse(widget.value);
              final currentValue = targetValue * _valueAnimation.value;
              return Text(
                currentValue.toStringAsFixed(0),
                style: widget.valueStyle ??
                    const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: widget.valueMaxLines ?? 1,
                overflow: widget.textOverflow ?? TextOverflow.ellipsis,
              );
            }
            return Text(
              widget.value,
              style: widget.valueStyle ??
                  const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: widget.valueMaxLines ?? 1,
              overflow: widget.textOverflow ?? TextOverflow.ellipsis,
            );
          },
        ),
        if (widget.changeValue != null || widget.changeText != null) ...[
          const SizedBox(height: 8),
          _buildTrend(),
        ],
        if (widget.description != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.description!,
            style: widget.descriptionStyle ??
                TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
          ),
        ],
        if (widget.showProgressBar) ...[
          const SizedBox(height: 12),
          _buildProgressBar(),
        ],
        if (widget.showChart) ...[
          const SizedBox(height: 12),
          _buildChart(),
        ],
        if (widget.actions != null && widget.actions!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: widget.actions!,
          ),
        ],
      ],
    );
  }
  
  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        if (widget.icon != null || widget.iconWidget != null) ...[
          _buildIcon(),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: widget.titleStyle ??
                    TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                maxLines: widget.titleMaxLines ?? 1,
                overflow: widget.textOverflow ?? TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    widget.value,
                    style: widget.valueStyle ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (widget.changeValue != null || widget.changeText != null) ...[
                    const SizedBox(width: 12),
                    _buildTrend(),
                  ],
                ],
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: widget.subtitleStyle ??
                      TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                ),
            ],
          ),
        ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }
  
  Widget _buildGridLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (widget.icon != null || widget.iconWidget != null) _buildIcon(),
            const Spacer(),
            if (widget.changeValue != null || widget.changeText != null) _buildTrend(),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.value,
            style: widget.valueStyle ??
                const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.title,
            style: widget.titleStyle ??
                TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStackedLayout() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: widget.titleStyle ??
                  TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.value,
              style: widget.valueStyle ??
                  const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (widget.changeValue != null || widget.changeText != null) ...[
              const SizedBox(height: 8),
              _buildTrend(),
            ],
          ],
        ),
        if (widget.icon != null || widget.iconWidget != null)
          Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                widget.icon,
                size: 64,
                color: widget.iconColor,
              ),
            ),
          ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget card = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        gradient: widget.backgroundGradient ??
            (widget.gradientColors != null
                ? LinearGradient(
                    colors: widget.gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        border: widget.borderWidth != null
            ? Border.all(
                color: widget.borderColor ?? Colors.grey[200]!,
                width: widget.borderWidth!,
              )
            : null,
        boxShadow: widget.boxShadow ??
            (widget.elevation != null
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05 * widget.elevation!),
                      blurRadius: widget.elevation!,
                      offset: Offset(0, widget.elevation! / 2),
                    ),
                  ]
                : null),
      ),
      child: _buildContent(),
    );
    
    // Add interaction
    if (widget.onTap != null || widget.onLongPress != null || widget.onDoubleTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onDoubleTap: widget.onDoubleTap,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          splashColor: widget.splashColor,
          highlightColor: widget.highlightColor,
          mouseCursor: widget.mouseCursor,
          child: card,
        ),
      );
    }
    
    // Add badge
    if (widget.showBadge && widget.badgeText != null) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.badgeText!,
                style: TextStyle(
                  color: widget.badgeTextColor ?? Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // Add tooltip
    if (widget.tooltip != null) {
      card = Tooltip(
        message: widget.tooltip!,
        child: card,
      );
    }
    
    // Add margin
    if (widget.margin != null) {
      card = Padding(
        padding: widget.margin!,
        child: card,
      );
    }
    
    return card;
  }
}

class _SimpleChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  
  _SimpleChartPainter({
    required this.data,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}