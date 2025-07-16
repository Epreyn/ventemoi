import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService extends GetxService {
  static StripeService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Prix IDs Stripe (à adapter selon votre configuration)
  static const String PRICE_ID_MONTHLY_FIRST_YEAR =
      'price_1ReLkQPLJZjht3nFComM7tLk';
  static const String PRICE_ID_MONTHLY_RECURRING =
      'price_1ReLlFPLJZjht3nFjMOlVjqG';
  static const String PRICE_ID_ANNUAL_FIRST_YEAR =
      'price_1ReLhpPLJZjht3nFtCCeJXQp';
  static const String PRICE_ID_ANNUAL_RECURRING =
      'price_1ReLjHPLJZjht3nFi2tzqXWu';
  static const String PRICE_ID_ADDITIONAL_SLOT =
      'price_1RjMd0PLJZjht3nFtfGuQWVu';

  // Créer ou récupérer un customer Stripe
  Future<String> _ensureStripeCustomer() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    print('🔵 Vérification du customer Stripe pour: ${user.email}');

    // Vérifier si le customer existe déjà
    DocumentSnapshot customerDoc =
        await _firestore.collection('customers').doc(user.uid).get();

    // Si le document n'existe pas, le créer
    if (!customerDoc.exists) {
      print('📝 Création du document customer...');
      await _firestore.collection('customers').doc(user.uid).set({
        'email': user.email ?? '',
        'created': FieldValue.serverTimestamp(),
      });

      // Attendre un peu pour que l'extension traite la création
      await Future.delayed(const Duration(seconds: 3));

      // Récupérer le document mis à jour
      customerDoc =
          await _firestore.collection('customers').doc(user.uid).get();
    }

    // Attendre que l'extension ajoute le stripeId
    String? stripeId;
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      if (customerDoc.exists) {
        final data = customerDoc.data() as Map<String, dynamic>?;
        stripeId = data?['stripeId'];

        if (stripeId != null && stripeId.isNotEmpty) {
          print('✅ Customer Stripe trouvé: $stripeId');
          return user.uid;
        }
      }

      attempts++;
      print('⏳ Attente du stripeId... Tentative $attempts/$maxAttempts');
      await Future.delayed(const Duration(seconds: 2));

      // Recharger le document
      customerDoc =
          await _firestore.collection('customers').doc(user.uid).get();
    }

    // Si on arrive ici, le stripeId n'a pas été créé
    throw Exception('''
    Le customer Stripe n'a pas pu être créé.
    Vérifiez que :
    1. L'extension Stripe est correctement installée
    2. La clé API Stripe est configurée
    3. L'option "Sync new users" est activée dans l'extension
    ''');
  }

  Future<String?> createMonthlyOptionCheckout({
    required String userType,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      print(
          '🔵 Création checkout mensuel pour user: ${_auth.currentUser?.uid}');

      final customerId = await _ensureStripeCustomer();

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      // IMPORTANT : On utilise le mode "subscription" mais on ajoute les deux items visibles
      final checkoutData = {
        'mode': 'subscription',
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
            'user_id': customerId,
            'subscription_type': 'monthly_with_setup',
            'setup_fee_paid': 'true',
          },
        },
        'metadata': {
          'purchase_type': 'first_year_monthly',
          'user_type': userType,
          'user_id': customerId,
          'includes_setup_fee': 'true',
          'setup_fee_amount': '270',
        },
        'allow_promotion_codes': true,
      };

      print('🔵 Données checkout: $checkoutData');

      final sessionRef = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('checkout_sessions')
          .add(checkoutData);

      print('🔵 Session créée avec ID: ${sessionRef.id}');

      return await _waitForCheckoutUrl(customerId, sessionRef.id);
    } catch (e) {
      print('❌ Erreur création checkout mensuel: $e');
      rethrow;
    }
  }

  // Version avec ID
  Future<Map<String, String>?> createMonthlyOptionCheckoutWithId({
    required String userType,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      print(
          '🔵 Création checkout mensuel avec ID pour user: ${_auth.currentUser?.uid}');

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
            'user_id': customerId,
            'subscription_type': 'monthly_with_setup',
          },
        },
        'metadata': {
          'purchase_type': 'first_year_monthly',
          'user_type': userType,
          'user_id': customerId,
          'includes_setup_fee': 'true',
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      final sessionRef = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('checkout_sessions')
          .add(checkoutData);

      final firestoreDocId = sessionRef.id;
      print('📄 Document Firestore créé: $firestoreDocId');

      final url = await _waitForCheckoutUrl(customerId, firestoreDocId);

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

  // Version alternative si vous voulez utiliser un seul prix de 325€ pour le premier mois
  // (270€ adhésion + 55€ premier mois) puis 55€/mois
  Future<String?> createMonthlyOptionCheckoutAlternative({
    required String userType,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      print(
          '🔵 Création checkout mensuel alternatif pour user: ${_auth.currentUser?.uid}');

      final customerId = await _ensureStripeCustomer();

      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      // Créer un abonnement avec un prix spécial pour le premier mois
      final checkoutData = {
        'mode': 'subscription',
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          {
            'price': PRICE_ID_MONTHLY_RECURRING, // 55€/mois
            'quantity': 1,
          }
        ],
        'subscription_data': {
          // Ajouter les frais d'adhésion comme élément unique sur la première facture
          'add_invoice_items': [
            {
              'price_data': {
                'currency': 'eur',
                'product_data': {
                  'name': 'Frais d\'adhésion VenteMoi',
                },
                'unit_amount': 27000, // 270€ en centimes
              },
              'quantity': 1,
            }
          ],
          'metadata': {
            'user_type': userType,
            'user_id': customerId,
            'subscription_type': 'monthly',
          },
        },
        'metadata': {
          'purchase_type': 'first_year_monthly',
          'user_type': userType,
          'user_id': customerId,
        },
        'allow_promotion_codes': true,
      };

      print('🔵 Données checkout: $checkoutData');

      // Créer la session de checkout
      final sessionRef = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('checkout_sessions')
          .add(checkoutData);

      print('🔵 Session créée avec ID: ${sessionRef.id}');

      // Attendre que l'URL soit générée
      return await _waitForCheckoutUrl(customerId, sessionRef.id);
    } catch (e) {
      print('❌ Erreur création checkout mensuel: $e');
      rethrow;
    }
  }

  // Créer une session de checkout pour l'option annuelle
  Future<String?> createAnnualOptionCheckout({
    required String userType,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      print('🔵 Création checkout annuel pour user: ${_auth.currentUser?.uid}');

      final customerId = await _ensureStripeCustomer();

      // URLs de redirection avec auto-fermeture
      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      // Données de la session
      final checkoutData = {
        'mode': 'payment',
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
          'user_id': customerId,
          'needs_future_subscription':
              'true', // Utiliser string au lieu de bool
          'future_price_id': PRICE_ID_ANNUAL_RECURRING,
        },
        'allow_promotion_codes': true,
      };

      print('🔵 Données checkout: $checkoutData');

      // Créer la session de checkout
      final sessionRef = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('checkout_sessions')
          .add(checkoutData);

      print('🔵 Session créée avec ID: ${sessionRef.id}');

      // Attendre que l'URL soit générée
      return await _waitForCheckoutUrl(customerId, sessionRef.id);
    } catch (e) {
      print('❌ Erreur création checkout annuel: $e');
      rethrow;
    }
  }

  // Créer une session de checkout pour l'option annuelle (avec ID)
  Future<Map<String, String>?> createAnnualOptionCheckoutWithId({
    required String userType,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      print(
          '🔵 Création checkout annuel avec ID pour user: ${_auth.currentUser?.uid}');

      final customerId = await _ensureStripeCustomer();

      // URLs de redirection avec auto-fermeture
      final successUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-success.html';
      final cancelUrlWithAutoClose =
          'https://app.ventemoi.fr/stripe-cancel.html';

      // Données de la session
      final checkoutData = {
        'mode': 'payment',
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
          'user_id': customerId,
          'needs_future_subscription': 'true',
          'future_price_id': PRICE_ID_ANNUAL_RECURRING,
        },
        'allow_promotion_codes': true,
        'created': FieldValue.serverTimestamp(),
      };

      // Créer la session de checkout
      final sessionRef = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('checkout_sessions')
          .add(checkoutData);

      final sessionId = sessionRef.id;
      print('🔵 Session créée avec ID: $sessionId');

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
      print('❌ Erreur création checkout annuel: $e');
      rethrow;
    }
  }

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
    // Essayer de récupérer plus d'infos pour le debug
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
        .where('payment_status', isEqualTo: 'paid')
        .snapshots();
  }

  // Gérer un paiement réussi
  Future<void> handleSuccessfulPayment(DocumentSnapshot sessionDoc) async {
    try {
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final metadata = sessionData['metadata'] as Map<String, dynamic>?;

      if (metadata == null) return;

      final userId = metadata['user_id'] as String?;
      final purchaseType = metadata['purchase_type'] as String?;
      final paymentType = metadata['type'] as String?;

      print('🎉 Traitement du paiement réussi: $purchaseType / $paymentType');

      // Trouver l'établissement
      final estabQuery = await _firestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (estabQuery.docs.isEmpty) {
        print('❌ Aucun établissement trouvé pour l\'utilisateur: $userId');
        return;
      }

      final establishmentId = estabQuery.docs.first.id;
      final establishmentRef =
          _firestore.collection('establishments').doc(establishmentId);

      // Traiter selon le type de paiement
      if (purchaseType == 'first_year_annual' ||
          purchaseType == 'first_year_monthly') {
        // Activer l'abonnement
        await establishmentRef.update({
          'has_accepted_contract': true,
          'has_active_subscription': true,
          'subscription_status':
              purchaseType == 'first_year_annual' ? 'annual' : 'monthly',
          'subscription_start_date': FieldValue.serverTimestamp(),
          'subscription_end_date':
              Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
          'payment_session_id': sessionDoc.id,
          'temporary_mode': false, // Retirer le mode temporaire
        });

        // Créer le bon cadeau de bienvenue
        await _createWelcomeGiftVoucher(establishmentId);

        print('✅ Abonnement activé pour l\'établissement: $establishmentId');
      } else if (paymentType == 'additional_category_slot') {
        // Ajouter un slot de catégorie
        final currentSlots = (await establishmentRef.get())
                .data()?['enterprise_category_slots'] ??
            2;

        await establishmentRef.update({
          'enterprise_category_slots': currentSlots + 1,
        });

        print('✅ Slot de catégorie ajouté. Total: ${currentSlots + 1}');
      }

      // Marquer la session comme traitée
      await sessionDoc.reference.update({
        'processed': true,
        'processed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur lors du traitement du paiement: $e');
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

  Future<Map<String, String>?> createAdditionalSlotCheckoutWithId({
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
        'mode': 'payment',
        'success_url': successUrlWithAutoClose,
        'cancel_url': cancelUrlWithAutoClose,
        'line_items': [
          {
            'price_data': {
              'currency': 'eur',
              'product_data': {
                'name': 'Slot de catégorie supplémentaire',
                'description':
                    'Accès à une catégorie d\'entreprise supplémentaire',
              },
              'unit_amount': 5000,
            },
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

      final firestoreDocId = sessionRef.id;
      print('📄 Document Firestore créé: $firestoreDocId');

      final url = await _waitForCheckoutUrl(customerId, firestoreDocId);

      if (url != null) {
        return {
          'url': url,
          'sessionId': firestoreDocId,
        };
      }

      return null;
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

  // Méthode de debug améliorée pour vérifier la configuration
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
        return;
      }

      final data = sessionDoc.data()!;
      print('📄 Session trouvée:');
      print('   ID: $sessionId');

      // Afficher tous les champs
      data.forEach((key, value) {
        if (value is Map) {
          print(
              '   $key: ${value.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
        } else if (value is Timestamp) {
          print('   $key: ${value.toDate()}');
        } else {
          print('   $key: $value');
        }
      });

      // 2. Vérifier les champs critiques
      print('\n🔎 Analyse:');

      final hasUrl = data.containsKey('url');
      final hasPaymentStatus = data.containsKey('payment_status');
      final hasStatus = data.containsKey('status');
      final hasPaymentIntent = data.containsKey('payment_intent');
      final hasError = data.containsKey('error');

      print('   ✓ URL générée: ${hasUrl ? '✅' : '❌'}');
      print(
          '   ✓ payment_status: ${hasPaymentStatus ? '✅ (${data['payment_status']})' : '❌'}');
      print('   ✓ status: ${hasStatus ? '✅ (${data['status']})' : '❌'}');
      print('   ✓ payment_intent: ${hasPaymentIntent ? '✅' : '❌'}');
      print('   ✓ Erreur: ${hasError ? '❌ ${data['error']}' : '✅ Aucune'}');

      // 3. Vérifier l'abonnement si c'est un mode subscription
      if (data['mode'] == 'subscription' && data['subscription'] != null) {
        print('\n📊 Abonnement:');
        final subId = data['subscription'];

        final subscriptions = await _firestore
            .collection('customers')
            .doc(user.uid)
            .collection('subscriptions')
            .where(FieldPath.documentId, isEqualTo: subId)
            .get();

        if (subscriptions.docs.isNotEmpty) {
          final subData = subscriptions.docs.first.data();
          print('   Status: ${subData['status']}');
          print('   Créé: ${subData['created']?.toDate()}');
        } else {
          print('   ❌ Abonnement non trouvé dans Firestore');
        }
      }

      // 4. Vérifier le webhook secret
      print('\n🔌 Configuration Extension:');
      print('   Pour vérifier les webhooks, allez dans:');
      print('   1. Firebase Console → Extensions → firestore-stripe-payments');
      print('   2. Cliquez sur "Reconfigure extension"');
      print('   3. Vérifiez que STRIPE_WEBHOOK_SECRET est configuré');
      print('   4. Dans Stripe Dashboard → Webhooks, vérifiez l\'endpoint');
    } catch (e) {
      print('❌ Erreur debug: $e');
    }

    print('\n=== FIN DEBUG ===\n');
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
}
