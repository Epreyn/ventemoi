import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserTypeNameCell extends StatelessWidget {
  final String userTypeId;
  const AdminUserTypeNameCell({super.key, required this.userTypeId});

  @override
  Widget build(BuildContext context) {
    if (userTypeId.isEmpty) {
      return const Text('N/A');
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('user_types').doc(userTypeId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('...');
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Text('Inconnu');
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        final typeName = data['name'] ?? 'Inconnu';
        return Text(typeName);
      },
    );
  }
}
