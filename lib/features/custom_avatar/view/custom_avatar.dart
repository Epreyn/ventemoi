import 'package:flutter/material.dart';

import '../../../features/custom_loader/view/custom_loader.dart';

class CustomAvatar extends StatelessWidget {
  final Stream<String?> avatarUrlStream;
  final String placeholderImagePath;

  const CustomAvatar({
    super.key,
    required this.avatarUrlStream,
    this.placeholderImagePath = 'images/user.png',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: avatarUrlStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(child: CustomLoader());
        }

        String? avatarUrl = snapshot.data;
        ImageProvider backgroundImage;
        if (avatarUrl == null || avatarUrl.isEmpty || avatarUrl == '') {
          backgroundImage = AssetImage(placeholderImagePath);
        } else {
          backgroundImage = NetworkImage(avatarUrl);
        }

        return CircleAvatar(
          backgroundImage: backgroundImage,
          onBackgroundImageError: (_, __) => AssetImage(placeholderImagePath),
        );
      },
    );
  }
}
