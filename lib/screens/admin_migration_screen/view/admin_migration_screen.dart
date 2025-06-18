import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../scripts/migration_association_visibility.dart';

class AdminMigrationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MIGRATIONS'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.group, color: Colors.blue),
                title: Text('Migration Visibilité Associations'),
                subtitle: Text(
                  'Ajoute les champs affiliatesCount et isVisibleOverride aux établissements associations',
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirmer la migration'),
                        content: Text(
                          'Cette opération va mettre à jour tous les établissements associations. Continuer ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Lancer'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      Get.dialog(
                        AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Migration en cours...'),
                            ],
                          ),
                        ),
                        barrierDismissible: false,
                      );

                      await MigrationAssociationVisibility.run();

                      Get.back(); // Fermer le dialog de chargement

                      Get.snackbar(
                        'Succès',
                        'Migration terminée avec succès',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: Text('LANCER'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
