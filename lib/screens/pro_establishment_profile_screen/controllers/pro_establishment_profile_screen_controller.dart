import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../core/models/establishment_category.dart';
import '../../../core/models/user_type.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';

class ProEstablishmentProfileScreenController extends GetxController with ControllerMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String customBottomAppBarTag = 'pro-establishment-form-bottom-app-bar';
  double maxFormWidth = 350.0;

  // Champs du formulaire
  final nameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  // Nouveau : champ vidéo
  final videoCtrl = TextEditingController();
  String videoTag = 'video_custom_text_field';
  String videoLabel = 'Lien Vidéo (YouTube, etc.)';

  // Infos sur la description
  String nameTag = 'name_custom_text_field';
  String nameLabel = 'Nom de l\'établissement';

  String descriptionTag = 'description_custom_text_field';
  String descriptionLabel = 'Description';
  int descriptionMaxCharacters = 300;
  int descriptionMinLines = 2;
  int descriptionMaxLines = 5;

  String addressTag = 'address_custom_text_field';
  String addressLabel = 'Adresse';

  String emailTag = 'email_custom_text_field';
  String emailLabel = 'Email';

  String phoneTag = 'phone_custom_text_field';
  String phoneLabel = 'Téléphone';

  // Catégorie unique
  String categoryTag = 'category_custom_text_field';
  String categoryLabel = 'Catégorie';
  double categoryMaxWidth = 350.0;
  double categoryMaxHeight = 50.0;
  Rx<EstablishmentCategory?> currentCategory = Rx<EstablishmentCategory?>(null);

  // Catégories multiples (si userType == 'Entreprise')
  RxList<String> enterpriseCatsIds = <String>[].obs;
  final int maxEnterpriseCats = 2;

  // Bannière / Logo
  RxString bannerUrl = ''.obs;
  RxBool isPickedBanner = false.obs;
  Rx<File?> bannerFile = Rx<File?>(null);
  Rx<Uint8List?> bannerBytes = Rx<Uint8List?>(null);

  RxString logoUrl = ''.obs;
  RxBool isPickedLogo = false.obs;
  Rx<File?> logoFile = Rx<File?>(null);
  Rx<Uint8List?> logoBytes = Rx<Uint8List?>(null);

  // ID doc de l'établissement
  String? establishmentDocId;

  // // Détection du userType => si 'Entreprise', on active le multi-cat
  // Rx<UserType?> currentUserType = Rx<UserType?>(null);

  // Booléen : a-t-il accepté le contrat ?
  RxBool hasAcceptedContract = false.obs;

  // Case à cocher dans l'AlertDialog
  RxBool checkAccepted = false.obs;

  @override
  void onInit() {
    super.onInit();

    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid != null) {
      _loadUserType(uid);
    }
  }

  // ------------------------------------------------
  // Charger le userType => 'Entreprise' / 'Association' / etc.
  // ------------------------------------------------
  Future<void> _loadUserType(String uid) async {
    final userType = await getUserTypeByUserId(uid);
    currentUserType.value = userType;
  }

  // ------------------------------------------------
  // Streams
  // ------------------------------------------------
  Stream<Map<String, dynamic>?> getEstablishmentDocStream() {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      establishmentDocId = snap.docs.first.id;
      final data = snap.docs.first.data();

      // Lire le booléen "has_accepted_contract"
      final bool accepted = data['has_accepted_contract'] ?? false;
      hasAcceptedContract.value = accepted;

      return data;
    });
  }

  Stream<List<EstablishmentCategory>> getCategoriesStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .snapshots()
        .map((q) => q.docs.map((d) => EstablishmentCategory.fromDocument(d)).toList());
  }

  Stream<List<EnterpriseCategory>> getEnterpriseCategoriesStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .snapshots()
        .map((q) => q.docs.map((d) => EnterpriseCategory.fromDocument(d)).toList());
  }

  Future<EstablishmentCategory?> getCategoryById(String catId) async {
    if (catId.isEmpty) return null;
    final snap = await UniquesControllers().data.firebaseFirestore.collection('categories').doc(catId).get();
    if (!snap.exists) return null;
    return EstablishmentCategory.fromDocument(snap);
  }

  Future<UserType?> getUserTypeByUserId(String userId) async {
    final snapUser = await UniquesControllers().data.firebaseFirestore.collection('users').doc(userId).get();
    if (!snapUser.exists) return null;
    final userData = snapUser.data()!;
    final userTypeId = userData['user_type_id'] ?? '';
    if (userTypeId.isEmpty) return null;

    final snapType = await UniquesControllers().data.firebaseFirestore.collection('user_types').doc(userTypeId).get();
    if (!snapType.exists) return null;
    return UserType.fromDocument(snapType);
  }

  // ------------------------------------------------
  // Pick banner / logo
  // ------------------------------------------------
  Future<void> pickBanner() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;

    isPickedBanner.value = true;

    if (!kIsWeb && picked.path != null) {
      bannerFile.value = File(picked.path!);
      bannerBytes.value = null;
    } else if (kIsWeb && picked.bytes != null) {
      bannerFile.value = null;
      bannerBytes.value = picked.bytes;
    }
  }

  Future<void> pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;

    isPickedLogo.value = true;

    if (!kIsWeb && picked.path != null) {
      logoFile.value = File(picked.path!);
      logoBytes.value = null;
    } else if (kIsWeb && picked.bytes != null) {
      logoFile.value = null;
      logoBytes.value = picked.bytes;
    }
  }

  // ------------------------------------------------
  // Enregistrement
  // ------------------------------------------------
  Future<void> saveEstablishmentProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (hasAcceptedContract.value == false) {
      openAlertDialog(
        'Conditions Générales',
        confirmText: 'Valider',
      );
      return;
    }

    await _saveProfileToFirestore();
  }

  Future<void> _saveProfileToFirestore() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      establishmentDocId ??= await _createEstablishmentDocIfNeeded(uid);

      // 1) On lit l’ancienne valeur "has_accepted_contract" (avant update)
      bool oldHasAccepted = false;
      if (establishmentDocId != null) {
        final oldDocSnap = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(establishmentDocId)
            .get();
        if (oldDocSnap.exists) {
          final oldData = oldDocSnap.data() ?? {};
          oldHasAccepted = oldData['has_accepted_contract'] ?? false;
        }
      }

      // 2) Préparer le nouveau banner/logo
      final newBannerUrl = await _handleBannerUpload(uid);
      final newLogoUrl = await _handleLogoUpload(uid);

      // 3) Récupérer le userType => pour "Entreprise", on set enterprise_categories
      final userType = currentUserType.value;

      final dataToUpdate = {
        'name': nameCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'telephone': phoneCtrl.text.trim(),
        'banner_url': newBannerUrl,
        'logo_url': newLogoUrl,
        'video_url': videoCtrl.text.trim(),
        'category_id': currentCategory.value?.id ?? '',
        'enterprise_categories': [],
        // Contrat accepté => toujours `true` si l’utilisateur a coché la case
        'has_accepted_contract': true,
      };

      if (userType != null && userType.name == 'Entreprise') {
        dataToUpdate['enterprise_categories'] = enterpriseCatsIds.toList();
      }

      // 4) On met à jour l’établissement
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(establishmentDocId)
          .update(dataToUpdate);

      // 5) Si l’ancien doc avait has_accepted_contract = false
      //    et maintenant c’est true => on applique la récompense.
      if (!oldHasAccepted) {
        // => c’est la 1ère fois qu’il accepte le contrat => on regarde le parrainage
        await _handleSponsorshipRewardIfAny(uid, emailCtrl.text.trim());
      }

      // Reset
      isPickedBanner.value = false;
      isPickedLogo.value = false;

      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Succès', 'Fiche mise à jour avec succès', false);
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }

  Future<void> _handleSponsorshipRewardIfAny(String uid, String userEmail) async {
    if (userEmail.isEmpty) return;

    // 1) Chercher s’il existe un doc "sponsorship" qui contient userEmail
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('sponsorships')
        .where('sponsoredEmails', arrayContains: userEmail.toLowerCase())
        .get();

    if (snap.docs.isEmpty) {
      return;
    }

    // Supposez qu’il n’y ait qu’un seul parrain => on prend le premier doc
    final sponsorshipDoc = snap.docs.first;
    final sponsorData = sponsorshipDoc.data();
    final sponsorUid = sponsorData['user_id'] ?? '';
    if (sponsorUid.isEmpty) {
      return;
    }

    // 2) +50 points dans le wallet du sponsor
    final sponsorWalletSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: sponsorUid)
        .limit(1)
        .get();

    if (sponsorWalletSnap.docs.isEmpty) {
      // Créer un wallet si besoin
      await UniquesControllers().data.firebaseFirestore.collection('wallets').doc().set({
        'user_id': sponsorUid,
        'points': 50,
        'coupons': 0,
      });
    } else {
      final walletRef = sponsorWalletSnap.docs.first.reference;
      await walletRef.update({
        'points': FieldValue.increment(50),
      });
    }

    // 3) Envoyer un mail au sponsor => "Félicitations, vous gagnez 50 points"
    final sponsorUserSnap = await UniquesControllers().data.firebaseFirestore.collection('users').doc(sponsorUid).get();

    if (sponsorUserSnap.exists) {
      final sponsorUserData = sponsorUserSnap.data()!;
      final sponsorEmail = (sponsorUserData['email'] ?? '').toString();
      final sponsorName = (sponsorUserData['name'] ?? 'Sponsor').toString();

      if (sponsorEmail.isNotEmpty) {
        await sendSponsorshipMailAboutEnterprise(
            sponsorName: sponsorName, sponsorEmail: sponsorEmail, userEmail: userEmail);
      }
    }
  }

  // ------------------------------------------------
  // AlertDialog d'acceptation
  // ------------------------------------------------
  @override
  void variablesToResetToAlertDialog() {
    checkAccepted.value = false;
  }

  @override
  Widget alertDialogContent() {
    return Obx(() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Merci de lire et accepter nos conditions générales avant de poursuivre :',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: checkAccepted.value,
                onChanged: (val) => checkAccepted.value = val ?? false,
              ),
              const Text('J\'accepte les CGU'),
            ],
          ),
        ],
      );
    });
  }

  @override
  Future<void> actionAlertDialog() async {
    if (!checkAccepted.value) {
      UniquesControllers().data.snackbar('Erreur', 'Vous devez cocher la case pour accepter.', true);
      return;
    }

    await _saveProfileToFirestore();
  }

  // ------------------------------------------------
  // Création doc si inexistant
  // ------------------------------------------------
  Future<String> _createEstablishmentDocIfNeeded(String uid) async {
    if (establishmentDocId != null) return establishmentDocId!;

    final docRef = await UniquesControllers().data.firebaseFirestore.collection('establishments').add({
      'user_id': uid,
      'name': '',
      'description': '',
      'address': '',
      'email': '',
      'telephone': '',
      'banner_url': '',
      'logo_url': '',
      'category_id': '',
      'enterprise_categories': [],
      'video_url': '',
      'has_accepted_contract': false,
    });

    return docRef.id;
  }

  // ------------------------------------------------
  // Upload Bannières / Logos
  // ------------------------------------------------
  Future<String> _handleBannerUpload(String uid) async {
    String newBannerUrl = bannerUrl.value;
    if (isPickedBanner.value) {
      newBannerUrl = await _uploadBanner(uid);
    }
    return newBannerUrl;
  }

  Future<String> _handleLogoUpload(String uid) async {
    String newLogoUrl = logoUrl.value;
    if (isPickedLogo.value) {
      newLogoUrl = await _uploadLogo(uid);
    }
    return newLogoUrl;
  }

  Future<String> _uploadBanner(String uid) async {
    String url = bannerUrl.value;
    try {
      if (bannerFile.value != null) {
        final fileName = p.basename(bannerFile.value!.path);
        final ref = UniquesControllers().data.firebaseStorage.ref('banners/$uid/$fileName');
        final task = ref.putFile(bannerFile.value!);
        await task.whenComplete(() async {
          url = await ref.getDownloadURL();
        });
      } else if (bannerBytes.value != null) {
        final fileName = 'banner_${bannerBytes.hashCode}.png';
        final ref = UniquesControllers().data.firebaseStorage.ref('banners/$uid/$fileName');
        final task = ref.putData(bannerBytes.value!);
        await task.whenComplete(() async {
          url = await ref.getDownloadURL();
        });
      }
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur Bannière', e.toString(), true);
    }
    return url;
  }

  Future<String> _uploadLogo(String uid) async {
    String url = logoUrl.value;
    try {
      if (logoFile.value != null) {
        final fileName = p.basename(logoFile.value!.path);
        final ref = UniquesControllers().data.firebaseStorage.ref('logos/$uid/$fileName');
        final task = ref.putFile(logoFile.value!);
        await task.whenComplete(() async {
          url = await ref.getDownloadURL();
        });
      } else if (logoBytes.value != null) {
        final fileName = 'logo_${logoBytes.hashCode}.png';
        final ref = UniquesControllers().data.firebaseStorage.ref('logos/$uid/$fileName');
        final task = ref.putData(logoBytes.value!);
        await task.whenComplete(() async {
          url = await ref.getDownloadURL();
        });
      }
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur Logo', e.toString(), true);
    }
    return url;
  }

  // ------------------------------------------------
  // Widgets d'affichage (logo / banner)
  // ------------------------------------------------

  Widget buildLogoWidget() {
    if (isPickedLogo.value) {
      // Fichier local
      if (logoFile.value != null) {
        return _buildImageContainer(
          file: logoFile.value,
          size: 15 * UniquesControllers().data.baseSpace,
        );
      }
      // Bytes web
      else if (logoBytes.value != null) {
        return _buildImageContainer(
          bytes: logoBytes.value,
          size: 15 * UniquesControllers().data.baseSpace,
        );
      }
    }
    // Sinon, l'URL existante
    if (logoUrl.value.isNotEmpty) {
      return _buildImageContainer(
        url: logoUrl.value,
        size: 15 * UniquesControllers().data.baseSpace,
      );
    }
    // Sinon "Aucun logo"
    return _buildPlaceholder(
      size: 15 * UniquesControllers().data.baseSpace,
      label: 'Aucun logo',
    );
  }

  Widget buildBannerWidget() {
    if (isPickedBanner.value) {
      if (bannerFile.value != null) {
        return _buildImageContainer(
          file: bannerFile.value,
          size: 22 * UniquesControllers().data.baseSpace,
          isBanner: true,
          maxFormWidth: maxFormWidth,
        );
      } else if (bannerBytes.value != null) {
        return _buildImageContainer(
          bytes: bannerBytes.value,
          size: 22 * UniquesControllers().data.baseSpace,
          isBanner: true,
          maxFormWidth: maxFormWidth,
        );
      }
    }
    if (bannerUrl.value.isNotEmpty) {
      return _buildImageContainer(
        url: bannerUrl.value,
        size: 22 * UniquesControllers().data.baseSpace,
        isBanner: true,
        maxFormWidth: maxFormWidth,
      );
    }
    // Placeholder
    return _buildPlaceholder(
      size: 22 * UniquesControllers().data.baseSpace,
      label: 'Aucune bannière',
      isBanner: true,
      maxFormWidth: maxFormWidth,
    );
  }

  Widget _buildImageContainer({
    File? file,
    Uint8List? bytes,
    String? url,
    required double size,
    bool isBanner = false,
    double? maxFormWidth,
  }) {
    DecorationImage? image;
    if (file != null) {
      image = DecorationImage(image: FileImage(file), fit: BoxFit.cover);
    } else if (bytes != null) {
      image = DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover);
    } else if (url != null && url.isNotEmpty) {
      image = DecorationImage(image: NetworkImage(url), fit: BoxFit.cover);
    }

    if (isBanner && maxFormWidth != null) {
      return Center(
        child: Container(
          height: size,
          width: maxFormWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UniquesControllers().data.baseSpace * 2),
            image: image,
          ),
        ),
      );
    } else {
      return Center(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UniquesControllers().data.baseSpace * 2),
            image: image,
          ),
        ),
      );
    }
  }

  Widget _buildPlaceholder({
    required double size,
    required String label,
    bool isBanner = false,
    double? maxFormWidth,
  }) {
    if (isBanner && maxFormWidth != null) {
      return Center(
        child: Container(
          height: size,
          width: maxFormWidth,
          color: Colors.grey.shade200,
          child: Center(child: Text(label)),
        ),
      );
    }
    return Center(
      child: Container(
        height: size,
        width: size,
        color: Colors.grey.shade200,
        child: Center(child: Text(label)),
      ),
    );
  }

  // ------------------------------------------------
  // FAB
  // ------------------------------------------------
  late Widget saveFloatingActionButton = CustomCardAnimation(
    index: UniquesControllers().data.dynamicIconList.length,
    child: FloatingActionButton.extended(
      onPressed: saveEstablishmentProfile,
      icon: const Icon(Icons.save),
      label: const Text('Enregistrer les modifications'),
    ),
  );
}
