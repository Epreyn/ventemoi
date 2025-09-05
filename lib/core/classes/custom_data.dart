import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import '../../features/custom_bottom_app_bar/models/custom_bottom_app_bar_icon_button_model.dart';
import '../../features/custom_loader/view/custom_loader.dart';
import '../routes/app_routes.dart';

class CustomData extends GetxController {
  RxBool isInAsyncCall = false.obs;

  final firebaseAuth = FirebaseAuth.instance;
  final firebaseFirestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;

  double baseSpace = 8;
  double baseMaxWidth = 350;
  int baseArrayDelayGapAnimation = 60;

  double baseAppBarHeight = 56;
  Duration baseAnimationDuration = const Duration(milliseconds: 300);
  Curve baseAnimationCurve = Curves.easeOut;

  TextStyle titleTextStyle = const TextStyle(
    fontSize: 18,
    letterSpacing: 1.5,
    wordSpacing: 2,
    fontWeight: FontWeight.bold,
    //color: CustomColors.caribbeanCurrent,
  );

  TextStyle cardTitleTextStyle = const TextStyle(
    fontSize: 18,
    letterSpacing: 1.5,
    wordSpacing: 2,
  );

  FloatingActionButtonLocation fabLocation =
      FloatingActionButtonLocation.endFloat;

  RxInt currentNavigationMenuIndex = 0.obs;

  RxList<CustomBottomAppBarIconButtonModel> dynamicIconList =
      <CustomBottomAppBarIconButtonModel>[].obs;

  Future<void> loadIconList(String userId) async {
    final userSnap =
        await firebaseFirestore.collection('users').doc(userId).get();
    final userTypeId = userSnap.data()?['user_type_id'] ?? '';
    final docSnap =
        await firebaseFirestore.collection('user_types').doc(userTypeId).get();

    if (!docSnap.exists) {
      dynamicIconList.value = List.empty();
      return;
    }

    final userTypeName = docSnap.data()?['name'] ?? '';

    if (userTypeName == 'Association' || userTypeName == 'Boutique') {
      dynamicIconList.value = shopIconList;
    } else if (userTypeName == 'Entreprise') {
      dynamicIconList.value = proIconList;
    } else if (userTypeName == 'Particulier') {
      dynamicIconList.value = clientIconList;
    } else if (userTypeName == 'Administrateur') {
      dynamicIconList.value = adminIconList;
    } else {
      dynamicIconList.value = shopIconList;
    }
  }

  RxList<CustomBottomAppBarIconButtonModel> shopIconList =
      <CustomBottomAppBarIconButtonModel>[
    CustomBottomAppBarIconButtonModel(
      tag: Routes.shopEstablishment,
      iconData: Icons.explore_outlined,
      text: 'Explorer',
      onPressed: () => Get.offNamed(Routes.shopEstablishment),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.pointsSummary,
      iconData: Icons.account_balance_wallet,
      text: 'Mon Portefeuille',
      onPressed: () => Get.offNamed(Routes.pointsSummary),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.quotes,
      iconData: Icons.description_outlined,
      text: 'Devis',
      onPressed: () => Get.offNamed(Routes.quotes),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.proEstablishmentProfile,
      iconData: Icons.store_outlined,
      text: 'Fiche d\'établissement',
      onPressed: () => Get.offNamed(Routes.proEstablishmentProfile),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.proSells,
      iconData: Icons.bar_chart_outlined,
      text: 'Ventes',
      onPressed: () => Get.offNamed(Routes.proSells),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.clientHistory,
      iconData: Icons.history,
      text: 'Historique',
      onPressed: () => Get.offNamed(Routes.clientHistory),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.profile,
      iconData: Icons.person_outline,
      text: 'Profil',
      onPressed: () => Get.offNamed(Routes.profile),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.sponsorship,
      iconData: Icons.bolt_outlined,
      text: 'Parrainnage',
      onPressed: () => Get.offNamed(Routes.sponsorship),
    ),
  ].obs;

  RxList<CustomBottomAppBarIconButtonModel> proIconList =
      <CustomBottomAppBarIconButtonModel>[
    CustomBottomAppBarIconButtonModel(
      tag: Routes.shopEstablishment,
      iconData: Icons.explore_outlined,
      text: 'Explorer',
      onPressed: () => Get.offNamed(Routes.shopEstablishment),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.pointsSummary,
      iconData: Icons.account_balance_wallet,
      text: 'Mon Portefeuille',
      onPressed: () => Get.offNamed(Routes.pointsSummary),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.quotes,
      iconData: Icons.description_outlined,
      text: 'Devis',
      onPressed: () => Get.offNamed(Routes.quotes),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.proEstablishmentProfile,
      iconData: Icons.store_outlined,
      text: 'Fiche d\'établissement',
      onPressed: () => Get.offNamed(Routes.proEstablishmentProfile),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.proPoints,
      iconData: Icons.onetwothree_outlined,
      text: 'Points',
      onPressed: () => Get.offNamed(Routes.proPoints),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.clientHistory,
      iconData: Icons.history,
      text: 'Historique',
      onPressed: () => Get.offNamed(Routes.clientHistory),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.profile,
      iconData: Icons.person_outline,
      text: 'Profil',
      onPressed: () => Get.offNamed(Routes.profile),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.sponsorship,
      iconData: Icons.bolt_outlined,
      text: 'Parrainnage',
      onPressed: () => Get.offNamed(Routes.sponsorship),
    ),
  ].obs;

  RxList<CustomBottomAppBarIconButtonModel> clientIconList =
      <CustomBottomAppBarIconButtonModel>[
    CustomBottomAppBarIconButtonModel(
      tag: Routes.shopEstablishment,
      iconData: Icons.explore_outlined,
      text: 'Explorer',
      onPressed: () => Get.offNamed(Routes.shopEstablishment),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.pointsSummary,
      iconData: Icons.account_balance_wallet,
      text: 'Mon Portefeuille',
      onPressed: () => Get.offNamed(Routes.pointsSummary),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.quotes,
      iconData: Icons.description_outlined,
      text: 'Devis',
      onPressed: () => Get.offNamed(Routes.quotes),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.clientHistory,
      iconData: Icons.history,
      text: 'Historique',
      onPressed: () => Get.offNamed(Routes.clientHistory),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.profile,
      iconData: Icons.person_outline,
      text: 'Profil',
      onPressed: () => Get.offNamed(Routes.profile),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.sponsorship,
      iconData: Icons.bolt_outlined,
      text: 'Parrainnage',
      onPressed: () => Get.offNamed(Routes.sponsorship),
    ),
  ].obs;

  RxList<CustomBottomAppBarIconButtonModel> adminIconList =
      <CustomBottomAppBarIconButtonModel>[
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminUsers,
      iconData: Icons.people_outline,
      text: 'Utilisateurs',
      onPressed: () => Get.offNamed(Routes.adminUsers),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminEstablishments,
      iconData: Icons.business_outlined,
      text: 'Établissements',
      onPressed: () => Get.offNamed(Routes.adminEstablishments),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminSells,
      iconData: Icons.bar_chart_outlined,
      text: 'Ventes',
      onPressed: () => Get.offNamed(Routes.adminSells),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminPointsAttributions,
      iconData: Icons.onetwothree_outlined,
      text: 'Points',
      onPressed: () => Get.offNamed(Routes.adminPointsAttributions),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminPointsRequests,
      iconData: Icons.edit_document,
      text: 'Bons',
      onPressed: () => Get.offNamed(Routes.adminPointsRequests),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminUserTypes,
      iconData: Icons.group_outlined,
      text: 'Types d\'Utilisateurs',
      onPressed: () => Get.offNamed(Routes.adminUserTypes),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminCategories,
      iconData: Icons.category_outlined,
      text: 'Catégories',
      onPressed: () => Get.offNamed(Routes.adminCategories),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminEnterpriseCategories,
      iconData: Icons.construction,
      text: 'Catégories d\'Entreprises',
      onPressed: () => Get.offNamed(Routes.adminEnterpriseCategories),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminCommissions,
      iconData: Icons.calculate_outlined,
      text: 'Commissions',
      onPressed: () => Get.offNamed(Routes.adminCommissions),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.adminOffers,
      iconData: Icons.local_offer_outlined,
      text: 'Offres du moment',
      onPressed: () => Get.offNamed(Routes.adminOffers),
    ),
    // CustomBottomAppBarIconButtonModel(
    //   tag: Routes.adminMigration,
    //   iconData: Icons.move_to_inbox_outlined,
    //   text: 'Migration',
    //   onPressed: () => Get.offNamed(Routes.adminMigration),
    // ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.profile,
      iconData: Icons.person_outline,
      text: 'Profil',
      onPressed: () => Get.offNamed(Routes.profile),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.sponsorship,
      iconData: Icons.bolt_outlined,
      text: 'Parrainnage',
      onPressed: () => Get.offNamed(Routes.sponsorship),
    ),
  ].obs;

  Widget loader({Color? color, double? size}) {
    return Center(
      child: CustomLoader(
        size: size,
        color: color ?? CustomTheme.lightScheme().primary,
      ),
    );
  }

  void back() {
    closeDialogAndBottomSheet();
  }

  void closeDialogAndBottomSheet() {
    if (Get.isDialogOpen!) Get.back();
    if (Get.isBottomSheetOpen!) Get.back();
  }

  void snackbar(String title, String message, bool error) {
    Get.showSnackbar(
      GetSnackBar(
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.all(baseSpace * 2),
        borderRadius: 20,
        duration: const Duration(seconds: 3),
        animationDuration: baseAnimationDuration,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeIn,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        messageText: Container(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: error
                          ? Colors.red.withOpacity(0.1)
                          : CustomTheme.lightScheme().primary.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(baseSpace * 1.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: baseSpace * 2,
                              vertical: baseSpace,
                            ),
                            decoration: BoxDecoration(
                              color: error
                                  ? Colors.red.withOpacity(0.1)
                                  : CustomTheme.lightScheme()
                                      .primary
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(baseSpace),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: error
                                          ? [
                                              Colors.red.withOpacity(0.8),
                                              Colors.red.withOpacity(0.6),
                                            ]
                                          : [
                                              CustomTheme.lightScheme().primary,
                                              CustomTheme.lightScheme()
                                                  .primary
                                                  .withOpacity(0.8),
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: error
                                            ? Colors.red.withOpacity(0.3)
                                            : CustomTheme.lightScheme()
                                                .primary
                                                .withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    error
                                        ? Icons.error_outline_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: baseSpace * 1.5),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          CustomTheme.lightScheme().onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Get.back(),
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: CustomTheme.lightScheme()
                                        .onSurface
                                        .withOpacity(0.5),
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: baseSpace * 2,
                              right: baseSpace * 2,
                              top: baseSpace,
                              bottom: baseSpace * 0.5,
                            ),
                            child: Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                color: CustomTheme.lightScheme()
                                    .onSurface
                                    .withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  RxString oldImageUrl = ''.obs;
  RxBool isPickedFile = false.obs;
  Rx<File?> profileImageFile = Rx<File?>(null);
  Rx<Uint8List?> profileImageBytes = Rx<Uint8List?>(null);
}
