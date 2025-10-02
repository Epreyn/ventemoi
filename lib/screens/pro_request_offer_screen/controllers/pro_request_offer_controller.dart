import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventemoi/core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/services/offer_email_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/stripe_service.dart';
import '../../../core/services/stripe_payment_manager.dart';

class ProRequestOfferController extends GetxController with ControllerMixin {
  static const tag = 'pro-request-offer';

  // Form controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final imageUrlCtrl = TextEditingController();
  final linkUrlCtrl = TextEditingController();
  final buttonTextCtrl = TextEditingController();
  final establishmentNameCtrl = TextEditingController();
  final contactPhoneCtrl = TextEditingController();
  
  // Observables
  final isLoading = false.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final pendingRequests = <Map<String, dynamic>>[].obs;
  final approvedOffers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    loadMyRequests();
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    imageUrlCtrl.dispose();
    linkUrlCtrl.dispose();
    buttonTextCtrl.dispose();
    establishmentNameCtrl.dispose();
    contactPhoneCtrl.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    try {
      final userId = UniquesControllers().getStorage.read('currentUserUID');
      if (userId == null) return;

      // Charger les données de l'établissement
      final establishmentSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (establishmentSnap.docs.isNotEmpty) {
        final data = establishmentSnap.docs.first.data();
        establishmentNameCtrl.text = data['name'] ?? '';
        contactPhoneCtrl.text = data['telephone'] ?? '';
      }
    } catch (e) {
    }
  }

  Future<void> loadMyRequests() async {
    try {
      final userId = UniquesControllers().getStorage.read('currentUserUID');
      if (userId == null) return;

      // Charger toutes les demandes de l'utilisateur et filtrer côté client
      final allRequestsSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('offer_requests')
          .where('user_id', isEqualTo: userId)
          .get();

      final allRequests = allRequestsSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filtrer et trier côté client pour éviter les index composites
      pendingRequests.value = allRequests
          .where((request) => request['status'] == 'pending')
          .toList()
        ..sort((a, b) {
          final aDate = a['created_at'] as Timestamp?;
          final bDate = b['created_at'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

      approvedOffers.value = allRequests
          .where((request) => request['status'] == 'approved')
          .toList()
        ..sort((a, b) {
          final aDate = a['created_at'] as Timestamp?;
          final bDate = b['created_at'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });
    } catch (e) {
      // En cas d'erreur, essayer une méthode encore plus simple
      await _loadRequestsSimple();
    }
  }

  Future<void> _loadRequestsSimple() async {
    try {
      final userId = UniquesControllers().getStorage.read('currentUserUID');
      if (userId == null) return;

      // Charger TOUTES les demandes et filtrer côté client
      final allSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('offer_requests')
          .get();

      final userRequests = allSnap.docs
          .where((doc) => doc.data()['user_id'] == userId)
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      pendingRequests.value = userRequests
          .where((request) => request['status'] == 'pending')
          .toList()
        ..sort((a, b) {
          final aDate = a['created_at'] as Timestamp?;
          final bDate = b['created_at'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

      approvedOffers.value = userRequests
          .where((request) => request['status'] == 'approved')
          .toList()
        ..sort((a, b) {
          final aDate = a['created_at'] as Timestamp?;
          final bDate = b['created_at'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

    } catch (e) {
      pendingRequests.value = [];
      approvedOffers.value = [];
    }
  }

  Future<void> submitOfferRequest() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      final userId = UniquesControllers().getStorage.read('currentUserUID');

      final requestData = {
        'user_id': userId,
        'establishment_name': establishmentNameCtrl.text.trim(),
        'contact_phone': contactPhoneCtrl.text.trim(),
        'title': titleCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'image_url': imageUrlCtrl.text.trim().isEmpty ? null : imageUrlCtrl.text.trim(),
        'link_url': linkUrlCtrl.text.trim().isEmpty ? null : linkUrlCtrl.text.trim(),
        'button_text': buttonTextCtrl.text.trim().isEmpty ? 'En savoir plus' : buttonTextCtrl.text.trim(),
        'start_date': startDate.value != null ? Timestamp.fromDate(startDate.value!) : null,
        'end_date': endDate.value != null ? Timestamp.fromDate(endDate.value!) : null,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('offer_requests')
          .add(requestData);

      // Envoyer un email aux admins pour les notifier de la nouvelle demande
      await OfferEmailService.sendNewOfferRequestToAdmins(
        requestData: requestData,
      );

      UniquesControllers().data.snackbar(
        'Demande envoyée',
        'Votre demande d\'offre publicitaire a été envoyée pour validation',
        false,
      );

      // Réinitialiser le formulaire
      clearForm();

      // Recharger les demandes
      await loadMyRequests();

    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible d\'envoyer la demande: $e',
        true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> proceedToPayment() async {
    if (!formKey.currentState!.validate()) return;

    // Vérifier que la date de début est sélectionnée
    if (startDate.value == null) {
      UniquesControllers().data.snackbar(
        'Date requise',
        'Veuillez sélectionner une date de début pour votre bannière',
        true,
      );
      return;
    }

    try {
      isLoading.value = true;
      final userId = UniquesControllers().getStorage.read('currentUserUID');

      // Calculer automatiquement la date de fin (7 jours après)
      final endDateCalculated = startDate.value!.add(const Duration(days: 7));

      // Préparer les données de l'offre pour la sauvegarde après paiement
      final offerData = {
        'user_id': userId,
        'establishment_name': establishmentNameCtrl.text.trim(),
        'contact_phone': contactPhoneCtrl.text.trim(),
        'title': titleCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'image_url': imageUrlCtrl.text.trim().isEmpty ? null : imageUrlCtrl.text.trim(),
        'link_url': linkUrlCtrl.text.trim().isEmpty ? null : linkUrlCtrl.text.trim(),
        'button_text': buttonTextCtrl.text.trim().isEmpty ? 'En savoir plus' : buttonTextCtrl.text.trim(),
        'start_date': Timestamp.fromDate(startDate.value!),
        'end_date': Timestamp.fromDate(endDateCalculated),
        'price': 50, // Prix en euros
        'duration_days': 7,
        'status': 'pending_payment',
        'created_at': FieldValue.serverTimestamp(),
      };

      // Sauvegarder temporairement l'offre en attente de paiement
      final docRef = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('pending_banner_offers')
          .add(offerData);

      // Récupérer l'ID de l'établissement
      String? establishmentId;
      final establishmentSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (establishmentSnap.docs.isNotEmpty) {
        establishmentId = establishmentSnap.docs.first.id;
      }

      isLoading.value = false;

      // Utiliser StripePaymentManager pour gérer le paiement avec dialog d'attente
      await StripePaymentManager.to.processBannerPayment(
        establishmentId: establishmentId ?? docRef.id,
        startDate: startDate.value!,
        onSuccess: () async {
          // Stocker l'ID de session dans l'offre
          await docRef.update({
            'payment_completed': true,
            'payment_date': FieldValue.serverTimestamp(),
          });

          UniquesControllers().data.snackbar(
            'Paiement réussi',
            'Votre bannière publicitaire sera activée dans quelques instants',
            false,
          );

          // Réinitialiser le formulaire
          clearForm();

          // Recharger les offres
          await loadMyRequests();

          // Rediriger vers la page de succès
          Get.offNamed('/banner-success');
        },
        onError: (error) {
          // En cas d'erreur, supprimer l'offre en attente
          docRef.delete();

          UniquesControllers().data.snackbar(
            'Paiement annulé',
            'Le paiement a été annulé ou a échoué',
            true,
          );
        },
      );

    } catch (e) {
      isLoading.value = false;
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible de procéder au paiement: $e',
        true,
      );
    }
  }

  void clearForm() {
    titleCtrl.clear();
    descriptionCtrl.clear();
    imageUrlCtrl.clear();
    linkUrlCtrl.clear();
    buttonTextCtrl.clear();
    startDate.value = null;
    endDate.value = null;
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('offer_requests')
          .doc(requestId)
          .update({
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
      });

      UniquesControllers().data.snackbar(
        'Demande annulée',
        'Votre demande a été annulée',
        false,
      );

      await loadMyRequests();
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Impossible d\'annuler la demande: $e',
        true,
      );
    }
  }
}