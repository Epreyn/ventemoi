import 'package:cloud_firestore/cloud_firestore.dart';

class Commission {
  final String id;
  final double minAmount; // Montant minimal
  final double maxAmount; // Montant maximal (ou 0 si isInfinite = true)
  final double percentage; // Commission en %
  final bool isInfinite; // Vrai => ignore maxAmount => s'applique à l'infini
  final double associationPercentage; // Part pour l'association
  final String
      emailException; // Si non vide => ne s'applique qu'à ce mail d'entreprise

  // Nouveaux champs
  final int?
      priority; // Priorité de la commission (plus élevé = plus prioritaire)
  final String? description; // Description optionnelle
  final bool? isDefault; // Commission par défaut si aucune autre ne s'applique
  final DateTime? createdAt; // Date de création
  final DateTime? updatedAt; // Date de dernière modification

  Commission({
    required this.id,
    required this.minAmount,
    required this.maxAmount,
    required this.percentage,
    required this.isInfinite,
    required this.associationPercentage,
    required this.emailException,
    this.priority,
    this.description,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
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
      priority: data['priority'] as int?,
      description: data['description'] as String?,
      isDefault: data['isDefault'] as bool?,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : null,
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
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
      'priority': priority ?? 0,
      'description': description ?? '',
      'isDefault': isDefault ?? false,
      'created_at': createdAt ?? DateTime.now(),
      'updated_at': updatedAt ?? DateTime.now(),
    };
  }

  // Méthode utilitaire pour afficher la plage de façon lisible
  String get rangeDisplay {
    if (isInfinite) {
      return '${minAmount.toStringAsFixed(0)}€ - ∞';
    }
    return '${minAmount.toStringAsFixed(0)}€ - ${maxAmount.toStringAsFixed(0)}€';
  }

  // Méthode pour vérifier si un montant est dans la plage
  bool isAmountInRange(double amount) {
    if (amount < minAmount) return false;
    if (isInfinite) return true;
    return amount < maxAmount;
  }

  // Méthode pour calculer la commission sur un montant
  double calculateCommission(double amount) {
    if (!isAmountInRange(amount)) return 0.0;
    return amount * percentage / 100;
  }

  // Méthode pour calculer la part de l'association
  double calculateAssociationPart(double amount) {
    if (!isAmountInRange(amount) || associationPercentage == 0) return 0.0;
    return amount * associationPercentage / 100;
  }

  // Copie avec modifications
  Commission copyWith({
    String? id,
    double? minAmount,
    double? maxAmount,
    double? percentage,
    bool? isInfinite,
    double? associationPercentage,
    String? emailException,
    int? priority,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Commission(
      id: id ?? this.id,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      percentage: percentage ?? this.percentage,
      isInfinite: isInfinite ?? this.isInfinite,
      associationPercentage:
          associationPercentage ?? this.associationPercentage,
      emailException: emailException ?? this.emailException,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Commission{id: $id, range: $rangeDisplay, percentage: $percentage%, '
        'priority: ${priority ?? 0}, emailException: $emailException, '
        'isDefault: ${isDefault ?? false}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Commission &&
        other.id == id &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.percentage == percentage &&
        other.isInfinite == isInfinite &&
        other.associationPercentage == associationPercentage &&
        other.emailException == emailException &&
        other.priority == priority &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        minAmount.hashCode ^
        maxAmount.hashCode ^
        percentage.hashCode ^
        isInfinite.hashCode ^
        associationPercentage.hashCode ^
        emailException.hashCode ^
        (priority ?? 0).hashCode ^
        (isDefault ?? false).hashCode;
  }
}
