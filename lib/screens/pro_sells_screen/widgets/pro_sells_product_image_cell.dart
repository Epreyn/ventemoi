import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../features/custom_loader/view/custom_loader.dart';

class ProSellsProductImageCell extends StatelessWidget {
  final String productId;
  const ProSellsProductImageCell({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty) {
      return const Icon(Icons.image_not_supported);
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: UniquesControllers().data.firebaseFirestore.collection('pro_products').doc(productId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(radius: 20, child: CustomLoader());
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const CircleAvatar(
            radius: 20,
            child: Icon(Icons.image_not_supported),
          );
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        final imageUrl = data['imageUrl'] ?? '';
        if (imageUrl.isEmpty) {
          return const CircleAvatar(
            radius: 20,
            child: Icon(Icons.image_not_supported),
          );
        }
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: NetworkImage(imageUrl),
        );
      },
    );
  }
}
