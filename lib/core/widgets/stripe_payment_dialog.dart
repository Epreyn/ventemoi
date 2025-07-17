// lib/core/widgets/stripe_payment_dialog.dart
// Version simplifiée et corrigée

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
import '../models/stripe_service.dart';

class StripePaymentDialog {
  static bool _isProcessing = false; // Guard contre les doublons
  static bool _isListeningToMessages = false;
  static StreamSubscription? _messageSubscription;
  static Timer? _localStorageTimer;

  static void show({
    required String sessionId,
    required String title,
    String? subtitle,
    required Function() onSuccess,
    Function(String)? onError,
    bool enablePolling = true,
    Duration pollingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
    Map<String, dynamic>? metadata,
  }) {
    // Éviter les doublons
    if (_isProcessing) {
      print('⚠️ Paiement déjà en cours, ignoré');
      return;
    }
    _isProcessing = true;

    // Variables d'état locales
    bool paymentProcessed = false;
    bool dialogClosed = false;

    // Variables observables pour l'UI
    final RxBool isCheckingPayment = false.obs;
    final RxInt attemptCount = 0.obs;
    final RxString debugStatus = 'Initialisation...'.obs;
    final RxInt consecutiveSuccessChecks = 0.obs;

    // Timers et subscriptions
    Timer? pollingTimer;
    Timer? timeoutTimer;
    StreamSubscription? firestoreSubscription;

    // Fonction de nettoyage
    void cleanup() {
      pollingTimer?.cancel();
      timeoutTimer?.cancel();
      firestoreSubscription?.cancel();
      _stopListeningToHtmlMessages();
      _isProcessing = false;
      dialogClosed = true;
    }

    // Callback de succès
    void handleSuccess() {
      if (!paymentProcessed && !dialogClosed) {
        paymentProcessed = true;
        cleanup();
        Get.back();
        onSuccess();
      }
    }

    // Callback d'erreur
    void handleError(String error) {
      if (!dialogClosed) {
        cleanup();
        Get.back();
        onError?.call(error);
      }
    }

    // Afficher la dialog
    Get.dialog(
      WillPopScope(
        onWillPop: () async {
          cleanup();
          return true;
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de chargement
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),

                // Titre
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),

                // Status
                Obx(() => Text(
                      debugStatus.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    )),
                const SizedBox(height: 8),

                // Compteur de tentatives
                Obx(() => Text(
                      'Vérification ${attemptCount.value > 0 ? "(${attemptCount.value})" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    )),
                const SizedBox(height: 20),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Complétez votre paiement dans l\'onglet Stripe',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bouton d'annulation
                TextButton(
                  onPressed: () {
                    handleError('Paiement annulé par l\'utilisateur');
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ).whenComplete(() {
      cleanup();
    });

    // Démarrer les vérifications
    _startAllVerifications(
      sessionId: sessionId,
      handleSuccess: handleSuccess,
      handleError: handleError,
      enablePolling: enablePolling,
      pollingInterval: pollingInterval,
      timeout: timeout,
      isCheckingPayment: isCheckingPayment,
      attemptCount: attemptCount,
      debugStatus: debugStatus,
      consecutiveSuccessChecks: consecutiveSuccessChecks,
      paymentProcessed: () => paymentProcessed,
      dialogClosed: () => dialogClosed,
      setPollingTimer: (timer) => pollingTimer = timer,
      setTimeoutTimer: (timer) => timeoutTimer = timer,
      setFirestoreSubscription: (sub) => firestoreSubscription = sub,
    );
  }

  // Méthode qui gère toutes les vérifications
  static void _startAllVerifications({
    required String sessionId,
    required Function() handleSuccess,
    required Function(String) handleError,
    required bool enablePolling,
    required Duration pollingInterval,
    required Duration timeout,
    required RxBool isCheckingPayment,
    required RxInt attemptCount,
    required RxString debugStatus,
    required RxInt consecutiveSuccessChecks,
    required bool Function() paymentProcessed,
    required bool Function() dialogClosed,
    required Function(Timer?) setPollingTimer,
    required Function(Timer?) setTimeoutTimer,
    required Function(StreamSubscription?) setFirestoreSubscription,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      handleError('Utilisateur non connecté');
      return;
    }

    debugStatus.value = 'Configuration de l\'écoute...';

    // 1. Écouter les changements Firestore en temps réel
    final firestoreSubscription = FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .collection('checkout_sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      print(
          '📊 Firestore update: payment_status=${data['payment_status']}, status=${data['status']}');

      // Vérifier le succès
      if (_isPaymentSuccessful(data) && !paymentProcessed()) {
        debugStatus.value = '✅ Paiement confirmé !';
        handleSuccess();
      }

      // Vérifier les erreurs
      if (data.containsKey('error') && data['error'] != null) {
        final error = data['error'];
        debugStatus.value = '❌ Erreur: ${error['message'] ?? error}';
        handleError('Erreur: ${error['message'] ?? error}');
      }
    });
    setFirestoreSubscription(firestoreSubscription);

    // 2. Écouter les messages web (pour le retour des pages HTML)
    if (kIsWeb) {
      _startListeningToHtmlMessages(
        sessionId: sessionId,
        onSuccess: () {
          if (!paymentProcessed()) {
            debugStatus.value = '✅ Paiement confirmé (via page web) !';
            handleSuccess();
          }
        },
        onCancel: () {
          if (!paymentProcessed() && !dialogClosed()) {
            handleError('Paiement annulé');
          }
        },
      );
    }

    // 3. Polling actif si activé
    if (enablePolling) {
      debugStatus.value = 'Vérification du paiement...';

      final pollingTimer = Timer.periodic(pollingInterval, (timer) async {
        if (!isCheckingPayment.value &&
            !paymentProcessed() &&
            !dialogClosed()) {
          isCheckingPayment.value = true;
          attemptCount.value++;

          try {
            // Vérifier directement dans Firestore
            final sessionDoc = await FirebaseFirestore.instance
                .collection('customers')
                .doc(user.uid)
                .collection('checkout_sessions')
                .doc(sessionId)
                .get();

            if (sessionDoc.exists) {
              final data = sessionDoc.data()!;

              if (_isPaymentSuccessful(data)) {
                consecutiveSuccessChecks.value++;
                debugStatus.value =
                    'Paiement détecté (${consecutiveSuccessChecks.value}/2)...';

                // Confirmer avec 2 vérifications consécutives
                if (consecutiveSuccessChecks.value >= 2) {
                  debugStatus.value = '✅ Paiement confirmé !';
                  timer.cancel();
                  handleSuccess();
                }
              } else {
                consecutiveSuccessChecks.value = 0;
              }
            }

            // Vérifier aussi l'établissement directement
            final estabQuery = await FirebaseFirestore.instance
                .collection('establishments')
                .where('user_id', isEqualTo: user.uid)
                .limit(1)
                .get();

            if (estabQuery.docs.isNotEmpty) {
              final estabData = estabQuery.docs.first.data();
              final hasActiveSubscription =
                  estabData['has_active_subscription'] ?? false;

              if (hasActiveSubscription && !paymentProcessed()) {
                print('✅ Abonnement actif détecté dans l\'établissement');
                debugStatus.value = '✅ Paiement confirmé (via établissement) !';
                timer.cancel();
                handleSuccess();
              }
            }
          } catch (e) {
            print('Erreur vérification: $e');
            consecutiveSuccessChecks.value = 0;
          } finally {
            isCheckingPayment.value = false;
          }
        }
      });
      setPollingTimer(pollingTimer);
    }

    // 4. Timeout
    final timeoutTimer = Timer(timeout, () {
      if (!paymentProcessed() && !dialogClosed()) {
        debugStatus.value = '⏱️ Délai dépassé';
        handleError(
            'Délai de vérification dépassé. Veuillez vérifier votre paiement.');
      }
    });
    setTimeoutTimer(timeoutTimer);
  }

  // Méthodes d'écoute pour le web
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
            html.window.localStorage.remove('stripe_payment_status');
            onSuccess();
          } else if (messageData['type'] == 'stripe-payment-cancelled') {
            print('❌ Message d\'annulation reçu de la page Stripe!');
            html.window.localStorage.remove('stripe_payment_status');
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
}
