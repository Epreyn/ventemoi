import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../screens/pro_establishment_profile_screen/controllers/pro_establishment_profile_screen_controller.dart'
    show ProEstablishmentProfileScreenController;
import '../classes/unique_controllers.dart';
import 'stripe_service.dart';

class PaymentListenerController extends GetxController {
  StreamSubscription<QuerySnapshot>? _paymentSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    // Écouter les sessions de paiement réussies
    _paymentSubscription = StripeService.to
        .listenToPaymentSessions(user.uid)
        .listen(_handlePaymentSession);
  }

  Future<void> _handlePaymentSession(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added ||
          change.type == DocumentChangeType.modified) {
        final sessionData = change.doc.data() as Map<String, dynamic>;
        final paymentStatus = sessionData['payment_status'] as String?;

        if (paymentStatus == 'paid') {
          await _processSuccessfulPayment(change.doc);
        }
      }
    }
  }

  Future<void> _processSuccessfulPayment(DocumentSnapshot sessionDoc) async {
    try {
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final metadata = sessionData['metadata'] as Map<String, dynamic>?;

      if (metadata == null) return;

      final paymentType = metadata['type'] as String?;

      // Traiter le paiement via le service Stripe
      await StripeService.to.handleSuccessfulPayment(sessionDoc);

      // Afficher une notification selon le type
      switch (paymentType) {
        case 'cgu_validation':
          UniquesControllers().data.snackbar(
                'Paiement réussi !',
                'Votre accès professionnel a été activé. Vous pouvez maintenant utiliser toutes les fonctionnalités.',
                false,
              );

          // Rafraîchir la page/contrôleur si nécessaire
          _refreshCurrentController();
          break;

        case 'additional_category_slot':
          UniquesControllers().data.snackbar(
                'Slot ajouté !',
                'Votre nouveau slot de catégorie a été ajouté avec succès.',
                false,
              );

          _refreshCurrentController();
          break;
      }
    } catch (e) {
      print('Erreur lors du traitement du paiement réussi: $e');
    }
  }

  void _refreshCurrentController() {
    // Rafraîchir le contrôleur actuel selon la route
    final currentRoute = Get.currentRoute;

    if (currentRoute.contains('establishment-profile')) {
      // Rafraîchir le contrôleur d'établissement
      try {
        final controller = Get.find<ProEstablishmentProfileScreenController>();
        // Le StreamBuilder se rafraîchira automatiquement
      } catch (e) {
        // Le contrôleur n'est pas encore chargé
      }
    }
  }

  // Méthode pour vérifier manuellement un paiement
  Future<bool> checkPaymentStatus(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final sessionDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) return false;

      final sessionData = sessionDoc.data()!;
      return sessionData['payment_status'] == 'paid';
    } catch (e) {
      print('Erreur lors de la vérification du paiement: $e');
      return false;
    }
  }
}
