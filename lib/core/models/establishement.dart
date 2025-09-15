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
  final Map<String, List<String>>? enterpriseSubcategoryOptions; // subcategoryId -> [optionIds]

  final String videoUrl;
  final bool hasAcceptedContract;

  final int affiliatesCount;
  final bool isVisibleOverride;
  final bool isAssociation;
  final int maxVouchersPurchase;
  final double cashbackPercentage;
  final String? website;
  final bool? isPremiumSponsor;
  final bool isVisible;

  // Alias pour la compatibilité
  int get maxVouchersPerPurchase => maxVouchersPurchase;

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
    this.enterpriseSubcategoryOptions,
    required this.videoUrl,
    required this.hasAcceptedContract,
    this.affiliatesCount = 0,
    this.isVisibleOverride = false,
    this.isAssociation = false,
    this.maxVouchersPurchase = 1,
    this.cashbackPercentage = 2.0,
    this.website,
    this.isPremiumSponsor,
    this.isVisible = false,
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
      enterpriseSubcategoryOptions: _parseSubcategoryOptions(data['enterprise_subcategory_options']),
      videoUrl: data['video_url'] ?? '',
      hasAcceptedContract: data['has_accepted_contract'] ?? false,
      affiliatesCount: data['affiliatesCount'] ?? 0,
      isVisibleOverride: data['isVisibleOverride'] ?? false,
      isAssociation: data['isAssociation'] ?? false,
      maxVouchersPurchase: data['max_vouchers_purchase'] ?? 1,
      cashbackPercentage: (data['cashback_percentage'] ?? 2.0).toDouble(),
      website: data['website'] ?? '',
      isPremiumSponsor: data['is_premium_sponsor'] ?? false,
      isVisible: data['is_visible'] ?? false,
    );
  }
  
  static Map<String, List<String>>? _parseSubcategoryOptions(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final result = <String, List<String>>{};
      data.forEach((key, value) {
        if (value is List) {
          result[key] = value.map((e) => e.toString()).toList();
        }
      });
      return result.isNotEmpty ? result : null;
    }
    return null;
  }
}
