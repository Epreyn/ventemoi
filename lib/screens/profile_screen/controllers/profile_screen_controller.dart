import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart'; // ajustez selon vos imports
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';

class ProfileScreenController extends GetxController with ControllerMixin {
  // ------------------------------------------------
  // Champs / Contrôleurs de formulaire
  // ------------------------------------------------
  String customBottomAppBarTag = 'profile-bottom-app-bar';
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  // Pour un Particulier => adresse perso
  final personalAddressController = TextEditingController();

  final RxDouble personalLat = 0.0.obs;
  final RxDouble personalLng = 0.0.obs;

  final couponsController = TextEditingController();
  final holderController = TextEditingController();
  final ibanController = TextEditingController();
  final bicController = TextEditingController();

  // SliderValue pour l’achat de bons (1..12)
  RxInt sliderValue = 1.obs;

  // Id du doc 'wallet' si besoin
  String? currentWalletDocId;
  // Id d’établissement (si besoin, ex: pour user de type Boutique)
  String? userEstablishmentId;

  // ---------------------------
  // Lifecycle
  // ---------------------------
  @override
  void onInit() {
    super.onInit();
    _fetchWalletDocId();
    _fetchUserEstablishmentId();
  }

  // ---------------------------
  // Récupération docId wallet (si besoin)
  // ---------------------------
  Future<void> _fetchWalletDocId() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      currentWalletDocId = snap.docs.first.id;
    }
  }

  // ---------------------------
  // Récupération docId establishment (si besoin pour boutique)
  // ---------------------------
  Future<void> _fetchUserEstablishmentId() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    final estDoc = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();
    if (estDoc.docs.isNotEmpty) {
      userEstablishmentId = estDoc.docs.first.id;
    }
  }

  // ---------------------------
  // Récupération du doc user en stream
  // => Pour remplir name, email, personal_address
  // ---------------------------
  Stream<Map<String, dynamic>?> getUserDocStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((docSnap) => docSnap.data());
  }

  // ---------------------------
  // Récupération doc wallet en stream
  // => Pour remplir coupons, bank details
  // ---------------------------
  Stream<Map<String, dynamic>?> getWalletDocStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((querySnap) {
      if (querySnap.docs.isEmpty) return null;
      return querySnap.docs.first.data();
    });
  }

  // ---------------------------
  // Mise à jour des TextEditingController
  // ---------------------------
  void updateControllers(Map<String, dynamic>? userData) {
    if (userData == null) return;
    nameController.text = userData['name'] ?? '';
    emailController.text = userData['email'] ?? '';
    // Particulier => personal_address
    personalAddressController.text = userData['personal_address'] ?? '';

    // Pour l’image de profil
    UniquesControllers().data.oldImageUrl.value = userData['image_url'] ?? '';
  }

  // ---------------------------
  // getUserTypeNameByUserId => pour détecter "Particulier", "Boutique", etc.
  // ---------------------------
  Future<String> getUserTypeNameByUserId(String userId) async {
    final userSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();
    if (!userSnap.exists) return '';
    final userData = userSnap.data()!;
    final userTypeId = userData['user_type_id'] ?? '';

    if (userTypeId.isEmpty) return '';
    final typeSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .doc(userTypeId)
        .get();
    if (!typeSnap.exists) return '';
    final tData = typeSnap.data()!;
    return tData['name'] ?? '';
  }

  // ---------------------------
  // Action principale => enregistrement
  // ---------------------------
  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    try {
      UniquesControllers().data.isInAsyncCall.value = true;
      final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (uid == null) {
        UniquesControllers().data.isInAsyncCall.value = false;
        return;
      }

      // Upload image s’il y en a une
      String newImageUrl = UniquesControllers().data.oldImageUrl.value;
      if (UniquesControllers().data.isPickedFile.value) {
        newImageUrl = await _uploadProfileImageIfNeeded(uid);
      }

      // Détecter si Particulier => on stocke personal_address
      final userTypeName = await getUserTypeNameByUserId(uid);

      final Map<String, dynamic> userUpdateMap = {
        'name': nameController.text.trim(),
        'image_url': newImageUrl,
      };
      if (userTypeName == 'Particulier') {
        userUpdateMap['personal_address'] =
            personalAddressController.text.trim();
      }
      // Mise à jour user
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .update(userUpdateMap);

      // Mise à jour wallet
      await updateWallet();

      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.isPickedFile.value = false;
      UniquesControllers().data.snackbar('Succès', 'Profil mis à jour', false);
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }

  // ---------------------------
  // Facteur => upload image local / web
  // ---------------------------
  Future<String> _uploadProfileImageIfNeeded(String uid) async {
    String url = UniquesControllers().data.oldImageUrl.value;
    if (UniquesControllers().data.profileImageFile.value != null) {
      final file = UniquesControllers().data.profileImageFile.value!;
      url = await uploadProfileImage(file, uid);
    } else if (UniquesControllers().data.profileImageBytes.value != null) {
      final bytes = UniquesControllers().data.profileImageBytes.value!;
      url =
          await uploadProfileImageWeb(bytes, 'profile_${bytes.hashCode}', uid);
    }
    return url;
  }

  Future<String> uploadProfileImage(File file, String uid) async {
    String url = '';
    try {
      final fileName = p.basename(file.path);
      final ref = UniquesControllers()
          .data
          .firebaseStorage
          .ref('avatars/$uid/$fileName');
      final task = ref.putFile(file);
      await task.whenComplete(() async {
        url = await ref.getDownloadURL();
      });
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur image', e.toString(), true);
    }
    return url;
  }

  Future<String> uploadProfileImageWeb(
      Uint8List bytes, String fileName, String uid) async {
    String url = '';
    try {
      final ref = UniquesControllers()
          .data
          .firebaseStorage
          .ref('avatars/$uid/$fileName');
      final task = ref.putData(bytes);
      await task.whenComplete(() async {
        url = await ref.getDownloadURL();
      });
    } catch (e) {
      UniquesControllers()
          .data
          .snackbar('Erreur image (web)', e.toString(), true);
    }
    return url;
  }

  // ---------------------------
  // Mise à jour du wallet => IBAN/BIC
  // ---------------------------
  Future<void> updateWallet() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();

    final bankMap = {
      'holder': holderController.text.trim(),
      'iban': ibanController.text.trim(),
      'bic': bicController.text.trim(),
    };

    if (snap.docs.isEmpty) {
      // Création wallet si inexistant
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': uid,
        'coupons': 0,
        'points': 0,
        'bank_details': bankMap,
      });
    } else {
      final docRef = snap.docs.first.reference;
      await docRef.update({'bank_details': bankMap});
    }
  }

  // ---------------------------
  // Achat de bons => slider 1..12 => doc points_requests
  // ---------------------------
  void buyCoupons() {
    sliderValue.value = 1;
    openBottomSheet(
      'Acheter des bons',
      hasAction: true,
      actionName: 'Acheter',
      actionIcon: Icons.check,
      doReset: true,
    );
  }

  @override
  void variablesToResetToBottomSheet() {
    sliderValue.value = 1;
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      const Text('Sélectionnez le nombre de bons à acheter (1 à 12) :'),
      const CustomSpace(heightMultiplier: 2),
      Obx(() {
        return Column(
          children: [
            Slider(
              value: sliderValue.value.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '${sliderValue.value}',
              onChanged: (val) {
                sliderValue.value = val.round();
              },
            ),
            Text(
              'Nombre de bons : ${sliderValue.value}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }),
    ];
  }

  @override
  Future<void> actionBottomSheet() async {
    Get.back();
    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (uid == null) {
        UniquesControllers().data.isInAsyncCall.value = false;
        return;
      }
      final nb = sliderValue.value;
      if (nb < 1) {
        UniquesControllers().data.isInAsyncCall.value = false;
        UniquesControllers()
            .data
            .snackbar('Erreur', 'Valeur de bons invalide', true);
        return;
      }

      // 1) Create the points_requests doc
      final pointsRequestsRef = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('points_requests')
          .doc();
      await pointsRequestsRef.set({
        'user_id': uid,
        'wallet_id': currentWalletDocId ?? '',
        'establishment_id': userEstablishmentId ?? '',
        'coupons_count': nb,
        'isValidated': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2) Fetch user doc (the "enterprise" user) to get name & email
      final userSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();
      if (!userSnap.exists) {
        // If there's no doc, you may want to skip emailing
        UniquesControllers().data.snackbar(
              'Info',
              'Impossible de trouver le document user. Pas d\'email pour la notification.',
              true,
            );
      } else {
        final userData = userSnap.data()!;
        final enterpriseEmail = (userData['email'] ?? '').toString().trim();
        final enterpriseName = (userData['name'] ?? '').toString().trim();

        // 3) Notify admins by email
        await sendEnterpriseBuyCouponsRequestEmailToAdmins(
          enterpriseEmail: enterpriseEmail,
          enterpriseName: enterpriseName,
          couponsCount: nb,
        );
      }

      UniquesControllers().data.snackbar(
            'Demande envoyée',
            'Votre demande d’achat de $nb bon(s) a bien été créée.',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ---------------------------
  // Suppression compte
  // ---------------------------
  Future<void> deleteAccount() async {
    openAlertDialog(
      'Supprimer le compte',
      confirmText: 'Supprimer',
      confirmColor: CustomTheme.lightScheme().error,
    );
  }

  @override
  Widget alertDialogContent() {
    return const Text('Êtes-vous sûr de vouloir supprimer votre compte ?');
  }

  @override
  Future<void> actionAlertDialog() async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;
      final user = UniquesControllers().data.firebaseAuth.currentUser;
      if (user == null) return;
      final uid = user.uid;

      // 1) Supprime le doc 'users/{uid}'
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .delete();

      // 2) Supprime le(s) doc(s) 'wallets' qui référencent user_id=uid
      final snap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .where('user_id', isEqualTo: uid)
          .get();

      for (var d in snap.docs) {
        await d.reference.delete();
      }

      // 3) Supprime le compte authentifié
      await user.delete();

      UniquesControllers().data.isInAsyncCall.value = false;

      UniquesControllers().data.snackbar(
          'Compte supprimé', 'Votre compte a été supprimé avec succès.', false);

      // 4) Redirection (ex: vers l’écran de login)
      Get.offAllNamed(Routes.login);
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }

  // ---------------------------
  // FAB => Enregistrer modifications
  // ---------------------------
  late Widget saveFloatingActionButton = CustomCardAnimation(
    index: UniquesControllers().data.dynamicIconList.length,
    child: FloatingActionButton.extended(
      onPressed: updateProfile,
      icon: const Icon(Icons.save),
      label: const Text('Enregistrer les modifications'),
    ),
  );
}
