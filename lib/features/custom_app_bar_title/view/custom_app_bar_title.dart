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
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 900;

    // Calculate responsive font size
    double responsiveFontSize;
    if (isSmallScreen) {
      responsiveFontSize =
          UniquesControllers().data.baseSpace * 2; // Smaller on mobile
    } else if (isMediumScreen) {
      responsiveFontSize = UniquesControllers().data.baseSpace * 2.3;
    } else {
      responsiveFontSize = UniquesControllers().data.baseSpace * 2.5;
    }

    return Center(
      child: Row(
        children: [
          CustomSpace(widthMultiplier: isSmallScreen ? 1 : 2),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                letterSpacing: UniquesControllers().data.baseSpace / 4,
                wordSpacing: UniquesControllers().data.baseSpace / 2,
                fontSize: responsiveFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
