import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllAdmins() async {
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
    final snapUser = await UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).get();

    if (!snapUser.exists) return '';
    final userData = snapUser.data()!;
    final userTypeId = userData['user_type_id'] ?? '';
    if (userTypeId.isEmpty) return '';

    final snapType = await UniquesControllers().data.firebaseFirestore.collection('user_types').doc(userTypeId).get();

    if (!snapType.exists) return '';
    final typeData = snapType.data()!;
    final typeName = typeData['name'] ?? '';
    return typeName.toString();
  }

  Stream<List<UserType>> getUserTypesStream() {
    return UniquesControllers().data.firebaseFirestore.collection('user_types').snapshots().map((query) {
      var filteredDocs = query.docs.toList();
      filteredDocs.sort((a, b) => a.data()['index'].compareTo(b.data()['index']));
      return filteredDocs.map((doc) => UserType.fromDocument(doc)).toList();
    });
  }

  Stream<List<UserType>> getUserTypesStreamExceptAdmin() {
    return UniquesControllers().data.firebaseFirestore.collection('user_types').snapshots().map((query) {
      var docs = query.docs.toList();
      docs.sort((a, b) => (a.data()['index'] as int).compareTo((b.data()['index'] as int)));
      docs = docs.where((doc) => (doc.data()['index'] as int) != 0).toList();
      return docs.map((doc) => UserType.fromDocument(doc)).toList();
    });
  }

  Future<String> getUserTypeNameByUserId(String userId) async {
    final snap = await UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).get();
    final userTypeId = snap.data()?['user_type_id'] ?? '';
    final typeSnap = await UniquesControllers().data.firebaseFirestore.collection('user_types').doc(userTypeId).get();
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
        .where('user_id', isEqualTo: UniquesControllers().data.firebaseAuth.currentUser?.uid)
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
    return UniquesControllers().data.firebaseFirestore.collection('categories').snapshots().map((query) {
      final docs = query.docs.toList();
      docs.sort((a, b) => (a.data()['index'] as int).compareTo((b.data()['index'] as int)));
      return docs.map((doc) => EstablishmentCategory.fromDocument(doc)).toList();
    });
  }

  getCategoryById(String id) async {
    final snap = await UniquesControllers().data.firebaseFirestore.collection('categories').doc(id).get();
    return EstablishmentCategory.fromDocument(snap);
  }

  Future<String> getCategoryNameById(String id) async {
    final snap = await UniquesControllers().data.firebaseFirestore.collection('categories').doc(id).get();
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
      await UniquesControllers().data.firebaseFirestore.collection('wallets').doc(docId).update({'points': newPoints});
    }
  }

  //#endregion

  //#region ALERT DIALOG

  int alertDialogAnimationDuration = 400;

  void variablesToResetToAlertDialog() {}

  actionAlertDialog() async {}

  Widget alertDialogContent() {
    return const SizedBox();
  }

  void openAlertDialog(String title, {String? confirmText, Color? confirmColor}) {
    variablesToResetToAlertDialog();

    Get.dialog(
      CustomAnimation(
        duration: Duration(milliseconds: alertDialogAnimationDuration),
        curve: Curves.easeInOutBack,
        isOpacity: true,
        yStartPosition: alertDialogAnimationDuration / 10,
        child: AlertDialog(
          title: Text(title),
          content: alertDialogContent(),
          actions: [
            CustomTextButton(
              tag: 'alert-dialog-back-button',
              text: 'Annuler',
              color: CustomTheme.lightScheme().onPrimary,
              onPressed: () {
                Get.back();
              },
            ),
            CustomTextButton(
              tag: 'alert-dialog-confirm-button',
              text: confirmText ?? 'Confirmer',
              color: confirmColor,
              onPressed: () async {
                Get.back();
                await actionAlertDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  //#endregion

  //#region BOTTOM SHEET

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
  }) {
    if (doReset) variablesToResetToBottomSheet();

    Get.bottomSheet(
      SingleChildScrollView(
        child: Container(
          transform: Matrix4.translationValues(
            0,
            -UniquesControllers().data.baseSpace * 2,
            0,
          ),
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
          ),
          decoration: BoxDecoration(
            //color: CustomColors.seasalt,
            color: CustomTheme.lightScheme().surface,
            borderRadius: BorderRadius.all(
              Radius.circular(UniquesControllers().data.baseSpace * 2),
              //topRight: Radius.circular(UniquesControllers().data.baseSpace * 2),
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  const CustomSpace(heightMultiplier: 2.4),
                  Center(
                    child: Text(
                      title.toUpperCase(),
                      style: UniquesControllers().data.titleTextStyle,
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2.4),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: UniquesControllers().data.baseSpace * 4,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bottomSheetChildren().length,
                      itemBuilder: (context, index) {
                        return bottomSheetChildren()[index];
                      },
                      separatorBuilder: (context, index) {
                        return const CustomSpace(heightMultiplier: 2);
                      },
                    ),
                  ),
                  const CustomSpace(heightMultiplier: 2),
                  Visibility(
                    visible: hasAction ?? true,
                    child: CustomFABButton(
                      tag: 'action-bottom-sheet-button',
                      text: actionName == null ? '' : actionName.toUpperCase(),
                      iconData: actionIcon,
                      onPressed: () async {
                        await actionBottomSheet();
                      },
                    ),
                  ),
                  Visibility(
                    visible: hasAction ?? true,
                    child: const CustomSpace(heightMultiplier: 4),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: UniquesControllers().data.baseSpace,
                    left: UniquesControllers().data.baseSpace,
                  ),
                  child: CustomIconButton(
                    tag: 'bottom-sheet-back-button',
                    iconData: Icons.arrow_back_rounded,
                    //iconColor: CustomColors.caribbeanCurrent,
                    //backgroundColor: CustomColors.seasalt,
                    onPressed: () {
                      UniquesControllers().data.back();
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Visibility(
                  visible: hasDeleteButton ?? false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: UniquesControllers().data.baseSpace,
                      right: UniquesControllers().data.baseSpace,
                    ),
                    child: CustomIconButton(
                      tag: 'bottom-sheet-delete-button',
                      iconData: Icons.delete_rounded,
                      //iconColor: CustomColors.caribbeanCurrent,
                      onPressed: deleteBottomSheet,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
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

    await UniquesControllers().data.firebaseFirestore.collection('mail').add(mailDoc);
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
        L’équipe de Vente Moi
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
        à l’association <strong>$sellerName</strong>.<br>
        Merci pour votre générosité !
      </p>
      <p>À bientôt,<br>L’équipe Vente Moi</p>
    ''';
    } else {
      // Achat de bons
      final codeSection = (reclamationPassword?.isNotEmpty == true)
          ? '<p>Votre code de réclamation est : <strong>$reclamationPassword</strong></p>'
          : '<p>(Aucun code généré)</p>';

      subject = 'Confirmation d’Achat de Bons - Vente Moi';
      content = '''
      <h1>Confirmation d’Achat</h1>
      <p>Bonjour $buyerName,</p>
      <p>
        Vous avez acheté <strong>$couponsCountOrPoints bon(s)</strong> 
        auprès de <strong>$sellerName</strong>.<br>
      </p>
      $codeSection
      <p>Conservez bien ce code pour récupérer vos bons.</p>
      <p>À bientôt,<br>L’équipe Vente Moi</p>
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
      <p>Félicitations et merci de votre engagement,<br>L’équipe Vente Moi</p>
    ''';
    } else {
      // Achat de bons
      subject = 'Notification d’Achat - Vente Moi';
      content = '''
      <h1>Notification d’Achat de Bons</h1>
      <p>Bonjour $sellerName,</p>
      <p>
        <strong>$buyerName</strong> vient d’acheter <strong>$couponsCountOrPoints bon(s)</strong>
        auprès de votre boutique.<br>
      </p>
      <p>Merci de préparer ces bons,<br>L’équipe Vente Moi</p>
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
    <p>À très bientôt,<br>L’équipe Vente Moi</p>
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
      L’entreprise <strong>$proEmail</strong> vient d’attribuer <strong>$points points</strong>
      à un utilisateur (montant: <strong>$montant €</strong>).<br><br>
      Commission appliquée : <strong>$commissionPercent&nbsp;%</strong><br>
      Montant de la commission : <strong>$commissionCost €</strong> (approx.)<br><br>
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
      final subject = 'Demande d’Achat de Bons – Vente Moi';
      final content = '''
        <h1>Nouvelle demande d’achat de bons</h1>
        <p>
          L’entreprise <strong>$enterpriseName</strong> ($enterpriseEmail) 
          vient de demander <strong>$couponsCount</strong> bon(s).<br/><br/>
          Merci de vérifier cette demande dans l’interface d’administration.
        </p>
        <p>– Message automatique de Vente Moi</p>
      ''';

      final fullHtml = _buildMailHtml(content); // uses your existing HTML wrapper

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
          Merci d’utiliser Vente Moi !
        </p>
        <p>À très bientôt,<br>L’équipe Vente Moi</p>
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
      Merci d’utiliser Vente Moi !
    </p>
    <p>À très bientôt,<br>L’équipe Vente Moi</p>
  ''';

    final html = _buildMailHtml(content);
    await sendMailSimple(
      toEmail: sponsorEmail,
      subject: subject,
      htmlBody: html,
    );
  }

//#endregion MAIL
}
