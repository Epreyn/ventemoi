// lib/utils/enterprise_category_migration.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EnterpriseCategoryMigration {
  final FirebaseFirestore firestore;

  EnterpriseCategoryMigration(this.firestore);

  Future<void> migrateExistingCategories() async {
    print('🔄 Début de la migration des catégories entreprise...');

    final batch = firestore.batch();
    final snapshot = await firestore.collection('enterprise_categories').get();

    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Ajouter les nouveaux champs s'ils n'existent pas
      if (!data.containsKey('parent_id') || !data.containsKey('level')) {
        batch.update(doc.reference, {
          'parent_id':
              null, // Toutes les catégories existantes deviennent principales
          'level': 0, // Niveau 0 = catégorie principale
        });
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
      print('✅ Migration terminée : $count catégories mises à jour');
    } else {
      print('ℹ️ Aucune migration nécessaire');
    }
  }

  // Ajoutez ces méthodes dans la classe EnterpriseCategoryMigration

  // Créer des exemples de sous-catégories
  Future<void> createSampleSubcategories() async {
    print('🔄 Création d\'exemples de sous-catégories...');

    // Récupérer quelques catégories principales
    final mainCategories = await firestore
        .collection('enterprise_categories')
        .where('level', isEqualTo: 0)
        .limit(3)
        .get();

    if (mainCategories.docs.isEmpty) {
      print('⚠️ Aucune catégorie principale trouvée');
      return;
    }

    // Exemples de sous-catégories par domaine
    final subcategoriesByDomain = {
      'Bâtiment': [
        'Plomberie',
        'Électricité',
        'Maçonnerie',
        'Peinture',
        'Menuiserie',
        'Carrelage',
      ],
      'Services': [
        'Comptabilité',
        'Conseil juridique',
        'Marketing digital',
        'Ressources humaines',
        'Formation',
      ],
      'Commerce': [
        'Alimentation',
        'Vêtements',
        'Électronique',
        'Décoration',
        'Cosmétiques',
      ],
    };

    for (final mainDoc in mainCategories.docs) {
      final mainData = mainDoc.data();
      final mainName = mainData['name'] as String;

      // Trouver les sous-catégories correspondantes
      String? matchingKey;
      for (final key in subcategoriesByDomain.keys) {
        if (mainName.toLowerCase().contains(key.toLowerCase()) ||
            key.toLowerCase().contains(mainName.toLowerCase())) {
          matchingKey = key;
          break;
        }
      }

      if (matchingKey != null) {
        final subcategories = subcategoriesByDomain[matchingKey]!;
        int index = 1;

        for (final subcatName in subcategories) {
          await firestore.collection('enterprise_categories').add({
            'name': subcatName,
            'parent_id': mainDoc.id,
            'level': 1,
            'index': index++,
          });
        }

        print(
            '✅ ${subcategories.length} sous-catégories créées pour "$mainName"');
      }
    }
  }

  // Vérifier l'intégrité des données
  Future<void> verifyDataIntegrity() async {
    print('🔍 Vérification de l\'intégrité des données...');

    final allCategories =
        await firestore.collection('enterprise_categories').get();

    int mainCount = 0;
    int subCount = 0;
    final Map<String, int> subcategoriesByParent = {};
    final List<String> issues = [];

    for (final doc in allCategories.docs) {
      final data = doc.data();
      final parentId = data['parent_id'];
      final level = data['level'] ?? 0;

      if (parentId == null) {
        mainCount++;
      } else {
        subCount++;
        subcategoriesByParent[parentId] =
            (subcategoriesByParent[parentId] ?? 0) + 1;

        // Vérifier que le parent existe
        final parentExists = allCategories.docs.any((d) => d.id == parentId);

        if (!parentExists) {
          issues.add(
              '⚠️ Sous-catégorie "${data['name']}" a un parent inexistant');
        }
      }

      // Vérifier la cohérence du niveau
      if (parentId == null && level != 0) {
        issues.add(
            '⚠️ Catégorie principale "${data['name']}" a un niveau incorrect: $level');
      } else if (parentId != null && level != 1) {
        issues.add(
            '⚠️ Sous-catégorie "${data['name']}" a un niveau incorrect: $level');
      }
    }

    print('\n📊 Résumé:');
    print('- Catégories principales: $mainCount');
    print('- Sous-catégories: $subCount');
    print('- Total: ${allCategories.docs.length}');

    if (subcategoriesByParent.isNotEmpty) {
      print('\n📂 Répartition des sous-catégories:');
      for (final entry in subcategoriesByParent.entries) {
        final parentDoc =
            allCategories.docs.firstWhere((d) => d.id == entry.key);
        final parentName = parentDoc.data()['name'];
        print('  - $parentName: ${entry.value} sous-catégories');
      }
    }

    if (issues.isNotEmpty) {
      print('\n❌ Problèmes détectés:');
      for (final issue in issues) {
        print(issue);
      }
    } else {
      print('\n✅ Aucun problème détecté');
    }
  }

  // Script principal de migration
  Future<void> runFullMigration() async {
    print('🚀 Démarrage de la migration complète\n');

    try {
      // Étape 1: Migrer les catégories existantes
      await migrateExistingCategories();

      // Étape 2: Créer des exemples (optionnel)
      print(
          '\nVoulez-vous créer des exemples de sous-catégories ? (Recommandé pour tester)');
      // Dans un vrai script, demander confirmation à l'utilisateur
      // await createSampleSubcategories();

      // Étape 3: Vérifier l'intégrité
      await verifyDataIntegrity();

      print('\n🎉 Migration terminée avec succès!');
    } catch (e) {
      print('\n❌ Erreur pendant la migration: $e');
      rethrow;
    }
  }
}
