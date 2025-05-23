import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../custom_animation/view/custom_animation.dart';

class CustomLogo extends StatelessWidget {
  const CustomLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAnimation(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack,
      yStartPosition: UniquesControllers().data.baseSpace * 2,
      isOpacity: true,
      child: Image.asset(
        'images/logo.png',
        width: UniquesControllers().data.baseSpace * 12,
      ),
    );
  }
}
