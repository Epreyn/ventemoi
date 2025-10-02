import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_email_service.dart';

class AccountDeletionService {
  static final AccountDeletionService _instance = AccountDeletionService._internal();
  factory AccountDeletionService() => _instance;
  AccountDeletionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Supprime complètement un compte utilisateur
  /// Préserve l'historique des transactions pour les autres utilisateurs
  Future<void> deleteUserAccount({
    required String uid,
    String? userEmail,
    String? userName,
  }) async {
    try {
      // 1. Récupérer les infos utilisateur si pas fournies
      if (userEmail == null || userName == null) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          userEmail = userDoc.data()?['email'] ?? '';
          userName = userDoc.data()?['name'] ?? '';
        }
      }

      // 2. Anonymiser les transactions existantes (garder l'historique mais sans données perso)
      await _anonymizeUserTransactions(uid, userName ?? 'Utilisateur supprimé');

      // 3. Supprimer les données personnelles dans l'ordre
      await _deletePersonalData(uid);

      // 4. Envoyer un email de confirmation si possible
      if (userEmail != null && userEmail.isNotEmpty) {
        final emailService = FirebaseEmailService();
        await emailService.sendAccountDeletionNotification(userEmail, userName ?? '');
      }

      // 5. Supprimer le compte Firebase Auth (doit être fait en dernier)
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        await currentUser.delete();
      }

    } catch (e) {
      print('Erreur lors de la suppression du compte: $e');
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  /// Anonymise toutes les transactions de l'utilisateur
  /// Remplace le nom et l'email par des valeurs anonymes
  Future<void> _anonymizeUserTransactions(String uid, String anonymizedName) async {
    final batch = _firestore.batch();

    // Anonymiser les points_attributions où l'utilisateur est le donneur
    final giverAttributions = await _firestore
        .collection('points_attributions')
        .where('giver_id', isEqualTo: uid)
        .get();

    for (var doc in giverAttributions.docs) {
      batch.update(doc.reference, {
        'giver_name': '$anonymizedName (compte supprimé)',
        'giver_email': 'supprime@ventemoi.com',
        // On garde l'ID pour la cohérence des données mais on marque comme supprimé
        'giver_deleted': true,
        'deletion_date': FieldValue.serverTimestamp(),
      });
    }

    // Anonymiser les points_attributions où l'utilisateur est le receveur
    final targetAttributions = await _firestore
        .collection('points_attributions')
        .where('target_id', isEqualTo: uid)
        .get();

    for (var doc in targetAttributions.docs) {
      batch.update(doc.reference, {
        'target_name': '$anonymizedName (compte supprimé)',
        'target_email': 'supprime@ventemoi.com',
        'target_deleted': true,
        'deletion_date': FieldValue.serverTimestamp(),
      });
    }

    // Anonymiser les purchases
    final purchases = await _firestore
        .collection('purchases')
        .where('buyer_id', isEqualTo: uid)
        .get();

    for (var doc in purchases.docs) {
      batch.update(doc.reference, {
        'buyer_name': '$anonymizedName (compte supprimé)',
        'buyer_email': 'supprime@ventemoi.com',
        'buyer_deleted': true,
        'deletion_date': FieldValue.serverTimestamp(),
      });
    }

    // Anonymiser les ventes
    final sales = await _firestore
        .collection('purchases')
        .where('seller_id', isEqualTo: uid)
        .get();

    for (var doc in sales.docs) {
      batch.update(doc.reference, {
        'seller_name': 'Établissement supprimé',
        'seller_deleted': true,
        'deletion_date': FieldValue.serverTimestamp(),
      });
    }

    // Anonymiser les vouchers (bons cadeaux)
    final vouchers = await _firestore
        .collection('vouchers')
        .where('boutique_id', isEqualTo: uid)
        .get();

    for (var doc in vouchers.docs) {
      batch.update(doc.reference, {
        'boutique_name': 'Boutique supprimée',
        'boutique_email': 'supprime@ventemoi.com',
        'boutique_deleted': true,
      });
    }

    // Anonymiser les vouchers reçus par des associations
    final associationVouchers = await _firestore
        .collection('vouchers')
        .where('association_user_id', isEqualTo: uid)
        .get();

    for (var doc in associationVouchers.docs) {
      batch.update(doc.reference, {
        'association_name': 'Association supprimée',
        'association_deleted': true,
      });
    }

    await batch.commit();
  }

  /// Supprime toutes les données personnelles de l'utilisateur
  Future<void> _deletePersonalData(String uid) async {
    final batch = _firestore.batch();

    // 1. Supprimer le document utilisateur principal
    batch.delete(_firestore.collection('users').doc(uid));

    // 2. Supprimer le(s) wallet(s)
    final wallets = await _firestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in wallets.docs) {
      batch.delete(doc.reference);
    }

    // 3. Supprimer les établissements
    final establishments = await _firestore
        .collection('establishments')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in establishments.docs) {
      batch.delete(doc.reference);
    }

    // 4. Supprimer les sponsorships
    final sponsorships = await _firestore
        .collection('sponsorships')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in sponsorships.docs) {
      batch.delete(doc.reference);
    }

    // 5. Supprimer les notifications
    final notifications = await _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    // 6. Supprimer les favoris
    final favorites = await _firestore
        .collection('favorites')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in favorites.docs) {
      batch.delete(doc.reference);
    }

    // 7. Supprimer les pending_points_attributions
    final pendingPoints = await _firestore
        .collection('pending_points_attributions')
        .where('giver_id', isEqualTo: uid)
        .get();

    for (var doc in pendingPoints.docs) {
      batch.delete(doc.reference);
    }

    // 8. Supprimer les gift_notifications
    final giftNotifications = await _firestore
        .collection('gift_notifications')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in giftNotifications.docs) {
      batch.delete(doc.reference);
    }

    // 9. Retirer l'utilisateur des listes de sponsorship d'autres utilisateurs
    await _removeFromSponsorshipLists(uid);

    // 10. Supprimer les messages de chat (si applicable)
    final chatMessages = await _firestore
        .collection('chat_messages')
        .where('sender_id', isEqualTo: uid)
        .get();

    for (var doc in chatMessages.docs) {
      // Anonymiser au lieu de supprimer pour garder la cohérence des conversations
      batch.update(doc.reference, {
        'sender_name': 'Utilisateur supprimé',
        'sender_deleted': true,
      });
    }

    // 11. Supprimer les reviews/avis
    final reviews = await _firestore
        .collection('reviews')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in reviews.docs) {
      // Anonymiser les avis pour garder les statistiques
      batch.update(doc.reference, {
        'user_name': 'Utilisateur supprimé',
        'user_deleted': true,
      });
    }

    // Exécuter toutes les suppressions
    await batch.commit();

    // Nettoyer les collections spécifiques qui pourraient avoir des références
    await _cleanupReferences(uid);
  }

  /// Retire l'utilisateur des listes de parrainage d'autres utilisateurs
  Future<void> _removeFromSponsorshipLists(String uid) async {
    // Récupérer l'email de l'utilisateur pour le retirer des listes
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userEmail = userDoc.data()?['email']?.toString().toLowerCase() ?? '';

    if (userEmail.isNotEmpty) {
      // Retirer des listes sponsored_emails
      final sponsorships = await _firestore
          .collection('sponsorships')
          .where('sponsored_emails', arrayContains: userEmail)
          .get();

      for (var doc in sponsorships.docs) {
        await doc.reference.update({
          'sponsored_emails': FieldValue.arrayRemove([userEmail]),
        });
      }
    }
  }

  /// Nettoie les références résiduelles dans d'autres collections
  Future<void> _cleanupReferences(String uid) async {
    // Nettoyer les références dans les offers
    final offers = await _firestore
        .collection('offers')
        .where('establishment_id', isEqualTo: uid)
        .get();

    for (var doc in offers.docs) {
      await doc.reference.delete();
    }

    // Nettoyer les références dans les enterprise_categories
    final categories = await _firestore
        .collection('enterprise_categories')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in categories.docs) {
      await doc.reference.delete();
    }

    // Nettoyer les références dans les association waitlists
    final waitlists = await _firestore
        .collection('association_waitlist')
        .where('user_id', isEqualTo: uid)
        .get();

    for (var doc in waitlists.docs) {
      await doc.reference.delete();
    }
  }

  /// Vérifie si l'utilisateur peut supprimer son compte
  /// (par exemple, s'il a des transactions en cours)
  Future<bool> canDeleteAccount(String uid) async {
    // Vérifier s'il y a des transactions non validées
    final pendingTransactions = await _firestore
        .collection('points_attributions')
        .where('target_id', isEqualTo: uid)
        .where('validated', isEqualTo: false)
        .get();

    if (pendingTransactions.docs.isNotEmpty) {
      throw Exception('Vous avez des transactions en attente. Veuillez les valider avant de supprimer votre compte.');
    }

    // Vérifier s'il y a des bons non utilisés
    final activeVouchers = await _firestore
        .collection('vouchers')
        .where('boutique_id', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .get();

    if (activeVouchers.docs.isNotEmpty) {
      throw Exception('Vous avez des bons actifs. Veuillez les utiliser ou les annuler avant de supprimer votre compte.');
    }

    // Vérifier le solde du wallet
    final wallet = await _firestore
        .collection('wallets')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();

    if (wallet.docs.isNotEmpty) {
      final walletData = wallet.docs.first.data();
      final points = walletData['points'] ?? 0;
      final coupons = walletData['coupons'] ?? 0;

      if (points > 0) {
        throw Exception('Vous avez encore $points points. Veuillez les utiliser avant de supprimer votre compte.');
      }

      if (coupons > 0) {
        throw Exception('Vous avez encore $coupons bons. Veuillez les utiliser avant de supprimer votre compte.');
      }
    }

    return true;
  }
}