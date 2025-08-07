// lib/core/services/initial_coupons_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'automatic_gift_voucher_service.dart';

class InitialCouponsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Attribue les 16 bons initiaux à une boutique après validation du paiement
  /// 12 bons restent dans le wallet, 4 sont distribués automatiquement
  static Future<void> attributeInitialCoupons({
    required String userId,
    required String userEmail,
    required String userType,
    required String userName,
  }) async {
    try {
      // Vérifier que c'est bien une boutique/entreprise
      if (userType != 'Boutique' && userType != 'Entreprise') {
        print('InitialCouponsService: Non applicable pour le type $userType');
        return;
      }

      // Vérifier si les bons ont déjà été attribués
      final walletQuery = await _firestore
          .collection('wallets')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      bool alreadyAttributed = false;

      if (walletQuery.docs.isEmpty) {
        // Créer le wallet avec 12 bons (les 4 autres seront distribués)
        await _firestore.collection('wallets').add({
          'user_id': userId,
          'coupons': 12, // 12 bons pour la boutique
          'points': 0,
          'initial_coupons_attributed': true,
          'initial_coupons_date': FieldValue.serverTimestamp(),
          'bank_details': {
            'iban': '',
            'bic': '',
            'holder': '',
          },
        });
        print('✅ Wallet créé avec 12 bons pour la boutique');
      } else {
        // Vérifier si déjà attribués
        final walletData = walletQuery.docs.first.data();
        alreadyAttributed = walletData['initial_coupons_attributed'] == true;

        if (!alreadyAttributed) {
          // Mettre à jour le wallet existant
          await walletQuery.docs.first.reference.update({
            'coupons': FieldValue.increment(12), // Ajouter 12 bons
            'initial_coupons_attributed': true,
            'initial_coupons_date': FieldValue.serverTimestamp(),
          });
          print('✅ 12 bons ajoutés au wallet existant');
        } else {
          print('⚠️ Les bons initiaux ont déjà été attribués');
          return; // Ne pas redistribuer si déjà fait
        }
      }

      // Distribuer automatiquement 4 bons à 4 utilisateurs différents
      if (!alreadyAttributed) {
        print('🎁 Distribution des 4 bons offerts...');
        await AutomaticGiftVoucherService.attributeWelcomeVouchers(
          commerceId: userId,
          commerceName: userName,
          commerceEmail: userEmail,
        );
      }

      // Créer une notification pour la boutique
      await _firestore.collection('notifications').add({
        'user_id': userId,
        'type': 'initial_coupons',
        'title': '🎉 16 bons cadeaux attribués !',
        'message':
            'Bienvenue ! Vous disposez de 12 bons cadeaux dans votre wallet, et 4 bons ont été offerts à des membres de la communauté pour faire découvrir votre établissement.',
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Créer un document de suivi pour l'attribution
      await _firestore.collection('initial_coupons_tracking').add({
        'user_id': userId,
        'user_type': userType,
        'wallet_coupons': 12,
        'distributed_coupons': 4,
        'total_coupons': 16,
        'attributed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur InitialCouponsService: $e');
      rethrow;
    }
  }
}
