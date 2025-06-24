import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ventemoi/scripts/enterprise_category_migration.dart';

class AdminMigrationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Migration - Sous-catégories'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.update,
              size: 80,
              color: Colors.orange,
            ),
            SizedBox(height: 24),
            Text(
              'Migration des catégories entreprise',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Cette opération va ajouter le support des sous-catégories',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                final migration = EnterpriseCategoryMigration(
                  FirebaseFirestore.instance,
                );

                // Afficher un dialog de progression
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: Text('Migration en cours...'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Veuillez patienter'),
                      ],
                    ),
                  ),
                );

                try {
                  await migration.runFullMigration();
                  Navigator.pop(context); // Fermer le dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Migration terminée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context); // Fermer le dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: Icon(Icons.play_arrow),
              label: Text('Lancer la migration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final migration = EnterpriseCategoryMigration(
                  FirebaseFirestore.instance,
                );
                await migration.verifyDataIntegrity();
              },
              child: Text('Vérifier l\'intégrité seulement'),
            ),
          ],
        ),
      ),
    );
  }
}
