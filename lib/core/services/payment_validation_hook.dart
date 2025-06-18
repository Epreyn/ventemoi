import 'package:cloud_firestore/cloud_firestore.dart';
import '../classes/unique_controllers.dart';
import 'sponsorship_service.dart';

class PaymentValidationHook {
  static final FirebaseFirestore _firestore =
      UniquesControllers().data.firebaseFirestore;

  /// Appelé lorsqu'un utilisateur non-particulier valide son paiement et accepte les CGU
  static Future<void> onPaymentAndCGUValidated({
    required String userId,
    required String userEmail,
    required String userType,
  }) async {
    try {
      // Vérifier si c'est bien un non-particulier
      if (userType == 'Particulier') {
        print(
            'PaymentValidationHook: Utilisateur est un particulier, pas de bonus de parrainage');
        return;
      }

      // Vérifier si l'utilisateur a un parrain
      final sponsorInfo = await SponsorshipService.checkForSponsor(userEmail);
      if (sponsorInfo == null) {
        print('PaymentValidationHook: Pas de parrain trouvé pour $userEmail');
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

      print(
          'PaymentValidationHook: 50 points attribués au parrain pour $userEmail');

      // Optionnel : Marquer dans le profil utilisateur qu'il a validé le paiement/CGU
      await _firestore.collection('users').doc(userId).update({
        'has_validated_payment': true,
        'has_accepted_cgu': true,
        'payment_validation_date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur PaymentValidationHook: $e');
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
      print('Erreur hasAlreadyValidated: $e');
      return false;
    }
  }
}
