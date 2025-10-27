// lib/screens/pro_establishment_profile_screen/controllers/pro_establishment_profile_screen_controller.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../core/models/establishment_category.dart';
import '../../../core/models/stripe_service.dart';
import '../../../core/models/user_type.dart';
import '../../../core/services/stripe_payment_manager.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../widgets/cgu_payment_dialog.dart';

class ProEstablishmentProfileScreenController extends GetxController
    with ControllerMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String customBottomAppBarTag = 'pro-establishment-form-bottom-app-bar';
  double maxFormWidth = 350.0;

  // Variables pour les catégories entreprise sélectionnées
  final RxList<String> selectedEnterpriseCategoryIds = <String>[].obs;
  final RxBool hasModifications = false.obs;
  
  // Options de sous-catégories (subcategoryId -> [optionIds])
  final RxMap<String, List<String>> selectedSubcategoryOptions = <String, List<String>>{}.obs;

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
  final int additionalSlotPrice = 5000; // 50€ en centimes
  
  // Nombre maximum de bons achetables
  RxInt maxVouchersPurchase = 1.obs;

  // Conditions d'utilisation des bons cadeaux
  final TextEditingController voucherUsageConditionsController = TextEditingController();

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

  // Flag pour éviter les vérifications multiples
  bool hasCheckedPostPayment = false;

  @override
  void onInit() {
    super.onInit();

    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid != null) {
      _loadUserType(uid);
    }
  }

  @override
  void onReady() {
    super.onReady();

    // Vérifier si on arrive après un paiement réussi
    _checkPostPaymentActivation();
  }

  // Vérifier l'activation après un paiement
  Future<void> _checkPostPaymentActivation() async {
    // Éviter les vérifications multiples
    if (hasCheckedPostPayment) return;
    hasCheckedPostPayment = true;

    try {
      final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (uid == null) return;

      // Attendre un peu pour laisser le temps aux webhooks Stripe
      await Future.delayed(const Duration(seconds: 2));

      // Vérifier si l'établissement existe et est activé
      final estabQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        final doc = estabQuery.docs.first;
        final data = doc.data();

        // Si on vient de payer mais que l'activation n'est pas complète
        if (data['stripe_session_id'] != null &&
            (data['has_accepted_contract'] != true ||
                data['has_active_subscription'] != true)) {

          // Forcer l'activation
          await doc.reference.update({
            'has_accepted_contract': true,
            'has_active_subscription': true,
            'subscription_status': data['payment_option'] ?? 'monthly',
            'subscription_start_date': FieldValue.serverTimestamp(),
            'subscription_end_date': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 365))),
            'post_payment_activation': true,
            'post_payment_activation_at': FieldValue.serverTimestamp(),
          });


          // // Créer le bon cadeau si nécessaire
          // final giftQuery = await UniquesControllers()
          //     .data
          //     .firebaseFirestore
          //     .collection('gift_vouchers')
          //     .where('establishment_id', isEqualTo: doc.id)
          //     .where('type', isEqualTo: 'welcome')
          //     .limit(1)
          //     .get();

          // if (giftQuery.docs.isEmpty) {
          //   await UniquesControllers()
          //       .data
          //       .firebaseFirestore
          //       .collection('gift_vouchers')
          //       .add({
          //     'establishment_id': doc.id,
          //     'amount': 50.0,
          //     'type': 'welcome',
          //     'status': 'active',
          //     'created_at': FieldValue.serverTimestamp(),
          //     'expires_at': Timestamp.fromDate(
          //         DateTime.now().add(const Duration(days: 365))),
          //     'code': 'WELCOME-${DateTime.now().millisecondsSinceEpoch}',
          //   });

          // }

          final walletQuery = await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('wallets')
              .where('user_id', isEqualTo: uid)
              .limit(1)
              .get();

          if (walletQuery.docs.isEmpty) {
            await UniquesControllers()
                .data
                .firebaseFirestore
                .collection('wallets')
                .add({
              'user_id': uid,
              'points': 50,
              'coupons': 0,
              'created_at': FieldValue.serverTimestamp(),
            });
          } else {
            final existingPoints = walletQuery.docs.first.data()['points'] ?? 0;
            // Vérifier si les points ont déjà été crédités pour éviter les doublons
            if (existingPoints < 50) {
              await walletQuery.docs.first.reference.update({
                'points': FieldValue.increment(50),
              });
            }
          }

          // Afficher un message de succès
          UniquesControllers().data.snackbar(
                'Activation réussie',
                'Votre établissement est maintenant actif dans le shop!',
                false,
              );
        }
      }
    } catch (e) {
    }
  }

  // Charger le userType
  Future<void> _loadUserType(String uid) async {
    final userType = await getUserTypeByUserId(uid);
    currentUserType.value = userType;
  }

  // Méthodes pour gérer les catégories entreprise
  void addEnterpriseCategory(String categoryId) {
    if (!selectedEnterpriseCategoryIds.contains(categoryId) &&
        selectedEnterpriseCategoryIds.length < enterpriseCategorySlots.value) {
      selectedEnterpriseCategoryIds.add(categoryId);
      hasModifications.value = true;
    }
  }

  void removeEnterpriseCategory(String categoryId) {
    selectedEnterpriseCategoryIds.remove(categoryId);
    // Supprimer aussi les options associées si c'est une sous-catégorie
    selectedSubcategoryOptions.remove(categoryId);
    hasModifications.value = true;
  }

  // Initialiser les catégories depuis le stream
  void initializeEnterpriseCategoriesFromStream(Map<String, dynamic> data) {
    // NE PAS réinitialiser si l'utilisateur a des modifications en cours
    if (hasModifications.value) {
      return;
    }

    final List<dynamic>? entCats =
        data['enterprise_categories'] as List<dynamic>?;
    final catIds = entCats?.map((e) => e.toString()).toList() ?? [];

    // Charger les options de sous-catégories
    final dynamic optionsData = data['enterprise_subcategory_options'];
    if (optionsData != null && optionsData is Map) {
      selectedSubcategoryOptions.clear();
      optionsData.forEach((key, value) {
        if (value is List) {
          selectedSubcategoryOptions[key] = value.map((e) => e.toString()).toList();
        }
      });
    }

    // Initialiser seulement si les valeurs ont changé
    if (!_listEquals(selectedEnterpriseCategoryIds, catIds)) {
      selectedEnterpriseCategoryIds.clear();
      selectedEnterpriseCategoryIds.addAll(catIds);
      hasModifications.value = false;

    }
  }

  // Helper pour comparer deux listes
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  
  // Gérer les options de sous-catégories
  void updateSubcategoryOptions(String subcategoryId, List<String> optionIds) {
    if (optionIds.isEmpty) {
      selectedSubcategoryOptions.remove(subcategoryId);
    } else {
      selectedSubcategoryOptions[subcategoryId] = optionIds;
    }
    hasModifications.value = true;
  }

  // Sauvegarder les changements de catégories entreprise
  Future<void> saveEnterpriseCategoriesChanges() async {
    if (establishmentDocId == null) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Aucun établissement trouvé',
            true,
          );
      return;
    }

    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(establishmentDocId)
          .update({
        'enterprise_categories': selectedEnterpriseCategoryIds,
        'enterprise_subcategory_options': selectedSubcategoryOptions.isEmpty 
            ? null 
            : selectedSubcategoryOptions,
      });

      hasModifications.value = false;

      UniquesControllers().data.snackbar(
            'Succès',
            'Vos métiers ont été mis à jour',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible de sauvegarder les modifications: $e',
            true,
          );
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // Annuler les changements et recharger depuis Firestore
  Future<void> resetEnterpriseCategoriesChanges() async {
    if (establishmentDocId == null) return;

    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      // Récupérer les données actuelles depuis Firestore
      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .doc(establishmentDocId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic>? entCats =
            data['enterprise_categories'] as List<dynamic>?;
        final catIds = entCats?.map((e) => e.toString()).toList() ?? [];

        // Réinitialiser les IDs sélectionnés
        selectedEnterpriseCategoryIds.clear();
        selectedEnterpriseCategoryIds.addAll(catIds);
        
        // Réinitialiser les options de sous-catégories
        selectedSubcategoryOptions.clear();
        final dynamic optionsData = data['enterprise_subcategory_options'];
        if (optionsData != null && optionsData is Map) {
          optionsData.forEach((key, value) {
            if (value is List) {
              selectedSubcategoryOptions[key] = value.map((e) => e.toString()).toList();
            }
          });
        }

        // Si vous utilisez encore l'ancien système de dropdowns
        final slots = data['enterprise_category_slots'] ?? 2;
        _initializeCategoryDropdowns(slots, catIds);
      }

      hasModifications.value = false;

      UniquesControllers().data.snackbar(
            'Info',
            'Modifications annulées',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible de recharger les données',
            true,
          );
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // Initialiser les dropdowns de catégories (ancien système)
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

  // Streams
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
      
      // Lire le nombre max de bons achetables
      final maxVouchers = data['max_vouchers_purchase'] ?? 1;
      maxVouchersPurchase.value = maxVouchers;

      // Lire les conditions d'utilisation des bons cadeaux
      voucherUsageConditionsController.text = data['voucher_usage_conditions'] ?? '';

      // Initialiser les dropdowns (ancien système)
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

  // Sauvegarder le profil complet
  Future<void> saveEstablishmentProfile() async {
    if (!formKey.currentState!.validate()) return;

    // Vérifier si l'établissement doit accepter les CGU et payer
    final userType = currentUserType.value;
    final needsSubscription = userType != null &&
        (userType.name == 'Entreprise' ||
            userType.name == 'Boutique' ||
            userType.name == 'Commerçant' ||
            userType.name == 'Sponsor');

    // Vérifier si l'utilisateur a besoin de payer
    // Cas 1 : N'a jamais accepté les CGU
    // Cas 2 : A accepté les CGU mais n'a pas d'abonnement actif (après retrait accès gratuit)
    // Cas 3 : A le flag requires_payment
    bool needsPayment = false;
    bool requiresPaymentFlag = false;

    if (needsSubscription) {
      if (establishmentDocId != null) {
        // Récupérer les données actuelles de l'établissement
        final estabDoc = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(establishmentDocId)
            .get();

        if (estabDoc.exists) {
          final data = estabDoc.data()!;
          requiresPaymentFlag = data['requires_payment'] ?? false;
          final hasAccepted = data['has_accepted_contract'] ?? false;
          final hasActiveSubscription =
              data['has_active_subscription'] ?? false;
          final isFreeAccess = data['is_free_access'] ?? false;

          // L'utilisateur doit payer si :
          // 1. Il n'a jamais accepté les CGU
          // 2. Il a accepté mais n'a pas d'abonnement actif et n'est pas en accès gratuit
          // 3. Il a le flag requires_payment (après retrait d'accès gratuit)
          needsPayment = !hasAccepted ||
              (!hasActiveSubscription && !isFreeAccess) ||
              requiresPaymentFlag;
        } else {
          // Nouvel établissement
          needsPayment = true;
        }
      } else {
        // Nouvel établissement
        needsPayment = true;
      }
    }

    if (needsSubscription && needsPayment) {
      // Retirer le flag requires_payment si présent
      if (requiresPaymentFlag && establishmentDocId != null) {
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(establishmentDocId)
            .update({
          'requires_payment': FieldValue.delete(),
        });
      }

      // Ouvrir la dialog CGU et paiement
      Get.dialog(
        CGUPaymentDialog(
          userType: userType.name,
        ),
        barrierDismissible: false,
      );
    } else {
      // Sauvegarder directement si pas besoin de subscription ou déjà payé
      await _performSaveEstablishmentProfile();
    }
  }

  // Méthode pour effectuer la sauvegarde
  Future<void> _performSaveEstablishmentProfile() async {
    UniquesControllers().data.isInAsyncCall.value = true;

    try {
      final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (uid == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Upload des images
      final String newBannerUrl = await _uploadBanner(uid) ?? bannerUrl.value;
      final String newLogoUrl = await _uploadLogo(uid) ?? logoUrl.value;

      // Préparer les données
      final Map<String, dynamic> dataToSave = {
        'name': nameCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'telephone': phoneCtrl.text.trim(),
        'video_url': videoCtrl.text.trim(),
        'banner_url': newBannerUrl,
        'logo_url': newLogoUrl,
        'category_id': currentCategory.value?.id ?? '',
        'enterprise_categories': selectedEnterpriseCategoryIds,
        'max_vouchers_purchase': maxVouchersPurchase.value,
        'voucher_usage_conditions': voucherUsageConditionsController.text.trim(),
      };

      // Sauvegarder
      if (establishmentDocId != null) {
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(establishmentDocId)
            .update(dataToSave);
      } else {
        // Créer un nouvel établissement
        dataToSave['user_id'] = uid;
        dataToSave['has_accepted_contract'] = false;
        dataToSave['enterprise_category_slots'] = 2;
        dataToSave['max_vouchers_purchase'] = 1;
        dataToSave['is_visible'] = false; // Invisible par défaut tant qu'il n'a pas payé

        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .add(dataToSave);
      }

      // Réinitialiser les états
      isPickedBanner.value = false;
      isPickedLogo.value = false;
      hasModifications.value = false;
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            e.toString(),
            true,
          );
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // Traiter le paiement de l'abonnement
  Future<void> _processSubscriptionPayment(String paymentOption) async {
    try {
      // TODO: Implémenter l'intégration Stripe ici

      // Pour le moment, mettre à jour les statuts
      if (establishmentDocId != null) {
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(establishmentDocId)
            .update({
          'has_accepted_contract': true,
          'has_active_subscription': true,
          'subscription_status':
              paymentOption == 'annual' ? 'annual' : 'monthly',
          'subscription_start_date': FieldValue.serverTimestamp(),
          'subscription_end_date':
              Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        });
      }

      UniquesControllers().data.snackbar(
            'Succès',
            'Profil établissement sauvegardé et abonnement activé',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Erreur lors du paiement : $e',
            true,
          );
    }
  }

  // Upload banner
  Future<String?> _uploadBanner(String uid) async {
    String? url;
    try {
      if (bannerFile.value != null) {
        final ext = p.extension(bannerFile.value!.path);
        final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}$ext';
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
      UniquesControllers().data.snackbar('Erreur Banner', e.toString(), true);
    }
    return url;
  }

  // Upload logo
  Future<String?> _uploadLogo(String uid) async {
    String? url;
    try {
      if (logoFile.value != null) {
        final ext = p.extension(logoFile.value!.path);
        final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}$ext';
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

  // Picker pour les images
  Future<void> pickFile(bool isLogo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          if (isLogo) {
            logoBytes.value = bytes;
            isPickedLogo.value = true;
          } else {
            bannerBytes.value = bytes;
            isPickedBanner.value = true;
          }
        }
      } else {
        final path = result.files.single.path;
        if (path != null) {
          if (isLogo) {
            logoFile.value = File(path);
            isPickedLogo.value = true;
          } else {
            bannerFile.value = File(path);
            isPickedBanner.value = true;
          }
        }
      }
    }
  }

  // Dans ProEstablishmentProfileScreenController

  // Méthodes pour picker logo et banner
  void pickLogo() {
    pickFile(true); // true pour logo
  }

  void pickBanner() {
    pickFile(false); // false pour banner
  }

  // Méthode pour ajouter un slot de catégorie (pour EnterpriseCategorySlotsWidget)
  void addCategorySlot() {
    // Implémenter l'ajout de slot supplémentaire
    openPaymentDialog(
      title: 'Slot supplémentaire',
      description: 'Ajouter un slot de catégorie supplémentaire pour 50€',
      price: additionalSlotPrice,
      onPaymentSuccess: () {
        // Le PaymentListener gérera la mise à jour automatiquement
        Get.snackbar(
          'Paiement en cours',
          'Votre slot supplémentaire sera ajouté après confirmation du paiement',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  // Dans ProEstablishmentProfileScreenController

  void openPaymentDialog({
    required String title,
    required String description,
    required int price,
    required VoidCallback onPaymentSuccess,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.orange),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prix :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${(price / 100).toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              // Implémenter le paiement Stripe ici
              _processPayment(price, onPaymentSuccess);
            },
            icon: Icon(Icons.credit_card),
            label: Text('Payer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour traiter le paiement
  Future<void> _processPayment(int price, VoidCallback onSuccess) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      // TODO: Implémenter l'intégration Stripe ici
      // Pour le moment, simuler un succès
      await Future.delayed(Duration(seconds: 2));

      onSuccess();

      UniquesControllers().data.snackbar(
            'Succès',
            'Paiement effectué avec succès',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Erreur lors du paiement: $e',
            true,
          );
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  void toggleEnterpriseCategory(String categoryId) {
    if (selectedEnterpriseCategoryIds.contains(categoryId)) {
      removeEnterpriseCategory(categoryId);
    } else if (selectedEnterpriseCategoryIds.length <
        enterpriseCategorySlots.value) {
      addEnterpriseCategory(categoryId);
    } else {
      Get.snackbar(
        'Limite atteinte',
        'Vous avez atteint le maximum de ${enterpriseCategorySlots.value} catégories',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  // Widgets d'affichage des images
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
      image = DecorationImage(
        image: FileImage(file),
        fit: BoxFit.cover,
      );
    } else if (bytes != null) {
      image = DecorationImage(
        image: MemoryImage(bytes),
        fit: BoxFit.cover,
      );
    } else if (url != null && url.isNotEmpty) {
      image = DecorationImage(
        image: NetworkImage(url),
        fit: BoxFit.cover,
      );
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
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(UniquesControllers().data.baseSpace * 2),
          image: image,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
      ),
    );
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

  Future<void> purchaseAdditionalSlot() async {
    await StripePaymentManager.to.processSlotPayment(
      onSuccess: () {
        _handleSlotPaymentSuccess();
      },
    );
  }

  // Méthode pour extraire l'ID de session de l'URL (à adapter selon votre logique)
  Future<String?> _getSessionIdFromUrl(String checkoutUrl) async {
    // Si vous stockez l'ID de session, récupérez-le ici
    // Sinon, modifiez createAdditionalSlotCheckout pour retourner un Map avec url et sessionId
    return null; // À implémenter
  }

  // Dialog d'attente pour l'achat de slot
  void _showSlotPaymentWaitingDialog(String sessionId) {
    StreamSubscription? subscription;
    Timer? timeoutTimer;
    Timer? pollingTimer;

    bool paymentProcessed = false;
    bool dialogClosed = false;

    final RxString debugStatus = 'Initialisation...'.obs;
    final RxBool isCheckingPayment = false.obs;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              minHeight: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de chargement
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Traitement du paiement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Achat d\'un slot de catégorie supplémentaire',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Veuillez finaliser votre paiement dans l\'onglet Stripe.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Cette fenêtre se fermera automatiquement.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Obx(() => Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              debugStatus.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    subscription?.cancel();
                    timeoutTimer?.cancel();
                    pollingTimer?.cancel();
                    dialogClosed = true;
                    Get.back();
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Fonction pour vérifier le succès
    Future<bool> verifyPaymentSuccess(DocumentSnapshot sessionDoc) async {
      if (!sessionDoc.exists) return false;

      final data = sessionDoc.data() as Map<String, dynamic>;

      final paymentStatus = data['payment_status'] as String?;
      final status = data['status'] as String?;
      final amountTotal = data['amount_total'] as int?;
      final paymentIntent = data['payment_intent'] as String?;

      final isPaid =
          (paymentStatus == 'paid' || paymentStatus == 'succeeded') ||
              (status == 'complete' || status == 'paid');
      final hasAmount = amountTotal != null && amountTotal > 0;
      final hasPaymentProof = paymentIntent != null;

      return isPaid && hasAmount && hasPaymentProof;
    }

    // Écouter les changements
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugStatus.value = 'Connexion à Stripe...';

      // Timeout de 5 minutes
      timeoutTimer = Timer(Duration(minutes: 5), () {
        if (!paymentProcessed && !dialogClosed) {
          subscription?.cancel();
          pollingTimer?.cancel();
          Get.back();
          UniquesControllers().data.snackbar(
                'Temps écoulé',
                'Le délai de paiement a expiré.',
                true,
              );
        }
      });

      // Écouter la session
      subscription = UniquesControllers()
          .data
          .firebaseFirestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && !paymentProcessed && !dialogClosed) {
          final data = snapshot.data()!;

          debugStatus.value =
              'Statut: ${data['payment_status'] ?? data['status'] ?? 'en attente'}';

          if (await verifyPaymentSuccess(snapshot)) {
            paymentProcessed = true;
            debugStatus.value = '✅ Paiement confirmé!';

            await Future.delayed(Duration(seconds: 1));

            subscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            if (!dialogClosed) {
              Get.back();
              _handleSlotPaymentSuccess();
            }
          }

          if (data['status'] == 'expired' || data['status'] == 'canceled') {
            debugStatus.value = '❌ Paiement annulé';

            subscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            if (!dialogClosed) {
              Get.back();
              UniquesControllers().data.snackbar(
                    'Paiement annulé',
                    'L\'achat du slot a été annulé',
                    true,
                  );
            }
          }
        }
      });

      // Vérification périodique
      pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
        if (!isCheckingPayment.value && !paymentProcessed && !dialogClosed) {
          isCheckingPayment.value = true;

          try {
            final sessionDoc = await UniquesControllers()
                .data
                .firebaseFirestore
                .collection('customers')
                .doc(user.uid)
                .collection('checkout_sessions')
                .doc(sessionId)
                .get();

            if (await verifyPaymentSuccess(sessionDoc)) {
              paymentProcessed = true;
              timer.cancel();

              subscription?.cancel();
              timeoutTimer?.cancel();

              if (!dialogClosed) {
                Get.back();
                _handleSlotPaymentSuccess();
              }
            }
          } catch (e) {
          } finally {
            isCheckingPayment.value = false;
          }
        }
      });
    }
  }

  void _handleSlotPaymentSuccess() async {
    try {
      final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
      if (uid == null) return;


      // Attendre que Firestore se mette à jour
      await Future.delayed(Duration(seconds: 1));

      // Recharger les données
      final estabQuery = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        final doc = estabQuery.docs.first;
        final establishmentId = doc.id;
        final data = doc.data();
        final currentSlots = data['enterprise_category_slots'] ?? 2;
        final newSlots = currentSlots + 1;


        // IMPORTANT: Mettre à jour Firestore
        await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .doc(establishmentId)
            .update({
          'enterprise_category_slots': newSlots,
          'last_slot_purchase': FieldValue.serverTimestamp(),
        });


        // Mettre à jour l'UI
        enterpriseCategorySlots.value = newSlots;

        // Ajouter un slot vide
        selectedEnterpriseCategories.add(Rx<EnterpriseCategory?>(null));

        UniquesControllers().data.snackbar(
              'Slot ajouté !',
              'Votre nouveau slot est disponible. Total: $newSlots',
              false,
            );

        update();
      } else {
      }
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible d\'ajouter le slot. Contactez le support.',
            true,
          );
    }
  }

  // Méthode pour afficher la dialog de confirmation d'achat
  void showPurchaseSlotDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.add_business, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Ajouter un slot'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous acheter un slot de catégorie supplémentaire ?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prix :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '50,00 €',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              purchaseAdditionalSlot();
            },
            icon: Icon(Icons.credit_card, color: Colors.white),
            label: Text('Acheter', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
