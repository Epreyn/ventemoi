import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

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

      final purchaseType = metadata['purchase_type'] as String?;
      final paymentType = metadata['type'] as String?;

      // Traiter le paiement via le service Stripe
      await StripeService.to.handleSuccessfulPayment(sessionDoc);

      // Afficher une notification selon le type
      if (purchaseType == 'first_year_annual') {
        UniquesControllers().data.snackbar(
              'Paiement réussi !',
              'Votre abonnement annuel est activé. Un bon cadeau de 50€ vous a été attribué.',
              false,
            );
        _refreshCurrentController();
      } else if (purchaseType == 'first_year_monthly') {
        UniquesControllers().data.snackbar(
              'Paiement réussi !',
              'Votre abonnement mensuel est activé. Un bon cadeau de 50€ vous a été attribué.',
              false,
            );
        _refreshCurrentController();
      } else if (paymentType == 'additional_category_slot') {
        UniquesControllers().data.snackbar(
              'Slot ajouté !',
              'Votre nouveau slot de catégorie a été ajouté avec succès.',
              false,
            );
        _refreshCurrentController();
      }
    } catch (e) {
      print('Erreur lors du traitement du paiement réussi: $e');
    }
  }

  void _refreshCurrentController() {
    // Rafraîchir le contrôleur actuel selon la route
    final currentRoute = Get.currentRoute;

    if (currentRoute.contains('establishment-profile')) {
      try {
        final controller = Get.find<ProEstablishmentProfileScreenController>();

        // Forcer le rechargement des données
        controller.establishmentDocId = null;

        // Afficher un message personnalisé avec animation
        Get.dialog(
          Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Félicitations !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Votre établissement est maintenant actif',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🎁 Bon cadeau de 50€ attribué',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Continuer',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );

        // Fermer automatiquement après 3 secondes
        Future.delayed(Duration(seconds: 3), () {
          if (Get.isDialogOpen!) Get.back();
        });
      } catch (e) {
        print('Controller non trouvé: $e');
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
