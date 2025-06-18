import 'package:cloud_firestore/cloud_firestore.dart';

import 'nameable.dart';

class Establishment implements Nameable {
  @override
  final String id;
  @override
  final String name;
  final String userId;
  final String description;
  final String address;
  final String email;
  final String telephone;
  final String logoUrl;
  final String bannerUrl;
  final String categoryId;
  final List<String>? enterpriseCategoryIds;
  final int enterpriseCategorySlots;

  final String videoUrl;
  final bool hasAcceptedContract;

  final int affiliatesCount;
  final bool isVisibleOverride;
  final bool isAssociation;

  Establishment({
    required this.id,
    required this.name,
    required this.userId,
    required this.description,
    required this.address,
    required this.email,
    required this.telephone,
    required this.logoUrl,
    required this.bannerUrl,
    required this.categoryId,
    required this.enterpriseCategoryIds,
    required this.enterpriseCategorySlots, // NOUVEAU
    required this.videoUrl,
    required this.hasAcceptedContract,
    this.affiliatesCount = 0,
    this.isVisibleOverride = false,
    this.isAssociation = false,
  });

  factory Establishment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawECats = data['enterprise_categories'] as List<dynamic>?;

    return Establishment(
      id: doc.id,
      name: data['name'] ?? '',
      userId: data['user_id'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      logoUrl: data['logo_url'] ?? '',
      bannerUrl: data['banner_url'] ?? '',
      categoryId: data['category_id'] ?? '',
      enterpriseCategoryIds: rawECats?.map((e) => e.toString()).toList(),
      enterpriseCategorySlots: data['enterprise_category_slots'] ?? 2,
      videoUrl: data['video_url'] ?? '',
      hasAcceptedContract: data['has_accepted_contract'] ?? false,
      affiliatesCount: data['affiliatesCount'] ?? 0,
      isVisibleOverride: data['isVisibleOverride'] ?? false,
      isAssociation: data['isAssociation'] ?? false,
    );
  }
}
