import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/classes/unique_controllers.dart';

class AdminUserTypeNameCell extends StatelessWidget {
  final String userTypeId;
  const AdminUserTypeNameCell({super.key, required this.userTypeId});

  @override
  Widget build(BuildContext context) {
    if (userTypeId.isEmpty) {
      return _buildChip('N/A', Colors.grey);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_types')
          .doc(userTypeId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingChip();
        }

        if (!snap.hasData || !snap.data!.exists) {
          return _buildChip('Inconnu', Colors.grey);
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final typeName = data['name'] ?? 'Inconnu';

        return _buildChip(typeName, _getTypeColor(typeName));
      },
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      child: Text(
        text,
        style: TextStyle(
          fontSize: UniquesControllers().data.baseSpace * 1.5,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingChip() {
    return Container(
      width: 60,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey[400]!,
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'particulier':
        return Colors.blue[700]!;
      case 'partenaire':
        return Colors.green[700]!;
      case 'entreprise':
        return Colors.orange[700]!;
      case 'professionnel':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
