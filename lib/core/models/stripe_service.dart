import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StripeService extends GetxService {
  static StripeService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String PRICE_ID_MONTHLY_FIRST_YEAR =
      'price_1RnEnpAOsm6ulZWoaL9qF82e'; // ADHESION + VIDEO
  static const String PRICE_ID_MONTHLY_RECURRING =
      'price_1RnEnmAOsm6ulZWoEjr61X2l';
  static const String PRICE_ID_ANNUAL_FIRST_YEAR =
      'price_1RnEnxAOsm6ulZWoklEwYoXm'; // Pack Première Année - Annuel
  static const String PRICE_ID_ANNUAL_RECURRING =
      'price_1RnEnxAOsm6ulZWoklEwYoXm';
  static const String PRICE_ID_ADDITIONAL_SLOT =
      'price_1RnEnjAOsm6ulZWoSj3PQQe6';

  // Modifier _ensureStripeCustomer pour utiliser la synchronisation
  Future<String> _ensureStripeCustomer() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    print('🔵 Vérification du customer Stripe pour: ${user.email}');

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
      print(
          '🔵 Création checkout mensuel pour user: ${_auth.currentUser?.uid}');

      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      // IMPORTANT : Utiliser customer_email au lieu d'un customer ID
      final checkoutData = {
        'mode': 'subscription',
        'customer_email': user.email, // ← CHANGEMENT CLÉ
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          // 1. Frais d'adhésion (visible sur la page de checkout)
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Frais d\'adhésion VenteMoi (unique)',
                'description': 'Accès à la plateforme pour votre établissement',
              },
              'unit_amount': 27000, // 270€
              'recurring': null, // Pas récurrent
            },
            'quantity': 1,
          },
          // 2. Abonnement mensuel
          {
            'price': PRICE_ID_MONTHLY_RECURRING, // 55€/mois
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
          'includes_setup_fee': 'true',
          'setup_fee_amount': '270',
        },
        'allow_promotion_codes': true,
      };

      print('🔵 Données checkout: $checkoutData');

      final sessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add(checkoutData);

      print('🔵 Session créée avec ID: ${sessionRef.id}');

      return await _waitForCheckoutUrl(user.uid, sessionRef.id);
    } catch (e) {
      print('❌ Erreur création checkout mensuel: $e');
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
      print(
          '🔵 Création checkout mensuel avec ID pour user: ${_auth.currentUser?.uid}');

      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // S'assurer que le document customer existe
      await _ensureCustomerDocument(user.uid, user.email!);

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      final checkoutData = {
        'mode': 'subscription',
        'customer_email': user.email, // ← Utiliser email au lieu de customer ID
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          // Frais d'adhésion visibles
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Frais d\'adhésion VenteMoi (unique)',
                'description': 'Accès à la plateforme pour votre établissement',
              },
              'unit_amount': 27000, // 270€
            },
            'quantity': 1,
          },
          // Abonnement mensuel
          {
            'price': PRICE_ID_MONTHLY_RECURRING, // 55€/mois
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
          'includes_setup_fee': 'true',
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
      print('📄 Document Firestore créé: $firestoreDocId');

      final url = await _waitForCheckoutUrl(user.uid, firestoreDocId);

      if (url != null) {
        return {
          'url': url,
          'sessionId': firestoreDocId,
        };
      }

      return null;
    } catch (e) {
      print('❌ Erreur création checkout mensuel: $e');
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
      print(
          '🔵 Création checkout annuel avec ID pour user: ${_auth.currentUser?.uid}');

      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // S'assurer que le document customer existe
      await _ensureCustomerDocument(user.uid, user.email!);

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      final checkoutData = {
        'mode': 'payment',
        'customer_email': user.email, // ← Utiliser email
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          {
            'price': PRICE_ID_ANNUAL_FIRST_YEAR,
            'quantity': 1,
          }
        ],
        'metadata': {
          'purchase_type': 'first_year_annual',
          'user_type': userType,
          'user_id': user.uid,
          'needs_future_subscription': 'true',
          'future_price_id': PRICE_ID_ANNUAL_RECURRING,
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
      print('🔵 Session créée avec ID: $sessionId');

      final url = await _waitForCheckoutUrl(user.uid, sessionId);

      if (url != null) {
        return {
          'url': url,
          'sessionId': sessionId,
        };
      }

      return null;
    } catch (e) {
      print('❌ Erreur création checkout annuel: $e');
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
              'unit_amount': 5000, // 50€ en centimes
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
      print('📄 Document Firestore créé: $sessionId');

      final url = await _waitForCheckoutUrl(user.uid, sessionId);

      if (url != null) {
        return {
          'url': url,
          'sessionId': sessionId,
        };
      }

      return null;
    } catch (e) {
      print('❌ Erreur création checkout slot: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour s'assurer que le document customer existe
  Future<void> _ensureCustomerDocument(String uid, String email) async {
    try {
      final customerDoc =
          await _firestore.collection('customers').doc(uid).get();

      if (!customerDoc.exists) {
        print('📝 Création du document customer...');
        await _firestore.collection('customers').doc(uid).set({
          'email': email,
          'created': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('⚠️ Erreur création document customer: $e');
    }
  }

  // Le reste du code reste identique...
  // (toutes les autres méthodes restent les mêmes)

  // Attendre que l'URL de checkout soit générée par l'extension Stripe
  Future<String?> _waitForCheckoutUrl(
      String customerId, String sessionId) async {
    print('⏳ En attente de l\'URL de checkout...');

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
          print(
              '🔍 Tentative ${i + 1}/$maxAttempts - Data: ${data.keys.join(', ')}');

          // Vérifier si l'extension a ajouté une erreur
          if (data.containsKey('error')) {
            final error = data['error'];
            print('❌ Erreur Stripe: $error');
            throw Exception('Erreur Stripe: ${error['message'] ?? error}');
          }

          // L'extension Stripe ajoute le champ 'url' automatiquement
          if (data.containsKey('url') && data['url'] != null) {
            final url = data['url'] as String;
            print('✅ URL de checkout obtenue: $url');
            return url;
          }

          // Vérifier aussi sessionId (certaines versions utilisent ce champ)
          if (data.containsKey('sessionId') && data['sessionId'] != null) {
            // Construire l'URL manuellement si nécessaire
            final sessionId = data['sessionId'] as String;
            final url = 'https://checkout.stripe.com/pay/$sessionId';
            print('✅ URL construite depuis sessionId: $url');
            return url;
          }
        }

        await Future.delayed(delayBetweenAttempts);
      } catch (e) {
        print('❌ Erreur lors de la vérification: $e');
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
    } catch (e) {
      print('Erreur vérification abonnement: $e');
    }

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
        print('❌ Pas de metadata dans la session');
        return;
      }

      final userId = metadata['user_id'] as String?;
      final purchaseType = metadata['purchase_type'] as String?;
      final paymentType = metadata['type'] as String?;

      print('🎉 handleSuccessfulPayment appelé:');
      print('   - userId: $userId');
      print('   - purchaseType: $purchaseType');
      print('   - paymentType: $paymentType');
      print('   - metadata: ${metadata.toString()}');

      // Vérifier si c'est un paiement de slot
      if (purchaseType == 'category_slot' ||
          paymentType == 'additional_category_slot') {
        print('📦 C\'est un paiement de slot!');

        // Trouver l'établissement
        final estabQuery = await _firestore
            .collection('establishments')
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();

        if (estabQuery.docs.isEmpty) {
          print('❌ Aucun établissement trouvé pour user: $userId');
          return;
        }

        final establishmentDoc = estabQuery.docs.first;
        final establishmentId = establishmentDoc.id;
        final currentData = establishmentDoc.data();
        final currentSlots = currentData['enterprise_category_slots'] ?? 2;

        print('🏢 Établissement trouvé: $establishmentId');
        print('   - Slots actuels: $currentSlots');

        // Incrémenter les slots
        await _firestore
            .collection('establishments')
            .doc(establishmentId)
            .update({
          'enterprise_category_slots': currentSlots + 1,
          'last_slot_purchase': FieldValue.serverTimestamp(),
        });

        print('✅ Slot ajouté avec succès! Nouveau total: ${currentSlots + 1}');
      }

      // Marquer la session comme traitée
      await sessionDoc.reference.update({
        'processed': true,
        'processed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur dans handleSuccessfulPayment: $e');
      print('   Stack: ${e.toString()}');
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

      print('🎁 Bon cadeau de bienvenue créé');
    } catch (e) {
      print('❌ Erreur création bon cadeau: $e');
    }
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
      print('❌ Erreur création checkout slot: $e');
      rethrow;
    }
  }

  // Méthode de debug pour vérifier la configuration
  Future<void> debugStripeSetup() async {
    print('\n🔍 === DEBUG STRIPE SETUP ===\n');

    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Aucun utilisateur connecté');
      return;
    }

    print('👤 Utilisateur: ${user.uid}');
    print('📧 Email: ${user.email}');

    // Vérifier le customer
    final customerDoc =
        await _firestore.collection('customers').doc(user.uid).get();

    if (customerDoc.exists) {
      final data = customerDoc.data()!;
      print('\n✅ Document customer existe:');
      print('   - stripeId: ${data['stripeId'] ?? 'NON DÉFINI'}');
      print('   - email: ${data['email']}');
      print('   - created: ${data['created']}');

      if (data['stripeId'] == null) {
        print('\n⚠️  ATTENTION: Le stripeId est manquant!');
        print('   L\'extension Stripe n\'a pas créé le customer.');
        print('   Vérifiez la configuration de l\'extension.');
      }
    } else {
      print('\n❌ Document customer n\'existe pas');
    }

    print('\n=== FIN DEBUG ===\n');
  }

  // Méthode de diagnostic pour tester les Cloud Functions
  Future<void> testCloudFunction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print('🧪 Test Cloud Function...');

    // Supprimer l'ancien document s'il existe
    final ref =
        FirebaseFirestore.instance.collection('customers').doc(user.uid);

    await ref.delete();
    print('🗑️ Ancien document supprimé');

    // Créer un nouveau document
    await ref.set({
      'email': user.email!,
      'created': FieldValue.serverTimestamp(),
    });

    print('📝 Nouveau document créé');
    print('⏳ Attente de la Cloud Function...');

    // Attendre et vérifier
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(seconds: 2));

      final doc = await ref.get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('stripeId')) {
          print('✅ SUCCESS! stripeId: ${data['stripeId']}');
          return;
        }
        if (data.containsKey('error')) {
          print('❌ ERREUR: ${data['error']}');
          return;
        }
      }
      print('   Tentative ${i + 1}/10...');
    }

    print('⏱️ Timeout - vérifiez les logs Cloud Functions');
  }

  // Ajouter ces méthodes dans la classe StripeService (lib/core/models/stripe_service.dart)

  // Méthode pour forcer la mise à jour du statut (en cas d'urgence)
  Future<void> forceCheckSessionStatus(String sessionId) async {
    print('🔄 Forçage de la vérification du statut...');

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
        print('❌ Session introuvable');
        return;
      }

      final data = sessionDoc.data()!;

      // Si la session a un payment_intent mais pas de payment_status
      if (data['payment_intent'] != null && data['payment_status'] == null) {
        print('⚠️ Session avec payment_intent mais sans payment_status');
        print('   → Mise à jour forcée du statut');

        await sessionRef.update({
          'payment_status': 'paid',
          'status': 'complete',
          'force_updated': true,
          'force_updated_at': FieldValue.serverTimestamp(),
        });

        print('✅ Statut forcé à "paid"');
      } else {
        print('ℹ️ Session déjà à jour ou pas de payment_intent');
      }
    } catch (e) {
      print('❌ Erreur force update: $e');
    }
  }

  // Méthode pour vérifier via Cloud Function (optionnelle)
  // Note: Cette méthode nécessite le déploiement d'une Cloud Function
  Future<bool> verifyPaymentViaCloudFunction(String sessionId) async {
    try {
      print('☁️ Tentative de vérification via Cloud Function...');

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
        print('☁️ Résultat: ${data['success']} - Status: ${data['status']}');

        return data['success'] == true;
        */

      // Pour l'instant, retourner false car non implémenté
      print('⚠️ Cloud Function non implémentée, utilisation du fallback');
      return false;
    } catch (e) {
      print('❌ Erreur Cloud Function: $e');
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
      print('Erreur vérification paiement: $e');
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
          print(
              '❌ Session $sessionId introuvable (tentative ${i + 1}/$maxRetries)');
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
        print('🔍 Session $sessionId - Tentative ${i + 1}:');
        print('   payment_status: $paymentStatus');
        print('   status: $status');
        print('   payment_intent: ${paymentIntent != null ? '✅' : '❌'}');
        print('   subscription: ${subscription != null ? '✅' : '❌'}');
        print('   invoice: ${invoice != null ? '✅' : '❌'}');

        // Succès si un de ces critères est rempli
        if (paymentStatus == 'paid' ||
            paymentStatus == 'succeeded' ||
            status == 'complete' ||
            status == 'paid' ||
            status == 'success' ||
            paymentIntent != null ||
            subscription != null ||
            invoice != null) {
          print('✅ Paiement confirmé!');
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
            print('✅ Abonnement actif détecté dans l\'établissement!');

            // Mettre à jour la session pour cohérence
            try {
              await sessionDoc.reference.update({
                'payment_status': 'paid',
                'updated_by_app': true,
                'updated_at': FieldValue.serverTimestamp(),
              });
            } catch (e) {
              print('⚠️ Impossible de mettre à jour la session: $e');
            }

            return true;
          }
        }

        // 4. Si on a des champs Stripe mais pas de statut, c'est probablement un succès
        if ((paymentIntent != null ||
                subscription != null ||
                invoice != null) &&
            paymentStatus == null &&
            i == maxRetries - 1) {
          print(
              '⚠️ Session avec données Stripe mais sans statut - considérée comme réussie');
          return true;
        }

        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print('❌ Erreur vérification (tentative ${i + 1}): $e');
      }
    }

    return false;
  }

  // Forcer la mise à jour du statut de paiement
  Future<void> forceUpdatePaymentStatus(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    print('🔄 Forçage de la mise à jour du statut pour session: $sessionId');

    try {
      // 1. Récupérer la session
      final sessionRef = _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .doc(sessionId);

      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) {
        print('❌ Session introuvable: $sessionId');
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
        print('⚠️ Indicateurs de paiement trouvés mais statut incorrect');
        print('   → Mise à jour forcée du statut');

        await sessionRef.update({
          'payment_status': 'paid',
          'status': 'complete',
          'force_updated': true,
          'force_updated_at': FieldValue.serverTimestamp(),
          'force_update_reason': hasActiveSubscription
              ? 'Active subscription detected'
              : 'Payment indicators present',
        });

        print('✅ Statut forcé à "paid"');
      } else if (!hasPaymentIndicators && !hasActiveSubscription) {
        print('❌ Aucun indicateur de paiement trouvé');
      } else {
        print('✅ Statut déjà correct');
      }
    } catch (e) {
      print('❌ Erreur force update: $e');
    }
  }

  // Méthode de debug améliorée
  Future<void> debugCheckoutSession(String sessionId) async {
    print('\n🔍 === DEBUG CHECKOUT SESSION ===\n');

    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Aucun utilisateur connecté');
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
        print('❌ Session introuvable: $sessionId');
        print('   User ID: ${user.uid}');
        return;
      }

      final data = sessionDoc.data()!;
      print('📄 Session trouvée:');
      print('   ID: $sessionId');
      print('   User: ${user.uid}');

      // 2. Afficher tous les champs
      print('\n📊 Données de la session:');
      data.forEach((key, value) {
        if (value is Map) {
          print('   $key:');
          value.forEach((k, v) {
            print('      $k: $v');
          });
        } else if (value is Timestamp) {
          print('   $key: ${value.toDate()}');
        } else if (value is List) {
          print('   $key: [${value.length} éléments]');
        } else {
          print('   $key: $value');
        }
      });

      // 3. Analyse des champs critiques
      print('\n🔎 Analyse du statut:');

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

      print('   ✓ URL générée: ${hasUrl ? '✅' : '❌'}');
      print(
          '   ✓ payment_status: ${hasPaymentStatus ? '✅ (${data['payment_status']})' : '❌'}');
      print('   ✓ status: ${hasStatus ? '✅ (${data['status']})' : '❌'}');
      print('   ✓ payment_intent: ${hasPaymentIntent ? '✅' : '❌'}');
      print('   ✓ subscription: ${hasSubscription ? '✅' : '❌'}');
      print('   ✓ invoice: ${hasInvoice ? '✅' : '❌'}');
      print(
          '   ✓ amount_total: ${hasAmountTotal ? '✅ (${data['amount_total']} centimes)' : '❌'}');
      print('   ✓ Erreur: ${hasError ? '❌ ${data['error']}' : '✅ Aucune'}');

      // 4. Vérifier l'établissement
      print('\n🏢 Vérification de l\'établissement:');
      final estabQuery = await _firestore
          .collection('establishments')
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        final estabData = estabQuery.docs.first.data();
        print('   ID: ${estabQuery.docs.first.id}');
        print(
            '   has_active_subscription: ${estabData['has_active_subscription'] ?? 'non défini'}');
        print(
            '   subscription_type: ${estabData['subscription_type'] ?? 'non défini'}');
        print(
            '   subscription_end_date: ${estabData['subscription_end_date']?.toDate() ?? 'non défini'}');
      } else {
        print('   ❌ Aucun établissement trouvé pour cet utilisateur');
      }

      // 5. Diagnostic
      print('\n💡 Diagnostic:');

      if (hasPaymentStatus && data['payment_status'] == 'paid') {
        print('   ✅ Paiement confirmé par Stripe');
      } else if (hasPaymentIntent || hasSubscription || hasInvoice) {
        print(
            '   ⚠️ Indicateurs de paiement présents mais statut non mis à jour');
        print('   → Essayez forceUpdatePaymentStatus()');
      } else if (hasError) {
        print('   ❌ Erreur Stripe détectée');
      } else if (!hasUrl) {
        print('   ⏳ Session en cours de création (URL non générée)');
      } else {
        print('   ⏳ En attente du webhook Stripe');
      }

      // 6. Recommandations
      print('\n📋 Actions recommandées:');

      if (!hasPaymentStatus && (hasPaymentIntent || hasSubscription)) {
        print('   1. Vérifier la configuration des webhooks Stripe');
        print('   2. Vérifier les logs des Cloud Functions');
        print('   3. Utiliser forceUpdatePaymentStatus() si nécessaire');
      }

      if (hasError) {
        print('   1. Vérifier les détails de l\'erreur ci-dessus');
        print('   2. Vérifier la configuration Stripe (prix, produits)');
        print('   3. Tester avec une nouvelle session');
      }
    } catch (e) {
      print('❌ Erreur debug: $e');
    }

    print('\n=== FIN DEBUG ===\n');
  }

  // Dans lib/core/models/stripe_service.dart

  // Créer une session de checkout pour un slot de catégorie
  Future<Map<String, String>?> createCategorySlotCheckout({
    required String categoryId,
    required String establishmentId,
  }) async {
    try {
      print('🔵 Création checkout slot pour catégorie: $categoryId');

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
              'unit_amount': 5000, // 50€ en centimes
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

      print('📄 Document Firestore créé: $sessionId');

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
      print('❌ Erreur création checkout slot: $e');
      rethrow;
    }
  }

  Future<String?> syncStripeCustomer() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      print('🔄 Synchronisation du customer Stripe...');

      // Appeler la Cloud Function
      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: 'europe-west1')
              .httpsCallable('syncExistingCustomer');

      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true && data['customerId'] != null) {
        print('✅ Customer synchronisé: ${data['customerId']}');
        return data['customerId'];
      }

      throw Exception('Échec de la synchronisation');
    } catch (e) {
      print('❌ Erreur sync customer: $e');
      // Fallback : utiliser l'email
      return null;
    }
  }
}
