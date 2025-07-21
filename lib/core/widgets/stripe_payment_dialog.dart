import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import conditionnel pour web
import 'stripe_payment_dialog_web.dart'
    if (dart.library.io) 'stripe_payment_dialog_stub.dart';

class StripePaymentDialog {
  static RxBool paymentProcessed = false.obs;
  static RxBool dialogClosed = false.obs;
  static RxString debugStatus = ''.obs;
  static RxBool isCheckingPayment = false.obs;
  static RxInt attemptCount = 0.obs;

  // Stockage des timers et subscriptions pour cleanup
  static Timer? _pollingTimer;
  static Timer? _timeoutTimer;
  static StreamSubscription? _firestoreSubscription;
  static StreamSubscription? _messageSubscription;
  static Timer? _localStorageTimer;
  static bool _isListeningToMessages = false;

  // Stocker le dernier paiement traité pour éviter les doublons
  static String? _lastProcessedPaymentId;
  static DateTime? _lastProcessedPaymentTime;

  static void show({
    required String sessionId,
    required String title,
    required String subtitle,
    required Function() onSuccess,
    required Function(String) onError,
    bool enablePolling = true,
    Duration pollingInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
    Map<String, dynamic>? metadata,
  }) {
    // Reset des variables
    paymentProcessed.value = false;
    dialogClosed.value = false;
    debugStatus.value = '';
    isCheckingPayment.value = false;
    attemptCount.value = 0;

    // Cleanup des anciens listeners
    _cleanup();

    Get.dialog(
      WillPopScope(
        onWillPop: () async {
          dialogClosed.value = true;
          _cleanup();
          return true;
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Veuillez compléter le paiement dans la fenêtre Stripe',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                if (kDebugMode) ...[
                  SizedBox(height: 16),
                  Obx(() => Text(
                        debugStatus.value,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      )),
                ],
                SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    dialogClosed.value = true;
                    Get.back();
                    _cleanup();
                    onError('Paiement annulé');
                  },
                  child: Text('Annuler'),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    _startPaymentVerification(
      sessionId: sessionId,
      onSuccess: () {
        if (!paymentProcessed.value && !dialogClosed.value) {
          paymentProcessed.value = true;
          Get.back();
          _cleanup();
          onSuccess();
        }
      },
      onError: (error) {
        if (!dialogClosed.value) {
          Get.back();
          _cleanup();
          onError(error);
        }
      },
      enablePolling: enablePolling,
      pollingInterval: pollingInterval,
      timeout: timeout,
      metadata: metadata,
    );
  }

  static void _cleanup() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _stopListeningToHtmlMessages();
  }

  static void _stopListeningToHtmlMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _localStorageTimer?.cancel();
    _localStorageTimer = null;
    _isListeningToMessages = false;
  }

  static DateTime? _getDateFromPayment(dynamic created) {
    if (created == null) return null;

    if (created is Timestamp) {
      return created.toDate();
    } else if (created is int) {
      return DateTime.fromMillisecondsSinceEpoch(created * 1000);
    } else if (created is String) {
      try {
        return DateTime.parse(created);
      } catch (e) {
        print('Erreur parsing date: $e');
        return null;
      }
    }

    return null;
  }

  static void _startPaymentVerification({
    required String sessionId,
    required Function() onSuccess,
    required Function(String) onError,
    required bool enablePolling,
    required Duration pollingInterval,
    required Duration timeout,
    Map<String, dynamic>? metadata,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      onError('Utilisateur non connecté');
      return;
    }

    // 1. Écouter directement les changements dans la collection payments
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .collection('payments')
        .orderBy('created', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            !paymentProcessed.value) {
          final paymentData = change.doc.data();
          final created = _getDateFromPayment(paymentData?['created']);

          if (created != null &&
              DateTime.now().difference(created).inMinutes < 2 &&
              paymentData?['status'] == 'succeeded') {
            // Vérifier que ce n'est pas un ancien paiement déjà traité
            final paymentId = change.doc.id;
            if (_lastProcessedPaymentId == paymentId) {
              print('⏭️ Paiement $paymentId déjà traité, ignoré');
              continue;
            }

            print('✅ Nouveau paiement détecté via listener!');
            print('   ID: ${paymentId}');
            print('   Amount: ${paymentData?['amount']}');
            print('   Status: ${paymentData?['status']}');
            print('   Created: $created');

            _lastProcessedPaymentId = paymentId;
            _lastProcessedPaymentTime = created;

            debugStatus.value = '✅ Paiement confirmé !';
            onSuccess();
          }
        }
      }
    }, onError: (error) {
      print('Erreur listener payments: $error');
    });

    // 2. Écouter les messages web
    if (kIsWeb) {
      _startListeningToHtmlMessages(
        sessionId: sessionId,
        onSuccess: () {
          if (!paymentProcessed.value) {
            debugStatus.value = '✅ Paiement confirmé (via page web) !';
            onSuccess();
          }
        },
        onCancel: () {
          if (!paymentProcessed.value && !dialogClosed.value) {
            onError('Paiement annulé');
          }
        },
      );
    }

    // 3. Polling actif amélioré
    if (enablePolling) {
      debugStatus.value = 'Vérification du paiement...';

      _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
        if (!isCheckingPayment.value &&
            !paymentProcessed.value &&
            !dialogClosed.value) {
          isCheckingPayment.value = true;
          attemptCount.value++;

          try {
            // D'ABORD vérifier la session spécifique
            final sessionDoc = await FirebaseFirestore.instance
                .collection('customers')
                .doc(user.uid)
                .collection('checkout_sessions')
                .doc(sessionId)
                .get();

            if (sessionDoc.exists) {
              final sessionData = sessionDoc.data()!;

              // Vérifier le statut de paiement de la session
              final paymentStatus = sessionData['payment_status'] as String?;
              if (paymentStatus == 'paid' || paymentStatus == 'succeeded') {
                print('✅ Session $sessionId marquée comme payée!');
                debugStatus.value = '✅ Paiement confirmé !';
                timer.cancel();
                onSuccess();
                return;
              }

              // Si la session a un payment_intent
              final paymentIntentId = sessionData['payment_intent'] as String?;
              if (paymentIntentId != null) {
                // Chercher CE paiement spécifique dans la collection payments
                final paymentsQuery = await FirebaseFirestore.instance
                    .collection('customers')
                    .doc(user.uid)
                    .collection('payments')
                    .where('id', isEqualTo: paymentIntentId)
                    .limit(1)
                    .get();

                if (paymentsQuery.docs.isNotEmpty) {
                  final paymentData = paymentsQuery.docs.first.data();
                  if (paymentData['status'] == 'succeeded') {
                    print(
                        '✅ Paiement spécifique trouvé pour session $sessionId!');
                    print('   Payment Intent: $paymentIntentId');
                    debugStatus.value = '✅ Paiement confirmé !';
                    timer.cancel();
                    onSuccess();
                    return;
                  }
                }
              }
            }

            // Log périodique
            if (attemptCount.value % 5 == 0) {
              print(
                  '🔍 Tentative ${attemptCount.value} - Pas de paiement trouvé pour session $sessionId');
              debugStatus.value =
                  'Vérification en cours... (${attemptCount.value})';
            }
          } catch (e) {
            print('❌ Erreur vérification: $e');
          } finally {
            isCheckingPayment.value = false;
          }
        }
      });
    }

    // 4. Timeout
    _timeoutTimer = Timer(timeout, () {
      if (!paymentProcessed.value && !dialogClosed.value) {
        debugStatus.value = '⏱️ Délai dépassé';
        onError(
            'Délai de vérification dépassé. Veuillez vérifier votre paiement.');
      }
    });
  }

  static void _startListeningToHtmlMessages({
    required String sessionId,
    required Function() onSuccess,
    required Function() onCancel,
  }) {
    if (!kIsWeb || _isListeningToMessages) return;

    _isListeningToMessages = true;

    StripePaymentDialogWeb.startListening(
      sessionId: sessionId,
      onSuccess: onSuccess,
      onCancel: onCancel,
    );
  }
}
