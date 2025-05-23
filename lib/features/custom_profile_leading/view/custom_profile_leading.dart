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
    return Row(
      children: [
        const CustomSpace(widthMultiplier: 2),
        CustomProfileLeadingAvatarStream(
          userId: userId,
          avatarRadius: avatarRadius,
        ),
        CustomTextStream(
          collectionName: 'users',
          documentId: userId,
          fieldToDisplay: 'name',
          isTitle: true,
        ),
      ],
    );
  }
}
