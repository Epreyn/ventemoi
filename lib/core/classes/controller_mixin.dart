import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/classes/email_templates.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import '../../features/custom_animation/view/custom_animation.dart';
import '../../features/custom_fab_button/view/custom_fab_button.dart';
import '../../features/custom_icon_button/view/custom_icon_button.dart';
import '../../features/custom_space/view/custom_space.dart';
import '../../features/custom_text_button/view/custom_text_button.dart';
import '../models/establishment_category.dart';
import '../models/user_type.dart';
import 'unique_controllers.dart';

mixin ControllerMixin on GetxController {
  //#region USER

  Stream<Map<String, dynamic>?> getUserDocStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(UniquesControllers().data.firebaseAuth.currentUser?.uid)
        .snapshots()
        .map((snap) => snap.data());
  }

  Future<List<Map<String, dynamic>>> getAllUsersWithTypeAdmin() async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .where('user_type_id', isEqualTo: '3YxzCA7BewiMswi8FDSt')
        .get();

    final result = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      result.add({
        'id': doc.id,
        ...doc.data(),
      });
    }

    return result;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getAllAdmins() async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .where('user_type_id', isEqualTo: '3YxzCA7BewiMswi8FDSt')
        .get();

    return snap.docs;
  }

  //#endregion

  //#region USER TYPES

  Rx<UserType?> currentUserType = Rx<UserType?>(null);

  Future<String> _fetchUserTypeName(String userId) async {
    final snapUser = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();

    if (!snapUser.exists) return '';
    final userData = snapUser.data()!;
    final userTypeId = userData['user_type_id'] ?? '';
    if (userTypeId.isEmpty) return '';

    final snapType = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .doc(userTypeId)
        .get();

    if (!snapType.exists) return '';
    final typeData = snapType.data()!;
    final typeName = typeData['name'] ?? '';
    return typeName.toString();
  }

  Stream<List<UserType>> getUserTypesStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .snapshots()
        .map((query) {
      var filteredDocs = query.docs.toList();
      filteredDocs
          .sort((a, b) => a.data()['index'].compareTo(b.data()['index']));
      return filteredDocs.map((doc) => UserType.fromDocument(doc)).toList();
    });
  }

  Stream<List<UserType>> getUserTypesStreamExceptAdmin() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .snapshots()
        .map((query) {
      var docs = query.docs.toList();
      docs.sort((a, b) =>
          (a.data()['index'] as int).compareTo((b.data()['index'] as int)));
      docs = docs.where((doc) => (doc.data()['index'] as int) != 0).toList();
      return docs.map((doc) => UserType.fromDocument(doc)).toList();
    });
  }

  Future<String> getUserTypeNameByUserId(String userId) async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();
    final userTypeId = snap.data()?['user_type_id'] ?? '';
    final typeSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .doc(userTypeId)
        .get();
    return typeSnap.data()?['name'] ?? '';
  }

  Future<String> getUserTypeIDByUserTypeName(String userTypeName) async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .where('name', isEqualTo: userTypeName)
        .get();
    return snap.docs.first.id;
  }

  //#endregion

  //#region WALLET

  Stream<Map<String, dynamic>?> getWalletDocStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id',
            isEqualTo: UniquesControllers().data.firebaseAuth.currentUser?.uid)
        .limit(1)
        .snapshots()
        .map((query) {
      if (query.docs.isEmpty) return null;
      return query.docs.first.data();
    });
  }

  //#endregion

  //#region ESTABLISHMENT CATEGORIES

  Rx<EstablishmentCategory?> currentCategory = Rx<EstablishmentCategory?>(null);

  Stream<List<EstablishmentCategory>> getCategoriesStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .snapshots()
        .map((query) {
      final docs = query.docs.toList();
      docs.sort((a, b) =>
          (a.data()['index'] as int).compareTo((b.data()['index'] as int)));
      return docs
          .map((doc) => EstablishmentCategory.fromDocument(doc))
          .toList();
    });
  }

  getCategoryById(String id) async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .doc(id)
        .get();
    return EstablishmentCategory.fromDocument(snap);
  }

  Future<String> getCategoryNameById(String id) async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .doc(id)
        .get();
    return EstablishmentCategory.fromDocument(snap).name;
  }

  //#endregion

  //#region CLIENT SHOP

  Stream<int> getUserWalletStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return 0;
      } else {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return data['points'] ?? 0;
      }
    });
  }

  Future<void> updateUserPoints(String uid, int newPoints) async {
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final docId = snap.docs.first.id;
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc(docId)
          .update({'points': newPoints});
    }
  }

  //#endregion

  //#region ALERT DIALOG - MODERNISÉ

  int alertDialogAnimationDuration = 400;

  void variablesToResetToAlertDialog() {}

  actionAlertDialog() async {}

  Widget alertDialogContent() {
    return const SizedBox();
  }

  void openAlertDialog(String title,
      {String? confirmText, Color? confirmColor, IconData? icon}) {
    variablesToResetToAlertDialog();

    Get.dialog(
      CustomAnimation(
        duration: Duration(milliseconds: alertDialogAnimationDuration),
        curve: Curves.easeInOutBack,
        isOpacity: true,
        yStartPosition: alertDialogAnimationDuration / 10,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
            ),
            child: Stack(
              children: [
                // Fond avec glassmorphism
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header avec icône
                              if (icon != null) ...[
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: (confirmColor ??
                                            CustomTheme.lightScheme().primary)
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 32,
                                    color: confirmColor ??
                                        CustomTheme.lightScheme().primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Titre
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 24),

                              // Contenu
                              Flexible(
                                child: SingleChildScrollView(
                                  child: alertDialogContent(),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Get.back(),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Annuler',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        Get.back();
                                        await actionAlertDialog();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: confirmColor ??
                                            CustomTheme.lightScheme().primary,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        confirmText ?? 'Confirmer',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  //#endregion

  //#region BOTTOM SHEET - MODERNISÉ

  void variablesToResetToBottomSheet() {}

  deleteBottomSheet() {}

  actionBottomSheet() async {}

  List<Widget> bottomSheetChildren() {
    return const [];
  }

  void openBottomSheet(
    String title, {
    bool? hasDeleteButton,
    String? deleteButtonRightName,
    bool? hasAction,
    String? actionName,
    IconData? actionIcon,
    double? maxWidth,
    bool doReset = true,
    Color? primaryColor,
    String? subtitle,
    Widget? headerWidget,
  }) {
    if (doReset) variablesToResetToBottomSheet();

    final color = primaryColor ?? CustomTheme.lightScheme().primary;

    Get.bottomSheet(
      Stack(
        children: [
          // Fond avec effet de gradient
          // Container(
          //   height: MediaQuery.of(Get.context!).size.height,
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //       colors: [
          //         Colors.black.withOpacity(0.5),
          //         Colors.black.withOpacity(0.7),
          //       ],
          //     ),
          //   ),
          // ),

          // Contenu principal
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? double.infinity,
                maxHeight: MediaQuery.of(Get.context!).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle animé
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween(begin: 30, end: 50),
                      builder: (context, value, child) {
                        return Container(
                          width: value,
                          height: 5,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Header amélioré
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[100]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Bouton retour avec animation
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 200),
                              tween: Tween(begin: 0, end: 1),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey[100]!,
                                          Colors.grey[50]!,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => Get.back(),
                                        customBorder: const CircleBorder(),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 16),

                            // Titre et sous-titre
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Bouton suppression avec animation
                            if (hasDeleteButton ?? false)
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 200),
                                tween: Tween(begin: 0, end: 1),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red.withOpacity(0.1),
                                            Colors.red.withOpacity(0.05),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: deleteBottomSheet,
                                          customBorder: const CircleBorder(),
                                          child: const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Icon(
                                              Icons.delete_rounded,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),

                        // Widget header personnalisé optionnel
                        if (headerWidget != null) ...[
                          const SizedBox(height: 16),
                          headerWidget,
                        ],

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Contenu scrollable avec fade effect
                  Flexible(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Animation d'entrée pour chaque enfant
                              ...bottomSheetChildren()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final child = entry.value;

                                return TweenAnimationBuilder<double>(
                                  duration: Duration(
                                      milliseconds: 300 + (index * 50)),
                                  tween: Tween(begin: 0, end: 1),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            bottom: index <
                                                    bottomSheetChildren()
                                                            .length -
                                                        1
                                                ? 16
                                                : 0,
                                          ),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        ),

                        // Gradient fade en haut
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action button amélioré
                  if (hasAction ?? true)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 400),
                            tween: Tween(begin: 0.8, end: 1),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [
                                        color,
                                        color.withOpacity(0.8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: actionBottomSheet,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                          horizontal: 24,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (actionIcon != null) ...[
                                              Icon(
                                                actionIcon,
                                                size: 22,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                            Text(
                                              actionName?.toUpperCase() ??
                                                  'VALIDER',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
    );
  }

  //#endregion

//#region MAIL

  Future<void> sendMailSimple({
    required String toEmail,
    required String subject,
    required String htmlBody,
  }) async {
    if (toEmail.trim().isEmpty) return;

    final mailDoc = {
      "to": toEmail.trim(),
      "message": {
        "subject": subject,
        "html": htmlBody,
      },
    };

    await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('mail')
        .add(mailDoc);
  }

  // Email de bienvenue utilisant le template moderne
  Future<void> sendWelcomeEmail(String toEmail, String userName) async {
    await sendModernWelcomeEmail(toEmail, userName);
  }

  // Email de bienvenue pour utilisateur créé
  Future<void> sendWelcomeEmailForCreatedUser({
    required String toEmail,
    required String whoDidCreate,
  }) async {
    if (toEmail.trim().isEmpty) return;

    final content = '''
      <h2>Bienvenue sur Vente Moi ! 🎉</h2>
      <p>
        Votre compte a été créé avec succès par <strong>$whoDidCreate</strong>.
      </p>

      <div class="highlight-box">
        <h3>Prochaines étapes</h3>
        <p style="text-align: left; margin: 10px 0;">
          1. Vous allez recevoir un email pour définir votre mot de passe<br>
          2. Une fois votre mot de passe créé, connectez-vous à votre compte<br>
          3. Explorez nos services et commencez à gagner des points !
        </p>
      </div>

      <p>
        Nous sommes ravis de vous compter parmi nous. N'hésitez pas à nous contacter
        si vous avez des questions.
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://app.ventemoi.fr" class="button">Découvrir Vente Moi</a>
      </div>
    ''';

    await sendMailSimple(
      toEmail: toEmail,
      subject: 'Votre compte Vente Moi a été créé',
      htmlBody: buildModernMailHtml(content),
    );
  }

  // Email de confirmation d'achat au buyer
  Future<void> sendPurchaseEmailToBuyer({
    required String buyerEmail,
    required String buyerName,
    required String sellerName,
    required bool isDonation,
    required int couponsCountOrPoints,
    required String? reclamationPassword,
  }) async {
    await sendModernPurchaseEmailToBuyer(
      buyerEmail: buyerEmail,
      buyerName: buyerName,
      sellerName: sellerName,
      isDonation: isDonation,
      couponsCountOrPoints: couponsCountOrPoints,
      reclamationPassword: reclamationPassword,
      purchaseDate: DateTime.now(),
    );
  }

  // Email de notification au seller
  Future<void> sendPurchaseEmailToSeller({
    required String sellerEmail,
    required String sellerName,
    required String buyerName,
    required bool isDonation,
    required int couponsCountOrPoints,
  }) async {
    if (sellerEmail.trim().isEmpty) return;

    late String subject;
    late String content;

    if (isDonation) {
      subject = '❤️ Nouveau don reçu - Vente Moi';
      content = '''
        <h2>Félicitations $sellerName ! 🎉</h2>
        <p>
          Vous venez de recevoir un don généreux de la part de <strong>$buyerName</strong>.
        </p>

        <div class="highlight-box">
          <h3>Détails du don</h3>
          <div class="info-value" style="font-size: 48px; color: #f8b02a; margin: 20px 0;">
            $couponsCountOrPoints
          </div>
          <p style="margin: 10px 0; color: #666;">
            points reçus
          </p>
        </div>

        <p>
          Ce don témoigne de la confiance et du soutien de vos bienfaiteurs.
          Merci pour votre engagement solidaire !
        </p>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://app.ventemoi.fr/#/mes-dons-recus" class="button">
            Voir mes dons reçus
          </a>
        </div>
      ''';
    } else {
      subject = '🛍️ Nouvel achat de bons - Vente Moi';
      content = '''
        <h2>Nouvelle vente réalisée ! 💰</h2>
        <p>
          <strong>$buyerName</strong> vient d'effectuer un achat dans votre boutique.
        </p>

        <div class="highlight-box">
          <h3>Détails de la commande</h3>
          <div class="info-grid" style="max-width: 400px; margin: 0 auto;">
            <div class="info-item">
              <div class="info-label">Nombre de bons</div>
              <div class="info-value" style="color: #f8b02a;">$couponsCountOrPoints</div>
            </div>
            <div class="info-item">
              <div class="info-label">Valeur totale</div>
              <div class="info-value" style="color: #f8b02a;">${couponsCountOrPoints * 50} €</div>
            </div>
          </div>
        </div>

        <p>
          Merci de préparer cette commande. Le client présentera son code
          pour récupérer ses bons.
        </p>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://app.ventemoi.fr/#/mes-ventes" class="button">
            Voir mes ventes
          </a>
        </div>
      ''';
    }

    await sendMailSimple(
      toEmail: sellerEmail,
      subject: subject,
      htmlBody: buildModernMailHtml(content),
    );
  }

  // Email d'alerte stock faible
  Future<void> sendLowCouponsEmailToSeller({
    required String sellerEmail,
    required String sellerName,
    required int couponsRemaining,
  }) async {
    if (sellerEmail.trim().isEmpty) return;

    final content = '''
      <h2>⚠️ Stock de bons faible</h2>
      <p>
        Bonjour $sellerName,
      </p>
      <p>
        Nous vous informons que votre stock de bons est en baisse.
      </p>

      <div class="highlight-box" style="background: linear-gradient(135deg, #fff5f5 0%, #ffe6e6 100%); border-color: #ff4444;">
        <h3 style="color: #ff4444;">Stock actuel</h3>
        <div class="info-value" style="font-size: 48px; color: #ff4444; margin: 20px 0;">
          $couponsRemaining
        </div>
        <p style="margin: 10px 0; color: #666;">
          bon(s) restant(s)
        </p>
      </div>

      <p>
        Pour éviter toute rupture de stock, nous vous recommandons de
        renouveler vos bons dès maintenant.
      </p>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://app.ventemoi.fr/#/mon-profil" class="button">
          Commander des bons
        </a>
      </div>
    ''';

    await sendMailSimple(
      toEmail: sellerEmail,
      subject: '⚠️ Alerte: Stock de bons faible',
      htmlBody: buildModernMailHtml(content),
    );
  }

  // Email de notification aux admins pour attribution de points
  Future<void> sendProAttributionMailToAdmins({
    required String proEmail,
    required double montant,
    required int points,
    required double commissionPercent,
    required int commissionCost,
  }) async {
    final adminDocs = await getAllAdmins();
    if (adminDocs.isEmpty) return;

    final content = '''
      <h2>📊 Nouvelle attribution de points</h2>
      <p>
        Une entreprise vient d'effectuer une attribution de points à un utilisateur.
      </p>

      <div class="highlight-box">
        <h3>Détails de l'opération</h3>
        <div class="info-grid" style="max-width: 500px; margin: 0 auto;">
          <div class="info-item">
            <div class="info-label">Entreprise</div>
            <div class="info-value">$proEmail</div>
          </div>
          <div class="info-item">
            <div class="info-label">Points attribués</div>
            <div class="info-value" style="color: #f8b02a;">$points</div>
          </div>
          <div class="info-item">
            <div class="info-label">Montant</div>
            <div class="info-value">$montant €</div>
          </div>
          <div class="info-item">
            <div class="info-label">Commission</div>
            <div class="info-value">$commissionPercent %</div>
          </div>
        </div>
        <p style="margin-top: 15px; text-align: center; color: #666;">
          Montant de la commission : <strong style="color: #f8b02a;">$commissionCost €</strong>
        </p>
      </div>

      <div style="text-align: center; margin: 30px 0;">
        <a href="https://app.ventemoi.fr/#/admin/attributions" class="button">
          Voir dans le back-office
        </a>
      </div>
    ''';

    for (final doc in adminDocs) {
      final adminData = doc.data();
      final adminEmail = (adminData['email'] ?? '').toString().trim();
      if (adminEmail.isNotEmpty) {
        await sendMailSimple(
          toEmail: adminEmail,
          subject: '📊 Nouvelle attribution de points (Entreprise)',
          htmlBody: buildModernMailHtml(content),
        );
      }
    }
  }

  // Email de demande d'achat de bons aux admins
  Future<void> sendEnterpriseBuyCouponsRequestEmailToAdmins({
    required String enterpriseEmail,
    required String enterpriseName,
    required int couponsCount,
  }) async {
    try {
      final adminDocs = await getAllAdmins();
      if (adminDocs.isEmpty) return;

      final content = '''
        <h2>📋 Nouvelle demande d'achat de bons</h2>
        <p>
          Une entreprise vient de soumettre une demande d'achat de bons.
        </p>

        <div class="highlight-box">
          <h3>Détails de la demande</h3>
          <div class="info-grid" style="max-width: 500px; margin: 0 auto;">
            <div class="info-item">
              <div class="info-label">Entreprise</div>
              <div class="info-value">$enterpriseName</div>
            </div>
            <div class="info-item">
              <div class="info-label">Email</div>
              <div class="info-value" style="font-size: 14px;">$enterpriseEmail</div>
            </div>
          </div>
          <div style="text-align: center; margin-top: 20px;">
            <div class="info-label">Nombre de bons demandés</div>
            <div class="info-value" style="font-size: 48px; color: #f8b02a; margin-top: 10px;">
              $couponsCount
            </div>
          </div>
        </div>

        <p>
          Cette demande nécessite votre validation dans l'interface d'administration.
        </p>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://app.ventemoi.fr/#/admin/demandes" class="button">
            Traiter la demande
          </a>
        </div>
      ''';

      for (final doc in adminDocs) {
        final adminData = doc.data();
        final adminEmail = (adminData['email'] ?? '').toString().trim();
        if (adminEmail.isNotEmpty) {
          await sendMailSimple(
            toEmail: adminEmail,
            subject: '📋 Demande d\'achat de bons - $enterpriseName',
            htmlBody: buildModernMailHtml(content),
          );
        }
      }
    } catch (err) {
      debugPrint('Error notifying admins about coupon request: $err');
    }
  }

  // Email de parrainage entreprise
  Future<void> sendSponsorshipMailAboutEnterprise({
    required String sponsorName,
    required String sponsorEmail,
    required String userEmail,
  }) async {
    try {
      final content = '''
        <h2>🎉 Félicitations $sponsorName !</h2>
        <p>
          Votre parrainage porte ses fruits ! <strong>$userEmail</strong> vient de
          s'inscrire sur Vente Moi grâce à vous.
        </p>

        <div class="highlight-box">
          <h3>Votre récompense</h3>
          <div class="info-value" style="font-size: 48px; color: #f8b02a; margin: 20px 0;">
            +50
          </div>
          <p style="margin: 10px 0; color: #666;">
            points bonus
          </p>
        </div>

        <p>
          Continuez à parrainer vos contacts et accumulez encore plus de points !
          Chaque parrainage réussi vous rapproche de nouvelles récompenses.
        </p>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://app.ventemoi.fr/#/parrainage" class="button">
            Parrainer d'autres contacts
          </a>
        </div>
      ''';

      await sendMailSimple(
        toEmail: sponsorEmail,
        subject: '🎊 +50 points grâce à votre parrainage !',
        htmlBody: buildModernMailHtml(content),
      );
    } catch (err) {
      debugPrint('Error sending sponsorship email: $err');
    }
  }

  // Email de parrainage pour attribution
  Future<void> sendSponsorshipMailForAttribution({
    required String sponsorName,
    required String sponsorEmail,
    required String filleulEmail,
    required int pointsWon,
  }) async {
    await sendSponsorshipNotificationEmail(
      sponsorEmail: sponsorEmail,
      sponsorName: sponsorName,
      newUserEmail: filleulEmail,
      pointsEarned: pointsWon,
    );
  }

  /// Email d'invitation avec points en attente
  Future<void> sendPointsInvitationEmail({
    required String recipientEmail,
    required int points,
    required String invitationToken,
  }) async {
    try {
      final appUrl =
          'https://app.ventemoi.fr/register?token=$invitationToken&email=${Uri.encodeComponent(recipientEmail)}';

      final content = '''
        <h2>🎉 Vous avez reçu des points !</h2>
        <p>
          Bonne nouvelle ! Vous avez reçu <strong style="color: #f8b02a; font-size: 24px;">$points points</strong>
          sur notre plateforme VenteMoi.
        </p>

        <div class="highlight-box">
          <h3>Vos points vous attendent</h3>
          <div class="info-value" style="font-size: 48px; color: #f8b02a; margin: 20px 0;">
            $points
          </div>
          <p style="margin: 10px 0; color: #666;">
            points offerts
          </p>
        </div>

        <p style="font-size: 16px; color: #555; line-height: 1.6; margin-top: 20px;">
          Pour récupérer vos points, il vous suffit de créer votre compte en cliquant sur le bouton ci-dessous :
        </p>

        <div style="text-align: center; margin: 30px 0;">
          <a href="$appUrl" class="button">
            Créer mon compte et récupérer mes points
          </a>
        </div>

        <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 30px;">
          <p style="font-size: 14px; color: #555; margin: 0;">
            <strong>Comment ça marche ?</strong><br>
            1. Cliquez sur le bouton ci-dessus<br>
            2. Créez votre compte avec cette adresse email : <strong>$recipientEmail</strong><br>
            3. Vos $points points seront automatiquement crédités<br>
            4. Utilisez vos points pour profiter de nos offres exclusives !
          </p>
        </div>

        <div class="divider"></div>

        <p style="font-size: 14px; color: #888; margin-top: 20px;">
          💡 <strong>Qu'est-ce que VenteMoi ?</strong><br>
          VenteMoi est une plateforme solidaire qui vous permet d'utiliser vos points pour :
        </p>
        <ul style="font-size: 14px; color: #666; line-height: 1.8;">
          <li>Acheter des bons d'achat chez nos partenaires</li>
          <li>Faire des dons à des associations</li>
          <li>Participer à l'économie solidaire locale</li>
          <li>Gagner encore plus de points en parrainant vos proches</li>
        </ul>

        <p style="font-size: 13px; color: #999; margin-top: 30px; text-align: center;">
          Si vous ne pouvez pas cliquer sur le bouton, copiez et collez ce lien dans votre navigateur :<br>
          <a href="$appUrl" style="color: #f8b02a; word-break: break-all;">$appUrl</a>
        </p>
      ''';

      await sendMailSimple(
        toEmail: recipientEmail,
        subject: '🎉 Vous avez reçu $points points sur VenteMoi !',
        htmlBody: buildModernMailHtml(content),
      );
    } catch (e) {
      rethrow;
    }
  }

//#endregion MAIL
}
