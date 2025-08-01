// core/models/purchase.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String id;
  final String buyerId;
  final String sellerId;
  final int
      couponsCount; // Pour les achats : nombre de coupons, Pour les dons : montant en points
  final String reclamationPassword;
  final bool isReclaimed;
  final DateTime date;
  final bool isDonation; // Nouveau champ pour distinguer don/achat

  Purchase({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.couponsCount,
    required this.reclamationPassword,
    required this.isReclaimed,
    required this.date,
    this.isDonation = false, // Par défaut c'est un achat
  });

  // Getter pour clarifier l'usage
  int get amount => couponsCount; // Montant générique
  int get pointsDonated => isDonation ? couponsCount : 0;
  int get couponsNumber => !isDonation ? couponsCount : 0;

  factory Purchase.fromDocument(String id, Map<String, dynamic> data) {
    return Purchase(
      id: id,
      buyerId: data['buyer_id'] ?? '',
      sellerId: data['seller_id'] ?? '',
      couponsCount: data['coupons_count'] ?? 0,
      reclamationPassword: data['reclamationPassword'] ?? '',
      isReclaimed: data['isReclaimed'] ?? false,
      date:
          data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      isDonation: data['isDonation'] ?? false, // Nouveau champ
    );
  }

  // Alternative constructor pour compatibilité
  factory Purchase.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Purchase.fromDocument(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'coupons_count': couponsCount,
      'reclamationPassword': reclamationPassword,
      'isReclaimed': isReclaimed,
      'date': date.toIso8601String(),
      'isDonation': isDonation, // Nouveau champ
    };
  }
}
