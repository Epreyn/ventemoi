import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../classes/unique_controllers.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Connexion avec Google
  /// Retourne l'UserCredential si connexion réussie
  /// Retourne null si l'utilisateur annule
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🟢 [GoogleAuthService] Début signInWithGoogle');

      // Déclencher le flux d'authentification Google
      print('🟢 [GoogleAuthService] Appel _googleSignIn.signIn()');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Si l'utilisateur annule, retourner null
      if (googleUser == null) {
        print('⚠️ [GoogleAuthService] googleUser est null (annulation)');
        return null;
      }

      print('🟢 [GoogleAuthService] GoogleUser récupéré: ${googleUser.email}');

      // Obtenir les détails d'authentification
      print('🟢 [GoogleAuthService] Récupération authentication');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🟢 [GoogleAuthService] Tokens récupérés - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}');

      // Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🟢 [GoogleAuthService] Credentials créés, appel signInWithCredential');

      // Se connecter à Firebase avec les credentials Google
      final userCredential = await _auth.signInWithCredential(credential);

      print('✅ [GoogleAuthService] signInWithCredential réussi - UID: ${userCredential.user?.uid}');

      return userCredential;
    } catch (e, stackTrace) {
      print('❌ [GoogleAuthService] ERREUR dans signInWithGoogle');
      print('Erreur: $e');
      print('StackTrace: $stackTrace');

      UniquesControllers().data.snackbar(
            'Erreur Google Sign In',
            e.toString(),
            true,
          );
      return null;
    }
  }

  /// Vérifie si l'utilisateur existe déjà dans Firestore
  Future<bool> userExists(String uid) async {
    try {
      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      // En cas d'erreur 403 (permission denied), on considère que l'utilisateur n'existe pas
      // car un nouvel utilisateur n'a pas encore les permissions pour lire la collection users
      print('Erreur lors de la vérification userExists: $e');
      return false;
    }
  }

  /// Récupère les informations de l'utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      UniquesControllers().data.snackbar(
            'Erreur lors de la déconnexion',
            e.toString(),
            true,
          );
    }
  }

  /// Crée un compte utilisateur Firestore pour un nouvel utilisateur Google
  /// (utilisé uniquement après avoir collecté les informations obligatoires)
  Future<void> createUserInFirestore({
    required String uid,
    required String email,
    required String name,
    required String userTypeId,
    String imageUrl = '',
  }) async {
    try {
      // Générer un code de parrainage
      final referralCode = _generateReferralCode();

      final userData = <String, dynamic>{
        'name': name,
        'email': email,
        'user_type_id': userTypeId,
        'image_url': imageUrl,
        'isVisible': true,
        'isEnable': true,
        'referral_code': referralCode,
        'created_at': FieldValue.serverTimestamp(),
        'auth_provider': 'google',
      };

      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .set(userData);

      // Créer le wallet avec 0 points (pas de bonus automatique)
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('wallets')
          .doc()
          .set({
        'user_id': uid,
        'points': 0,
        'coupons': 0,
        'bank_details': Map<String, dynamic>.from({
          'iban': '',
          'bic': '',
          'holder': '',
        }),
      });

      // Créer le document sponsorship
      await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('sponsorships')
          .doc()
          .set({
        'user_id': uid,
        'sponsored_emails': [],
        'sponsorship_details': {},
        'total_earnings': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      6,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }
}
