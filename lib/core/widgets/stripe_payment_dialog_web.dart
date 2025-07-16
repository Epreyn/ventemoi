// lib/core/widgets/stripe_payment_dialog_web.dart

import 'dart:async';
import 'dart:html' as html;
import 'dart:convert';

class StripePaymentDialogWeb {
  static bool _isListening = false;
  static StreamSubscription? _messageSubscription;
  static Timer? _localStorageTimer;

  static void startListening({
    required String sessionId,
    required Function() onSuccess,
    required Function() onCancel,
  }) {
    if (_isListening) return;

    _isListening = true;

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

  static void stopListening() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _localStorageTimer?.cancel();
    _localStorageTimer = null;
    _isListening = false;
  }
}
