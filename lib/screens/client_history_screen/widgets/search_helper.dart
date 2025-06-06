// Helper pour créer les termes de recherche
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchHelper {
  /// Génère les termes de recherche pour un utilisateur
  /// à partir de son nom et email
  static List<String> generateSearchTerms({
    String? displayName,
    String? email,
  }) {
    final terms = <String>[];

    // Ajouter les termes du nom
    if (displayName != null && displayName.isNotEmpty) {
      final nameLower = displayName.toLowerCase();
      terms.add(nameLower);

      // Ajouter chaque mot du nom
      final words = nameLower.split(' ');
      for (final word in words) {
        if (word.isNotEmpty) {
          terms.add(word);

          // Ajouter les préfixes de chaque mot
          for (int i = 1; i <= word.length; i++) {
            terms.add(word.substring(0, i));
          }
        }
      }

      // Ajouter les préfixes du nom complet
      for (int i = 1; i <= nameLower.length; i++) {
        terms.add(nameLower.substring(0, i));
      }
    }

    // Ajouter les termes de l'email
    if (email != null && email.isNotEmpty) {
      final emailLower = email.toLowerCase();
      terms.add(emailLower);

      // Ajouter la partie avant @
      final emailPrefix = emailLower.split('@').first;
      terms.add(emailPrefix);

      // Ajouter les préfixes de l'email
      for (int i = 1; i <= emailPrefix.length; i++) {
        terms.add(emailPrefix.substring(0, i));
      }
    }

    // Retourner les termes uniques
    return terms.toSet().toList();
  }

  /// Exemple d'utilisation lors de la création/mise à jour d'un utilisateur
  static Future<void> updateUserSearchTerms(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final searchTerms = generateSearchTerms(
        displayName: userData['display_name'],
        email: userData['email'],
      );

      await userDoc.reference.update({
        'search_terms': searchTerms,
      });
    }
  }
}
