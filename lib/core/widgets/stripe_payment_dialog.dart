// lib/core/widgets/stripe_payment_dialog.dart

import 'dart:async';
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../classes/unique_controllers.dart';

class StripePaymentDialog {
  static bool _isListeningToMessages = false;
  static StreamSubscription? _messageSubscription;
  static Timer? _localStorageTimer;

  static void show({
    required String sessionId,
    required String title,
    required String subtitle,
    required Function() onSuccess,
    Function(String)? onError,
    bool enablePolling = true,
    Duration pollingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
    Map<String, dynamic>? metadata,
  }) {
    // Variables pour gérer les subscriptions
    StreamSubscription? subscription;
    Timer? timeoutTimer;
    Timer? pollingTimer;

    // Contrôles pour éviter les déclenchements multiples
    bool paymentProcessed = false;
    bool dialogClosed = false;

    // États de debug
    final RxString debugStatus = 'Initialisation...'.obs;
    final RxBool isCheckingPayment = false.obs;
    final RxInt attemptCount = 0.obs;

    // Commencer à écouter les messages des pages HTML
    _startListeningToHtmlMessages(
      sessionId: sessionId,
      onSuccess: () {
        if (!paymentProcessed && !dialogClosed) {
          paymentProcessed = true;
          subscription?.cancel();
          pollingTimer?.cancel();
          timeoutTimer?.cancel();
          Get.back();
          onSuccess();
        }
      },
      onCancel: () {
        if (!dialogClosed) {
          subscription?.cancel();
          pollingTimer?.cancel();
          timeoutTimer?.cancel();
          Get.back();
          onError?.call('Paiement annulé');
        }
      },
    );

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
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Veuillez finaliser votre paiement dans l\'onglet Stripe qui s\'est ouvert.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Cette fenêtre se fermera automatiquement une fois le paiement confirmé.',
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
                      child: Column(
                        children: [
                          Row(
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
                          if (attemptCount.value > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Tentative ${attemptCount.value}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    subscription?.cancel();
                    pollingTimer?.cancel();
                    timeoutTimer?.cancel();
                    dialogClosed = true;
                    Get.back();
                    onError?.call('Paiement annulé par l\'utilisateur');
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
    ).then((_) {
      dialogClosed = true;
      subscription?.cancel();
      timeoutTimer?.cancel();
      pollingTimer?.cancel();
      _stopListeningToHtmlMessages();
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugStatus.value = 'Connexion à Stripe...';

      // Timeout global
      timeoutTimer = Timer(timeout, () {
        if (!paymentProcessed && !dialogClosed) {
          subscription?.cancel();
          pollingTimer?.cancel();
          Get.back();
          onError?.call('Le délai de paiement a expiré. Veuillez réessayer.');
        }
      });

      // 1. Écouter les changements en temps réel dans Firestore
      subscription = FirebaseFirestore.instance
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

          // Vérifier le succès avec plusieurs indicateurs
          if (_isPaymentSuccessful(data)) {
            paymentProcessed = true;
            debugStatus.value = '✅ Paiement confirmé!';

            print('✅ Paiement réussi détecté par listener!');

            await Future.delayed(Duration(seconds: 1));

            subscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            if (!dialogClosed) {
              Get.back();
              onSuccess();
            }
          }

          // Vérifier si c'est une annulation
          if (_isPaymentCancelled(data)) {
            debugStatus.value = '❌ Paiement annulé';
            print('❌ Paiement annulé ou expiré');

            subscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            if (!dialogClosed) {
              Get.back();
              onError?.call('Le paiement a été annulé ou a expiré');
            }
          }

          // Gérer les erreurs
          if (data['error'] != null) {
            final error = data['error'];
            debugStatus.value = '❌ Erreur: ${error['message'] ?? error}';
            print('❌ Erreur Stripe: $error');

            subscription?.cancel();
            timeoutTimer?.cancel();
            pollingTimer?.cancel();

            if (!dialogClosed) {
              Get.back();
              onError?.call('Erreur: ${error['message'] ?? error}');
            }
          }
        }
      });

      // 2. Polling si activé
      if (enablePolling) {
        pollingTimer = Timer.periodic(pollingInterval, (timer) async {
          if (!isCheckingPayment.value && !paymentProcessed && !dialogClosed) {
            isCheckingPayment.value = true;
            attemptCount.value++;

            try {
              debugStatus.value = 'Vérification en cours...';

              // Vérifier la session
              final sessionDoc = await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(user.uid)
                  .collection('checkout_sessions')
                  .doc(sessionId)
                  .get();

              if (sessionDoc.exists &&
                  _isPaymentSuccessful(sessionDoc.data()!)) {
                paymentProcessed = true;
                debugStatus.value = '✅ Paiement confirmé par polling!';
                timer.cancel();

                subscription?.cancel();
                timeoutTimer?.cancel();

                if (!dialogClosed) {
                  Get.back();
                  onSuccess();
                }
              }

              // Vérifier aussi directement l'établissement
              final estabQuery = await FirebaseFirestore.instance
                  .collection('establishments')
                  .where('user_id', isEqualTo: user.uid)
                  .limit(1)
                  .get();

              if (estabQuery.docs.isNotEmpty) {
                final estabData = estabQuery.docs.first.data();
                final hasActiveSubscription =
                    estabData['has_active_subscription'] ?? false;

                if (hasActiveSubscription && !paymentProcessed) {
                  print('✅ Abonnement actif détecté dans l\'établissement');
                  paymentProcessed = true;
                  timer.cancel();

                  subscription?.cancel();
                  timeoutTimer?.cancel();

                  if (!dialogClosed) {
                    Get.back();
                    onSuccess();
                  }
                }
              }
            } catch (e) {
              print('Erreur vérification: $e');
            } finally {
              isCheckingPayment.value = false;
            }
          }
        });
      }
    }
  }

  // Écouter les messages postMessage depuis les pages HTML
  static void _startListeningToHtmlMessages({
    required String sessionId,
    required Function() onSuccess,
    required Function() onCancel,
  }) {
    if (!kIsWeb || _isListeningToMessages) return;

    _isListeningToMessages = true;

    // Écouter les messages postMessage
    _messageSubscription = html.window.onMessage.listen((event) {
      try {
        final data = event.data;

        if (data is Map || data is String) {
          Map<String, dynamic> messageData;

          if (data is String) {
            messageData = json.decode(data);
          } else {
            messageData = Map<String, dynamic>.from(data);
          }

          // Vérifier si c'est un message de nos pages Stripe
          if (messageData['type'] == 'stripe-payment-success') {
            print('✅ Message de succès reçu de la page Stripe!');
            onSuccess();
          } else if (messageData['type'] == 'stripe-payment-cancelled') {
            print('❌ Message d\'annulation reçu de la page Stripe!');
            onCancel();
          }
        }
      } catch (e) {
        print('Erreur parsing message: $e');
      }
    });

    // Écouter les changements de localStorage
    _localStorageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      try {
        final storageData = html.window.localStorage['stripe_payment_status'];

        if (storageData != null) {
          final data = json.decode(storageData);

          if (data['status'] == 'success') {
            print('✅ Succès détecté via localStorage!');
            html.window.localStorage.remove('stripe_payment_status');
            onSuccess();
          } else if (data['status'] == 'cancelled') {
            print('❌ Annulation détectée via localStorage!');
            html.window.localStorage.remove('stripe_payment_status');
            onCancel();
          }
        }
      } catch (e) {
        // Ignorer les erreurs
      }
    });
  }

  static void _stopListeningToHtmlMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _localStorageTimer?.cancel();
    _localStorageTimer = null;
    _isListeningToMessages = false;
  }

  // Méthode pour vérifier si le paiement est réussi
  static bool _isPaymentSuccessful(Map<String, dynamic> data) {
    final paymentStatus = data['payment_status'] as String?;
    final status = data['status'] as String?;
    final paymentIntent = data['payment_intent'] as String?;
    final subscription = data['subscription'] as String?;
    final invoice = data['invoice'] as String?;
    final amountTotal = data['amount_total'] as int?;

    final isPaid = (paymentStatus == 'paid' || paymentStatus == 'succeeded') ||
        (status == 'complete' || status == 'paid' || status == 'success') ||
        (paymentIntent != null || subscription != null || invoice != null);

    final hasAmount = amountTotal != null && amountTotal > 0;

    return isPaid && hasAmount;
  }

  // Vérifier si le paiement est annulé
  static bool _isPaymentCancelled(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    return status == 'expired' || status == 'canceled' || status == 'cancelled';
  }
}
