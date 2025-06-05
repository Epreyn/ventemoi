import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';

// Controller pour gérer l'état du TextField
class ModernTextFieldController extends GetxController {
  final RxBool isFocused = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorText = ''.obs;
  final RxInt currentLength = 0.obs;
  final RxBool isPasswordVisible = false.obs;

  late FocusNode focusNode;
  late TextEditingController textController;

  @override
  void onInit() {
    super.onInit();
    focusNode = FocusNode();
    focusNode.addListener(_onFocusChanged);
  }

  @override
  void onClose() {
    focusNode.removeListener(_onFocusChanged);
    focusNode.dispose();
    super.onClose();
  }

  void _onFocusChanged() {
    isFocused.value = focusNode.hasFocus;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void updateLength(int length) {
    currentLength.value = length;
  }

  void setError(String? error) {
    if (error != null && error.isNotEmpty) {
      hasError.value = true;
      errorText.value = error;
    } else {
      hasError.value = false;
      errorText.value = '';
    }
  }
}

class ModernTextField extends StatelessWidget {
  final String tag;
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool? enabled;
  final int? minLines;
  final int? maxLines;
  final int? maxCharacters;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final double? maxWidth;
  final bool showCounter;
  final bool validateOnChange;

  const ModernTextField({
    super.key,
    required this.tag,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixWidget,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.enabled,
    this.minLines,
    this.maxLines,
    this.maxCharacters,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.autofocus = false,
    this.maxWidth,
    this.showCounter = true,
    this.validateOnChange = false,
  });

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(ModernTextFieldController(), tag: tag);
    cc.textController = controller;

    // Initialiser la longueur
    cc.updateLength(controller.text.length);

    final colorScheme = CustomTheme.lightScheme();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? 500.0,
      ),
      child: Obx(() {
        final isFocused = cc.isFocused.value;
        final hasError = cc.hasError.value;
        final currentLength = cc.currentLength.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label flottant moderne
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isFocused || controller.text.isNotEmpty ? 20 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isFocused || controller.text.isNotEmpty ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    labelText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasError
                          ? colorScheme.error
                          : isFocused
                              ? colorScheme.primary
                              : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),

            // Container principal du TextField
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isFocused
                    ? colorScheme.primary.withOpacity(0.04)
                    : enabled == false
                        ? Colors.grey[100]
                        : Colors.grey[50],
                border: Border.all(
                  color: hasError
                      ? colorScheme.error
                      : isFocused
                          ? colorScheme.primary
                          : Colors.transparent,
                  width: isFocused ? 2.0 : 1.5,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: (hasError
                                  ? colorScheme.error
                                  : colorScheme.primary)
                              .withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                focusNode: cc.focusNode,
                controller: controller,
                enabled: enabled ?? true,
                obscureText: isPassword && !cc.isPasswordVisible.value,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                minLines: minLines ?? 1,
                maxLines: isPassword ? 1 : (maxLines ?? 1),
                inputFormatters: [
                  ...?inputFormatters,
                  if (maxCharacters != null)
                    LengthLimitingTextInputFormatter(maxCharacters),
                ],
                autofocus: autofocus,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: (enabled ?? true) ? Colors.black87 : Colors.grey[600],
                  letterSpacing:
                      isPassword && !cc.isPasswordVisible.value ? 2 : 0,
                ),
                onChanged: (value) {
                  cc.updateLength(value.length);

                  // Validation en temps réel uniquement si activée
                  if (validateOnChange && validator != null) {
                    final error = validator!(value);
                    cc.setError(error);
                  } else {
                    // Effacer l'erreur quand l'utilisateur tape
                    if (hasError) {
                      cc.setError(null);
                    }
                  }

                  onChanged?.call(value);
                },
                onFieldSubmitted: onFieldSubmitted,
                validator: (value) {
                  if (validator != null) {
                    final error = validator!(value);
                    cc.setError(error);
                    return error;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: hintText ?? (isFocused ? '' : labelText),
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: prefixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            prefixIcon,
                            color: hasError
                                ? colorScheme.error
                                : isFocused
                                    ? colorScheme.primary
                                    : Colors.grey[600],
                            size: 22,
                          ),
                        )
                      : null,
                  suffixIcon: _buildSuffixIcon(cc, colorScheme),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: prefixIcon != null ? 12 : 20,
                    vertical: 18,
                  ),
                  isDense: true,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),

            // Helper text, Error text ou Counter
            if (hasError ||
                helperText != null ||
                (maxCharacters != null && showCounter))
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: hasError ||
                        helperText != null ||
                        (maxCharacters != null && showCounter)
                    ? null
                    : 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: hasError
                              ? Text(
                                  cc.errorText.value,
                                  key: const ValueKey('error'),
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : helperText != null
                                  ? Text(
                                      helperText!,
                                      key: const ValueKey('helper'),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                      if (maxCharacters != null && showCounter)
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: currentLength > maxCharacters!
                                ? colorScheme.error
                                : currentLength > maxCharacters! * 0.8
                                    ? Colors.orange
                                    : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: currentLength > maxCharacters! * 0.8
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          child: Text('$currentLength/$maxCharacters'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget? _buildSuffixIcon(
      ModernTextFieldController cc, ColorScheme colorScheme) {
    if (isPassword) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              cc.isPasswordVisible.value
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              key: ValueKey(cc.isPasswordVisible.value),
              color:
                  cc.isFocused.value ? colorScheme.primary : Colors.grey[600],
              size: 22,
            ),
          ),
          onPressed: cc.togglePasswordVisibility,
          splashRadius: 24,
          splashColor: colorScheme.primary.withOpacity(0.1),
        ),
      );
    }

    if (suffixWidget != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: suffixWidget,
      );
    }

    // Indicateur de validation réussie
    if (controller.text.isNotEmpty && !cc.hasError.value && validator != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 22,
        ),
      );
    }

    return null;
  }
}
