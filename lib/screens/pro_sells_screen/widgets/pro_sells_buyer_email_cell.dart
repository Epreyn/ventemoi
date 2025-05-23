import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';

class ProSellsBuyerEmailCell extends StatelessWidget {
  final String buyerId;
  const ProSellsBuyerEmailCell({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    if (buyerId.isEmpty) {
      return const Text('Aucun email');
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: UniquesControllers().data.firebaseFirestore.collection('users').doc(buyerId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('...');
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Text('???');
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        final email = data['email'] ?? '???';
        return Text(email);
      },
    );
  }
}
