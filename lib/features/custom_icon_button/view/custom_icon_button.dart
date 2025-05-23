import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/custom_icon_button_controller.dart';

class CustomIconButton extends StatelessWidget {
  final String tag;
  final IconData? iconData;
  final String? text;
  final double? buttonSize;
  final double? padding;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool? isClickable;
  final Function() onPressed;

  const CustomIconButton({
    super.key,
    required this.tag,
    this.iconData,
    this.text,
    this.buttonSize,
    this.padding,
    this.iconColor,
    this.backgroundColor,
    this.isClickable,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    CustomIconButtonController cc = Get.put(
      CustomIconButtonController(),
      tag: tag,
    );

    final Widget buttonWidget;
    if (text == null) {
      buttonWidget = IconButton(
        padding: EdgeInsets.all(padding ?? 0),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            backgroundColor ?? Colors.transparent,
          ),
        ),
        icon: Center(
          child: Icon(
            iconData,
            color: iconColor,
          ),
        ),
        onPressed: onPressed,
      );
    } else {
      buttonWidget = TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          iconData,
          color: iconColor,
        ),
        label: Text(
          text!,
          style: TextStyle(
            color: iconColor,
          ),
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            backgroundColor ?? Colors.transparent,
          ),
          padding: WidgetStateProperty.all<EdgeInsets>(
            EdgeInsets.all(padding ?? 0),
          ),
        ),
      );
    }

    double? boxWidth = (text == null) ? (buttonSize ?? cc.baseButtonSize) : null;
    double? boxHeight = (text == null) ? (buttonSize ?? cc.baseButtonSize) : null;

    return SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          buttonWidget,
          if (isClickable == false)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }
}
