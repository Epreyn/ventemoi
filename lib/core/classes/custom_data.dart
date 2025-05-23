import 'dart:io';

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
      iconData: Icons.shopping_cart_outlined,
      text: 'Boutique',
      onPressed: () => Get.offNamed(Routes.shopEstablishment),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.enterprisesList,
      iconData: Icons.business_outlined,
      text: 'Entreprises',
      onPressed: () => Get.offNamed(Routes.enterprisesList),
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
      iconData: Icons.shopping_cart_outlined,
      text: 'Boutique',
      onPressed: () => Get.offNamed(Routes.shopEstablishment),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.enterprisesList,
      iconData: Icons.business_outlined,
      text: 'Entreprises',
      onPressed: () => Get.offNamed(Routes.enterprisesList),
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
      iconData: Icons.shopping_cart_outlined,
      text: 'Boutique',
      onPressed: () => Get.offNamed(Routes.shopEstablishment),
    ),
    CustomBottomAppBarIconButtonModel(
      tag: Routes.enterprisesList,
      iconData: Icons.business_outlined,
      text: 'Entreprises',
      onPressed: () => Get.offNamed(Routes.enterprisesList),
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
    Get.snackbar(
      title,
      message,
      icon: error
          ? const Icon(
              Icons.error,
              //color: CustomColors.atomicTangerine,
            )
          : const Icon(
              Icons.check_circle,
              //color: CustomColors.caribbeanCurrent,
            ),
      maxWidth: 600,
      borderWidth: baseSpace / 2,
      isDismissible: true,
      margin: EdgeInsets.symmetric(
        vertical: baseSpace * 2,
        horizontal: baseSpace * 2,
      ),
      duration: const Duration(seconds: 2),
      animationDuration: baseAnimationDuration * 2,
      // borderColor: CustomColors.caribbeanCurrent,
      // colorText: CustomColors.eerieBlack,
      // backgroundColor: CustomColors.lightBlue,
      mainButton: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          'OK',
          style: TextStyle(
              //color: CustomColors.caribbeanCurrent,
              ),
        ),
      ),
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  RxString oldImageUrl = ''.obs;
  RxBool isPickedFile = false.obs;
  Rx<File?> profileImageFile = Rx<File?>(null);
  Rx<Uint8List?> profileImageBytes = Rx<Uint8List?>(null);
}
