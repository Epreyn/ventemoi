import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/custom_text_form_field_controller.dart';

class CustomTextFormField extends StatelessWidget {
  final String tag;

  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final String labelText;
  final String? hintText;
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

  const CustomTextFormField({
    super.key,
    required this.tag,
    required this.controller,
    this.textInputAction,
    required this.labelText,
    this.hintText,
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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: cc.maxWith,
      ),
      child: Stack(
        children: [
          Obx(
            () => TextFormField(
              textInputAction: textInputAction ?? TextInputAction.done,
              keyboardType: keyboardType ?? TextInputType.text,
              controller: controller,
              enabled: enabled ?? true,
              obscureText: cc.isObscure.value,
              minLines: minLines ?? 1,
              maxLines: unlimitedLines == true ? null : (maxLines ?? 1),
              inputFormatters: cc.inputFormatters,
              onChanged: (value) {
                cc.currentLength.value = value.length;
                if (onChanged != null) {
                  onChanged!(value);
                }
              },
              onFieldSubmitted: onFieldSubmitted,
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
              decoration: InputDecoration(
                labelText:
                    maxCharacters == null ? labelText : "$labelText (${cc.currentLength.value}/${maxCharacters!})",
                hintText: hintText,
                prefixIcon: iconData != null ? Icon(iconData) : null,
                suffixIcon: (isPassword ?? false)
                    ? MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            cc.isObscure.value = !cc.isObscure.value;
                          },
                          child: Icon(
                            cc.isObscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                        ),
                      )
                    : null,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(90 / (maxLines ?? 1)),
                ),
              ),
            ),
          ),
          if (isClickable == false)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: Container(),
              ),
            ),
        ],
      ),
      //   },
      // ),
    );
  }
}
