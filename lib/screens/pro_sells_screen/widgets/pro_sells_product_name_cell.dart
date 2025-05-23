import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';

class ProSellsProductNameCell extends StatelessWidget {
  final String productId;
  const ProSellsProductNameCell({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty) {
      return const Text('Produit inconnu');
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: UniquesControllers().data.firebaseFirestore.collection('pro_products').doc(productId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('...');
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Text('???');
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? '???';
        return Text(name);
      },
    );
  }
}
