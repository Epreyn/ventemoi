// lib/features/custom_text_form_field/view/custom_text_form_field_v2.dart
// VERSION SANS GETX - STABLE POUR iOS

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/custom_theme.dart';

class CustomTextFormFieldV2 extends StatefulWidget {
  final String tag;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final String labelText;
  final String? errorText;
  final IconData? iconData;
  final bool? isPassword;
  final TextInputType? keyboardType;
  final String? validatorPattern;
  final String? Function(String?)? validator;
  final bool? isNullable;
  final bool? enabled;
  final bool? isClickable;
  final int? minLines;
  final int? maxLines;
  final bool? unlimitedLines;
  final int? maxCharacters;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final TextCapitalization? textCapitalization;
  final Widget? suffixIcon;
  final double? maxWidth;
  final FocusNode? focusNode;
  final bool? autocorrect;
  final bool? enableSuggestions;
  final VoidCallback? onTap;

  const CustomTextFormFieldV2({
    super.key,
    required this.tag,
    required this.controller,
    this.textInputAction,
    required this.labelText,
    this.errorText,
    this.iconData,
    this.isPassword,
    this.keyboardType,
    this.validatorPattern,
    this.validator,
    this.isNullable,
    this.enabled,
    this.isClickable,
    this.minLines,
    this.maxLines,
    this.unlimitedLines,
    this.maxCharacters,
    this.onChanged,
    this.onFieldSubmitted,
    this.textCapitalization,
    this.suffixIcon,
    this.maxWidth,
    this.focusNode,
    this.autocorrect,
    this.enableSuggestions,
    this.onTap,
  });

  @override
  State<CustomTextFormFieldV2> createState() => _CustomTextFormFieldV2State();
}

class _CustomTextFormFieldV2State extends State<CustomTextFormFieldV2> {
  late bool _isObscure;
  int _currentLength = 0;
  final List<TextInputFormatter> _inputFormatters = [];

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isPassword ?? false;
    _currentLength = widget.controller.text.length;

    if (widget.maxCharacters != null) {
      _inputFormatters
          .add(LengthLimitingTextInputFormatter(widget.maxCharacters));
    }

    // Listener pour mettre à jour le compteur
    widget.controller.addListener(_updateLength);
  }

  void _updateLength() {
    if (mounted && widget.maxCharacters != null) {
      setState(() {
        _currentLength = widget.controller.text.length;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLength);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = widget.maxWidth ?? 350.0;

    // Si isClickable est false, on désactive le champ
    if (widget.isClickable == false) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AbsorbPointer(
          absorbing: true,
          child: _buildTextField(),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: _buildTextField(),
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      focusNode: widget.focusNode, // ✅ IMPORTANT
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      keyboardType: widget.keyboardType ?? TextInputType.text,
      textCapitalization: widget.textCapitalization ?? TextCapitalization.none,
      controller: widget.controller,
      enabled: widget.enabled ?? true,
      obscureText: _isObscure,
      minLines: widget.minLines ?? 1,
      maxLines: widget.unlimitedLines == true ? null : (widget.maxLines ?? 1),
      inputFormatters: _inputFormatters,
      autocorrect: widget.autocorrect ?? true,
      enableSuggestions: widget.enableSuggestions ?? true,
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
      onFieldSubmitted: widget.onFieldSubmitted,
      onTap: widget.onTap,
      validator: (value) {
        if (widget.validator != null) {
          return widget.validator!(value);
        } else if (widget.validatorPattern != null) {
          if (value!.isEmpty) {
            return widget.errorText ?? "Ce champ est vide";
          } else if (!RegExp(widget.validatorPattern!).hasMatch(value)) {
            return widget.errorText ?? "Ce champ est invalide";
          }
        } else {
          if (value! == "" && widget.isNullable == false) {
            return widget.errorText ?? "Ce champ est vide";
          }
        }
        return null;
      },
      style: TextStyle(
        fontSize: 16,
        color: widget.enabled ?? true ? Colors.black87 : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: widget.maxCharacters == null
            ? widget.labelText
            : "${widget.labelText} ($_currentLength/${widget.maxCharacters!})",
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 16,
        ),
        prefixIcon: widget.iconData != null
            ? Icon(
                widget.iconData,
                color: CustomTheme.lightScheme().primary,
              )
            : null,
        suffixIcon: widget.suffixIcon != null
            ? widget.suffixIcon
            : (widget.isPassword ?? false)
                ? IconButton(
                    icon: Icon(
                      _isObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  )
                : null,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: CustomTheme.lightScheme().primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: CustomTheme.lightScheme().error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: CustomTheme.lightScheme().error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: widget.enabled ?? true
            ? Colors.white.withOpacity(0.8)
            : Colors.grey[100],
      ),
    );
  }
}
