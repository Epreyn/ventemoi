import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Widget qui affiche le nom du vendeur (sellerName)
/// en lisant la collection `establishments` en filtrant
/// par `where('user_id', isEqualTo: sellerId)`.
class ClientHistorySellerNameCell extends StatelessWidget {
  final String sellerId;
  const ClientHistorySellerNameCell({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    // Si l’ID est vide, on affiche directement "Inconnu".
    if (sellerId.isEmpty) {
      return const Text('Inconnu');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('establishments')
          .where('user_id', isEqualTo: sellerId)
          .limit(1)
          .snapshots(), // On ne prend que le premier, si plusieurs existent
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('...');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Inconnu');
        }

        // On récupère le premier doc
        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Text('Inconnu');
        }

        final sellerName = data['name'] ?? 'Inconnu';
        return Text(sellerName);
      },
    );
  }
}
