// lib/core/models/special_offer.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialOffer {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? linkUrl;
  final String? buttonText;
  final bool isActive;
  final int priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? backgroundColor;
  final String? textColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpecialOffer({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.linkUrl,
    this.buttonText,
    required this.isActive,
    required this.priority,
    this.startDate,
    this.endDate,
    this.backgroundColor,
    this.textColor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpecialOffer.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpecialOffer(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'],
      linkUrl: data['link_url'],
      buttonText: data['button_text'],
      isActive: data['is_active'] ?? false,
      priority: data['priority'] ?? 0,
      startDate: data['start_date'] != null 
          ? (data['start_date'] as Timestamp).toDate()
          : null,
      endDate: data['end_date'] != null
          ? (data['end_date'] as Timestamp).toDate()
          : null,
      backgroundColor: data['background_color'],
      textColor: data['text_color'],
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'button_text': buttonText,
      'is_active': isActive,
      'priority': priority,
      'start_date': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'end_date': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'background_color': backgroundColor,
      'text_color': textColor,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isCurrentlyActive {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }
    
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }
    
    return true;
  }
}