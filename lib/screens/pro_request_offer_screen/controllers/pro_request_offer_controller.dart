import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventemoi/core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';

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
      print('Erreur chargement données: $e');
    }
  }

  Future<void> loadMyRequests() async {
    try {
      final userId = UniquesControllers().getStorage.read('currentUserUID');
      if (userId == null) return;

      // Charger les demandes en attente
      final pendingSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('offer_requests')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();

      pendingRequests.value = pendingSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Charger les offres approuvées
      final approvedSnap = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('offer_requests')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .orderBy('created_at', descending: true)
          .get();

      approvedOffers.value = approvedSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Erreur chargement demandes: $e');
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