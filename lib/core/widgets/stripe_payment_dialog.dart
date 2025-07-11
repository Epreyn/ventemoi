// Créer un nouveau fichier : lib/core/widgets/stripe_payment_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../classes/unique_controllers.dart';
import '../models/payment_listener.dart';

class StripePaymentDialog {
  static void show({
    required String sessionId,
    required String title,
    String? subtitle,
    required Function() onSuccess,
    Function()? onCancel,
    Function(String error)? onError,
  }) {
    // Variables de contrôle
    StreamSubscription? subscription;
    Timer? timeoutTimer;
    Timer? pollingTimer;
    bool paymentProcessed = false;
    bool dialogClosed = false;

    // États observables
    final RxString debugStatus = 'Connexion à Stripe...'.obs;
    final RxBool isCheckingPayment = false.obs;
    final RxInt attemptCount = 0.obs;

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
              minHeight: 350,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation de chargement améliorée
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1 * value),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Transform.scale(
                          scale: value,
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                if (subtitle != null) ...[
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
                ],
                SizedBox(height: 16),
                Text(
                  'Veuillez finaliser votre paiement dans l\'onglet Stripe.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Cette fenêtre se fermera automatiquement.',
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
                        color:
                            _getStatusColor(debugStatus.value).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(debugStatus.value)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(debugStatus.value),
                            size: 16,
                            color: _getStatusColor(debugStatus.value),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              debugStatus.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(debugStatus.value),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 8),
                Obx(() => Text(
                      'Tentative ${attemptCount.value}/20',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    )),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        subscription?.cancel();
                        timeoutTimer?.cancel();
                        pollingTimer?.cancel();
                        dialogClosed = true;
                        Get.back();
                        onCancel?.call();
                        UniquesControllers().data.snackbar(
                              'Paiement annulé',
                              'Vous pourrez réessayer plus tard',
                              true,
                            );
                      },
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(width: 16),
                    TextButton(
                      onPressed: () async {
                        await _checkPaymentManually(
                          sessionId,
                          debugStatus,
                          onSuccess,
                          dialogClosed,
                        );
                      },
                      child: Text(
                        'Vérifier',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Démarrer l'écoute du paiement
    _startPaymentListening(
      sessionId: sessionId,
      subscription: subscription,
      timeoutTimer: timeoutTimer,
      pollingTimer: pollingTimer,
      paymentProcessed: paymentProcessed,
      dialogClosed: dialogClosed,
      debugStatus: debugStatus,
      isCheckingPayment: isCheckingPayment,
      attemptCount: attemptCount,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  static Color _getStatusColor(String status) {
    if (status.contains('✅')) return Colors.green;
    if (status.contains('❌')) return Colors.red;
    if (status.contains('⚠️')) return Colors.orange;
    return Colors.grey;
  }

  static IconData _getStatusIcon(String status) {
    if (status.contains('✅')) return Icons.check_circle;
    if (status.contains('❌')) return Icons.cancel;
    if (status.contains('⚠️')) return Icons.warning;
    return Icons.info_outline;
  }

  static Future<void> _checkPaymentManually(
    String sessionId,
    RxString debugStatus,
    Function() onSuccess,
    bool dialogClosed,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugStatus.value = '🔍 Vérification manuelle...';

    try {
      final sessionDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final data = sessionDoc.data()!;
        print('📋 Vérification manuelle - Données complètes:');
        data.forEach((key, value) {
          if (value != null) print('   - $key: $value');
        });

        if (_isPaymentSuccessful(data)) {
          debugStatus.value = '✅ Paiement confirmé!';
          await Future.delayed(Duration(seconds: 1));
          if (!dialogClosed) {
            Get.back();
            onSuccess();
          }
        } else {
          debugStatus.value = '⚠️ Paiement non confirmé';
        }
      } else {
        debugStatus.value = '❌ Session introuvable';
      }
    } catch (e) {
      debugStatus.value = '❌ Erreur: ${e.toString()}';
      print('❌ Erreur vérification manuelle: $e');
    }
  }

  static void _startPaymentListening({
    required String sessionId,
    StreamSubscription? subscription,
    Timer? timeoutTimer,
    Timer? pollingTimer,
    required bool paymentProcessed,
    required bool dialogClosed,
    required RxString debugStatus,
    required RxBool isCheckingPayment,
    required RxInt attemptCount,
    required Function() onSuccess,
    Function(String error)? onError,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.back();
      onError?.call('Utilisateur non connecté');
      return;
    }

    print('🔍 Démarrage écoute session: $sessionId');

    // Timeout de 5 minutes
    timeoutTimer = Timer(Duration(minutes: 5), () {
      if (!paymentProcessed && !dialogClosed) {
        subscription?.cancel();
        pollingTimer?.cancel();
        Get.back();
        onError?.call('Délai de paiement expiré');
        UniquesControllers().data.snackbar(
              'Temps écoulé',
              'Le délai de paiement a expiré. Veuillez réessayer.',
              true,
            );
      }
    });

    // Modifier la partie d'écoute dans _startPaymentListening
    subscription = FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .collection('checkout_sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists && !paymentProcessed && !dialogClosed) {
        final data = snapshot.data()!;
        attemptCount.value++;

        print('📘 Session mise à jour (tentative ${attemptCount.value}):');

        // Logger TOUS les champs qui changent
        data.forEach((key, value) {
          if (value != null && key != 'metadata' && key != 'line_items') {
            print('   - $key: $value');
          }
        });

        // Vérifier différents champs possibles
        final paymentStatus = data['payment_status'] as String?;
        final status = data['status'] as String?;
        final paymentIntent = data['payment_intent'] as String?;
        final amountTotal = data['amount_total'] as int?;
        final paymentSucceeded = data['payment_succeeded'] as bool?;

        // Mettre à jour le statut avec plus de détails
        if (paymentIntent != null) {
          debugStatus.value = 'Payment Intent créé';
        } else if (amountTotal != null) {
          debugStatus.value =
              'Montant: ${(amountTotal / 100).toStringAsFixed(2)}€';
        } else {
          debugStatus.value =
              'Statut: ${paymentStatus ?? status ?? 'en attente'}';
        }

        // Conditions de succès élargies
        if (paymentStatus == 'paid' ||
            paymentStatus == 'succeeded' ||
            status == 'complete' ||
            status == 'paid' ||
            paymentSucceeded == true ||
            (paymentIntent != null && amountTotal != null && amountTotal > 0)) {
          paymentProcessed = true;
          debugStatus.value = '✅ Paiement confirmé!';
          print('✅ Paiement réussi détecté!');

          await Future.delayed(Duration(milliseconds: 500));

          subscription?.cancel();
          timeoutTimer?.cancel();
          pollingTimer?.cancel();

          if (!dialogClosed) {
            Get.back();
            onSuccess();
          }
        }

        // Vérifier l'annulation ou l'expiration
        if (status == 'expired' ||
            status == 'canceled' ||
            status == 'cancelled' ||
            data['error'] != null) {
          debugStatus.value = '❌ Paiement échoué';
          final error = data['error'];
          if (error != null) {
            print('❌ Erreur: $error');
          }

          subscription?.cancel();
          timeoutTimer?.cancel();
          pollingTimer?.cancel();

          if (!dialogClosed) {
            Get.back();
            onError?.call('Paiement échoué');
          }
        }
      }
    });

    // Vérification active toutes les 2 secondes
    pollingTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!isCheckingPayment.value && !paymentProcessed && !dialogClosed) {
        isCheckingPayment.value = true;
        attemptCount.value++;

        try {
          final sessionDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(user.uid)
              .collection('checkout_sessions')
              .doc(sessionId)
              .get();

          if (sessionDoc.exists) {
            final data = sessionDoc.data()!;

            if (_isPaymentSuccessful(data)) {
              paymentProcessed = true;
              debugStatus.value = '✅ Paiement confirmé!';
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
          print('Erreur polling: $e');
        } finally {
          isCheckingPayment.value = false;
        }
      }
    });

    if (Get.isRegistered<PaymentListenerController>()) {
      final paymentListener = Get.find<PaymentListenerController>();

      // Écouter les changements du PaymentListener
      ever(paymentListener.slotPaymentDetected, (detected) {
        if (detected && !paymentProcessed && !dialogClosed) {
          print('💰 Paiement de slot détecté par PaymentListener!');

          paymentProcessed = true;
          debugStatus.value = '✅ Paiement confirmé!';

          subscription?.cancel();
          timeoutTimer?.cancel();
          pollingTimer?.cancel();

          if (!dialogClosed) {
            Get.back();
            onSuccess();

            // Réinitialiser le flag
            paymentListener.slotPaymentDetected.value = false;
          }
        }
      });
    }
  }

  // Méthode unifiée pour vérifier le succès
  static bool _isPaymentSuccessful(Map<String, dynamic> data) {
    final paymentStatus = data['payment_status'] as String?;
    final status = data['status'] as String?;
    final mode = data['mode'] as String?;

    // Pour les paiements simples
    if (mode == 'payment') {
      return paymentStatus == 'paid' ||
          paymentStatus == 'succeeded' ||
          status == 'complete' ||
          status == 'paid';
    }

    // Pour les subscriptions
    if (mode == 'subscription') {
      final subscription = data['subscription'] as String?;
      return (paymentStatus == 'paid' || status == 'complete') &&
          subscription != null;
    }

    // Fallback
    return paymentStatus == 'paid' || paymentStatus == 'succeeded';
  }

  // Vérifier si le paiement est annulé
  static bool _isPaymentCancelled(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    return status == 'expired' || status == 'canceled' || status == 'cancelled';
  }
}
