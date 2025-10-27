import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../custom_animation/view/custom_animation.dart';

class CustomLogo extends StatelessWidget {
  final Color? color;

  const CustomLogo({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/logo.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      width: UniquesControllers().data.baseSpace * 12,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
    );
  }
}
