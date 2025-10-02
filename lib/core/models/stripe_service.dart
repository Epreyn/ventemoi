import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../classes/unique_controllers.dart';
import '../constants/stripe_prices.dart';

class StripeService extends GetxService {
  static StripeService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Import des IDs depuis StripePrices
  static const String PRICE_ID_ADHESION = StripePrices.adhesionProPriceId;
  static const String PRICE_ID_MONTHLY_RECURRING = StripePrices.cotisationMensuellePriceId;
  static const String PRICE_ID_ANNUAL_RECURRING = StripePrices.cotisationAnnuellePriceId;
  static const String PRICE_ID_ADDITIONAL_SLOT = StripePrices.slotSupplementairePriceId;
  static const String PRICE_ID_VIDEO_STANDARD = StripePrices.videoStandardMembrePriceId;
  static const String PRICE_ID_VIDEO_PREMIUM = StripePrices.videoPremiumMembrePriceId;
  static const String PRICE_ID_VIDEO_SIGNATURE = StripePrices.videoSignatureMembrePriceId;

  // Modifier _ensureStripeCustomer pour utiliser la synchronisation
  Future<String> _ensureStripeCustomer() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    // Essayer de synchroniser avec Stripe
    final stripeId = await syncStripeCustomer();

    if (stripeId != null) {
      return user.uid; // On retourne l'UID Firebase, pas le stripeId
    }

    // Fallback : s'assurer que le document existe
    await _ensureCustomerDocument(user.uid, user.email!);

    return user.uid;
  }

  // Créer une session checkout SANS référencer un customer ID inexistant
  Future<String?> createMonthlyOptionCheckout({
    required String userType,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {

      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      // IMPORTANT : Utiliser customer_email au lieu d'un customer ID
      final checkoutData = {
        'mode': 'subscription',
        'customer_email': user.email,
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          // 1. Adhésion uniquement (la vidéo est offerte)
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Adhésion VenteMoi - Pack Première Année',
                'description': 'Accès à la plateforme + Vidéo standard OFFERTE',
              },
              'unit_amount': StripePrices.adhesionAmountTTC, // 324€ TTC (vidéo offerte)
            },
            'quantity': 1,
          },
          // 2. Abonnement mensuel récurrent
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Cotisation Mensuelle VenteMoi Pro',
                'description': 'Cotisation mensuelle incluant toutes les fonctionnalités',
              },
              'unit_amount': StripePrices.cotisationMensuelleAmountTTC, // 66€ TTC
              'recurring': {
                'interval': 'month',
              },
            },
            'quantity': 1,
          }
        ],
        'subscription_data': {
          'metadata': {
            'user_type': userType,
            'user_id': user.uid,
            'subscription_type': 'monthly_with_setup',
            'setup_fee_paid': 'true',
          },
        },
        'metadata': {
          'purchase_type': 'first_year_monthly',
          'user_type': userType,
          'user_id': user.uid,
          'includes_adhesion': 'true',
          'includes_video_free': 'standard', // Vidéo offerte
          'adhesion_amount': '324', // TTC
        },
        'allow_promotion_codes': true,
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      return await _waitForCheckoutUrl(user.uid, sessionRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Version avec ID - CORRIGÉE
  Future<Map<String, String>?> createMonthlyOptionCheckoutWithId({
    required String userType,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {

      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // S'assurer que le document customer existe
      await _ensureCustomerDocument(user.uid, user.email!);

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      // Pack première année mensuel = Adhésion + Vidéo + Abonnement mensuel
      final checkoutData = {
        'mode': 'subscription',
        'customer_email': user.email,
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          // 1. Adhésion uniquement (la vidéo est offerte)
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Adhésion VenteMoi - Pack Première Année',
                'description': 'Accès à la plateforme + Vidéo standard OFFERTE',
              },
              'unit_amount': StripePrices.adhesionAmountTTC, // 324€ TTC (vidéo offerte)
            },
            'quantity': 1,
          },
          // 2. Abonnement mensuel récurrent
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Cotisation Mensuelle VenteMoi Pro',
                'description': 'Cotisation mensuelle incluant toutes les fonctionnalités',
              },
              'unit_amount': StripePrices.cotisationMensuelleAmountTTC, // 66€ TTC
              'recurring': {
                'interval': 'month',
              },
            },
            'quantity': 1,
          }
        ],
        'subscription_data': {
          'metadata': {
            'user_type': userType,
            'user_id': user.uid,
            'subscription_type': 'monthly_with_setup',
          },
        },
        'metadata': {
          'purchase_type': 'first_year_monthly',
          'user_type': userType,
          'user_id': user.uid,
          'includes_adhesion': 'true',
          'includes_video_free': 'standard', // Vidéo offerte
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      final firestoreDocId = sessionRef.id;

      final url = await _waitForCheckoutUrl(user.uid, firestoreDocId);

      if (url != null) {
        return {
          'url': url,
          'sessionId': firestoreDocId,
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Créer une session de checkout pour l'option annuelle - CORRIGÉE
  Future<Map<String, String>?> createAnnualOptionCheckoutWithId({
    required String userType,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {

      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // S'assurer que le document customer existe
      await _ensureCustomerDocument(user.uid, user.email!);

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      // Pack première année = Adhésion + Cotisation annuelle (vidéo OFFERTE)
      final checkoutData = {
        'mode': 'payment',
        'customer_email': user.email,
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          // Pack complet première année en un seul paiement
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Pack Première Année VenteMoi - Formule Annuelle',
                'description': 'Adhésion + Cotisation annuelle + Vidéo standard OFFERTE',
              },
              'unit_amount': StripePrices.adhesionAmountTTC + StripePrices.cotisationAnnuelleAmountTTC, // 324€ + 720€ = 1044€ TTC
            },
            'quantity': 1,
          }
        ],
        'metadata': {
          'purchase_type': 'first_year_annual_pack',
          'user_type': userType,
          'user_id': user.uid,
          'includes_adhesion': 'true',
          'includes_video_free': 'standard', // Vidéo offerte
          'includes_annual_subscription': 'true',
          'total_ht': '870', // 270 + 600 (vidéo offerte)
          'total_ttc': '1044', // 870 * 1.2
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      final sessionId = sessionRef.id;

      final url = await _waitForCheckoutUrl(user.uid, sessionId);

      if (url != null) {
        return {
          'url': url,
          'sessionId': sessionId,
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Créer une session de checkout pour un slot additionnel - CORRIGÉE
  Future<Map<String, String>?> createAdditionalSlotCheckoutWithId({
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // S'assurer que le document customer existe
      await _ensureCustomerDocument(user.uid, user.email!);

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      final tempSessionId = DateTime.now().millisecondsSinceEpoch.toString();

      final checkoutData = {
        'mode': 'payment',
        'customer_email': user.email, // ← Utiliser email
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Slot de catégorie supplémentaire',
                'description':
                    'Permet d\'ajouter une catégorie d\'entreprise supplémentaire',
              },
              'unit_amount': StripePrices.slotSupplementaireAmountTTC, // 60€ TTC
            },
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'additional_category_slot',
          'user_id': user.uid,
          'purchase_type': 'category_slot',
          'temp_session_id': tempSessionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      final sessionId = sessionRef.id;

      final url = await _waitForCheckoutUrl(user.uid, sessionId);

      if (url != null) {
        return {
          'url': url,
          'sessionId': sessionId,
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Nouvelle méthode pour s'assurer que le document customer existe
  Future<void> _ensureCustomerDocument(String uid, String email) async {
    try {
      final customerDoc =
          await _firestore.collection('customers').doc(uid).get();

      if (!customerDoc.exists) {
        await _firestore.collection('customers').doc(uid).set({
          'email': email,
          'created': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {}
  }

  // Le reste du code reste identique...
  // (toutes les autres méthodes restent les mêmes)

  // Attendre que l'URL de checkout soit générée par l'extension Stripe
  Future<String?> _waitForCheckoutUrl(
      String customerId, String sessionId) async {
    const maxAttempts = 20;
    const delayBetweenAttempts = Duration(seconds: 2);

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final sessionDoc = await _firestore
            .collection('customers')
            .doc(customerId)
            .collection('checkout_sessions')
            .doc(sessionId)
            .get();

        if (sessionDoc.exists) {
          final data = sessionDoc.data()!;

          // Debug: afficher les champs disponibles

          // Vérifier si l'extension a ajouté une erreur
          if (data.containsKey('error')) {
            final error = data['error'];
            throw Exception('Erreur Stripe: ${error['message'] ?? error}');
          }

          // L'extension Stripe ajoute le champ 'url' automatiquement
          if (data.containsKey('url') && data['url'] != null) {
            final url = data['url'] as String;
            return url;
          }

          // Vérifier aussi sessionId (certaines versions utilisent ce champ)
          if (data.containsKey('sessionId') && data['sessionId'] != null) {
            // Construire l'URL manuellement si nécessaire
            final sessionId = data['sessionId'] as String;
            final url = 'https://checkout.stripe.com/pay/$sessionId';
            return url;
          }
        }

        await Future.delayed(delayBetweenAttempts);
      } catch (e) {
        if (i == maxAttempts - 1) rethrow;
      }
    }

    // Si on arrive ici, c'est qu'on a dépassé le timeout
    final sessionDoc = await _firestore
        .collection('customers')
        .doc(customerId)
        .collection('checkout_sessions')
        .doc(sessionId)
        .get();

    final debugData =
        sessionDoc.exists ? sessionDoc.data() : 'Document non trouvé';

    throw Exception('''
Timeout: URL de checkout non générée.
État final: $debugData

Vérifiez que:
1. L'extension Stripe est correctement installée et configurée
2. Les Cloud Functions de l'extension sont actives
3. Les prix Stripe existent et sont actifs dans votre dashboard
4. Le webhook Stripe est correctement configuré
5. La clé API Stripe a les permissions nécessaires
''');
  }

  // Lancer l'URL de checkout dans le navigateur
  Future<void> launchCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank', // ← Ouverture dans un nouvel onglet
      );
    } else {
      throw Exception('Impossible d\'ouvrir l\'URL de checkout');
    }
  }

  // Vérifier le statut de l'abonnement
  Future<Map<String, dynamic>?> checkSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final customerDoc =
          await _firestore.collection('customers').doc(user.uid).get();

      if (customerDoc.exists) {
        final subscriptions = await _firestore
            .collection('customers')
            .doc(user.uid)
            .collection('subscriptions')
            .where('status', whereIn: ['trialing', 'active'])
            .limit(1)
            .get();

        if (subscriptions.docs.isNotEmpty) {
          return subscriptions.docs.first.data();
        }
      }
    } catch (e) {}

    return null;
  }

  // ==== NOUVELLES MÉTHODES POUR PAYMENT LISTENER ====

  // Écouter les sessions de paiement
  Stream<QuerySnapshot> listenToPaymentSessions(String userId) {
    return _firestore
        .collection('customers')
        .doc(userId)
        .collection('checkout_sessions')
        // Ne pas filtrer ici - on veut voir TOUS les changements
        .orderBy('created', descending: true)
        .limit(10) // Limiter aux 10 dernières sessions
        .snapshots();
  }

  // Dans StripeService
  Future<void> handleSuccessfulPayment(DocumentSnapshot sessionDoc) async {
    try {
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final metadata = sessionData['metadata'] as Map<String, dynamic>?;

      if (metadata == null) {
        return;
      }

      final userId = metadata['user_id'] as String?;
      final purchaseType = metadata['purchase_type'] as String?;
      final paymentType = metadata['type'] as String?;

      // Vérifier si c'est un paiement de slot
      if (purchaseType == 'category_slot' ||
          paymentType == 'additional_category_slot') {
        // Trouver l'établissement
        final estabQuery = await _firestore
            .collection('establishments')
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();

        if (estabQuery.docs.isEmpty) {
          return;
        }

        final establishmentDoc = estabQuery.docs.first;
        final establishmentId = establishmentDoc.id;
        final currentData = establishmentDoc.data();
        final currentSlots = currentData['enterprise_category_slots'] ?? 2;

        // Incrémenter les slots
        await _firestore
            .collection('establishments')
            .doc(establishmentId)
            .update({
          'enterprise_category_slots': currentSlots + 1,
          'last_slot_purchase': FieldValue.serverTimestamp(),
        });
      }

      // Marquer la session comme traitée
      await sessionDoc.reference.update({
        'processed': true,
        'processed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Créer un bon cadeau de bienvenue
  Future<void> _createWelcomeGiftVoucher(String establishmentId) async {
    try {
      // Créer le bon cadeau
      await _firestore.collection('gift_vouchers').add({
        'establishment_id': establishmentId,
        'amount': 50.0,
        'type': 'welcome',
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'expires_at':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        'code': 'WELCOME-${DateTime.now().millisecondsSinceEpoch}',
      });
    } catch (e) {}
  }

  // Créer une session de paiement pour un slot additionnel
  Future<String?> createAdditionalSlotCheckout({
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final customerId = await _ensureStripeCustomer();

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      final checkoutData = {
        'mode': 'subscription',
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          {
            'price': PRICE_ID_ADDITIONAL_SLOT,
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'additional_category_slot',
          'user_id': customerId,
          'purchase_type': 'category_slot',
        },
        'allow_promotion_codes': true,
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('checkout_sessions')
          .add(checkoutData);

      return await _waitForCheckoutUrl(customerId, sessionRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Méthode générique pour créer une session de paiement unique personnalisée
  Future<Map<String, String>?> createGenericOneTimeCheckout({
    required String establishmentId,
    required int amount,
    required String productName,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _ensureCustomerDocument(user.uid, user.email!);

      final successUrl = 'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrl = 'https://app.ventemoi.fr/stripe-cancel.html';

      final tempSessionId = DateTime.now().millisecondsSinceEpoch.toString();

      final checkoutData = {
        'mode': 'payment',
        'customer_email': user.email,
        'success_url': successUrl,
        'cancel_url': cancelUrl,
        'line_items': [
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': productName,
                'description': description,
              },
              'unit_amount': amount,
            },
            'quantity': 1,
          }
        ],
        'metadata': metadata ??
            {
              'establishment_id': establishmentId,
              'user_id': user.uid,
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
        'client_reference_id': tempSessionId,
        'allow_promotion_codes': true,
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      final url = await _waitForCheckoutUrl(user.uid, sessionRef.id);
      if (url != null) {
        return {
          'url': url,
          'sessionId': tempSessionId,
        };
      }
      return null;
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Erreur lors de la création du paiement: $e',
            true,
          );
      return null;
    }
  }

  // Méthode de debug pour vérifier la configuration
  Future<void> debugStripeSetup() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    // Vérifier le customer
    final customerDoc =
        await _firestore.collection('customers').doc(user.uid).get();

    if (customerDoc.exists) {
      final data = customerDoc.data()!;

      if (data['stripeId'] == null) {}
    } else {}
  }

  // Méthode de diagnostic pour tester les Cloud Functions
  Future<void> testCloudFunction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Supprimer l'ancien document s'il existe
    final ref =
        FirebaseFirestore.instance.collection('customers').doc(user.uid);

    await ref.delete();

    // Créer un nouveau document
    await ref.set({
      'email': user.email!,
      'created': FieldValue.serverTimestamp(),
    });

    // Attendre et vérifier
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(seconds: 2));

      final doc = await ref.get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('stripeId')) {
          return;
        }
        if (data.containsKey('error')) {
          return;
        }
      }
    }
  }

  // Ajouter ces méthodes dans la classe StripeService (lib/core/models/stripe_service.dart)

  // Méthode pour forcer la mise à jour du statut (en cas d'urgence)
  Future<void> forceCheckSessionStatus(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Récupérer la session
      final sessionRef = _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId);

      final sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) {
        return;
      }

      final data = sessionDoc.data()!;

      // Si la session a un payment_intent mais pas de payment_status
      if (data['payment_intent'] != null && data['payment_status'] == null) {
        await sessionRef.update({
          'payment_status': 'paid',
          'status': 'complete',
          'force_updated': true,
          'force_updated_at': FieldValue.serverTimestamp(),
        });
      } else {}
    } catch (e) {}
  }

  // Méthode pour vérifier via Cloud Function (optionnelle)
  // Note: Cette méthode nécessite le déploiement d'une Cloud Function
  Future<bool> verifyPaymentViaCloudFunction(String sessionId) async {
    try {
      // Si vous n'avez pas de Cloud Function déployée, retournez false
      // Cette méthode est un placeholder pour une future implémentation

      // Pour implémenter cette fonctionnalité :
      // 1. Déployez la Cloud Function fournie précédemment
      // 2. Remplacez ce code par l'appel réel à la fonction

      // Exemple d'implémentation (décommentez si vous avez la Cloud Function) :
      /*
        final HttpsCallable callable = FirebaseFunctions
            .instanceFor(region: 'europe-west1')
            .httpsCallable('verifyPaymentStatus');

        final result = await callable.call({
          'sessionId': sessionId,
        });

        final data = result.data as Map<String, dynamic>;

        return data['success'] == true;
        */

      // Pour l'instant, retourner false car non implémenté
      return false;
    } catch (e) {
      return false;
    }
  }

  // Méthode utilitaire pour vérifier si un paiement est réussi
  Future<bool> checkPaymentSuccess(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final sessionDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) return false;

      final data = sessionDoc.data()!;

      // Vérifier plusieurs indicateurs de succès
      final paymentStatus = data['payment_status'] as String?;
      final status = data['status'] as String?;
      final paymentIntent = data['payment_intent'] as String?;
      final subscription = data['subscription'] as String?;
      final invoice = data['invoice'] as String?;
      final amountTotal = data['amount_total'] as int?;

      final isPaid = (paymentStatus == 'paid' ||
              paymentStatus == 'succeeded') ||
          (status == 'complete' || status == 'paid' || status == 'success') ||
          (paymentIntent != null || subscription != null || invoice != null);

      final hasAmount = amountTotal != null && amountTotal > 0;

      return isPaid && hasAmount;
    } catch (e) {
      return false;
    }
  }

  // Ajoutez ces méthodes dans votre classe StripeService (lib/core/models/stripe_service.dart)

  // Méthode de vérification améliorée avec retry
  Future<bool> checkPaymentStatusWithRetry(String sessionId,
      {int maxRetries = 3}) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    for (int i = 0; i < maxRetries; i++) {
      try {
        // 1. Vérifier la session checkout
        final sessionDoc = await _firestore
            .collection('customers')
            .doc(user.uid)
            .collection('checkout_sessions')
            .doc(sessionId)
            .get();

        if (!sessionDoc.exists) {
          await Future.delayed(Duration(seconds: 2));
          continue;
        }

        final data = sessionDoc.data()!;

        // 2. Vérifier plusieurs indicateurs de succès
        final paymentStatus = data['payment_status'] as String?;
        final status = data['status'] as String?;
        final paymentIntent = data['payment_intent'] as String?;
        final subscription = data['subscription'] as String?;
        final invoice = data['invoice'] as String?;

        // Debug

        // Succès si un de ces critères est rempli
        if (paymentStatus == 'paid' ||
            paymentStatus == 'succeeded' ||
            status == 'complete' ||
            status == 'paid' ||
            status == 'success' ||
            paymentIntent != null ||
            subscription != null ||
            invoice != null) {
          return true;
        }

        // 3. Vérifier aussi directement l'abonnement/établissement
        final estabQuery = await _firestore
            .collection('establishments')
            .where('user_id', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (estabQuery.docs.isNotEmpty) {
          final hasActiveSubscription =
              estabQuery.docs.first.data()['has_active_subscription'] ?? false;

          if (hasActiveSubscription) {
            // Mettre à jour la session pour cohérence
            try {
              await sessionDoc.reference.update({
                'payment_status': 'paid',
                'updated_by_app': true,
                'updated_at': FieldValue.serverTimestamp(),
              });
            } catch (e) {}

            return true;
          }
        }

        // 4. Si on a des champs Stripe mais pas de statut, c'est probablement un succès
        if ((paymentIntent != null ||
                subscription != null ||
                invoice != null) &&
            paymentStatus == null &&
            i == maxRetries - 1) {
          return true;
        }

        await Future.delayed(Duration(seconds: 2));
      } catch (e) {}
    }

    return false;
  }

  // Forcer la mise à jour du statut de paiement
  Future<void> forceUpdatePaymentStatus(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Récupérer la session
      final sessionRef = _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId);

      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) {
        return;
      }

      final data = sessionDoc.data()!;

      // 2. Vérifier si on a des indicateurs de paiement
      final hasPaymentIndicators = data['payment_intent'] != null ||
          data['subscription'] != null ||
          data['invoice'] != null;

      // 3. Vérifier l'établissement
      final estabQuery = await _firestore
          .collection('establishments')
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      final hasActiveSubscription = estabQuery.docs.isNotEmpty &&
          (estabQuery.docs.first.data()['has_active_subscription'] ?? false);

      // 4. Forcer la mise à jour si nécessaire
      if ((hasPaymentIndicators || hasActiveSubscription) &&
          data['payment_status'] != 'paid') {
        await sessionRef.update({
          'payment_status': 'paid',
          'status': 'complete',
          'force_updated': true,
          'force_updated_at': FieldValue.serverTimestamp(),
          'force_update_reason': hasActiveSubscription
              ? 'Active subscription detected'
              : 'Payment indicators present',
        });
      } else if (!hasPaymentIndicators && !hasActiveSubscription) {
      } else {}
    } catch (e) {}
  }

  // Méthode de debug améliorée
  Future<void> debugCheckoutSession(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      // 1. Vérifier la session
      final sessionDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        return;
      }

      final data = sessionDoc.data()!;

      // 2. Afficher tous les champs
      data.forEach((key, value) {
        if (value is Map) {
          value.forEach((k, v) {});
        } else if (value is Timestamp) {
        } else if (value is List) {
        } else {}
      });

      // 3. Analyse des champs critiques

      final hasUrl = data.containsKey('url') && data['url'] != null;
      final hasPaymentStatus =
          data.containsKey('payment_status') && data['payment_status'] != null;
      final hasStatus = data.containsKey('status') && data['status'] != null;
      final hasPaymentIntent =
          data.containsKey('payment_intent') && data['payment_intent'] != null;
      final hasSubscription =
          data.containsKey('subscription') && data['subscription'] != null;
      final hasInvoice = data.containsKey('invoice') && data['invoice'] != null;
      final hasError = data.containsKey('error') && data['error'] != null;
      final hasAmountTotal =
          data.containsKey('amount_total') && data['amount_total'] != null;


      // 4. Vérifier l'établissement
      final estabQuery = await _firestore
          .collection('establishments')
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        final estabData = estabQuery.docs.first.data();
      } else {}

      // 5. Diagnostic

      if (hasPaymentStatus && data['payment_status'] == 'paid') {
      } else if (hasPaymentIntent || hasSubscription || hasInvoice) {
      } else if (hasError) {
      } else if (!hasUrl) {
      } else {}

      // 6. Recommandations

      if (!hasPaymentStatus && (hasPaymentIntent || hasSubscription)) {}

      if (hasError) {}
    } catch (e) {}
  }

  // Dans lib/core/models/stripe_service.dart

  // Créer une session de checkout pour un slot de catégorie
  Future<Map<String, String>?> createCategorySlotCheckout({
    required String categoryId,
    required String establishmentId,
  }) async {
    try {
      final customerId = await _ensureStripeCustomer();

      // URLs de redirection
      final successUrl = 'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrl = 'https://app.ventemoi.fr/stripe-cancel.html';

      // Générer un ID unique temporaire pour le tracking
      final tempSessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Données de la session avec price_data au lieu de price
      final checkoutData = {
        'mode': 'payment',
        'success_url': successUrl,
        'cancel_url': cancelUrl,
        'line_items': [
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Slot de catégorie supplémentaire',
                'description':
                    'Permet d\'ajouter une catégorie d\'entreprise supplémentaire',
              },
              'unit_amount': StripePrices.slotSupplementaireAmountTTC, // 60€ TTC
            },
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'slot_purchase',
          'purchase_type': 'category_slot',
          'category_id': categoryId,
          'establishment_id': establishmentId,
          'user_id': customerId,
          'temp_session_id': tempSessionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      // Créer la session avec toutes les données
      final sessionRef = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('checkout_sessions')
          .add(checkoutData);

      final sessionId = sessionRef.id;

      // Attendre que l'URL soit générée
      final url = await _waitForCheckoutUrl(customerId, sessionId);

      if (url != null) {
        return {
          'url': url,
          'sessionId': sessionId,
        };
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> syncStripeCustomer() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Appeler la Cloud Function
      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('syncExistingCustomer');

      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true && data['customerId'] != null) {
        return data['customerId'];
      }

      throw Exception('Échec de la synchronisation');
    } catch (e) {
      // Fallback : utiliser l'email
      return null;
    }
  }

  // ========== NOUVELLES MÉTHODES POUR LES PRODUITS STRIPE ==========

  // Créer une session pour un sponsor Bronze
  Future<Map<String, String>?> createSponsorBronzeCheckout({
    required String establishmentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _ensureCustomerDocument(user.uid, user.email!);

      final checkoutData = {
        'mode': 'payment',
        'customer_email': user.email,
        'success_url': 'https://app.ventemoi.fr/stripe-success.html',
        'cancel_url': 'https://app.ventemoi.fr/stripe-cancel.html',
        'line_items': [
          {
            'price': StripePrices.sponsorBronzePriceId,
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'sponsor',
          'level': 'bronze',
          'establishment_id': establishmentId,
          'user_id': user.uid,
          'vouchers_included': '1',
          'voucher_value': '50',
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      final url = await _waitForCheckoutUrl(user.uid, sessionRef.id);
      if (url != null) {
        return {'url': url, 'sessionId': sessionRef.id};
      }
      return null;
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Erreur lors de la création du paiement sponsor: $e',
        true,
      );
      return null;
    }
  }

  // Créer une session pour un sponsor Silver
  Future<Map<String, String>?> createSponsorSilverCheckout({
    required String establishmentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _ensureCustomerDocument(user.uid, user.email!);

      final checkoutData = {
        'mode': 'payment',
        'customer_email': user.email,
        'success_url': 'https://app.ventemoi.fr/stripe-success.html',
        'cancel_url': 'https://app.ventemoi.fr/stripe-cancel.html',
        'line_items': [
          {
            'price': StripePrices.sponsorSilverPriceId,
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'sponsor',
          'level': 'silver',
          'establishment_id': establishmentId,
          'user_id': user.uid,
          'vouchers_included': '3',
          'voucher_value': '50',
          'video_included': 'standard',
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      final url = await _waitForCheckoutUrl(user.uid, sessionRef.id);
      if (url != null) {
        return {'url': url, 'sessionId': sessionRef.id};
      }
      return null;
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Erreur lors de la création du paiement sponsor: $e',
        true,
      );
      return null;
    }
  }

  // Créer une session pour une vidéo (membre ou public)
  Future<Map<String, String>?> createVideoCheckout({
    required String establishmentId,
    required String videoType, // 'standard', 'premium', 'signature'
    required bool isMember,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _ensureCustomerDocument(user.uid, user.email!);

      // Sélectionner le bon price ID selon le type et le statut membre
      String priceId;
      if (isMember) {
        switch (videoType) {
          case 'premium':
            priceId = StripePrices.videoPremiumMembrePriceId;
            break;
          case 'signature':
            priceId = StripePrices.videoSignatureMembrePriceId;
            break;
          default:
            priceId = StripePrices.videoStandardMembrePriceId;
        }
      } else {
        switch (videoType) {
          case 'premium':
            priceId = StripePrices.videoPremiumPublicPriceId;
            break;
          case 'signature':
            priceId = StripePrices.videoSignaturePublicPriceId;
            break;
          default:
            priceId = StripePrices.videoStandardPublicPriceId;
        }
      }

      final checkoutData = {
        'mode': 'payment',
        'customer_email': user.email,
        'success_url': 'https://app.ventemoi.fr/stripe-success.html',
        'cancel_url': 'https://app.ventemoi.fr/stripe-cancel.html',
        'line_items': [
          {
            'price': priceId,
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'video',
          'video_type': videoType,
          'is_member': isMember.toString(),
          'establishment_id': establishmentId,
          'user_id': user.uid,
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      final url = await _waitForCheckoutUrl(user.uid, sessionRef.id);
      if (url != null) {
        return {'url': url, 'sessionId': sessionRef.id};
      }
      return null;
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Erreur lors de la création du paiement vidéo: $e',
        true,
      );
      return null;
    }
  }

  // Créer une session pour le bandeau publicitaire hebdomadaire
  Future<Map<String, String>?> createBandeauHebdoCheckout({
    required String establishmentId,
    required DateTime startDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _ensureCustomerDocument(user.uid, user.email!);

      final checkoutData = {
        'mode': 'payment',
        'customer_email': user.email,
        'success_url': 'https://app.ventemoi.fr/stripe-success.html',
        'cancel_url': 'https://app.ventemoi.fr/stripe-cancel.html',
        'line_items': [
          {
            'price': StripePrices.bandeauHebdoPriceId,
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'advertising',
          'product': 'bandeau_hebdo',
          'establishment_id': establishmentId,
          'user_id': user.uid,
          'start_date': startDate.toIso8601String(),
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      final url = await _waitForCheckoutUrl(user.uid, sessionRef.id);
      if (url != null) {
        return {'url': url, 'sessionId': sessionRef.id};
      }
      return null;
    } catch (e) {
      UniquesControllers().data.snackbar(
        'Erreur',
        'Erreur lors de la création du paiement publicitaire: $e',
        true,
      );
      return null;
    }
  }
}
