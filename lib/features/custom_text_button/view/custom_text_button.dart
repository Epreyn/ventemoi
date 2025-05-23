import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String tag;
  final String text;
  final Color? color;
  final IconData? iconData;
  final Function() onPressed;

  const CustomTextButton({
    super.key,
    required this.tag,
    required this.text,
    this.color,
    this.iconData,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // final CustomTextButtonController cc = Get.put(
    //   CustomTextButtonController(),
    //   tag: tag,
    // );

    final baseColor = color ?? null;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: baseColor, // Text color
      ),
      child: Text(text),
    );
  }
}
