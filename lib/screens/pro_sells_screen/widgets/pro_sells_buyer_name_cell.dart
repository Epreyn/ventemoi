// pro_sells_buyer_name_cell.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';

class ProSellsBuyerNameCell extends StatelessWidget {
  final String buyerId;
  const ProSellsBuyerNameCell({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    if (buyerId.isEmpty) {
      return Text(
        'Acheteur inconnu',
        style: TextStyle(
          fontSize: UniquesControllers().data.baseSpace * 1.8,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(buyerId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            height: 20,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Text(
            'Utilisateur supprimé',
            style: TextStyle(
              fontSize: UniquesControllers().data.baseSpace * 1.8,
              fontWeight: FontWeight.w600,
              color: Colors.red[400],
              fontStyle: FontStyle.italic,
            ),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Sans nom';

        return Text(
          name,
          style: TextStyle(
            fontSize: UniquesControllers().data.baseSpace * 1.8,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        );
      },
    );
  }
}
