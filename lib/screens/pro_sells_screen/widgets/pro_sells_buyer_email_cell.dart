// pro_sells_buyer_email_cell.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/classes/unique_controllers.dart';

class ProSellsBuyerEmailCell extends StatelessWidget {
  final String buyerId;
  const ProSellsBuyerEmailCell({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    if (buyerId.isEmpty) {
      return Text(
        'Aucun email',
        style: TextStyle(
          fontSize: UniquesControllers().data.baseSpace * 1.5,
          color: Colors.grey[600],
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
            height: 16,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Text(
            'Email indisponible',
            style: TextStyle(
              fontSize: UniquesControllers().data.baseSpace * 1.5,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final email = data['email'] ?? 'Aucun email';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.email_outlined,
              size: 14,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                email,
                style: TextStyle(
                  fontSize: UniquesControllers().data.baseSpace * 1.5,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
