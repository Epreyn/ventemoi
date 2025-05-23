import 'package:cloud_firestore/cloud_firestore.dart';

class Commission {
  final String id;
  final double minAmount; // Montant minimal
  final double maxAmount; // Montant maximal (ou 0 si isInfinite = true)
  final double percentage; // Commission en %
  final bool isInfinite; // Vrai => ignore maxAmount => s’applique à l’infini
  final double associationPercentage;
  final String
      emailException; // Si non vide => ne s’applique qu’à ce mail d’entreprise

  Commission({
    required this.id,
    required this.minAmount,
    required this.maxAmount,
    required this.percentage,
    required this.isInfinite,
    required this.associationPercentage,
    required this.emailException,
  });

  factory Commission.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Commission(
      id: doc.id,
      minAmount: (data['min_amount'] ?? 0.0).toDouble(),
      maxAmount: (data['max_amount'] ?? 9999999.0).toDouble(),
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      isInfinite: data['isInfinite'] ?? false,
      associationPercentage: (data['association_percentage'] ?? 0.0).toDouble(),
      emailException: data['email_exception'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'percentage': percentage,
      'isInfinite': isInfinite,
      'association_percentage': associationPercentage,
      'email_exception': emailException,
    };
  }
}
