import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../classes/unique_controllers.dart';
import '../models/stripe_product.dart';

class StripeService extends GetxService {
  static StripeService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // IDs des produits prédéfinis (à configurer dans Stripe Dashboard)
  static const String cguValidationProductId = 'prod_cgu_validation';
  static const String additionalCategorySlotProductId =
      'prod_additional_category';

  // -------------------------------------------------------------------------
  // Initialisation du service
  // -------------------------------------------------------------------------
  @override
  Future<void> onInit() async {
    super.onInit();
    await _ensureProductsExist();
  }

  // -------------------------------------------------------------------------
  // Créer ou vérifier que les produits existent
  // -------------------------------------------------------------------------
  Future<void> _ensureProductsExist() async {
    try {
      // Vérifier si les produits existent, sinon les créer
      await _createProductIfNotExists(
        productId: cguValidationProductId,
        name: 'Validation CGU - Accès Professionnel',
        description:
            'Paiement unique pour accéder aux fonctionnalités professionnelles',
        priceInCents: 2900, // 29€
        metadata: {'type': 'cgu_validation'},
      );

      await _createProductIfNotExists(
        productId: additionalCategorySlotProductId,
        name: 'Slot de Catégorie Supplémentaire',
        description: 'Ajout d\'un slot de catégorie pour les entreprises',
        priceInCents: 500, // 5€
        metadata: {'type': 'additional_category_slot'},
      );
    } catch (e) {
      print('Erreur lors de la création des produits Stripe: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Créer un produit et son prix s'ils n'existent pas
  // -------------------------------------------------------------------------
  Future<void> _createProductIfNotExists({
    required String productId,
    required String name,
    required String description,
    required int priceInCents,
    required Map<String, dynamic> metadata,
  }) async {
    // Vérifier si le produit existe
    final productDoc =
        await _firestore.collection('products').doc(productId).get();

    if (!productDoc.exists) {
      // Créer le produit
      await _firestore.collection('products').doc(productId).set({
        'name': name,
        'description': description,
        'active': true,
        'metadata': metadata,
        'created': FieldValue.serverTimestamp(),
      });

      // Créer le prix associé
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('prices')
          .add({
        'currency': 'eur',
        'unit_amount': priceInCents,
        'type': 'one_time',
        'active': true,
        'metadata': metadata,
      });
    }
  }

  // -------------------------------------------------------------------------
  // Créer une session de paiement pour la validation des CGU
  // -------------------------------------------------------------------------
  Future<String?> createCguValidationCheckout({
    required String userType, // 'Boutique', 'Entreprise', 'Association'
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      // Récupérer le prix du produit CGU
      final priceSnapshot = await _firestore
          .collection('products')
          .doc(cguValidationProductId)
          .collection('prices')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (priceSnapshot.docs.isEmpty) {
        throw 'Prix non trouvé pour la validation CGU';
      }

      final priceId = priceSnapshot.docs.first.id;

      // Créer le customer s'il n'existe pas
      await _createCustomerIfNeeded(user.uid, user.email ?? '');

      // Créer la session de checkout
      final checkoutSessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add({
        'mode': 'payment',
        'success_url': successUrl ?? 'https://ventemoi.com/success',
        'cancel_url': cancelUrl ?? 'https://ventemoi.com/cancel',
        'line_items': [
          {
            'price': priceId,
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'cgu_validation',
          'user_type': userType,
          'user_id': user.uid,
        },
        'allow_promotion_codes': true,
      });

      // Attendre que Stripe traite la session et ajoute l'URL
      await _waitForCheckoutUrl(user.uid, checkoutSessionRef.id);

      // Récupérer l'URL de checkout
      final sessionDoc = await checkoutSessionRef.get();
      final sessionData = sessionDoc.data();

      return sessionData?['url'] as String?;
    } catch (e) {
      print('Erreur lors de la création du checkout CGU: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Créer une session de paiement pour un slot de catégorie supplémentaire
  // -------------------------------------------------------------------------
  Future<String?> createAdditionalCategorySlotCheckout({
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      // Récupérer le prix du slot supplémentaire
      final priceSnapshot = await _firestore
          .collection('products')
          .doc(additionalCategorySlotProductId)
          .collection('prices')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (priceSnapshot.docs.isEmpty) {
        throw 'Prix non trouvé pour le slot de catégorie';
      }

      final priceId = priceSnapshot.docs.first.id;

      // Créer le customer s'il n'existe pas
      await _createCustomerIfNeeded(user.uid, user.email ?? '');

      // Créer la session de checkout
      final checkoutSessionRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add({
        'mode': 'payment',
        'success_url': successUrl ?? 'https://ventemoi.com/success',
        'cancel_url': cancelUrl ?? 'https://ventemoi.com/cancel',
        'line_items': [
          {
            'price': priceId,
            'quantity': 1,
          }
        ],
        'metadata': {
          'type': 'additional_category_slot',
          'user_id': user.uid,
        },
        'allow_promotion_codes': true,
      });

      // Attendre que Stripe traite la session
      await _waitForCheckoutUrl(user.uid, checkoutSessionRef.id);

      // Récupérer l'URL de checkout
      final sessionDoc = await checkoutSessionRef.get();
      final sessionData = sessionDoc.data();

      return sessionData?['url'] as String?;
    } catch (e) {
      print('Erreur lors de la création du checkout slot: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Créer un customer Stripe s'il n'existe pas
  // -------------------------------------------------------------------------
  Future<void> _createCustomerIfNeeded(String uid, String email) async {
    final customerDoc = await _firestore.collection('customers').doc(uid).get();

    if (!customerDoc.exists) {
      await _firestore.collection('customers').doc(uid).set({
        'email': email,
        'metadata': {
          'firebaseUID': uid,
        },
      });
    }
  }

  // -------------------------------------------------------------------------
  // Attendre que Stripe ajoute l'URL de checkout
  // -------------------------------------------------------------------------
  Future<void> _waitForCheckoutUrl(String customerId, String sessionId) async {
    int attempts = 0;
    const maxAttempts = 10;
    const delay = Duration(milliseconds: 500);

    while (attempts < maxAttempts) {
      final sessionDoc = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('checkout_sessions')
          .doc(sessionId)
          .get();

      final sessionData = sessionDoc.data();
      if (sessionData != null && sessionData['url'] != null) {
        return;
      }

      attempts++;
      await Future.delayed(delay);
    }

    throw 'Timeout: URL de checkout non générée';
  }

  // -------------------------------------------------------------------------
  // Ouvrir l'URL de checkout
  // -------------------------------------------------------------------------
  Future<void> launchCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } else {
      throw 'Impossible d\'ouvrir l\'URL de paiement';
    }
  }

  // -------------------------------------------------------------------------
  // Vérifier le statut d'un paiement
  // -------------------------------------------------------------------------
  Future<bool> hasValidatedCgu(String userId) async {
    try {
      // Chercher une session de paiement réussie pour les CGU
      final sessionsSnapshot = await _firestore
          .collection('customers')
          .doc(userId)
          .collection('checkout_sessions')
          .where('payment_status', isEqualTo: 'paid')
          .get();

      for (final session in sessionsSnapshot.docs) {
        final metadata = session.data()['metadata'] as Map<String, dynamic>?;
        if (metadata?['type'] == 'cgu_validation') {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Erreur lors de la vérification CGU: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Écouter les paiements réussis
  // -------------------------------------------------------------------------
  Stream<QuerySnapshot> listenToPaymentSessions(String userId) {
    return _firestore
        .collection('customers')
        .doc(userId)
        .collection('checkout_sessions')
        .where('payment_status', isEqualTo: 'paid')
        .snapshots();
  }

  // -------------------------------------------------------------------------
  // Traiter un paiement réussi
  // -------------------------------------------------------------------------
  Future<void> handleSuccessfulPayment(DocumentSnapshot sessionDoc) async {
    try {
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final metadata = sessionData['metadata'] as Map<String, dynamic>?;

      if (metadata == null) return;

      final paymentType = metadata['type'] as String?;
      final userId = metadata['user_id'] as String?;

      if (userId == null) return;

      switch (paymentType) {
        case 'cgu_validation':
          await _handleCguValidationPayment(userId, metadata);
          break;
        case 'additional_category_slot':
          await _handleAdditionalSlotPayment(userId);
          break;
      }
    } catch (e) {
      print('Erreur lors du traitement du paiement: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Traiter le paiement de validation des CGU
  // -------------------------------------------------------------------------
  Future<void> _handleCguValidationPayment(
    String userId,
    Map<String, dynamic> metadata,
  ) async {
    // Marquer les CGU comme acceptées dans l'établissement
    final establishmentSnapshot = await _firestore
        .collection('establishments')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    if (establishmentSnapshot.docs.isNotEmpty) {
      await establishmentSnapshot.docs.first.reference.update({
        'has_accepted_contract': true,
        'cgu_payment_date': FieldValue.serverTimestamp(),
      });
    }

    // Traiter le parrainage si applicable
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final userEmail = userData['email'] as String?;

      if (userEmail != null) {
        await _handleSponsorshipRewardIfAny(userId, userEmail);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Traiter le paiement d'un slot supplémentaire
  // -------------------------------------------------------------------------
  Future<void> _handleAdditionalSlotPayment(String userId) async {
    final establishmentSnapshot = await _firestore
        .collection('establishments')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    if (establishmentSnapshot.docs.isNotEmpty) {
      final estabDoc = establishmentSnapshot.docs.first;
      final currentSlots = estabDoc.data()['enterprise_category_slots'] ?? 2;

      await estabDoc.reference.update({
        'enterprise_category_slots': currentSlots + 1,
      });
    }
  }

  // -------------------------------------------------------------------------
  // Gérer la récompense de parrainage
  // -------------------------------------------------------------------------
  Future<void> _handleSponsorshipRewardIfAny(
      String userId, String userEmail) async {
    // Chercher s'il existe un parrainage pour cet email
    final sponsorshipSnapshot = await _firestore
        .collection('sponsorships')
        .where('sponsoredEmails', arrayContains: userEmail.toLowerCase())
        .get();

    if (sponsorshipSnapshot.docs.isEmpty) return;

    final sponsorshipDoc = sponsorshipSnapshot.docs.first;
    final sponsorData = sponsorshipDoc.data();
    final sponsorUid = sponsorData['user_id'] as String?;

    if (sponsorUid == null) return;

    // Ajouter 50 points au parrain
    final sponsorWalletSnapshot = await _firestore
        .collection('wallets')
        .where('user_id', isEqualTo: sponsorUid)
        .limit(1)
        .get();

    if (sponsorWalletSnapshot.docs.isEmpty) {
      // Créer un wallet pour le parrain
      await _firestore.collection('wallets').add({
        'user_id': sponsorUid,
        'points': 50,
        'coupons': 0,
      });
    } else {
      // Mettre à jour le wallet existant
      await sponsorWalletSnapshot.docs.first.reference.update({
        'points': FieldValue.increment(50),
      });
    }

    // Envoyer un email au parrain
    await _sendSponsorshipRewardEmail(sponsorUid, userEmail);
  }

  // -------------------------------------------------------------------------
  // Envoyer un email de récompense au parrain
  // -------------------------------------------------------------------------
  Future<void> _sendSponsorshipRewardEmail(
      String sponsorUid, String sponsoredEmail) async {
    try {
      final sponsorDoc =
          await _firestore.collection('users').doc(sponsorUid).get();
      if (!sponsorDoc.exists) return;

      final sponsorData = sponsorDoc.data()!;
      final sponsorEmail = sponsorData['email'] as String?;
      final sponsorName = sponsorData['name'] as String? ?? 'Sponsor';

      if (sponsorEmail == null || sponsorEmail.isEmpty) return;

      // Utiliser le système d'email existant de votre ControllerMixin
      final mailDoc = {
        "to": sponsorEmail,
        "message": {
          "subject": "Parrainage : +50 points - VenteMoi",
          "html": _buildSponsorshipEmailHtml(sponsorName, sponsoredEmail),
        },
      };

      await _firestore.collection('mail').add(mailDoc);
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'email de parrainage: $e');
    }
  }

  String _buildSponsorshipEmailHtml(String sponsorName, String sponsoredEmail) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Vente Moi – Récompense de Parrainage</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #fafafa; color: #333; }
      .header { background-color: #f8b02a; padding: 16px; text-align: center; }
      .content { margin: 16px; }
      h1 { color: #f8b02a; }
      p { line-height: 1.5; }
      .footer { margin: 16px; font-size: 12px; color: #666; }
    </style>
  </head>
  <body>
    <div class="header">
      <img src="https://firebasestorage.googleapis.com/v0/b/vente-moi.appspot.com/o/logo.png?alt=media"
           alt="Logo Vente Moi" style="max-height: 50px;" />
    </div>
    <div class="content">
      <h1>Félicitations $sponsorName !</h1>
      <p>
        Vous venez de gagner <strong>50 points</strong>
        grâce au parrainage de <strong>$sponsoredEmail</strong> qui vient de valider ses CGU professionnelles.
      </p>
      <p>
        Merci d'utiliser Vente Moi et de contribuer au développement de notre communauté !
      </p>
      <p>
        À très bientôt,<br>
        L'équipe Vente Moi
      </p>
    </div>
    <div class="footer">
      Cet e-mail vous a été envoyé automatiquement par Vente Moi.<br>
      Pour toute question, contactez
      <a href="mailto:support@ventemoi.com">support@ventemoi.com</a>.
    </div>
  </body>
</html>
''';
  }
}
