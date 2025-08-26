import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/models/stripe_service.dart';

import '../../screens/pro_establishment_profile_screen/controllers/pro_establishment_profile_screen_controller.dart';
import '../classes/unique_controllers.dart';
import 'enterprise_category.dart';

class PaymentListenerController extends GetxController {
  StreamSubscription<QuerySnapshot>? _paymentSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString lastPaymentType = ''.obs;
  final Rx<DateTime?> lastPaymentDate = Rx<DateTime?>(null);

  final RxBool slotPaymentDetected = false.obs;
  final RxString lastSlotSessionId = ''.obs;

  // Tracker les sessions déjà traitées
  final Set<String> _processedSessions = {};

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  @override
  void onClose() {
    _paymentSubscription?.cancel();
    super.onClose();
  }

  void _startListening() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Écouter TOUTES les sessions
    _paymentSubscription = StripeService.to
        .listenToPaymentSessions(user.uid)
        .listen(_handlePaymentSession);
  }

  Future<void> _handlePaymentSession(QuerySnapshot snapshot) async {
    // print('🔔 PaymentListener: ${snapshot.docChanges.length} changements détectés');

    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added ||
          change.type == DocumentChangeType.modified) {
        final sessionId = change.doc.id;
        final sessionData = change.doc.data() as Map<String, dynamic>;
        final paymentStatus = sessionData['payment_status'] as String?;
        final metadata = sessionData['metadata'] as Map<String, dynamic>?;


        // Vérifier si c'est payé ET non déjà traité
        if (paymentStatus == 'paid' &&
            !_processedSessions.contains(sessionId)) {
          _processedSessions.add(sessionId);

          // Vérifier si c'est un paiement de slot
          if (metadata?['type'] == 'additional_category_slot' ||
              metadata?['purchase_type'] == 'category_slot') {
            lastSlotSessionId.value = sessionId;
            slotPaymentDetected.value = true;
          }

          await _processSuccessfulPayment(change.doc);
        } else if (paymentStatus != 'paid') {
        } else if (_processedSessions.contains(sessionId)) {
        }
      }
    }
  }

  Future<void> _processSuccessfulPayment(DocumentSnapshot sessionDoc) async {
    try {

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final metadata = sessionData['metadata'] as Map<String, dynamic>?;

      if (metadata == null) {
        return;
      }

      final userId = metadata['user_id'] as String?;
      final purchaseType = metadata['purchase_type'] as String?;
      final paymentType = metadata['type'] as String?;


      // Appeler handleSuccessfulPayment de StripeService
      await StripeService.to.handleSuccessfulPayment(sessionDoc);

      // Notification spécifique pour les slots
      if (paymentType == 'additional_category_slot' ||
          purchaseType == 'category_slot') {

        // Attendre un peu pour que Firestore se mette à jour
        await Future.delayed(Duration(seconds: 1));

        // Récupérer les données mises à jour
        final estabQuery = await FirebaseFirestore.instance
            .collection('establishments')
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();

        if (estabQuery.docs.isNotEmpty) {
          final doc = estabQuery.docs.first;
          final newSlots = doc.data()['enterprise_category_slots'] ?? 2;


          UniquesControllers().data.snackbar(
                'Slot ajouté !',
                'Votre nouveau slot de catégorie est disponible. Total: $newSlots',
                false,
              );

          // Rafraîchir le contrôleur si disponible
          if (Get.isRegistered<ProEstablishmentProfileScreenController>()) {
            final controller =
                Get.find<ProEstablishmentProfileScreenController>();

            // Mettre à jour directement
            controller.enterpriseCategorySlots.value = newSlots;
            controller.selectedEnterpriseCategories
                .add(Rx<EnterpriseCategory?>(null));
            controller.update();

          }
        }
      }

      // Marquer comme traité
      await sessionDoc.reference.update({
        'processed_by_app': true,
        'processed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
    }
  }

  // Nettoyer périodiquement
  void cleanupOldSessions() {
    if (_processedSessions.length > 50) {
      _processedSessions.clear();
    }
  }
}
