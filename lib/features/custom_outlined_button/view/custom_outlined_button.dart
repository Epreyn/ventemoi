import 'package:flutter/material.dart';

import '../../../features/custom_space/view/custom_space.dart';

class CustomOutlinedButton extends StatelessWidget {
  final String tag;
  final String text;
  final Color? color;
  final IconData? iconData;
  final Function() onPressed;

  const CustomOutlinedButton({
    super.key,
    required this.tag,
    required this.text,
    this.color,
    this.iconData,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        children: [
          if (iconData != null) Icon(iconData),
          if (iconData != null) const CustomSpace(widthMultiplier: 1),
          Text(text),
        ],
      ),
    );
  }
}
