// lib/core/services/sponsor_video_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../classes/unique_controllers.dart';
import '../constants/stripe_prices.dart';
import '../models/stripe_service.dart';

class SponsorVideoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== SPONSORS ====================

  /// Acheter un pack sponsor
  static Future<bool> purchaseSponsorPackage({
    required String establishmentId,
    required String level, // 'bronze' ou 'silver'
  }) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      final priceId = level == 'bronze'
          ? StripePrices.sponsorBronzePriceId
          : StripePrices.sponsorSilverPriceId;

      final amount = level == 'bronze'
          ? StripePrices.sponsorBronzeAmount
          : StripePrices.sponsorSilverAmount;

      // Créer la session de paiement Stripe
      final Map<String, String>? result =
          await StripeService.to.createGenericOneTimeCheckout(
        establishmentId: establishmentId,
        amount: amount,
        productName: 'Pack Sponsor ${level == 'bronze' ? 'Bronze' : 'Silver'}',
        description: level == 'bronze'
            ? '1 bon cadeau 50€ + Mise en avant + Logo sur l\'application'
            : '3 bons cadeaux 50€ + 2 mises en avant + Vidéo standard + Visibilité Prestige',
        metadata: level == 'bronze'
            ? StripePrices.sponsorBronzeMetadata
            : StripePrices.sponsorSilverMetadata,
      );

      if (result != null && result['sessionId'] != null) {
        // Enregistrer la commande en attente
        await _firestore.collection('sponsor_orders').add({
          'establishment_id': establishmentId,
          'level': level,
          'stripe_session_id': result['sessionId'],
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
          'benefits': level == 'bronze'
              ? {
                  'vouchers': 1,
                  'voucher_value': 50,
                  'social_media_boost': true,
                  'logo_display': true,
                }
              : {
                  'vouchers': 3,
                  'voucher_value': 50,
                  'social_media_boost': 2,
                  'video_included': 'standard',
                  'prestige_visibility': true,
                },
        });

        return true;
      }

      return false;
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible de traiter le paiement: $e',
            true,
          );
      return false;
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  /// Activer le sponsor après paiement réussi
  static Future<void> activateSponsor(String sessionId) async {
    try {
      // Récupérer la commande
      final orderQuery = await _firestore
          .collection('sponsor_orders')
          .where('stripe_session_id', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (orderQuery.docs.isNotEmpty) {
        final order = orderQuery.docs.first;
        final orderData = order.data();
        final establishmentId = orderData['establishment_id'];
        final level = orderData['level'];

        // Mettre à jour le statut de la commande
        await order.reference.update({
          'status': 'completed',
          'activated_at': FieldValue.serverTimestamp(),
        });

        // Activer le sponsor sur l'établissement
        await _firestore
            .collection('establishments')
            .doc(establishmentId)
            .update({
          'is_sponsor': true,
          'sponsor_level': level,
          'sponsor_activated_at': FieldValue.serverTimestamp(),
          'sponsor_expires_at': DateTime.now().add(Duration(days: 365)), // 1 an
        });

        // Créer les bons cadeaux
        final voucherCount = level == 'bronze' ? 1 : 3;
        for (int i = 0; i < voucherCount; i++) {
          await _firestore.collection('gift_vouchers').add({
            'establishment_id': establishmentId,
            'value': 50,
            'status': 'available',
            'type': 'sponsor_welcome',
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        // Si Silver, planifier la vidéo
        if (level == 'silver') {
          await _firestore.collection('video_orders').add({
            'establishment_id': establishmentId,
            'type': 'standard',
            'status': 'pending',
            'included_in': 'sponsor_silver',
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // Utiliser un logger approprié au lieu de print
      // UniquesControllers().data.debugPrint('Erreur activation sponsor: $e');
    }
  }

  // ==================== VIDÉOS ====================

  /// Acheter une prestation vidéo
  static Future<bool> purchaseVideoPackage({
    required String establishmentId,
    required String level, // 'standard', 'premium', ou 'signature'
    required bool isMember,
  }) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      // Déterminer le prix selon le niveau et le statut membre
      String priceId;
      int amount;

      switch (level) {
        case 'standard':
          if (isMember) {
            priceId = StripePrices.videoStandardMembrePriceId;
            amount = StripePrices.videoStandardMembreAmount;
          } else {
            priceId = StripePrices.videoStandardPublicPriceId;
            amount = StripePrices.videoStandardPublicAmount;
          }
          break;
        case 'premium':
          if (isMember) {
            priceId = StripePrices.videoPremiumMembrePriceId;
            amount = StripePrices.videoPremiumMembreAmount;
          } else {
            priceId = StripePrices.videoPremiumPublicPriceId;
            amount = StripePrices.videoPremiumPublicAmount;
          }
          break;
        case 'signature':
          if (isMember) {
            priceId = StripePrices.videoSignatureMembrePriceId;
            amount = StripePrices.videoSignatureMembreAmount;
          } else {
            priceId = StripePrices.videoSignaturePublicPriceId;
            amount = StripePrices.videoSignaturePublicAmount;
          }
          break;
        default:
          throw Exception('Niveau vidéo invalide');
      }

      // Créer la session de paiement Stripe
      final Map<String, String>? result =
          await StripeService.to.createGenericOneTimeCheckout(
        establishmentId: establishmentId,
        amount: amount,
        productName:
            'Vidéo ${level[0].toUpperCase() + level.substring(1)} ${isMember ? '(Membre)' : '(Public)'}',
        description: StripePrices.productDescriptions['video_$level'] ??
            'Prestation vidéo professionnelle',
        metadata: {
          'type': 'video',
          'level': level,
          'customer_type': isMember ? 'member' : 'public',
        },
      );

      if (result != null && result['sessionId'] != null) {
        // Enregistrer la commande vidéo
        await _firestore.collection('video_orders').add({
          'establishment_id': establishmentId,
          'level': level,
          'is_member': isMember,
          'stripe_session_id': result['sessionId'],
          'status': 'pending_payment',
          'created_at': FieldValue.serverTimestamp(),
          'details': _getVideoDetails(level),
        });

        return true;
      }

      return false;
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible de traiter le paiement: $e',
            true,
          );
      return false;
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  /// Obtenir les détails de la vidéo selon le niveau
  static Map<String, dynamic> _getVideoDetails(String level) {
    switch (level) {
      case 'standard':
        return {
          'duration': '30 seconds',
          'shooting_time': '1h30',
          'format': 'vertical',
          'montage': 'simple',
          'drone': false,
        };
      case 'premium':
        return {
          'duration': '1 minute',
          'shooting_time': 'half day',
          'format': 'vertical or horizontal',
          'montage': 'advanced',
          'drone': true,
          'drone_shots': 1,
        };
      case 'signature':
        return {
          'duration': '1 minute 30 seconds',
          'shooting_time': '6 hours',
          'format': 'vertical or horizontal',
          'montage': 'professional',
          'drone': true,
          'drone_shots': 'multiple',
          'interview': true,
        };
      default:
        return {};
    }
  }

  // ==================== BANDEAU PUBLICITAIRE ====================

  /// Acheter un emplacement sur le bandeau publicitaire
  static Future<bool> purchaseBannerAd({
    required String establishmentId,
    required DateTime startDate,
  }) async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      // Vérifier la disponibilité de la semaine
      final endDate = startDate.add(Duration(days: 7));
      final conflictQuery = await _firestore
          .collection('banner_ads')
          .where('start_date', isLessThan: endDate)
          .where('end_date', isGreaterThan: startDate)
          .get();

      if (conflictQuery.docs.isNotEmpty) {
        UniquesControllers().data.snackbar(
              'Indisponible',
              'Cette période est déjà réservée',
              true,
            );
        return false;
      }

      // Créer la session de paiement Stripe
      final Map<String, String>? result =
          await StripeService.to.createGenericOneTimeCheckout(
        establishmentId: establishmentId,
        amount: StripePrices.bandeauHebdoAmount,
        productName: 'Bandeau publicitaire',
        description:
            'Affichage dans le bandeau "Offres du moment" pendant 7 jours',
        metadata: {
          'type': 'advertising',
          'duration': '7_days',
          'start_date': startDate.toIso8601String(),
        },
      );

      if (result != null && result['sessionId'] != null) {
        // Réserver l'emplacement
        await _firestore.collection('banner_ads').add({
          'establishment_id': establishmentId,
          'stripe_session_id': result['sessionId'],
          'start_date': startDate,
          'end_date': endDate,
          'status': 'pending_payment',
          'created_at': FieldValue.serverTimestamp(),
        });

        return true;
      }

      return false;
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur',
            'Impossible de traiter le paiement: $e',
            true,
          );
      return false;
    } finally {
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }

  /// Activer la publicité après paiement
  static Future<void> activateBannerAd(String sessionId) async {
    try {
      final adQuery = await _firestore
          .collection('banner_ads')
          .where('stripe_session_id', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (adQuery.docs.isNotEmpty) {
        await adQuery.docs.first.reference.update({
          'status': 'active',
          'activated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Utiliser un logger approprié au lieu de print
      //UniquesControllers().data.debugPrint('Erreur activation bannière: $e');
    }
  }

  // ==================== GESTION DES COMMANDES ====================

  /// Récupérer les commandes sponsor d'un établissement
  static Stream<List<Map<String, dynamic>>> getSponsorOrders(
      String establishmentId) {
    return _firestore
        .collection('sponsor_orders')
        .where('establishment_id', isEqualTo: establishmentId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Récupérer les commandes vidéo d'un établissement
  static Stream<List<Map<String, dynamic>>> getVideoOrders(
      String establishmentId) {
    return _firestore
        .collection('video_orders')
        .where('establishment_id', isEqualTo: establishmentId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Récupérer les réservations de bandeau d'un établissement
  static Stream<List<Map<String, dynamic>>> getBannerAds(
      String establishmentId) {
    return _firestore
        .collection('banner_ads')
        .where('establishment_id', isEqualTo: establishmentId)
        .orderBy('start_date', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }
}
