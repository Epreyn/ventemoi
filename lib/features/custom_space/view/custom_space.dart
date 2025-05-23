import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';

class CustomSpace extends StatelessWidget {
  final double? heightMultiplier;
  final double? widthMultiplier;

  const CustomSpace({
    super.key,
    this.heightMultiplier,
    this.widthMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightMultiplier != null ? UniquesControllers().data.baseSpace * heightMultiplier! : null,
      width: widthMultiplier != null ? UniquesControllers().data.baseSpace * widthMultiplier! : null,
    );
  }
}
