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
import '../widgets/cgu_payment_dialog.dart';

class ProEstablishmentProfileScreenController extends GetxController
    with ControllerMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String customBottomAppBarTag = 'pro-establishment-form-bottom-app-bar';
  double maxFormWidth = 350.0;

  // Champs du formulaire
  final nameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final videoCtrl = TextEditingController();

  // Tags et labels
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

  String videoTag = 'video_custom_text_field';
  String videoLabel = 'Lien Vidéo (YouTube, etc.)';

  // Catégorie unique
  String categoryTag = 'category_custom_text_field';
  String categoryLabel = 'Catégorie';
  double categoryMaxWidth = 350.0;
  double categoryMaxHeight = 50.0;
  Rx<EstablishmentCategory?> currentCategory = Rx<EstablishmentCategory?>(null);

  // Catégories entreprise
  RxList<Rx<EnterpriseCategory?>> selectedEnterpriseCategories =
      <Rx<EnterpriseCategory?>>[].obs;
  RxInt enterpriseCategorySlots = 2.obs;
  final int additionalSlotPrice = 500; // 5€ en centimes

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

  // Détection du userType
  Rx<UserType?> currentUserType = Rx<UserType?>(null);

  // Statuts
  RxBool hasAcceptedContract = false.obs;
  RxBool hasActiveSubscription = false.obs;
  RxString subscriptionStatus = ''.obs;
  Rx<DateTime?> subscriptionEndDate = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();

    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid != null) {
      _loadUserType(uid);
    }
  }

  // ------------------------------------------------
  // Charger le userType
  // ------------------------------------------------
  Future<void> _loadUserType(String uid) async {
    final userType = await getUserTypeByUserId(uid);
    currentUserType.value = userType;
  }

  // ------------------------------------------------
  // Initialiser les dropdowns de catégories
  // ------------------------------------------------
  void _initializeCategoryDropdowns(
      int slots, List<String>? existingCategoryIds) {
    selectedEnterpriseCategories.clear();

    for (int i = 0; i < slots; i++) {
      selectedEnterpriseCategories.add(Rx<EnterpriseCategory?>(null));
    }

    if (existingCategoryIds != null) {
      for (int i = 0; i < existingCategoryIds.length && i < slots; i++) {
        _loadCategoryById(existingCategoryIds[i], i);
      }
    }
  }

  Future<void> _loadCategoryById(String catId, int index) async {
    if (catId.isEmpty) return;
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .doc(catId)
        .get();
    if (snap.exists) {
      final cat = EnterpriseCategory.fromDocument(snap);
      if (index < selectedEnterpriseCategories.length) {
        selectedEnterpriseCategories[index].value = cat;
      }
    }
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

      // Lire les statuts
      final bool accepted = data['has_accepted_contract'] ?? false;
      hasAcceptedContract.value = accepted;

      final bool hasSubscription = data['has_active_subscription'] ?? false;
      hasActiveSubscription.value = hasSubscription;

      subscriptionStatus.value = data['subscription_status'] ?? '';

      final Timestamp? endDate = data['subscription_end_date'];
      subscriptionEndDate.value = endDate?.toDate();

      // Lire le nombre de slots
      final slots = data['enterprise_category_slots'] ?? 2;
      enterpriseCategorySlots.value = slots;

      // Initialiser les dropdowns
      final List<dynamic>? entCats =
          data['enterprise_categories'] as List<dynamic>?;
      final catIds = entCats?.map((e) => e.toString()).toList();
      _initializeCategoryDropdowns(slots, catIds);

      return data;
    });
  }

  Stream<List<EstablishmentCategory>> getCategoriesStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .snapshots()
        .map((q) =>
            q.docs.map((d) => EstablishmentCategory.fromDocument(d)).toList());
  }

  Stream<List<EnterpriseCategory>> getEnterpriseCategoriesStream() {
    return UniquesControllers()
        .data
        .firebaseFirestore
        .collection('enterprise_categories')
        .snapshots()
        .map((q) =>
            q.docs.map((d) => EnterpriseCategory.fromDocument(d)).toList());
  }

  Future<EstablishmentCategory?> getCategoryById(String catId) async {
    if (catId.isEmpty) return null;
    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('categories')
        .doc(catId)
        .get();
    if (!snap.exists) return null;
    return EstablishmentCategory.fromDocument(snap);
  }

  Future<UserType?> getUserTypeByUserId(String userId) async {
    final snapUser = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(userId)
        .get();
    if (!snapUser.exists) return null;
    final userData = snapUser.data()!;
    final userTypeId = userData['user_type_id'] ?? '';
    if (userTypeId.isEmpty) return null;

    final snapType = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('user_types')
        .doc(userTypeId)
        .get();
    if (!snapType.exists) return null;
    return UserType.fromDocument(snapType);
  }

  // ------------------------------------------------
  // Obtenir le prix de l'abonnement
  // ------------------------------------------------
  String getSubscriptionPrice() {
    final userType = currentUserType.value;
    if (userType == null) return '0';

    // Les tarifs sont mensuels après la première année
    switch (userType.name) {
      case 'Boutique':
      case 'Commerçant':
      case 'Entreprise':
        return '50'; // 50€/mois après la 1ère année
      case 'Association':
        return '0'; // Gratuit
      default:
        return '0';
    }
  }

  String getFirstYearPrice() {
    final userType = currentUserType.value;
    if (userType == null) return '0';

    // Prix de la première année (adhésion + cotisation)
    switch (userType.name) {
      case 'Boutique':
      case 'Commerçant':
      case 'Entreprise':
        return '930'; // 450€ adhésion + 40€/mois x 12 = 930€ HT
      case 'Association':
        return '0'; // Gratuit
      default:
        return '0';
    }
  }

  // ------------------------------------------------
  // Pick banner / logo
  // ------------------------------------------------
  Future<void> pickBanner() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);
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
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);
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
  // Ajouter une catégorie (paiement Stripe)
  // ------------------------------------------------
  Future<void> addCategorySlot() async {
    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      // TODO: Intégrer Stripe ici pour le paiement du slot
      await Future.delayed(const Duration(seconds: 2));

      enterpriseCategorySlots.value++;
      selectedEnterpriseCategories.add(Rx<EnterpriseCategory?>(null));

      if (establishmentDocId != null) {
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(establishmentDocId)
            .update({
          'enterprise_category_slots': enterpriseCategorySlots.value,
        });
      }

      UniquesControllers().data.snackbar(
          'Succès', 'Nouveau slot de catégorie ajouté avec succès', false);
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // ------------------------------------------------
  // Obtenir les catégories sélectionnées
  // ------------------------------------------------
  List<String> getSelectedCategoryIds() {
    final ids = <String>[];
    for (final catObs in selectedEnterpriseCategories) {
      final cat = catObs.value;
      if (cat != null) {
        ids.add(cat.id);
      }
    }
    return ids;
  }

  // ------------------------------------------------
  // Enregistrement
  // ------------------------------------------------
  Future<void> saveEstablishmentProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Si pas encore accepté les CGU ou pas d'abonnement actif
    if (!hasAcceptedContract.value || !hasActiveSubscription.value) {
      String? paymentOption;
      await showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) => CGUPaymentDialog(
          userType: currentUserType.value?.name ?? '',
          onConfirm: (String paymentOption) async {
            // Le dialog gère le choix de l'option de paiement en interne
            await _processPaymentAndSave(paymentOption);
          },
        ),
      );
    } else {
      // Si déjà accepté et abonnement actif, sauvegarder directement
      await _saveProfileToFirestore();
    }
  }

  // ------------------------------------------------
  // Traiter le paiement et sauvegarder
  // ------------------------------------------------
  Future<void> _processPaymentAndSave(String paymentOption) async {
    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      // TODO: Intégrer Stripe ici pour le paiement de l'abonnement
      // Utiliser paymentOption ('monthly' ou 'annual') pour déterminer le montant et la fréquence
      await Future.delayed(const Duration(seconds: 2));

      // Mettre à jour les statuts
      hasAcceptedContract.value = true;
      hasActiveSubscription.value = true;
      subscriptionStatus.value = 'active';
      subscriptionEndDate.value =
          DateTime.now().add(const Duration(days: 365)); // 1 an d'engagement

      // Stocker le type de paiement choisi
      // paymentOption sera 'monthly' ou 'annual'

      // Sauvegarder avec les nouveaux statuts
      await _saveProfileToFirestore(
          isFirstActivation: true, paymentOption: paymentOption);
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar(
          'Erreur de paiement', 'Le paiement a échoué : ${e.toString()}', true);
    }
  }

  // ------------------------------------------------
  // Sauvegarder le profil
  // ------------------------------------------------
  Future<void> _saveProfileToFirestore(
      {bool isFirstActivation = false, String? paymentOption}) async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      establishmentDocId ??= await _createEstablishmentDocIfNeeded(uid);

      // Gérer les uploads
      final newBannerUrl = await _handleBannerUpload(uid);
      final newLogoUrl = await _handleLogoUpload(uid);

      // Récupérer le userType
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
        'enterprise_category_slots': enterpriseCategorySlots.value,
        'has_accepted_contract': hasAcceptedContract.value,
        'has_active_subscription': hasActiveSubscription.value,
        'subscription_status': subscriptionStatus.value,
        'subscription_end_date': subscriptionEndDate.value != null
            ? Timestamp.fromDate(subscriptionEndDate.value!)
            : null,
        'is_visible_in_shop':
            hasAcceptedContract.value && hasActiveSubscription.value,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Ajouter l'option de paiement si fournie
      if (paymentOption != null) {
        dataToUpdate['payment_option'] = paymentOption;
      }

      if (userType != null && userType.name == 'Entreprise') {
        dataToUpdate['enterprise_categories'] = getSelectedCategoryIds();
      }

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(establishmentDocId)
          .update(dataToUpdate);

      // Si c'est la première activation, gérer le parrainage
      if (isFirstActivation && emailCtrl.text.trim().isNotEmpty) {
        await _handleSponsorshipRewardIfAny(uid, emailCtrl.text.trim());
      }

      // Reset
      isPickedBanner.value = false;
      isPickedLogo.value = false;

      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar(
          'Succès',
          isFirstActivation
              ? 'Votre établissement est maintenant visible dans le shop !'
              : 'Fiche mise à jour avec succès',
          false);
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }

  // ------------------------------------------------
  // Gérer le parrainage
  // ------------------------------------------------
  Future<void> _handleSponsorshipRewardIfAny(
      String uid, String userEmail) async {
    if (userEmail.isEmpty) return;

    final snap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('sponsorships')
        .where('sponsoredEmails', arrayContains: userEmail.toLowerCase())
        .get();

    if (snap.docs.isEmpty) {
      return;
    }

    final sponsorshipDoc = snap.docs.first;
    final sponsorData = sponsorshipDoc.data();
    final sponsorUid = sponsorData['user_id'] ?? '';
    if (sponsorUid.isEmpty) {
      return;
    }

    // +100€ en bons cadeaux pour le parrain (entreprise/commerce)
    final sponsorWalletSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('wallets')
        .where('user_id', isEqualTo: sponsorUid)
        .limit(1)
        .get();

    if (sponsorWalletSnap.docs.isEmpty) {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': sponsorUid,
        'points': 0,
        'coupons': 2, // 100€ = 2 bons de 50€
      });
    } else {
      final walletRef = sponsorWalletSnap.docs.first.reference;
      await walletRef.update({
        'coupons': FieldValue.increment(2), // 100€ = 2 bons de 50€
      });
    }

    // Envoyer un mail au sponsor
    final sponsorUserSnap = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('users')
        .doc(sponsorUid)
        .get();

    if (sponsorUserSnap.exists) {
      final sponsorUserData = sponsorUserSnap.data()!;
      final sponsorEmail = (sponsorUserData['email'] ?? '').toString();
      final sponsorName = (sponsorUserData['name'] ?? 'Sponsor').toString();

      if (sponsorEmail.isNotEmpty) {
        await sendSponsorshipMailAboutEnterprise(
            sponsorName: sponsorName,
            sponsorEmail: sponsorEmail,
            userEmail: userEmail);
      }
    }
  }

  // ------------------------------------------------
  // Création doc si inexistant
  // ------------------------------------------------
  Future<String> _createEstablishmentDocIfNeeded(String uid) async {
    if (establishmentDocId != null) return establishmentDocId!;

    final docRef = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .add({
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
      'enterprise_category_slots': 2,
      'video_url': '',
      'has_accepted_contract': false,
      'has_active_subscription': false,
      'subscription_status': '',
      'subscription_end_date': null,
      'is_visible_in_shop': false,
      'payment_option': 'monthly', // Option par défaut
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
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
        final ref = UniquesControllers()
            .data
            .firebaseStorage
            .ref('banners/$uid/$fileName');
        final task = ref.putFile(bannerFile.value!);
        await task.whenComplete(() async {
          url = await ref.getDownloadURL();
        });
      } else if (bannerBytes.value != null) {
        final fileName = 'banner_${bannerBytes.hashCode}.png';
        final ref = UniquesControllers()
            .data
            .firebaseStorage
            .ref('banners/$uid/$fileName');
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
        final ref = UniquesControllers()
            .data
            .firebaseStorage
            .ref('logos/$uid/$fileName');
        final task = ref.putFile(logoFile.value!);
        await task.whenComplete(() async {
          url = await ref.getDownloadURL();
        });
      } else if (logoBytes.value != null) {
        final fileName = 'logo_${logoBytes.hashCode}.png';
        final ref = UniquesControllers()
            .data
            .firebaseStorage
            .ref('logos/$uid/$fileName');
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
      if (logoFile.value != null) {
        return _buildImageContainer(
          file: logoFile.value,
          size: 15 * UniquesControllers().data.baseSpace,
        );
      } else if (logoBytes.value != null) {
        return _buildImageContainer(
          bytes: logoBytes.value,
          size: 15 * UniquesControllers().data.baseSpace,
        );
      }
    }
    if (logoUrl.value.isNotEmpty) {
      return _buildImageContainer(
        url: logoUrl.value,
        size: 15 * UniquesControllers().data.baseSpace,
      );
    }
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
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(UniquesControllers().data.baseSpace * 2),
            image: image,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(UniquesControllers().data.baseSpace * 2),
            image: image,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
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
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius:
                BorderRadius.circular(UniquesControllers().data.baseSpace * 2),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: UniquesControllers().data.baseSpace * 5,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: UniquesControllers().data.baseSpace * 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(UniquesControllers().data.baseSpace * 2),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: UniquesControllers().data.baseSpace * 3,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: UniquesControllers().data.baseSpace * 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
