import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../custom_space/view/custom_space.dart';

class CustomAppBarTitle extends StatelessWidget {
  final String title;

  const CustomAppBarTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        children: [
          const CustomSpace(widthMultiplier: 2),
          Text(
            title,
            style: TextStyle(
              //color: CustomColors.caribbeanCurrent,
              fontWeight: FontWeight.w500,
              letterSpacing: UniquesControllers().data.baseSpace / 4,
              wordSpacing: UniquesControllers().data.baseSpace / 2,
              fontSize: UniquesControllers().data.baseSpace * 2.5,
            ),
          ),
        ],
      ),
    );
  }
}
