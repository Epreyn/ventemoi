import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

/// Enum for search bar styles
enum ReusableSearchBarStyle {
  filled,
  outlined,
  underlined,
  elevated,
  flat,
  custom,
}

/// A highly customizable search bar widget
class ReusableSearchBar extends StatefulWidget {
  // Core properties
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final ReusableSearchBarStyle style;
  
  // Search functionality
  final bool showSearchIcon;
  final IconData? searchIcon;
  final bool showClearButton;
  final IconData? clearIcon;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  
  // Filters and actions
  final Widget? leading;
  final Widget? trailing;
  final List<Widget>? actions;
  final bool showFilterButton;
  final IconData? filterIcon;
  final VoidCallback? onFilterTap;
  final int? filterCount;
  final Color? filterBadgeColor;
  
  // Voice search
  final bool showVoiceSearch;
  final IconData? voiceIcon;
  final VoidCallback? onVoiceTap;
  
  // Suggestions
  final List<String>? suggestions;
  final Widget Function(BuildContext, String)? suggestionBuilder;
  final ValueChanged<String>? onSuggestionSelected;
  final bool showSuggestions;
  final double? suggestionsMaxHeight;
  final Color? suggestionsBackgroundColor;
  final BorderRadius? suggestionsBorderRadius;
  final EdgeInsetsGeometry? suggestionsPadding;
  
  // Styling
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? contentPadding;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? borderWidth;
  final double? borderRadius;
  final BorderRadius? customBorderRadius;
  final Gradient? backgroundGradient;
  final List<BoxShadow>? boxShadow;
  final double? elevation;
  
  // Text styling
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextAlign? textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final bool? showCursor;
  final double? cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  
  // Icons styling
  final Color? iconColor;
  final double? iconSize;
  final EdgeInsetsGeometry? iconPadding;
  
  // Animation
  final Duration? animationDuration;
  final Curve? animationCurve;
  final bool enableAnimation;
  
  // Misc
  final String? semanticsLabel;
  final bool enableInteractiveSelection;
  final bool obscureText;
  final String obscuringCharacter;
  final MouseCursor? mouseCursor;
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;
  final Clip clipBehavior;
  final String? restorationId;
  final bool scribbleEnabled;
  final bool enableIMEPersonalizedLearning;
  final Iterable<String>? autofillHints;
  final void Function(String, Map<String, dynamic>)? onAppPrivateCommand;
  final bool? enableSuggestions;
  final double? scrollPadding;
  final DragStartBehavior dragStartBehavior;
  final bool expands;
  final TapRegionCallback? onTapOutside;
  final Brightness? keyboardAppearance;
  final StrutStyle? strutStyle;
  final bool canRequestFocus;
  final UndoHistoryController? undoController;
  final SpellCheckConfiguration? spellCheckConfiguration;
  final TextMagnifierConfiguration? magnifierConfiguration;
  
  const ReusableSearchBar({
    super.key,
    this.hintText,
    this.labelText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.onClear,
    this.style = ReusableSearchBarStyle.filled,
    this.showSearchIcon = true,
    this.searchIcon,
    this.showClearButton = true,
    this.clearIcon,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.leading,
    this.trailing,
    this.actions,
    this.showFilterButton = false,
    this.filterIcon,
    this.onFilterTap,
    this.filterCount,
    this.filterBadgeColor,
    this.showVoiceSearch = false,
    this.voiceIcon,
    this.onVoiceTap,
    this.suggestions,
    this.suggestionBuilder,
    this.onSuggestionSelected,
    this.showSuggestions = true,
    this.suggestionsMaxHeight,
    this.suggestionsBackgroundColor,
    this.suggestionsBorderRadius,
    this.suggestionsPadding,
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.contentPadding,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderWidth,
    this.borderRadius,
    this.customBorderRadius,
    this.backgroundGradient,
    this.boxShadow,
    this.elevation,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.textAlign,
    this.textAlignVertical,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.showCursor,
    this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.iconColor,
    this.iconSize,
    this.iconPadding,
    this.animationDuration,
    this.animationCurve,
    this.enableAnimation = true,
    this.semanticsLabel,
    this.enableInteractiveSelection = true,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.mouseCursor,
    this.scrollPhysics,
    this.scrollController,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.scribbleEnabled = true,
    this.enableIMEPersonalizedLearning = true,
    this.autofillHints,
    this.onAppPrivateCommand,
    this.enableSuggestions,
    this.scrollPadding,
    this.dragStartBehavior = DragStartBehavior.start,
    this.expands = false,
    this.onTapOutside,
    this.keyboardAppearance,
    this.strutStyle,
    this.canRequestFocus = true,
    this.undoController,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
  });

  @override
  State<ReusableSearchBar> createState() => _ReusableSearchBarState();
}

class _ReusableSearchBarState extends State<ReusableSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFocused = false;
  bool _hasText = false;
  List<String> _filteredSuggestions = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _controller.text.isNotEmpty;
    
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve ?? Curves.easeInOut,
    );
    
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    if (widget.suggestions != null && widget.suggestions!.isNotEmpty) {
      _filteredSuggestions = widget.suggestions!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    
    // Filter suggestions
    if (widget.suggestions != null && widget.showSuggestions) {
      final query = _controller.text.toLowerCase();
      setState(() {
        _filteredSuggestions = widget.suggestions!
            .where((suggestion) => suggestion.toLowerCase().contains(query))
            .toList();
      });
      
      if (_filteredSuggestions.isNotEmpty && _isFocused) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
    
    widget.onChanged?.call(_controller.text);
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _animationController.forward();
      if (_filteredSuggestions.isNotEmpty && widget.showSuggestions) {
        _showOverlay();
      }
    } else {
      _animationController.reverse();
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: context.findRenderObject()?.paintBounds.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, widget.height ?? 48),
          child: _buildSuggestionsOverlay(),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsOverlay() {
    return Material(
      elevation: widget.elevation ?? 4,
      borderRadius: widget.suggestionsBorderRadius ?? BorderRadius.circular(8),
      color: widget.suggestionsBackgroundColor ?? Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: widget.suggestionsMaxHeight ?? 200,
        ),
        child: ListView.builder(
          padding: widget.suggestionsPadding ?? EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _filteredSuggestions.length,
          itemBuilder: (context, index) {
            final suggestion = _filteredSuggestions[index];
            
            if (widget.suggestionBuilder != null) {
              return InkWell(
                onTap: () {
                  _controller.text = suggestion;
                  widget.onSuggestionSelected?.call(suggestion);
                  _removeOverlay();
                },
                child: widget.suggestionBuilder!(context, suggestion),
              );
            }
            
            return ListTile(
              dense: true,
              title: Text(suggestion),
              onTap: () {
                _controller.text = suggestion;
                widget.onSuggestionSelected?.call(suggestion);
                _removeOverlay();
              },
            );
          },
        ),
      ),
    );
  }

  InputBorder _getBorder(Color color, double width) {
    final borderRadius = widget.customBorderRadius ??
        BorderRadius.circular(widget.borderRadius ?? 24);
    
    switch (widget.style) {
      case ReusableSearchBarStyle.outlined:
        return OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: color, width: width),
        );
      case ReusableSearchBarStyle.underlined:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
        );
      default:
        return OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        );
    }
  }

  Widget _buildTextField() {
    final theme = Theme.of(context);
    final defaultBorderColor = widget.borderColor ?? Colors.grey[300]!;
    final defaultFocusedBorderColor = widget.focusedBorderColor ?? theme.primaryColor;
    final defaultBorderWidth = widget.borderWidth ?? 1.0;
    
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Search...',
        hintStyle: widget.hintStyle,
        labelText: widget.labelText,
        labelStyle: widget.labelStyle,
        prefixIcon: widget.leading ??
            (widget.showSearchIcon
                ? Icon(
                    widget.searchIcon ?? Icons.search,
                    size: widget.iconSize ?? 20,
                    color: widget.iconColor ?? Colors.grey[600],
                  )
                : null),
        suffixIcon: _buildSuffixIcons(),
        border: _getBorder(defaultBorderColor, defaultBorderWidth),
        enabledBorder: _getBorder(defaultBorderColor, defaultBorderWidth),
        focusedBorder: _getBorder(defaultFocusedBorderColor, defaultBorderWidth + 0.5),
        filled: widget.style == ReusableSearchBarStyle.filled ||
            widget.style == ReusableSearchBarStyle.elevated,
        fillColor: widget.backgroundColor ?? Colors.grey[100],
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        isDense: true,
      ),
      style: widget.textStyle,
      textAlign: widget.textAlign ?? TextAlign.start,
      textAlignVertical: widget.textAlignVertical,
      textCapitalization: widget.textCapitalization,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction ?? TextInputAction.search,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      showCursor: widget.showCursor,
      cursorWidth: widget.cursorWidth ?? 2.0,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      obscuringCharacter: widget.obscuringCharacter,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      mouseCursor: widget.mouseCursor,
      scrollPhysics: widget.scrollPhysics,
      scrollController: widget.scrollController,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId,
      scribbleEnabled: widget.scribbleEnabled,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      autofillHints: widget.autofillHints,
      onAppPrivateCommand: widget.onAppPrivateCommand,
      enableSuggestions: widget.enableSuggestions ?? true,
      scrollPadding: EdgeInsets.all(widget.scrollPadding ?? 20.0),
      dragStartBehavior: widget.dragStartBehavior,
      expands: widget.expands,
      onTapOutside: widget.onTapOutside,
      keyboardAppearance: widget.keyboardAppearance,
      strutStyle: widget.strutStyle,
      canRequestFocus: widget.canRequestFocus,
      undoController: widget.undoController,
      spellCheckConfiguration: widget.spellCheckConfiguration,
      magnifierConfiguration: widget.magnifierConfiguration,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onTap: widget.onTap,
    );
  }

  Widget? _buildSuffixIcons() {
    final List<Widget> icons = [];
    
    // Clear button
    if (widget.showClearButton && _hasText) {
      icons.add(
        IconButton(
          icon: Icon(
            widget.clearIcon ?? Icons.clear,
            size: widget.iconSize ?? 20,
            color: widget.iconColor ?? Colors.grey[600],
          ),
          onPressed: () {
            _controller.clear();
            widget.onClear?.call();
          },
          padding: widget.iconPadding ?? EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }
    
    // Voice search
    if (widget.showVoiceSearch) {
      icons.add(
        IconButton(
          icon: Icon(
            widget.voiceIcon ?? Icons.mic,
            size: widget.iconSize ?? 20,
            color: widget.iconColor ?? Colors.grey[600],
          ),
          onPressed: widget.onVoiceTap,
          padding: widget.iconPadding ?? EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }
    
    // Filter button
    if (widget.showFilterButton) {
      icons.add(
        Stack(
          children: [
            IconButton(
              icon: Icon(
                widget.filterIcon ?? Icons.filter_list,
                size: widget.iconSize ?? 20,
                color: widget.iconColor ?? Colors.grey[600],
              ),
              onPressed: widget.onFilterTap,
              padding: widget.iconPadding ?? EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            if (widget.filterCount != null && widget.filterCount! > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.filterBadgeColor ?? Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    widget.filterCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    // Trailing widget
    if (widget.trailing != null) {
      icons.add(widget.trailing!);
    }
    
    // Additional actions
    if (widget.actions != null) {
      icons.addAll(widget.actions!);
    }
    
    if (icons.isEmpty) return null;
    if (icons.length == 1) return icons.first;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget searchBar = CompositedTransformTarget(
      link: _layerLink,
      child: _buildTextField(),
    );
    
    // Apply container styling
    if (widget.style == ReusableSearchBarStyle.elevated) {
      searchBar = Material(
        elevation: widget.elevation ?? 2,
        borderRadius: widget.customBorderRadius ??
            BorderRadius.circular(widget.borderRadius ?? 24),
        color: widget.backgroundColor ?? Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        child: searchBar,
      );
    } else if (widget.backgroundGradient != null || widget.boxShadow != null) {
      searchBar = Container(
        decoration: BoxDecoration(
          gradient: widget.backgroundGradient,
          borderRadius: widget.customBorderRadius ??
              BorderRadius.circular(widget.borderRadius ?? 24),
          boxShadow: widget.boxShadow,
        ),
        child: searchBar,
      );
    }
    
    // Apply size constraints
    if (widget.width != null || widget.height != null) {
      searchBar = SizedBox(
        width: widget.width,
        height: widget.height,
        child: searchBar,
      );
    }
    
    // Apply padding/margin
    if (widget.padding != null) {
      searchBar = Padding(
        padding: widget.padding!,
        child: searchBar,
      );
    }
    
    if (widget.margin != null) {
      searchBar = Padding(
        padding: widget.margin!,
        child: searchBar,
      );
    }
    
    // Apply animation
    if (widget.enableAnimation) {
      searchBar = AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_animation.value * 0.02),
            child: child,
          );
        },
        child: searchBar,
      );
    }
    
    return searchBar;
  }
}