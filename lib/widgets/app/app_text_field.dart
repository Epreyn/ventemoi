import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_theme_config.dart';

/// TextField de l'application avec la charte graphique
class AppTextField extends StatefulWidget {
  final String tag;
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool showClearButton;
  final VoidCallback? onClear;
  final bool showPasswordToggle;
  final EdgeInsetsGeometry? margin;
  
  const AppTextField({
    super.key,
    required this.tag,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onFieldSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.showClearButton = true,
    this.onClear,
    this.showPasswordToggle = false,
    this.margin,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _obscureText;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    _hasText = _controller.text.isNotEmpty;
    
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
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

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _hasText = _controller.text.isNotEmpty;
      });
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    Widget textField = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: (value) {
        widget.onSubmitted?.call(value);
        widget.onFieldSubmitted?.call();
      },
      style: AppThemeConfig.bodyMedium,
      cursorColor: AppThemeConfig.primaryColor,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: _isFocused
                    ? AppThemeConfig.primaryColor
                    : AppThemeConfig.grey600,
                size: AppThemeConfig.iconSizeMedium,
              )
            : null,
        suffixIcon: _buildSuffixIcon(),
        filled: true,
        fillColor: widget.enabled ? AppThemeConfig.grey50 : AppThemeConfig.grey100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppThemeConfig.spaceXL,
          vertical: AppThemeConfig.spaceLG,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          borderSide: BorderSide(
            color: AppThemeConfig.grey300,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          borderSide: BorderSide(
            color: AppThemeConfig.grey300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          borderSide: BorderSide(
            color: AppThemeConfig.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          borderSide: BorderSide(
            color: AppThemeConfig.errorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          borderSide: BorderSide(
            color: AppThemeConfig.errorColor,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConfig.inputBorderRadius),
          borderSide: BorderSide(
            color: AppThemeConfig.grey200,
            width: 1,
          ),
        ),
        labelStyle: MaterialStateTextStyle.resolveWith((states) {
          if (states.contains(MaterialState.focused)) {
            return AppThemeConfig.labelMedium.copyWith(
              color: AppThemeConfig.primaryColor,
            );
          }
          return AppThemeConfig.labelMedium;
        }),
        hintStyle: AppThemeConfig.bodyMedium.copyWith(
          color: AppThemeConfig.textHint,
        ),
        errorStyle: AppThemeConfig.labelSmall.copyWith(
          color: AppThemeConfig.errorColor,
        ),
      ),
    );
    
    if (widget.margin != null) {
      textField = Padding(
        padding: widget.margin!,
        child: textField,
      );
    }
    
    return textField;
  }
  
  Widget? _buildSuffixIcon() {
    final List<Widget> widgets = [];
    
    // Clear button
    if (widget.showClearButton && _hasText && widget.enabled) {
      widgets.add(
        IconButton(
          icon: Icon(
            Icons.clear,
            color: AppThemeConfig.grey600,
            size: AppThemeConfig.iconSizeSmall,
          ),
          onPressed: _clearText,
        ),
      );
    }
    
    // Password toggle
    if (widget.showPasswordToggle && widget.obscureText) {
      widgets.add(
        IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppThemeConfig.grey600,
            size: AppThemeConfig.iconSizeSmall,
          ),
          onPressed: _togglePasswordVisibility,
        ),
      );
    }
    
    if (widgets.isEmpty) return null;
    if (widgets.length == 1) return widgets.first;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}