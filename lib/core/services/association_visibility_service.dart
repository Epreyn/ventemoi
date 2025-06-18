import 'package:cloud_firestore/cloud_firestore.dart';
import '../classes/unique_controllers.dart';

class AssociationVisibilityService {
  static final FirebaseFirestore _firestore =
      UniquesControllers().data.firebaseFirestore;

  /// Met à jour le nombre d'affiliés pour un établissement association
  static Future<void> updateAffiliatesCount(String establishmentId) async {
    try {
      // Récupérer l'établissement
      final estabDoc = await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .get();

      if (!estabDoc.exists) return;

      final userId = estabDoc.data()?['user_id'];
      if (userId == null) return;

      // Récupérer le document sponsorship de l'utilisateur propriétaire
      final sponsorshipQuery = await _firestore
          .collection('sponsorships')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (sponsorshipQuery.docs.isEmpty) {
        // Pas de document sponsorship, donc 0 affiliés
        await estabDoc.reference.update({
          'affiliatesCount': 0,
        });
        await checkAndUpdateVisibility(establishmentId);
        return;
      }

      final sponsorshipDoc = sponsorshipQuery.docs.first;
      final sponsoredEmails =
          List<String>.from(sponsorshipDoc.data()['sponsored_emails'] ?? []);

      // Compter combien de ces emails correspondent à des utilisateurs actifs
      int activeAffiliatesCount = 0;

      for (String email in sponsoredEmails) {
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .where('isEnable', isEqualTo: true)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          activeAffiliatesCount++;
        }
      }

      // Mettre à jour le compteur dans le document establishment
      await estabDoc.reference.update({
        'affiliatesCount': activeAffiliatesCount,
      });

      // Vérifier si l'association doit être visible
      await checkAndUpdateVisibility(establishmentId);
    } catch (e) {
      print('Erreur updateAffiliatesCount: $e');
    }
  }

  /// Vérifie et met à jour la visibilité d'un établissement association
  static Future<void> checkAndUpdateVisibility(String establishmentId) async {
    try {
      final estabDoc = await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .get();

      if (!estabDoc.exists) return;

      final data = estabDoc.data()!;
      final affiliatesCount = data['affiliatesCount'] ?? 0;
      final isVisibleOverride = data['isVisibleOverride'] ?? false;
      final isAssociation = data['isAssociation'] ?? false;

      // Si ce n'est pas une association, on ne fait rien
      if (!isAssociation) return;

      // L'association est visible si :
      // - Elle a 15 affiliés ou plus OU
      // - L'admin a forcé la visibilité
      final shouldBeVisible = affiliatesCount >= 15 || isVisibleOverride;

      // Mettre à jour la visibilité de l'utilisateur propriétaire
      final userId = data['user_id'];
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'isVisible': shouldBeVisible,
        });
      }
    } catch (e) {
      print('Erreur checkAndUpdateVisibility: $e');
    }
  }

  /// Force la visibilité d'une association (admin only)
  static Future<void> setVisibilityOverride(
      String establishmentId, bool override) async {
    try {
      await _firestore
          .collection('establishments')
          .doc(establishmentId)
          .update({
        'isVisibleOverride': override,
      });

      // Recalculer la visibilité
      await checkAndUpdateVisibility(establishmentId);
    } catch (e) {
      print('Erreur setVisibilityOverride: $e');
    }
  }

  /// Trouve l'établissement d'un utilisateur
  static Future<String?> getEstablishmentIdByUserId(String userId) async {
    try {
      final estabQuery = await _firestore
          .collection('establishments')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (estabQuery.docs.isNotEmpty) {
        return estabQuery.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Erreur getEstablishmentIdByUserId: $e');
      return null;
    }
  }
}
