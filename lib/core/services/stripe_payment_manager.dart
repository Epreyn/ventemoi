// lib/core/services/stripe_payment_manager.dart

import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stripe_service.dart';
import '../widgets/stripe_payment_dialog.dart';
import '../classes/unique_controllers.dart';

class StripePaymentManager extends GetxService {
  static StripePaymentManager get to => Get.find();

  // Paiement d'abonnement (mensuel, annuel, ou sponsor)
  Future<void> processSubscriptionPayment({
    required String userType,
    required String paymentOption, // 'monthly', 'annual', 'bronze' ou 'silver'
    required Function() onSuccess,
    Function(String)? onError,
    bool enablePolling = true,
    Duration pollingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      Map<String, String>? result;

      // Gérer les sponsors différemment
      if (userType == 'Sponsor') {
        // Récupérer l'ID de l'établissement pour les sponsors
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) throw Exception('Utilisateur non connecté');

        final estabQuery = await FirebaseFirestore.instance
            .collection('establishments')
            .where('user_id', isEqualTo: uid)
            .limit(1)
            .get();

        String establishmentId;
        if (estabQuery.docs.isNotEmpty) {
          establishmentId = estabQuery.docs.first.id;
        } else {
          // Créer un établissement temporaire pour le sponsor
          final estabDoc = await FirebaseFirestore.instance.collection('establishments').add({
            'user_id': uid,
            'user_type': 'Sponsor',
            'created_at': FieldValue.serverTimestamp(),
          });
          establishmentId = estabDoc.id;
        }

        if (paymentOption == 'silver') {
          result = await StripeService.to.createSponsorSilverCheckout(
            establishmentId: establishmentId,
          );
        } else {
          result = await StripeService.to.createSponsorBronzeCheckout(
            establishmentId: establishmentId,
          );
        }
      } else if (paymentOption == 'annual') {
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
        UniquesControllers().data.isInAsyncCall.value = false;

        // Afficher la dialog d'attente améliorée
        String subtitle;
        if (userType == 'Sponsor') {
          subtitle = paymentOption == 'silver' ? 'Sponsor Silver' : 'Sponsor Bronze';
        } else {
          subtitle = paymentOption == 'annual'
              ? 'Abonnement annuel'
              : 'Abonnement mensuel';
        }

        StripePaymentDialog.show(
          sessionId: result['sessionId']!,
          title: 'Traitement du paiement',
          subtitle: subtitle,
          onSuccess: onSuccess,
          onError: onError ??
              (error) {
                UniquesControllers().data.snackbar(
                      'Erreur',
                      error,
                      true,
                    );
              },
          enablePolling: enablePolling,
          pollingInterval: pollingInterval,
          timeout: timeout,
          metadata: {
            'userType': userType,
            'paymentOption': paymentOption,
          },
        );

        // Attendre que la dialog soit affichée
        await Future.delayed(Duration(milliseconds: 300));

        // Ouvrir Stripe dans un nouvel onglet
        await StripeService.to.launchCheckout(result['url']!);
      } else {
        throw 'Impossible de créer la session de paiement';
      }
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;

      if (onError != null) {
        onError('Erreur lors du paiement: $e');
      } else {
        UniquesControllers().data.snackbar(
              'Erreur',
              'Erreur lors du paiement: $e',
              true,
            );
      }
    }
  }

  // Paiement de bannière publicitaire
  Future<void> processBannerPayment({
    required String establishmentId,
    required DateTime startDate,
    required Function() onSuccess,
    Function(String)? onError,
    bool enablePolling = true,
    Duration pollingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      final result = await StripeService.to.createBandeauHebdoCheckout(
        establishmentId: establishmentId,
        startDate: startDate,
      );

      if (result != null &&
          result['url'] != null &&
          result['sessionId'] != null) {
        UniquesControllers().data.isInAsyncCall.value = false;

        // Afficher la dialog d'attente
        StripePaymentDialog.show(
          sessionId: result['sessionId']!,
          title: 'Traitement du paiement',
          subtitle: 'Bannière publicitaire - 7 jours',
          onSuccess: onSuccess,
          onError: onError ??
              (error) {
                UniquesControllers().data.snackbar(
                      'Erreur',
                      error,
                      true,
                    );
              },
          enablePolling: enablePolling,
          pollingInterval: pollingInterval,
          timeout: timeout,
          metadata: {
            'type': 'banner_ad',
            'establishmentId': establishmentId,
            'startDate': startDate.toIso8601String(),
          },
        );

        // Attendre que la dialog soit affichée
        await Future.delayed(Duration(milliseconds: 300));

        // Ouvrir Stripe dans un nouvel onglet
        await StripeService.to.launchCheckout(result['url']!);
      } else {
        throw 'Impossible de créer la session de paiement';
      }
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;

      if (onError != null) {
        onError('Erreur lors du paiement: $e');
      } else {
        UniquesControllers().data.snackbar(
              'Erreur',
              'Erreur lors du paiement: $e',
              true,
            );
      }
    }
  }

  // Paiement de slot additionnel
  Future<void> processSlotPayment({
    required Function() onSuccess,
    Function(String)? onError,
    bool enablePolling = true,
    Duration pollingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
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
        UniquesControllers().data.isInAsyncCall.value = false;

        StripePaymentDialog.show(
          sessionId: result['sessionId']!,
          title: 'Achat de slot',
          subtitle: 'Catégorie supplémentaire',
          onSuccess: onSuccess,
          onError: onError ??
              (error) {
                UniquesControllers().data.snackbar(
                      'Erreur',
                      error,
                      true,
                    );
              },
          enablePolling: enablePolling,
          pollingInterval: pollingInterval,
          timeout: timeout,
          metadata: {
            'purchaseType': 'category_slot',
          },
        );

        await Future.delayed(Duration(milliseconds: 300));
        await StripeService.to.launchCheckout(result['url']!);
      } else {
        throw 'Impossible de créer la session de paiement';
      }
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;

      if (onError != null) {
        onError('Erreur lors de l\'achat: $e');
      } else {
        UniquesControllers().data.snackbar(
              'Erreur',
              'Erreur lors de l\'achat: $e',
              true,
            );
      }
    }
  }

  // Méthode utilitaire pour débugger une session
  Future<void> debugSession(String sessionId) async {
    try {
      await StripeService.to.debugCheckoutSession(sessionId);
    } catch (e) {
    }
  }

  // Méthode pour vérifier manuellement le statut d'un paiement
  Future<bool> verifyPaymentStatus(String sessionId) async {
    try {
      return await StripeService.to.checkPaymentSuccess(sessionId);
    } catch (e) {
      return false;
    }
  }

  // Méthode pour forcer la mise à jour du statut
  Future<void> forceCheckSessionStatus(String sessionId) async {
    try {
      await StripeService.to.forceCheckSessionStatus(sessionId);
    } catch (e) {
    }
  }

  // Méthode pour vérifier via Cloud Function (optionnelle)
  Future<bool> verifyViaCloudFunction(String sessionId) async {
    try {
      return await StripeService.to.verifyPaymentViaCloudFunction(sessionId);
    } catch (e) {
      return false;
    }
  }
}
