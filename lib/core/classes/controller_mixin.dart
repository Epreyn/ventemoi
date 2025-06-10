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

  String _buildMailHtml(String content) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Vente Moi – Notification</title>
    <style>
      body {
        font-family: Arial, sans-serif;
        margin: 0; padding: 0;
        background-color: #fafafa;
        color: #333;
      }
      .header {
        background-color: #f8b02a;
        padding: 16px;
        text-align: center;
      }
      .header img {
        max-height: 50px;
      }
      .content {
        margin: 16px;
      }
      h1 { color: #f8b02a; }
      p { line-height: 1.5; }
      .footer {
        margin: 16px;
        font-size: 12px;
        color: #666;
      }
    </style>
  </head>
  <body>
    <div class="header">
      <img src="https://firebasestorage.googleapis.com/v0/b/vente-moi.appspot.com/o/logo.png?alt=media"
           alt="Logo Vente Moi" />
    </div>
    <div class="content">
      $content
    </div>
    <div class="footer">
      Cet e-mail vous a été envoyé automatiquement par Vente Moi.<br>
      Pour toute question, contactez
      <a href="mailto:support@ventemoi.com">support@ventemoi.com</a>.
    </div>
  </body>
</html>
''';
  }

  Future<void> sendWelcomeEmail(String toEmail, String userName) async {
    final content = '''
      <h1>Bonjour $userName,</h1>
      <p>
        Merci de vous être inscrit sur <strong>Vente Moi</strong> !
        Nous sommes ravis de vous accueillir parmi nous.
      </p>
      <p>
        Vous pouvez dès à présent vous connecter à votre compte et profiter
        de toutes les fonctionnalités de la plateforme.
      </p>
      <p>
        À très bientôt,<br>
        L'équipe de Vente Moi
      </p>
    ''';

    final fullHtml = _buildMailHtml(content);

    await sendMailSimple(
      toEmail: toEmail,
      subject: 'Bienvenue sur Vente Moi',
      htmlBody: fullHtml,
    );
  }

  Future<void> sendWelcomeEmailForCreatedUser({
    required String toEmail,
    required String whoDidCreate,
  }) async {
    if (toEmail.trim().isEmpty) return;

    // Contenu HTML spécifique
    final content = '''
    <h1>Bienvenue sur Vente Moi</h1>
    <p>
      Votre compte a été créé par <strong>$whoDidCreate</strong> sur la plateforme Vente Moi.
    </p>
    <p>
      Vous allez recevoir un autre e-mail pour définir votre mot de passe.
      Une fois votre mot de passe créé, vous pourrez vous connecter et profiter de nos services.
    </p>
    <p>
      À très bientôt,<br>
      L'équipe Vente Moi
    </p>
  ''';

    // On génère le HTML complet avec header/footer commun
    final fullHtml = _buildMailHtml(content);

    // On appelle la fonction déjà existante qui insère dans Firestore
    await sendMailSimple(
      toEmail: toEmail,
      subject: 'Votre compte Vente Moi',
      htmlBody: fullHtml,
    );
  }

  Future<void> sendPurchaseEmailToBuyer({
    required String buyerEmail,
    required String buyerName,
    required String sellerName,
    required bool isDonation,
    required int couponsCountOrPoints,
    required String? reclamationPassword,
  }) async {
    if (buyerEmail.trim().isEmpty) return;

    // Construisons le message spécifique
    late String subject;
    late String content;

    if (isDonation) {
      // Don
      subject = 'Confirmation de Don - Vente Moi';
      content = '''
      <h1>Confirmation de Don</h1>
      <p>Bonjour $buyerName,</p>
      <p>
        Vous venez de faire un don de <strong>$couponsCountOrPoints point(s)</strong>
        à l'association <strong>$sellerName</strong>.<br>
        Merci pour votre générosité !
      </p>
      <p>À bientôt,<br>L'équipe Vente Moi</p>
    ''';
    } else {
      // Achat de bons
      final codeSection = (reclamationPassword?.isNotEmpty == true)
          ? '<p>Votre code de réclamation est : <strong>$reclamationPassword</strong></p>'
          : '<p>(Aucun code généré)</p>';

      subject = 'Confirmation d\'Achat de Bons - Vente Moi';
      content = '''
      <h1>Confirmation d'Achat</h1>
      <p>Bonjour $buyerName,</p>
      <p>
        Vous avez acheté <strong>$couponsCountOrPoints bon(s)</strong>
        auprès de <strong>$sellerName</strong>.<br>
      </p>
      $codeSection
      <p>Conservez bien ce code pour récupérer vos bons.</p>
      <p>À bientôt,<br>L'équipe Vente Moi</p>
    ''';
    }

    final fullHtml = _buildMailHtml(content);
    await sendMailSimple(
      toEmail: buyerEmail,
      subject: subject,
      htmlBody: fullHtml,
    );
  }

  /// Envoie un mail de notification de don/achat au Seller (association ou boutique).
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
      // Le buyer a fait un DON à l'association
      subject = 'Notification de Don - Vente Moi';
      content = '''
      <h1>Notification de Don</h1>
      <p>Bonjour $sellerName,</p>
      <p>
        Vous venez de recevoir un don de <strong>$couponsCountOrPoints point(s)</strong>
        de la part de <strong>$buyerName</strong>.<br>
      </p>
      <p>Félicitations et merci de votre engagement,<br>L'équipe Vente Moi</p>
    ''';
    } else {
      // Achat de bons
      subject = 'Notification d\'Achat - Vente Moi';
      content = '''
      <h1>Notification d'Achat de Bons</h1>
      <p>Bonjour $sellerName,</p>
      <p>
        <strong>$buyerName</strong> vient d'acheter <strong>$couponsCountOrPoints bon(s)</strong>
        auprès de votre boutique.<br>
      </p>
      <p>Merci de préparer ces bons,<br>L'équipe Vente Moi</p>
    ''';
    }

    final fullHtml = _buildMailHtml(content);
    await sendMailSimple(
      toEmail: sellerEmail,
      subject: subject,
      htmlBody: fullHtml,
    );
  }

  Future<void> sendLowCouponsEmailToSeller({
    required String sellerEmail,
    required String sellerName,
    required int couponsRemaining,
  }) async {
    if (sellerEmail.trim().isEmpty) return;

    final subject = 'Alerte: Stock de bons faible';
    final content = '''
    <h1>Stock de bons en baisse</h1>
    <p>Bonjour $sellerName,</p>
    <p>
      Il ne vous reste plus que <strong>$couponsRemaining bon(s)</strong>
      disponible(s) sur votre compte Vente Moi.<br>
      Pensez à en reprendre si nécessaire, via votre profil boutique.
    </p>
    <p>À très bientôt,<br>L'équipe Vente Moi</p>
  ''';

    final fullHtml = _buildMailHtml(content);

    await sendMailSimple(
      toEmail: sellerEmail,
      subject: subject,
      htmlBody: fullHtml,
    );
  }

  Future<void> sendProAttributionMailToAdmins({
    required String proEmail,
    required double montant,
    required int points,
    required double commissionPercent,
    required int commissionCost,
  }) async {
    // 1) Fetch all admins
    final adminDocs = await getAllAdmins();
    if (adminDocs.isEmpty) return;

    // 2) Build the subject + HTML content
    final subject = 'Nouvelle Attribution de Points (Entreprise)';
    final content = '''
    <h1>Nouvelle attribution de points</h1>
    <p>
      Bonjour Admin,<br><br>
      L'entreprise <strong>$proEmail</strong> vient d'attribuer <strong>$points points</strong>
      à un utilisateur (montant: <strong>$montant €</strong>).<br><br>
      Commission appliquée : <strong>$commissionPercent&nbsp;%</strong><br>
      Montant de la commission : <strong>$commissionCost €</strong> (approx.)<br><br>
      Merci de vérifier si nécessaire dans le back-office.<br>
      <em>Message automatique de Vente Moi.</em>
    </p>
  ''';

    final fullHtml = _buildMailHtml(content);

    // 3) Send to each admin
    for (final doc in adminDocs) {
      final adminData = doc.data();
      final adminEmail = (adminData['email'] ?? '').toString().trim();
      if (adminEmail.isNotEmpty) {
        await sendMailSimple(
          toEmail: adminEmail,
          subject: subject,
          htmlBody: fullHtml,
        );
      }
    }
  }

  Future<void> sendEnterpriseBuyCouponsRequestEmailToAdmins({
    required String enterpriseEmail,
    required String enterpriseName,
    required int couponsCount,
  }) async {
    try {
      // 1) Fetch all admins
      final adminDocs = await getAllAdmins(); // existing in your Mixin
      if (adminDocs.isEmpty) return;

      // 2) Prepare subject & HTML
      final subject = 'Demande d\'Achat de Bons – Vente Moi';
      final content = '''
        <h1>Nouvelle demande d'achat de bons</h1>
        <p>
          L'entreprise <strong>$enterpriseName</strong> ($enterpriseEmail)
          vient de demander <strong>$couponsCount</strong> bon(s).<br/><br/>
          Merci de vérifier cette demande dans l'interface d'administration.
        </p>
        <p>– Message automatique de Vente Moi</p>
      ''';

      final fullHtml =
          _buildMailHtml(content); // uses your existing HTML wrapper

      // 3) Send mail to each admin
      for (final doc in adminDocs) {
        final adminData = doc.data();
        final adminEmail = (adminData['email'] ?? '').toString().trim();
        if (adminEmail.isNotEmpty) {
          await sendMailSimple(
            toEmail: adminEmail,
            subject: subject,
            htmlBody: fullHtml,
          );
        }
      }
    } catch (err) {
      debugPrint('Error notifying admins about coupon request: $err');
    }
  }

  Future<void> sendSponsorshipMailAboutEnterprise({
    required String sponsorName,
    required String sponsorEmail,
    required String userEmail,
  }) async {
    try {
      final subject = 'Parrainage : +50 points';
      final content = '''
        <h1>Félicitations $sponsorName !</h1>
        <p>
          Vous venez de gagner <strong>50 points</strong>
          grâce au parrainage de <strong>$userEmail</strong>.<br>
          Merci d'utiliser Vente Moi !
        </p>
        <p>À très bientôt,<br>L'équipe Vente Moi</p>
      ''';
      final html = _buildMailHtml(content);

      await sendMailSimple(
        toEmail: sponsorEmail,
        subject: subject,
        htmlBody: html,
      );
    } catch (err) {
      debugPrint('Error notifying admins about coupon request: $err');
    }
  }

  Future<void> sendSponsorshipMailForAttribution({
    required String sponsorName,
    required String sponsorEmail,
    required String filleulEmail,
    required int pointsWon,
  }) async {
    final subject = 'Parrainage : +$pointsWon points';
    final content = '''
    <h1>Félicitations $sponsorName !</h1>
    <p>
      Vous venez de gagner <strong>$pointsWon points</strong>
      grâce au parrainage de <strong>$filleulEmail</strong>.<br>
      Merci d'utiliser Vente Moi !
    </p>
    <p>À très bientôt,<br>L'équipe Vente Moi</p>
  ''';

    final html = _buildMailHtml(content);
    await sendMailSimple(
      toEmail: sponsorEmail,
      subject: subject,
      htmlBody: html,
    );
  }

  /// NOUVEAU : Envoie un email d'invitation avec des points en attente
  Future<void> sendPointsInvitationEmail({
    required String recipientEmail,
    required int points,
    required String invitationToken,
  }) async {
    try {
      // URL de votre application avec le token d'invitation
      final appUrl =
          'https://app.ventemoi.fr/register?token=$invitationToken&email=${Uri.encodeComponent(recipientEmail)}';

      // Construire le contenu de l'email avec le template moderne de email_templates.dart
      final content = '''
        <h2>🎉 Vous avez reçu des points !</h2>
        <p>
          Bonne nouvelle ! Vous avez reçu <strong style="color: #ff7a00; font-size: 24px;">$points points</strong>
          sur notre plateforme VenteMoi.
        </p>

        <div class="highlight-box">
          <h3>Vos points vous attendent</h3>
          <div class="info-value" style="font-size: 48px; color: #ff7a00; margin: 20px 0;">
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

        <div style="background: #e8f4fd; padding: 20px; border-radius: 8px; margin-top: 30px;">
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
          <a href="$appUrl" style="color: #ff7a00; word-break: break-all;">$appUrl</a>
        </p>
      ''';

      // Utiliser buildModernMailHtml de email_templates.dart pour avoir le template moderne
      final fullHtml = buildModernMailHtml(content);

      await sendMailSimple(
        toEmail: recipientEmail,
        subject: '🎉 Vous avez reçu $points points sur VenteMoi !',
        htmlBody: fullHtml,
      );
    } catch (e) {
      print('Erreur envoi email invitation: $e');
      rethrow;
    }
  }

//#endregion MAIL
}
