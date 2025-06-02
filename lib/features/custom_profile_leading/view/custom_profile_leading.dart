import 'package:flutter/material.dart';

import '../../../features/custom_space/view/custom_space.dart';
import '../../custom_text_stream/view/custom_text_stream.dart';
import '../widgets/custom_profile_leading_avatar_stream.dart';

class CustomProfileLeading extends StatelessWidget {
  final String userId;
  final double avatarRadius;

  const CustomProfileLeading({
    super.key,
    required this.userId,
    this.avatarRadius = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Responsive avatar radius
    final responsiveAvatarRadius = isSmallScreen
        ? avatarRadius * 0.8 // 80% size on small screens
        : avatarRadius;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CustomSpace(widthMultiplier: 2),
        CustomProfileLeadingAvatarStream(
          userId: userId,
          avatarRadius: responsiveAvatarRadius,
        ),
        // Show name with flexible sizing
        Flexible(
          child: CustomTextStream(
            collectionName: 'users',
            documentId: userId,
            fieldToDisplay: 'name',
            isTitle: true,
          ),
        ),
      ],
    );
  }
}
