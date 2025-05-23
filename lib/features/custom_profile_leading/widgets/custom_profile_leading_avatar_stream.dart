import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../custom_logo/view/custom_logo.dart';

class CustomProfileLeadingAvatarStream extends StatelessWidget {
  final String userId;
  final double avatarRadius;

  const CustomProfileLeadingAvatarStream({
    super.key,
    required this.userId,
    required this.avatarRadius,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: avatarRadius,
            //backgroundColor: Colors.grey.shade300,
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return CircleAvatar(
            radius: avatarRadius,
            //backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person),
          );
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        final imageUrl = data['image_url'] ?? '';

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: avatarRadius * 1.1,
              //backgroundColor: CustomColors.caribbeanCurrent,
            ),
            ClipOval(
              child: Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                //color: Colors.white,
                child: imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover) : const CustomLogo(),
              ),
            ),
          ],
        );
      },
    );
  }
}
