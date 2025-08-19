import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A highly customizable text field widget that can be reused across projects
class ReusableTextField extends StatefulWidget {
  // Core properties
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? counterText;
  final String? prefixText;
  final String? suffixText;
  
  // Icons
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final Color? iconColor;
  final double? iconSize;
  
  // Text input properties
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool readOnly;
  final bool? showCursor;
  final bool autofocus;
  final String obscuringCharacter;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final MouseCursor? mouseCursor;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;
  final Iterable<String>? autofillHints;
  final Clip clipBehavior;
  final String? restorationId;
  final bool scribbleEnabled;
  final bool enableIMEPersonalizedLearning;
  final bool canRequestFocus;
  
  // Styling
  final TextStyle? style;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final TextStyle? counterStyle;
  final TextStyle? prefixStyle;
  final TextStyle? suffixStyle;
  
  // Decoration
  final Color? fillColor;
  final bool? filled;
  final Color? focusColor;
  final Color? hoverColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? disabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final EdgeInsetsGeometry? contentPadding;
  final bool isDense;
  final Widget? counter;
  final BoxConstraints? constraints;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  
  // Focus
  final FocusNode? focusNode;
  final bool? autovalidateMode;
  
  // Custom properties for enhanced functionality
  final bool showCharacterCount;
  final bool showPasswordToggle;
  final double? borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final Widget? label;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? margin;
  final Decoration? containerDecoration;
  final List<BoxShadow>? boxShadow;
  final Gradient? backgroundGradient;
  final VoidCallback? onClear;
  final bool showClearButton;
  
  const ReusableTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.counterText,
    this.prefixText,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.iconColor,
    this.iconSize,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onFieldSubmitted,
    this.onSaved,
    this.validator,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection,
    this.selectionControls,
    this.onTap,
    this.onTapOutside,
    this.mouseCursor,
    this.buildCounter,
    this.scrollPhysics,
    this.scrollController,
    this.autofillHints,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.scribbleEnabled = true,
    this.enableIMEPersonalizedLearning = true,
    this.canRequestFocus = true,
    this.style,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
    this.helperStyle,
    this.counterStyle,
    this.prefixStyle,
    this.suffixStyle,
    this.fillColor,
    this.filled,
    this.focusColor,
    this.hoverColor,
    this.border,
    this.enabledBorder,
    this.disabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.contentPadding,
    this.isDense = false,
    this.counter,
    this.constraints,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.focusNode,
    this.autovalidateMode,
    this.showCharacterCount = false,
    this.showPasswordToggle = false,
    this.borderRadius,
    this.borderWidth,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.floatingLabelBehavior,
    this.label,
    this.width,
    this.height,
    this.alignment,
    this.margin,
    this.containerDecoration,
    this.boxShadow,
    this.backgroundGradient,
    this.onClear,
    this.showClearButton = false,
  });

  @override
  State<ReusableTextField> createState() => _ReusableTextFieldState();
}

class _ReusableTextFieldState extends State<ReusableTextField> {
  late bool _obscureText;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _controller.text.isNotEmpty;
    
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  InputBorder _getBorder(Color color, double width) {
    if (widget.borderRadius != null) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius!),
        borderSide: BorderSide(color: color, width: width),
      );
    }
    return widget.border ??
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
  }

  Widget? _buildSuffixIcon() {
    final List<Widget> suffixWidgets = [];
    
    if (widget.showClearButton && _hasText && !widget.readOnly) {
      suffixWidgets.add(
        IconButton(
          icon: Icon(
            Icons.clear,
            size: widget.iconSize ?? 20,
            color: widget.iconColor ?? Colors.grey,
          ),
          onPressed: () {
            _controller.clear();
            widget.onClear?.call();
            widget.onChanged?.call('');
          },
        ),
      );
    }
    
    if (widget.showPasswordToggle && widget.obscureText) {
      suffixWidgets.add(
        IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            size: widget.iconSize ?? 20,
            color: widget.iconColor ?? Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      );
    }
    
    if (widget.suffixIcon != null) {
      suffixWidgets.add(
        Icon(
          widget.suffixIcon,
          size: widget.iconSize ?? 20,
          color: widget.iconColor,
        ),
      );
    }
    
    if (widget.suffix != null) {
      suffixWidgets.add(widget.suffix!);
    }
    
    if (suffixWidgets.isEmpty) return null;
    if (suffixWidgets.length == 1) return suffixWidgets.first;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: suffixWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderColor = widget.borderColor ?? Colors.grey[400]!;
    final defaultFocusedBorderColor = widget.focusedBorderColor ?? theme.primaryColor;
    final defaultErrorBorderColor = widget.errorBorderColor ?? theme.colorScheme.error;
    final defaultBorderWidth = widget.borderWidth ?? 1.0;

    Widget textField = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        label: widget.label,
        labelStyle: widget.labelStyle,
        hintText: widget.hintText,
        hintStyle: widget.hintStyle,
        helperText: widget.helperText,
        helperStyle: widget.helperStyle,
        helperMaxLines: 2,
        errorText: widget.errorText,
        errorStyle: widget.errorStyle,
        errorMaxLines: 2,
        counterText: widget.showCharacterCount ? null : widget.counterText,
        counter: widget.counter,
        counterStyle: widget.counterStyle,
        prefixText: widget.prefixText,
        prefixStyle: widget.prefixStyle,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: widget.iconSize ?? 20,
                color: widget.iconColor,
              )
            : null,
        prefix: widget.prefix,
        prefixIconConstraints: widget.prefixIconConstraints,
        suffixText: widget.suffixText,
        suffixStyle: widget.suffixStyle,
        suffix: _buildSuffixIcon(),
        suffixIconConstraints: widget.suffixIconConstraints,
        fillColor: widget.fillColor,
        filled: widget.filled,
        focusColor: widget.focusColor,
        hoverColor: widget.hoverColor,
        border: widget.border ?? _getBorder(defaultBorderColor, defaultBorderWidth),
        enabledBorder: widget.enabledBorder ?? _getBorder(defaultBorderColor, defaultBorderWidth),
        disabledBorder: widget.disabledBorder ?? _getBorder(Colors.grey[300]!, defaultBorderWidth),
        focusedBorder: widget.focusedBorder ?? _getBorder(defaultFocusedBorderColor, defaultBorderWidth + 1),
        errorBorder: widget.errorBorder ?? _getBorder(defaultErrorBorderColor, defaultBorderWidth),
        focusedErrorBorder: widget.focusedErrorBorder ?? _getBorder(defaultErrorBorderColor, defaultBorderWidth + 1),
        contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: widget.isDense,
        constraints: widget.constraints,
        floatingLabelBehavior: widget.floatingLabelBehavior,
      ),
      style: widget.style,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      textDirection: widget.textDirection,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      obscuringCharacter: widget.obscuringCharacter,
      obscureText: _obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted ?? widget.onSubmitted,
      onSaved: widget.onSaved,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      mouseCursor: widget.mouseCursor,
      buildCounter: widget.buildCounter,
      scrollPhysics: widget.scrollPhysics,
      scrollController: widget.scrollController,
      autofillHints: widget.autofillHints,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId,
      scribbleEnabled: widget.scribbleEnabled,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      canRequestFocus: widget.canRequestFocus,
    );

    if (widget.containerDecoration != null || 
        widget.boxShadow != null || 
        widget.backgroundGradient != null ||
        widget.width != null ||
        widget.height != null) {
      textField = Container(
        width: widget.width,
        height: widget.height,
        alignment: widget.alignment,
        margin: widget.margin,
        decoration: widget.containerDecoration ?? BoxDecoration(
          gradient: widget.backgroundGradient,
          boxShadow: widget.boxShadow,
        ),
        child: textField,
      );
    } else if (widget.margin != null) {
      textField = Padding(
        padding: widget.margin!,
        child: textField,
      );
    }

    return textField;
  }
}