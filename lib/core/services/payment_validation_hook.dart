import 'package:cloud_firestore/cloud_firestore.dart';
import '../classes/unique_controllers.dart';
import 'initial_coupons_service.dart';
import 'sponsorship_service.dart';

class PaymentValidationHook {
  static final FirebaseFirestore _firestore =
      UniquesControllers().data.firebaseFirestore;

  static Future<void> onPaymentAndCGUValidated({
    required String userId,
    required String userEmail,
    required String userType,
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

      // Vérifier si c'est bien un non-particulier pour le parrainage
      if (userType == 'Particulier') {
        // print('PaymentValidationHook: Utilisateur est un particulier, pas de bonus de parrainage');
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

      // print('PaymentValidationHook: 50 points attribués au parrain pour $userEmail');

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
