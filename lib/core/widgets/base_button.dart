import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class BaseButton extends StatelessWidget {
  final String tag;
  final String? text;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? iconData;
  final bool? isLoading;
  final bool? isDisabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const BaseButton({
    super.key,
    required this.tag,
    this.text,
    required this.onPressed,
    this.color,
    this.iconData,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.padding,
    this.textStyle,
  });

  Widget buildButtonContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final bool effectiveDisabled = isDisabled! || isLoading!;

    return GestureDetector(
      onTap: effectiveDisabled ? null : onPressed,
      child: MouseRegion(
        cursor: effectiveDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: Opacity(
          opacity: effectiveDisabled ? 0.5 : 1.0,
          child: buildButtonContent(context),
        ),
      ),
    );
  }

  Widget buildButtonRow({
    required BuildContext context,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    double spacing = 8.0,
  }) {
    if (isLoading!) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          if (text != null) ...[
            SizedBox(width: spacing),
            Text(
              text!,
              style: textStyle ?? Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconData != null) ...[
          Icon(
            iconData,
            size: 20,
            color: color,
          ),
          if (text != null) SizedBox(width: spacing),
        ],
        if (text != null)
          Text(
            text!,
            style: textStyle ?? Theme.of(context).textTheme.labelLarge,
          ),
      ],
    );
  }
}

abstract class BaseButtonController extends GetxController {
  // Common button properties
  double baseButtonSize = 42.0;
  double fontSize = 16;
  double letterSpacing = 1;
  double borderRadius = 24;

  // Common button methods
  Color getButtonColor(BuildContext context, Color? customColor) {
    return customColor ?? Theme.of(context).colorScheme.primary;
  }

  Color getTextColor(BuildContext context, Color? buttonColor) {
    if (buttonColor == null) {
      return Theme.of(context).colorScheme.onPrimary;
    }
    return buttonColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
