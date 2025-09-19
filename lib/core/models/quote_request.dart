import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteRequest {
  final String id;
  final String userId; // Particulier qui demande le devis
  final String? enterpriseId; // Entreprise destinataire (null si demande générale)
  final String? enterpriseName;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String projectType;
  final String projectDescription;
  final double? estimatedBudget;
  final String status; // pending, responded, accepted, rejected, completed
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? enterpriseResponse;
  final double? quotedAmount;
  final int? pointsGenerated;
  final bool pointsClaimed;
  final bool isGeneralRequest;

  QuoteRequest({
    required this.id,
    required this.userId,
    this.enterpriseId,
    this.enterpriseName,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.projectType,
    required this.projectDescription,
    this.estimatedBudget,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.enterpriseResponse,
    this.quotedAmount,
    this.pointsGenerated,
    this.pointsClaimed = false,
    this.isGeneralRequest = false,
  });

  factory QuoteRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuoteRequest(
      id: doc.id,
      userId: data['user_id'] ?? '',
      enterpriseId: data['enterprise_id'],
      enterpriseName: data['enterprise_name'],
      userName: data['user_name'] ?? '',
      userEmail: data['user_email'] ?? '',
      userPhone: data['user_phone'] ?? '',
      projectType: data['project_type'] ?? '',
      projectDescription: data['project_description'] ?? '',
      estimatedBudget: data['estimated_budget']?.toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['responded_at'] != null 
          ? (data['responded_at'] as Timestamp).toDate() 
          : null,
      enterpriseResponse: data['enterprise_response'],
      quotedAmount: data['quoted_amount']?.toDouble(),
      pointsGenerated: data['points_generated'],
      pointsClaimed: data['points_claimed'] ?? false,
      isGeneralRequest: data['is_general_request'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'enterprise_id': enterpriseId,
      'enterprise_name': enterpriseName,
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      'project_type': projectType,
      'project_description': projectDescription,
      'estimated_budget': estimatedBudget,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
      'responded_at': respondedAt,
      'enterprise_response': enterpriseResponse,
      'quoted_amount': quotedAmount,
      'points_generated': pointsGenerated,
      'points_claimed': pointsClaimed,
      'is_general_request': isGeneralRequest,
    };
  }
}