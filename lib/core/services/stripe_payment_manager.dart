// Créer un nouveau fichier : lib/core/services/stripe_payment_manager.dart

import 'package:get/get.dart';
import '../models/stripe_service.dart';
import '../widgets/stripe_payment_dialog.dart';
import '../classes/unique_controllers.dart';

class StripePaymentManager extends GetxService {
  static StripePaymentManager get to => Get.find();

  // Paiement d'abonnement (mensuel ou annuel)
  Future<void> processSubscriptionPayment({
    required String userType,
    required String paymentOption, // 'monthly' ou 'annual'
    required Function() onSuccess,
  }) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      Map<String, String>? result;

      if (paymentOption == 'annual') {
        result = await StripeService.to.createAnnualOptionCheckoutWithId(
          userType: userType,
          successUrl: 'https://app.ventemoi.fr/stripe-success.html',
          cancelUrl: 'https://app.ventemoi.fr/stripe-cancel.html',
        );
      } else {
        result = await StripeService.to.createMonthlyOptionCheckoutWithId(
          userType: userType,
          successUrl: 'https://app.ventemoi.fr/stripe-success.html',
          cancelUrl: 'https://app.ventemoi.fr/stripe-cancel.html',
        );
      }

      if (result != null &&
          result['url'] != null &&
          result['sessionId'] != null) {
        // Afficher la dialog d'attente
        StripePaymentDialog.show(
          sessionId: result['sessionId']!,
          title: 'Traitement du paiement',
          subtitle: paymentOption == 'annual'
              ? 'Abonnement annuel'
              : 'Abonnement mensuel',
          onSuccess: onSuccess,
          onError: (error) {
            UniquesControllers().data.snackbar(
                  'Erreur',
                  error,
                  true,
                );
          },
        );

        // Attendre que la dialog soit affichée
        await Future.delayed(Duration(milliseconds: 300));

        // Ouvrir Stripe
        await StripeService.to.launchCheckout(result['url']!);
      } else {
        throw 'Impossible de créer la session de paiement';
      }
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

  // Paiement de slot additionnel
  Future<void> processSlotPayment({
    required Function() onSuccess,
  }) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      final result = await StripeService.to.createAdditionalSlotCheckoutWithId(
        successUrl: 'https://app.ventemoi.fr/stripe-success.html',
        cancelUrl: 'https://app.ventemoi.fr/stripe-cancel.html',
      );

      if (result != null &&
          result['url'] != null &&
          result['sessionId'] != null) {
        StripePaymentDialog.show(
          sessionId: result['sessionId']!,
          title: 'Achat de slot',
          subtitle: 'Catégorie supplémentaire',
          onSuccess: onSuccess,
          onError: (error) {
            UniquesControllers().data.snackbar(
                  'Erreur',
                  error,
                  true,
                );
          },
        );

        await Future.delayed(Duration(milliseconds: 300));
        await StripeService.to.launchCheckout(result['url']!);
      } else {
        throw 'Impossible de créer la session de paiement';
      }
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Erreur lors de l\'achat: $e',
            true,
          );
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }
}
