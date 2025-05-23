import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/unique_controllers.dart';

import '../controllers/custom_fab_button_controller.dart';

class CustomFABButton extends StatelessWidget {
  final String tag;
  final String text;
  final Color? color;
  final Color? textColor;
  final IconData? iconData;
  final Function() onPressed;

  const CustomFABButton({
    super.key,
    required this.tag,
    required this.text,
    this.color,
    this.textColor,
    this.iconData,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final CustomFABButtonController cc = Get.put(
      CustomFABButtonController(),
      tag: tag,
    );

    return FloatingActionButton.extended(
      heroTag: tag,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      extendedPadding: EdgeInsets.symmetric(
        horizontal: UniquesControllers().data.baseSpace * 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          UniquesControllers().data.baseSpace * 10,
        ),
      ),
      backgroundColor: color,
      onPressed: onPressed,
      label: Text(text, style: TextStyle(color: textColor)),
      icon: iconData != null ? Icon(iconData) : null,
    );
  }
}
