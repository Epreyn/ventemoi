import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart'; // ajustez selon vos imports
import '../../../core/services/payment_validation_hook.dart';
import '../../../core/services/account_deletion_service.dart';
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

  // SliderValue pour l'achat de bons (1..12)
  RxInt sliderValue = 1.obs;

  // Id du doc 'wallet' si besoin
  String? currentWalletDocId;
  // Id d'établissement (si besoin, ex: pour user de type Boutique)
  String? userEstablishmentId;
  // Nom de l'établissement
  RxString establishmentName = ''.obs;

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
  // Recharger les infos du wallet
  // ---------------------------
  Future<void> loadWalletInfo() async {
    await _fetchWalletDocId();
    // Force un rafraîchissement du stream
    if (currentWalletDocId != null) {
      final walletDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc(currentWalletDocId)
          .get();

      if (walletDoc.exists) {
        final data = walletDoc.data()!;
        couponsController.text = '${data['coupons'] ?? 0}';
      }
    }
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
      final estData = estDoc.docs.first.data();
      establishmentName.value = estData['name'] ?? 'Boutique';
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

    // Pour l'image de profil
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

      // Upload image s'il y en a une
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
    sliderValue.value = 3; // Commencer à 3 au lieu de 1
    openBottomSheet(
      'Créditer des bons', // Changé de "Acheter" à "Créditer"
      subtitle: 'Sélectionnez le nombre de bons à créditer',
      hasAction: true,
      actionName: 'Créditer', // Changé de "Acheter" à "Créditer"
      actionIcon: Icons.add_circle,
      primaryColor: CustomTheme.lightScheme().primary,
      headerWidget: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CustomTheme.lightScheme().primary.withOpacity(0.1),
              CustomTheme.lightScheme().primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: CustomTheme.lightScheme().primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '1 bon = 50€ de valeur',
                    style: TextStyle(
                      color: CustomTheme.lightScheme().primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // NOUVEAU : Avertissement communication
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.campaign,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attention : la communication sur nos réseaux commence à partir de 6 bons.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      doReset: true,
    );
  }

  @override
  void variablesToResetToBottomSheet() {
    sliderValue.value = 3; // Commencer à 3
  }

  @override
  List<Widget> bottomSheetChildren() {
    return [
      // Card principale avec le slider
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icône animée
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CustomTheme.lightScheme().primary,
                          CustomTheme.lightScheme().primary.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CustomTheme.lightScheme()
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.confirmation_number,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Valeur actuelle
            Obx(() => Column(
                  children: [
                    Text(
                      '${sliderValue.value}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: CustomTheme.lightScheme().primary,
                      ),
                    ),
                    Text(
                      sliderValue.value > 1 ? 'bons' : 'bon',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )),

            const SizedBox(height: 24),

            // Boutons de sélection rapide (3, 6, 12)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [3, 6, 12].map((qty) {
                return Obx(() => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          sliderValue.value = qty;
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: sliderValue.value == qty
                                ? LinearGradient(
                                    colors: [
                                      CustomTheme.lightScheme().primary,
                                      CustomTheme.lightScheme()
                                          .primary
                                          .withOpacity(0.8),
                                    ],
                                  )
                                : null,
                            color: sliderValue.value == qty
                                ? null
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sliderValue.value == qty
                                  ? CustomTheme.lightScheme().primary
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            boxShadow: sliderValue.value == qty
                                ? [
                                    BoxShadow(
                                      color: CustomTheme.lightScheme()
                                          .primary
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$qty',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: sliderValue.value == qty
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'bons',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: sliderValue.value == qty
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ));
              }).toList(),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      // Calcul du prix
      Obx(() => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CustomTheme.lightScheme().primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CustomTheme.lightScheme().primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prix unitaire',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    const Text(
                      '50€',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quantité',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '× ${sliderValue.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${sliderValue.value * 50}€',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CustomTheme.lightScheme().primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),

      const SizedBox(height: 20),

      // Indicateur de communication
      Obx(() {
        if (sliderValue.value >= 6) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Communication sur nos réseaux incluse !',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
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

      // NOUVEAU: Créer directement les bons renouvelés pour la boutique
      final batch = UniquesControllers().data.firebaseFirestore.batch();
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 90));

      // Générer les bons renouvelés
      for (int i = 0; i < nb; i++) {
        final voucherCode = _generateVoucherCode();
        final voucherRef = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('vouchers')
            .doc();

        batch.set(voucherRef, {
          'buyer_id': uid, // La boutique qui renouvelle
          'establishment_id': userEstablishmentId ?? '',
          'establishment_name': establishmentName.value,
          'value': 50, // Valeur du bon : 50€
          'code': voucherCode,
          'created_at': now.toIso8601String(),
          'expiry_date': expiryDate.toIso8601String(),
          'status': 'active',
          'used_at': null,
          // IMPORTANT: Marquer comme bon renouvelé
          'is_renewed': true,
          'renewal_date': now.toIso8601String(),
          'renewal_cost': 15, // Coût pour la boutique : 15€
          'ventemoi_owes': 35, // Ce que VenteMoi doit : 35€
          'payment_status': 'pending', // Statut du paiement par VenteMoi
          'payment_date': null,
        });
      }

      // Mettre à jour le wallet de la boutique
      if (currentWalletDocId != null) {
        final walletRef = UniquesControllers()
            .data
            .firebaseFirestore
            .collection('wallets')
            .doc(currentWalletDocId);

        batch.update(walletRef, {
          'coupons': FieldValue.increment(nb),
          'last_renewal': now.toIso8601String(),
        });
      }

      // Exécuter le batch
      await batch.commit();

      // 2) Fetch user doc (the "enterprise" user) to get name & email pour notifications
      final userSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();
      if (userSnap.exists) {
        final userData = userSnap.data()!;
        final enterpriseEmail = (userData['email'] ?? '').toString().trim();
        final enterpriseName = (userData['name'] ?? '').toString().trim();

        // Envoyer un email de confirmation (au lieu de demande)
        // TODO: Créer une nouvelle fonction pour email de confirmation de renouvellement

        // NOUVEAU: Si c'est une entreprise/boutique qui vient de payer et accepter les CGU
        // Déclencher le hook de parrainage
        final userTypeName = await getUserTypeNameByUserId(uid);
        if (userTypeName != 'Particulier') {
          // Vérifier si c'est la première fois qu'il valide
          final hasAlreadyValidated =
              await PaymentValidationHook.hasAlreadyValidated(uid);
          if (!hasAlreadyValidated) {
            await PaymentValidationHook.onPaymentAndCGUValidated(
              userId: uid,
              userEmail: enterpriseEmail,
              userType: userTypeName,
            );
          }
        }
      }

      // Rafraîchir le nombre de bons dans l'interface
      await loadWalletInfo();

      UniquesControllers().data.snackbar(
            'Bons crédités',
            'Vos ${nb} bon(s) ont été crédités avec succès !',
            false,
          );
    } catch (e) {
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  // Fonction helper pour générer un code de bon unique
  String _generateVoucherCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // ---------------------------
  // Suppression compte
  // ---------------------------
  Future<void> deleteAccount() async {
    // Afficher d'abord un dialogue d'avertissement détaillé
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: CustomTheme.lightScheme().error),
            SizedBox(width: 8),
            Text('Supprimer votre compte'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cette action est irréversible !',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomTheme.lightScheme().error,
                ),
              ),
              SizedBox(height: 16),
              Text('La suppression de votre compte entraînera :'),
              SizedBox(height: 8),
              _buildDeletionItem('• Suppression de vos informations personnelles'),
              _buildDeletionItem('• Perte de tous vos points et bons'),
              _buildDeletionItem('• Suppression de votre historique de parrainage'),
              _buildDeletionItem('• Impossibilité de récupérer votre compte'),
              SizedBox(height: 16),
              Text(
                'Vos transactions passées seront anonymisées pour préserver l\'historique des autres utilisateurs.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _proceedWithDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomTheme.lightScheme().error,
              foregroundColor: Colors.white,
            ),
            child: Text('Continuer la suppression'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Future<void> _proceedWithDeletion() async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;
      final user = UniquesControllers().data.firebaseAuth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final userEmail = user.email;

      // Récupérer le nom de l'utilisateur
      String? userName;
      final userDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        userName = userDoc.data()?['name'];
      }

      // Vérifier d'abord si l'utilisateur peut supprimer son compte
      final deletionService = AccountDeletionService();

      try {
        await deletionService.canDeleteAccount(uid);
      } catch (e) {
        UniquesControllers().data.isInAsyncCall.value = false;
        Get.dialog(
          AlertDialog(
            title: Text('Suppression impossible'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Compris'),
              ),
            ],
          ),
        );
        return;
      }

      // Essayer de supprimer directement
      try {
        await deletionService.deleteUserAccount(
          uid: uid,
          userEmail: userEmail,
          userName: userName,
        );

        UniquesControllers().data.isInAsyncCall.value = false;
        UniquesControllers().data.snackbar(
          'Compte supprimé',
          'Votre compte a été supprimé avec succès. Nous sommes tristes de vous voir partir.',
          false,
        );
        Get.offAllNamed(Routes.login);

      } catch (authError) {
        // Si la suppression échoue (besoin de ré-authentification)
        if (authError.toString().contains('requires-recent-login')) {
          UniquesControllers().data.isInAsyncCall.value = false;

          // Demander le mot de passe pour ré-authentifier
          final passwordController = TextEditingController();
          Get.dialog(
            AlertDialog(
              title: Text('Confirmation requise'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pour des raisons de sécurité, veuillez entrer votre mot de passe pour confirmer la suppression.'),
                  SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (password) {
                      Get.back();
                      _deleteAccountWithReauth(userEmail!, password, userName);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    _deleteAccountWithReauth(
                      userEmail!,
                      passwordController.text,
                      userName,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomTheme.lightScheme().error,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Supprimer'),
                ),
              ],
            ),
          );
        } else {
          throw authError;
        }
      }
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }

  // Méthode pour supprimer le compte avec ré-authentification
  Future<void> _deleteAccountWithReauth(String email, String password, String? userName) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      // Ré-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final user = UniquesControllers().data.firebaseAuth.currentUser;
      if (user == null) return;

      await user.reauthenticateWithCredential(credential);
      final uid = user.uid;

      // Utiliser le service de suppression
      final deletionService = AccountDeletionService();
      await deletionService.deleteUserAccount(
        uid: uid,
        userEmail: email,
        userName: userName,
      );

      UniquesControllers().data.isInAsyncCall.value = false;

      UniquesControllers().data.snackbar(
        'Compte supprimé',
        'Votre compte a été supprimé avec succès. Nous sommes tristes de vous voir partir.',
        false,
      );

      // Redirection vers l'écran de login
      Get.offAllNamed(Routes.login);
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar(
        'Erreur',
        'Mot de passe incorrect ou erreur lors de la suppression.',
        true,
      );
    }
  }

  // Ces méthodes ne sont plus nécessaires avec le nouveau AlertDialog
  @override
  Widget alertDialogContent() {
    return const SizedBox.shrink();
  }

  @override
  Future<void> actionAlertDialog() async {
    // Cette méthode n'est plus utilisée
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
