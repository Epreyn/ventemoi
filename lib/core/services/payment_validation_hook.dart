import 'package:cloud_firestore/cloud_firestore.dart';
import '../classes/unique_controllers.dart';
import 'initial_coupons_service.dart';
import 'sponsorship_service.dart';
import 'sponsor_video_service.dart';

class PaymentValidationHook {
  static final FirebaseFirestore _firestore =
      UniquesControllers().data.firebaseFirestore;

  static Future<void> onPaymentAndCGUValidated({
    required String userId,
    required String userEmail,
    required String userType,
    String? stripeSessionId,
    String? paymentOption,
  }) async {
    try {
      // Récupérer les infos complètes de l'utilisateur pour le nom
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'Boutique';

      // NOUVEAU : Attribuer les 16 bons initiaux pour les boutiques/entreprises
      // 12 dans le wallet + 4 distribués automatiquement
      if (userType == 'Boutique' || userType == 'Entreprise') {
        await InitialCouponsService.attributeInitialCoupons(
          userId: userId,
          userEmail: userEmail,
          userType: userType,
          userName: userName,
        );
      }

      // Pour les sponsors, créer les bons cadeaux selon leur formule
      if (userType == 'Sponsor' && stripeSessionId != null) {
        // Récupérer l'établissement du sponsor
        final estabQuery = await _firestore
            .collection('establishments')
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();

        if (estabQuery.docs.isNotEmpty) {
          final establishmentId = estabQuery.docs.first.id;
          final level = paymentOption == 'silver' ? 'silver' : 'bronze';
          final voucherCount = level == 'bronze' ? 1 : 3;

          // Créer les bons cadeaux pour le sponsor
          for (int i = 0; i < voucherCount; i++) {
            await _firestore.collection('gift_vouchers').add({
              'establishment_id': establishmentId,
              'value': 50,
              'status': 'available',
              'type': 'sponsor_welcome',
              'sponsor_level': level,
              'created_at': FieldValue.serverTimestamp(),
              'expires_at': Timestamp.fromDate(
                  DateTime.now().add(const Duration(days: 365))),
            });
          }

          // Mettre à jour l'établissement avec le statut sponsor
          await _firestore
              .collection('establishments')
              .doc(establishmentId)
              .update({
            'is_sponsor': true,
            'sponsor_level': level,
            'sponsor_activated_at': FieldValue.serverTimestamp(),
            'sponsor_expires_at': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 365))),
          });

          // Si Silver, planifier la vidéo incluse
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
      }

      // Vérifier si c'est bien un non-particulier pour le parrainage
      if (userType == 'Particulier') {
        return;
      }

      // Le reste du code pour le parrainage...
      final sponsorInfo = await SponsorshipService.checkForSponsor(userEmail);
      if (sponsorInfo == null) {
        return;
      }

      // Attribuer les 50 points de bonus au parrain
      await SponsorshipService.attributeNonParticulierSponsorshipPoints(
        sponsorId: sponsorInfo['sponsor_id'],
        filleulId: userId,
        filleulEmail: userEmail,
        filleulType: userType,
        sponsorshipDocId: sponsorInfo['sponsorship_doc_id'],
      );


      // Marquer dans le profil utilisateur qu'il a validé le paiement/CGU
      await _firestore.collection('users').doc(userId).update({
        'has_validated_payment': true,
        'has_accepted_cgu': true,
        'payment_validation_date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ne pas faire échouer le processus principal si le parrainage échoue
    }
  }

  /// Vérifie si un utilisateur a déjà validé son paiement et CGU
  static Future<bool> hasAlreadyValidated(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      return data['has_validated_payment'] == true &&
          data['has_accepted_cgu'] == true;
    } catch (e) {
      return false;
    }
  }
}
