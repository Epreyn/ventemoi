import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/services/association_visibility_service.dart';

class MigrationAssociationVisibility {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> run() async {
    print('🚀 Début de la migration des associations...');

    try {
      // Récupérer l'ID du type Association
      final userTypeSnap = await _firestore
          .collection('user_types')
          .where('name', isEqualTo: 'Association')
          .limit(1)
          .get();

      if (userTypeSnap.docs.isEmpty) {
        print('❌ Type "Association" non trouvé');
        return;
      }

      final associationTypeId = userTypeSnap.docs.first.id;
      print('✅ Type Association trouvé: $associationTypeId');

      // Récupérer tous les utilisateurs de type Association
      final associationUsersSnap = await _firestore
          .collection('users')
          .where('user_type_id', isEqualTo: associationTypeId)
          .get();

      print(
          '📊 Nombre d\'associations trouvées: ${associationUsersSnap.docs.length}');

      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      int totalUpdated = 0;

      // Étape 1 : Ajouter les champs aux établissements
      for (var userDoc in associationUsersSnap.docs) {
        final estabQuery = await _firestore
            .collection('establishments')
            .where('user_id', isEqualTo: userDoc.id)
            .limit(1)
            .get();

        if (estabQuery.docs.isNotEmpty) {
          final estabDoc = estabQuery.docs.first;

          batch.update(estabDoc.reference, {
            'affiliatesCount': 0,
            'isVisibleOverride': false,
            'isAssociation': true,
          });

          batchCount++;
          totalUpdated++;

          if (batchCount >= 500) {
            await batch.commit();
            print('✅ Batch de 500 documents mis à jour');
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        print('✅ Dernier batch mis à jour');
      }

      print('📝 Total établissements mis à jour: $totalUpdated');

      // Étape 2 : Recalculer les compteurs d'affiliés
      print('🔄 Recalcul des compteurs d\'affiliés...');
      int recalculated = 0;

      for (var userDoc in associationUsersSnap.docs) {
        final estabId =
            await AssociationVisibilityService.getEstablishmentIdByUserId(
                userDoc.id);
        if (estabId != null) {
          await AssociationVisibilityService.updateAffiliatesCount(estabId);
          recalculated++;
          if (recalculated % 10 == 0) {
            print('  ↳ $recalculated associations traitées...');
          }
        }
      }

      print('✅ Migration terminée avec succès !');
      print('📊 Résumé:');
      print('  - Associations trouvées: ${associationUsersSnap.docs.length}');
      print('  - Établissements mis à jour: $totalUpdated');
      print('  - Compteurs recalculés: $recalculated');
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
    }
  }
}
