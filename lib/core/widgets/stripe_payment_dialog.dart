// lib/core/widgets/stripe_payment_dialog.dart
// Version corrigée qui gère les timestamps Unix

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
  static bool _isProcessing = false;
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
    Duration timeout = const Duration(minutes: 2),
    Map<String, dynamic>? metadata,
  }) {
    if (_isProcessing) {
      print('⚠️ Paiement déjà en cours, ignoré');
      return;
    }
    _isProcessing = true;

    bool paymentProcessed = false;
    bool dialogClosed = false;

    final RxBool isCheckingPayment = false.obs;
    final RxInt attemptCount = 0.obs;
    final RxString debugStatus = 'Initialisation...'.obs;

    Timer? pollingTimer;
    Timer? timeoutTimer;
    StreamSubscription? firestoreSubscription;

    void cleanup() {
      pollingTimer?.cancel();
      timeoutTimer?.cancel();
      firestoreSubscription?.cancel();
      _stopListeningToHtmlMessages();
      _isProcessing = false;
      dialogClosed = true;
    }

    void handleSuccess() {
      if (!paymentProcessed && !dialogClosed) {
        paymentProcessed = true;
        cleanup();
        Get.back();
        onSuccess();
      }
    }

    void handleError(String error) {
      if (!dialogClosed) {
        cleanup();
        Get.back();
        onError?.call(error);
      }
    }

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
                Obx(() => Text(
                      debugStatus.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    )),
                const SizedBox(height: 8),
                Obx(() => Text(
                      'Vérification ${attemptCount.value > 0 ? "(${attemptCount.value})" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    )),
                const SizedBox(height: 20),
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
      paymentProcessed: () => paymentProcessed,
      dialogClosed: () => dialogClosed,
      setPollingTimer: (timer) => pollingTimer = timer,
      setTimeoutTimer: (timer) => timeoutTimer = timer,
      setFirestoreSubscription: (sub) => firestoreSubscription = sub,
    );
  }

  // Helper pour convertir le timestamp en DateTime
  static DateTime? _getDateFromPayment(dynamic created) {
    if (created == null) return null;

    try {
      // Si c'est un Timestamp Firestore
      if (created is Timestamp) {
        return created.toDate();
      }

      // Si c'est un nombre (timestamp Unix en secondes)
      if (created is num) {
        return DateTime.fromMillisecondsSinceEpoch(created.toInt() * 1000);
      }

      // Si c'est déjà une DateTime
      if (created is DateTime) {
        return created;
      }

      return null;
    } catch (e) {
      print('Erreur conversion date: $e');
      return null;
    }
  }

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

    // 1. Écouter les changements dans payments en temps réel
    final paymentsSubscription = FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .collection('payments')
        .orderBy('created', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final paymentDoc = snapshot.docs.first;
        final data = paymentDoc.data();

        // Utiliser la méthode helper pour gérer différents formats
        final created = _getDateFromPayment(data['created']);

        if (created != null &&
            DateTime.now().difference(created).inMinutes < 5 &&
            data['status'] == 'succeeded' &&
            !paymentProcessed()) {
          print('✅ Paiement détecté via listener!');
          print('   ID: ${paymentDoc.id}');
          print('   Amount: ${data['amount']}');
          print('   Status: ${data['status']}');
          print('   Created: $created');

          debugStatus.value = '✅ Paiement confirmé !';
          handleSuccess();
        }
      }
    }, onError: (error) {
      print('Erreur listener payments: $error');
    });
    setFirestoreSubscription(paymentsSubscription);

    // 2. Écouter les messages web
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

    // 3. Polling actif
    if (enablePolling) {
      debugStatus.value = 'Vérification du paiement...';

      final pollingTimer = Timer.periodic(pollingInterval, (timer) async {
        if (!isCheckingPayment.value &&
            !paymentProcessed() &&
            !dialogClosed()) {
          isCheckingPayment.value = true;
          attemptCount.value++;

          try {
            // Vérifier dans la collection payments
            final paymentsQuery = await FirebaseFirestore.instance
                .collection('customers')
                .doc(user.uid)
                .collection('payments')
                .orderBy('created', descending: true)
                .limit(5)
                .get();

            for (var paymentDoc in paymentsQuery.docs) {
              final paymentData = paymentDoc.data();

              // Utiliser la méthode helper pour gérer différents formats
              final created = _getDateFromPayment(paymentData['created']);

              if (created != null &&
                  DateTime.now().difference(created).inMinutes < 5 &&
                  paymentData['status'] == 'succeeded') {
                print('✅ Paiement trouvé dans payments !');
                print('   ID: ${paymentDoc.id}');
                print('   Amount: ${paymentData['amount']}');
                print('   Status: ${paymentData['status']}');
                print('   Created: $created');

                // Vérifier le montant ou les metadata
                final amount = paymentData['amount'];
                final metadata =
                    paymentData['metadata'] as Map<String, dynamic>?;

                // Si c'est probablement notre paiement
                if (amount == 5000 || // 50€ en centimes
                    (metadata != null &&
                        (metadata['user_id'] == user.uid ||
                            metadata['purchase_type'] == 'category_slot'))) {
                  debugStatus.value = '✅ Paiement confirmé !';
                  timer.cancel();
                  handleSuccess();
                  return;
                }
              }
            }

            // Log périodique
            if (attemptCount.value % 5 == 0) {
              print(
                  '🔍 Tentative ${attemptCount.value} - Pas de paiement récent trouvé');
              debugStatus.value =
                  'Vérification en cours... (${attemptCount.value})';
            }

            // Après 10 tentatives, vérifier l'établissement
            if (attemptCount.value == 10) {
              debugStatus.value = 'Vérification alternative...';

              final estabQuery = await FirebaseFirestore.instance
                  .collection('establishments')
                  .where('user_id', isEqualTo: user.uid)
                  .limit(1)
                  .get();

              if (estabQuery.docs.isNotEmpty) {
                final hasActiveSubscription =
                    estabQuery.docs.first.data()['has_active_subscription'] ??
                        false;

                if (hasActiveSubscription) {
                  print('✅ Abonnement actif détecté dans l\'établissement!');
                  debugStatus.value = '✅ Paiement confirmé !';
                  timer.cancel();
                  handleSuccess();
                  return;
                }
              }
            }
          } catch (e) {
            print('❌ Erreur vérification: $e');
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

  static void _startListeningToHtmlMessages({
    required String sessionId,
    required Function() onSuccess,
    required Function() onCancel,
  }) {
    if (!kIsWeb || _isListeningToMessages) return;

    _isListeningToMessages = true;

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

    if (kIsWeb) {
      try {
        final channel = html.BroadcastChannel('stripe_payment_status');
        channel.onMessage.listen((event) {
          try {
            final data = event.data;
            if (data is Map || data is String) {
              Map<String, dynamic> messageData;

              if (data is String) {
                messageData = json.decode(data);
              } else {
                messageData = Map<String, dynamic>.from(data);
              }

              if (messageData['type'] == 'stripe-payment-success') {
                print('✅ Succès reçu via BroadcastChannel!');
                onSuccess();
              } else if (messageData['type'] == 'stripe-payment-cancelled') {
                print('❌ Annulation reçue via BroadcastChannel!');
                onCancel();
              }
            }
          } catch (e) {
            print('Erreur BroadcastChannel: $e');
          }
        });
      } catch (e) {
        print('BroadcastChannel non supporté');
      }
    }
  }

  static void _stopListeningToHtmlMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _localStorageTimer?.cancel();
    _localStorageTimer = null;
    _isListeningToMessages = false;
  }
}
