import 'package:cloud_firestore/cloud_firestore.dart';
import '../classes/unique_controllers.dart';
import 'association_waitlist_service.dart';

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
      final affiliatesCount = data['affiliates_count'] ?? 0;
      final forceVisibleOverride = data['force_visible_override'] ?? false;
      final userTypeId = data['user_type_id'] ?? '';
      
      // Vérifier si c'est une association
      final userTypeDoc = await _firestore
          .collection('user_types')
          .doc(userTypeId)
          .get();
      
      if (!userTypeDoc.exists) return;
      
      final typeName = userTypeDoc.data()?['name'] ?? '';
      final isAssociation = typeName == 'Association';

      // Si ce n'est pas une association, on ne fait rien
      if (!isAssociation) return;
      
      // Si l'admin a forcé la visibilité, l'association est visible
      if (forceVisibleOverride) {
        await estabDoc.reference.update({
          'is_visible': true,
        });
        
        // Traiter les bons en attente pour cette association
        await AssociationWaitlistService.processPendingVouchers(establishmentId);
        return;
      }

      // Si l'association a 15+ affiliés
      if (affiliatesCount >= 15) {
        // Vérifier si elle peut devenir visible selon le nombre de boutiques
        final canBeVisible = await AssociationWaitlistService.canAssociationBeVisible();
        
        if (canBeVisible) {
          // L'association peut être visible
          await estabDoc.reference.update({
            'is_visible': true,
            'became_visible_at': FieldValue.serverTimestamp(),
          });
          
          // Traiter les bons en attente pour cette association
          await AssociationWaitlistService.processPendingVouchers(establishmentId);
        } else {
          // L'association a assez d'affiliés mais doit attendre
          // Ajouter à la liste d'attente si elle n'y est pas déjà
          final isCurrentlyVisible = data['is_visible'] ?? false;
          
          if (!isCurrentlyVisible) {
            await AssociationWaitlistService.addToWaitlist(establishmentId);
            
            // Mettre à jour pour indiquer qu'elle est en attente
            await estabDoc.reference.update({
              'is_visible': false,
              'in_waitlist': true,
              'waitlist_reason': 'Limite du nombre d\'associations atteinte',
            });
          }
        }
      } else {
        // Pas assez d'affiliés, association non visible
        await estabDoc.reference.update({
          'is_visible': false,
          'in_waitlist': false,
        });
      }
    } catch (e) {
      print('Erreur dans checkAndUpdateVisibility: $e');
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
      return null;
    }
  }
}
