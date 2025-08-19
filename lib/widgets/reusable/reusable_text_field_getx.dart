import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controllers/reusable_text_field_controller.dart';

/// GetX version of ReusableTextField - Stateless for better performance
class ReusableTextFieldX extends StatelessWidget {
  // Core properties
  final String tag;
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
  
  const ReusableTextFieldX({
    super.key,
    required this.tag,
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

  InputBorder _getBorder(Color color, double width, double? radius) {
    if (borderRadius != null || radius != null) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius ?? borderRadius!),
        borderSide: BorderSide(color: color, width: width),
      );
    }
    return border ??
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
  }

  Widget? _buildSuffixIcon(ReusableTextFieldController cc) {
    final List<Widget> suffixWidgets = [];
    
    if (showClearButton && cc.hasText.value && !readOnly) {
      suffixWidgets.add(
        IconButton(
          icon: Icon(
            Icons.clear,
            size: iconSize ?? 20,
            color: iconColor ?? Colors.grey,
          ),
          onPressed: cc.clearText,
        ),
      );
    }
    
    if (showPasswordToggle && obscureText) {
      suffixWidgets.add(
        IconButton(
          icon: Icon(
            cc.obscureText.value ? Icons.visibility : Icons.visibility_off,
            size: iconSize ?? 20,
            color: iconColor ?? Colors.grey,
          ),
          onPressed: cc.togglePasswordVisibility,
        ),
      );
    }
    
    if (suffixIcon != null) {
      suffixWidgets.add(
        Icon(
          suffixIcon,
          size: iconSize ?? 20,
          color: iconColor,
        ),
      );
    }
    
    if (suffix != null) {
      suffixWidgets.add(suffix!);
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
    final defaultBorderColor = borderColor ?? Colors.grey[400]!;
    final defaultFocusedBorderColor = focusedBorderColor ?? theme.primaryColor;
    final defaultErrorBorderColor = errorBorderColor ?? theme.colorScheme.error;
    final defaultBorderWidth = borderWidth ?? 1.0;
    
    // Initialize controller
    final cc = Get.put(
      ReusableTextFieldController(
        controller: controller,
        focusNode: focusNode,
        initialObscureText: obscureText,
        isPasswordField: obscureText,
        showPasswordToggle: showPasswordToggle,
        showClearButton: showClearButton,
        onClear: onClear,
        onChanged: onChanged,
      ),
      tag: tag,
    );

    Widget textField = Obx(() => TextFormField(
      controller: cc.textController,
      focusNode: cc.focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        label: label,
        labelStyle: labelStyle,
        hintText: hintText,
        hintStyle: hintStyle,
        helperText: helperText,
        helperStyle: helperStyle,
        helperMaxLines: 2,
        errorText: errorText,
        errorStyle: errorStyle,
        errorMaxLines: 2,
        counterText: showCharacterCount ? null : counterText,
        counter: counter,
        counterStyle: counterStyle,
        prefixText: prefixText,
        prefixStyle: prefixStyle,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: iconSize ?? 20,
                color: iconColor,
              )
            : null,
        prefix: prefix,
        prefixIconConstraints: prefixIconConstraints,
        suffixText: suffixText,
        suffixStyle: suffixStyle,
        suffix: _buildSuffixIcon(cc),
        suffixIconConstraints: suffixIconConstraints,
        fillColor: fillColor,
        filled: filled,
        focusColor: focusColor,
        hoverColor: hoverColor,
        border: border ?? _getBorder(defaultBorderColor, defaultBorderWidth, borderRadius),
        enabledBorder: enabledBorder ?? _getBorder(defaultBorderColor, defaultBorderWidth, borderRadius),
        disabledBorder: disabledBorder ?? _getBorder(Colors.grey[300]!, defaultBorderWidth, borderRadius),
        focusedBorder: focusedBorder ?? _getBorder(defaultFocusedBorderColor, defaultBorderWidth + 1, borderRadius),
        errorBorder: errorBorder ?? _getBorder(defaultErrorBorderColor, defaultBorderWidth, borderRadius),
        focusedErrorBorder: focusedErrorBorder ?? _getBorder(defaultErrorBorderColor, defaultBorderWidth + 1, borderRadius),
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: isDense,
        constraints: constraints,
        floatingLabelBehavior: floatingLabelBehavior,
      ),
      style: style,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      textDirection: textDirection,
      readOnly: readOnly,
      showCursor: showCursor,
      autofocus: autofocus,
      obscuringCharacter: obscuringCharacter,
      obscureText: cc.obscureText.value,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted ?? onSubmitted,
      onSaved: onSaved,
      validator: validator,
      inputFormatters: inputFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      selectionControls: selectionControls,
      onTap: onTap,
      onTapOutside: onTapOutside,
      mouseCursor: mouseCursor,
      buildCounter: buildCounter,
      scrollPhysics: scrollPhysics,
      scrollController: scrollController,
      autofillHints: autofillHints,
      clipBehavior: clipBehavior,
      restorationId: restorationId,
      scribbleEnabled: scribbleEnabled,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      canRequestFocus: canRequestFocus,
    ));

    if (containerDecoration != null || 
        boxShadow != null || 
        backgroundGradient != null ||
        width != null ||
        height != null) {
      textField = Container(
        width: width,
        height: height,
        alignment: alignment,
        margin: margin,
        decoration: containerDecoration ?? BoxDecoration(
          gradient: backgroundGradient,
          boxShadow: boxShadow,
        ),
        child: textField,
      );
    } else if (margin != null) {
      textField = Padding(
        padding: margin!,
        child: textField,
      );
    }

    return textField;
  }
}