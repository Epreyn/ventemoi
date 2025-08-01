// lib/features/custom_text_form_field/view/custom_text_form_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';

import '../../../core/theme/custom_theme.dart';
import '../controllers/custom_text_form_field_controller.dart';

class CustomTextFormField extends StatelessWidget {
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

  const CustomTextFormField({
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
  Widget build(BuildContext context) {
    final CustomTextFormFieldController cc = Get.put(
      CustomTextFormFieldController(
        controller: controller,
        maxCharacters: maxCharacters,
      ),
      tag: tag,
    );

    cc.initIsPassword(isPassword);
    cc.maxCharactersListener();

    // Si isClickable est false, on retourne un champ désactivé
    if (isClickable == false) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? cc.maxWith,
        ),
        child: AbsorbPointer(
          absorbing: true,
          child: _buildTextField(cc, context),
        ),
      );
    }

    // Sinon, on retourne le champ normal
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? cc.maxWith,
      ),
      child: _buildTextField(cc, context),
    );
  }

  Widget _buildTextField(
      CustomTextFormFieldController cc, BuildContext context) {
    return Obx(
      () => TextFormField(
        focusNode: focusNode, // ✅ DÉCOMMENTÉ - TRÈS IMPORTANT !
        textInputAction: textInputAction ?? TextInputAction.done,
        keyboardType: keyboardType ?? TextInputType.text,
        textCapitalization: textCapitalization ?? TextCapitalization.none,
        controller: controller,
        enabled: enabled ?? true,
        obscureText: cc.isObscure.value,
        minLines: minLines ?? 1,
        maxLines: unlimitedLines == true ? null : (maxLines ?? 1),
        inputFormatters: cc.inputFormatters,
        autocorrect: autocorrect ?? true,
        enableSuggestions: enableSuggestions ?? true,
        onChanged: (value) {
          cc.currentLength.value = value.length;
          if (onChanged != null) {
            onChanged!(value);
          }
        },
        onFieldSubmitted: onFieldSubmitted,
        onTap: onTap,
        validator: (value) {
          if (validator != null) {
            return validator!(value);
          } else if (validatorPattern != null) {
            if (value!.isEmpty) {
              return errorText ?? "Ce champ est vide";
            } else if (!RegExp(validatorPattern!).hasMatch(value)) {
              return errorText ?? "Ce champ est invalide";
            }
          } else {
            if (value! == "" && isNullable == false) {
              return errorText ?? "Ce champ est vide";
            }
          }
          return null;
        },
        style: TextStyle(
          fontSize: 16, // Important pour iOS
          color: enabled ?? true ? Colors.black87 : Colors.grey[600],
        ),
        decoration: InputDecoration(
          labelText: maxCharacters == null
              ? labelText
              : "$labelText (${cc.currentLength.value}/${maxCharacters!})",
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
          ),
          prefixIcon: iconData != null
              ? Icon(
                  iconData,
                  color: CustomTheme.lightScheme().primary,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? suffixIcon
              : (isPassword ?? false)
                  ? _buildPasswordToggle(cc)
                  : null,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: EdgeInsets.symmetric(
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
          fillColor: enabled ?? true
              ? Colors.white.withOpacity(0.8)
              : Colors.grey[100],
        ),
      ),
    );
  }

  // Widget pour le toggle de mot de passe (sans MouseRegion sur mobile)
  Widget _buildPasswordToggle(CustomTextFormFieldController cc) {
    final toggleWidget = GestureDetector(
      onTap: () {
        cc.isObscure.value = !cc.isObscure.value;
      },
      child: Icon(
        cc.isObscure.value
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: Colors.grey[600],
      ),
    );

    // MouseRegion seulement sur Web
    if (kIsWeb) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: toggleWidget,
      );
    }

    return toggleWidget;
  }
}
