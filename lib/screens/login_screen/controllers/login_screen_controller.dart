// lib/screens/login_screen/controllers/login_screen_controller.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';
import 'package:ventemoi/core/services/gift_notification_service_simple.dart';
import 'package:ventemoi/core/services/firebase_email_service.dart';
import 'package:ventemoi/widgets/celebration_dialog_improved.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';
import '../../onboarding_screen/controllers/onboarding_screen_controller.dart';

class LoginScreenController extends GetxController {
  String pageTitle = 'Connexion';

  // ⚠️ AJOUT DES FOCUSNODES
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  // État pour éviter les envois multiples
  RxBool isResendingEmail = false.obs;

  String emailTag = 'email';
  String emailLabel = 'Email';
  String emailError = 'Veuillez entrer une adresse mail valide';
  IconData emailIconData = Icons.email_outlined;
  TextInputType emailInputType = TextInputType.emailAddress;
  TextInputAction emailInputAction = TextInputAction.next;
  TextEditingController emailController = TextEditingController();

  String passwordTag = 'password';
  String passwordLabel = 'Mot de Passe';
  String passwordError = 'Veuillez entrer un mot de passe';
  IconData passwordIconData = Icons.lock_outlined;
  TextInputType passwordInputType = TextInputType.visiblePassword;
  TextInputAction passwordInputAction = TextInputAction.done;
  TextEditingController passwordController = TextEditingController();

  String forgotPasswordTag = 'forgotPassword';
  String forgotPasswordLabel = 'Mot de passe oublié ?';
  double maxWidth = 350.0;

  String connectionTag = 'connection';
  String connectionLabel = 'Connexion'.toUpperCase();
  IconData connectionIconData = Icons.login_outlined;

  String registerTag = 'register-login';
  String registerLabel = 'Inscription'.toUpperCase();
  IconData registerIconData = Icons.list_alt_outlined;

  String dividerTag = 'divider';
  String dividerLabel = 'OU';
  Color dividerColor = CustomTheme.lightScheme().onPrimary;
  double dividerWidth = 150;

  // Visibilité du mot de passe
  RxBool isPasswordVisible = false.obs;
  
  // Se souvenir de moi
  RxBool rememberMe = false.obs;
  final GetStorage storage = GetStorage('Storage');

  @override
  void onInit() {
    super.onInit();
    // Charger les identifiants sauvegardés au démarrage
    loadSavedCredentials();
    // Tenter une connexion automatique si "Se souvenir" est coché
    attemptAutoLogin();
  }

  // ⚠️ IMPORTANT : Disposer des FocusNodes
  @override
  void onClose() {
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
  
  // Charger les identifiants sauvegardés
  void loadSavedCredentials() {
    try {
      final savedEmail = storage.read('saved_email');
      final savedPassword = storage.read('saved_password');
      final savedRememberMe = storage.read('remember_me') ?? false;

      print('🔐 Loading saved credentials:');
      print('  - Email: ${savedEmail != null ? '***' : 'null'}');
      print('  - Password: ${savedPassword != null ? '***' : 'null'}');
      print('  - Remember Me: $savedRememberMe');

      if (savedRememberMe && savedEmail != null && savedPassword != null) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberMe.value = true;
        print('✅ Credentials loaded successfully');
      } else {
        print('ℹ️ No saved credentials to load');
      }
    } catch (e) {
      print('❌ Error loading credentials: $e');
    }
  }

  // Tenter une connexion automatique
  Future<void> attemptAutoLogin() async {
    try {
      // Vérifier si "Se souvenir" est activé et que les identifiants sont présents
      final savedRememberMe = storage.read('remember_me') ?? false;
      final savedEmail = storage.read('saved_email');
      final savedPassword = storage.read('saved_password');

      if (savedRememberMe && savedEmail != null && savedPassword != null) {
        print('🔄 Attempting auto-login...');

        // Afficher un indicateur de chargement pendant la connexion automatique
        UniquesControllers().data.isInAsyncCall.value = true;

        // Attendre un peu pour que l'UI se charge (optionnel)
        await Future.delayed(Duration(milliseconds: 500));

        // Tenter la connexion
        await loginSilent();
      }
    } catch (e) {
      print('❌ Auto-login failed: $e');
      UniquesControllers().data.isInAsyncCall.value = false;
    }
  }
  
  // Sauvegarder ou supprimer les identifiants selon le choix
  void saveCredentials() {
    print('💾 Saving credentials - Remember Me: ${rememberMe.value}');
    if (rememberMe.value) {
      storage.write('saved_email', emailController.text);
      storage.write('saved_password', passwordController.text);
      storage.write('remember_me', true);
      print('✅ Credentials saved to storage');
    } else {
      storage.remove('saved_email');
      storage.remove('saved_password');
      storage.write('remember_me', false);
      print('🗑️ Credentials removed from storage');
    }
  }
  
  // Toggle Se souvenir de moi
  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  void passwordScreenOnPressed() {
    Get.offNamed(Routes.password);
  }
  
  // Alias pour la nouvelle interface
  void onForgotPassword() {
    passwordScreenOnPressed();
  }

  void registerScreenOnPressed() {
    Get.offNamed(Routes.register);
  }
  
  // Alias pour la nouvelle interface
  void onRegister() {
    registerScreenOnPressed();
  }
  
  // Alias pour la nouvelle interface
  void onSignIn() {
    login();
  }

  // Version silencieuse de login pour l'auto-connexion
  Future<void> loginSilent() async {
    try {
      // Connexion avec les identifiants sauvegardés
      final userCredential = await UniquesControllers()
          .data
          .firebaseAuth
          .signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );

      final user = userCredential.user;
      if (user == null) {
        UniquesControllers().data.isInAsyncCall.value = false;
        return;
      }

      // Si l'email n'est pas vérifié, on arrête silencieusement
      if (!user.emailVerified) {
        UniquesControllers().data.isInAsyncCall.value = false;
        await UniquesControllers().data.firebaseAuth.signOut();
        return;
      }

      final uid = user.uid;
      UniquesControllers().getStorage.write('currentUserUID', uid);

      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        UniquesControllers().data.isInAsyncCall.value = false;
        await UniquesControllers().data.firebaseAuth.signOut();
        return;
      }

      final data = doc.data()!;

      final bool isEnabled = data['isEnable'] ?? false;
      if (!isEnabled) {
        UniquesControllers().data.isInAsyncCall.value = false;
        await UniquesControllers().data.firebaseAuth.signOut();
        return;
      }

      // Vérifier si l'onboarding doit être affiché
      final shouldShowOnboarding =
          await OnboardingScreenController.shouldShowOnboarding();
      if (shouldShowOnboarding) {
        UniquesControllers().data.isInAsyncCall.value = false;
        Get.offAllNamed(Routes.onboarding);
        return;
      }

      // Suite du code existant pour la redirection normale...
      final userTypeID = data['user_type_id'] as String?;
      final userTypeDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .doc(userTypeID)
          .get();
      final userType = userTypeDoc.data()!['name'] as String;

      // Initialiser le service de notifications de cadeaux en parallèle
      print('🎁 GIFT CHECK: Initializing gift notification service...');
      Future<List<GiftNotification>> giftCheckFuture = Future.value([]);

      if (!Get.isRegistered<GiftNotificationServiceSimple>()) {
        await Get.putAsync(() => GiftNotificationServiceSimple().init());
      }

      // Lancer la vérification des cadeaux en arrière-plan (sans await)
      final giftService = Get.find<GiftNotificationServiceSimple>();
      giftCheckFuture = Future(() async {
        print('🎁 GIFT CHECK: Checking for new gifts in background...');
        await giftService.cleanTestDocuments();
        final gifts = await giftService.checkForNewGiftsSimple();
        print('🎁 GIFT CHECK: Found ${gifts.length} new gifts/points');
        return gifts;
      });

      // Redirection selon le type d'utilisateur
      String targetRoute;

      // Pour les établissements, vérifier s'ils sont visibles
      bool shouldGoToExplorer = false;

      if (userType == 'Administrateur') {
        targetRoute = Routes.adminUsers;
      } else if (userType == 'Particulier') {
        targetRoute = Routes.shopEstablishment;
      } else if (userType == 'Boutique' || userType == 'Entreprise' ||
                 userType == 'Sponsor' || userType == 'Cine7com' ||
                 userType == 'Association') {
        // Récupérer les informations de l'établissement
        final estabQuery = await UniquesControllers()
            .data
            .firebaseFirestore
            .collection('establishments')
            .where('user_id', isEqualTo: uid)
            .limit(1)
            .get();

        if (estabQuery.docs.isNotEmpty) {
          final estabData = estabQuery.docs.first.data();
          final isVisible = estabData['is_visible'] ?? false;

          if (!isVisible) {
            shouldGoToExplorer = true;
            targetRoute = Routes.shopEstablishment;
          } else {
            // Si c'est un Sponsor, aller vers la page des commissions
            if (userType == 'Sponsor') {
              targetRoute = Routes.adminCommissions;
            } else {
              targetRoute = Routes.profile;
            }
          }
        } else {
          targetRoute = Routes.profile;
        }
      } else {
        targetRoute = Routes.shopEstablishment;
      }

      UniquesControllers().data.isInAsyncCall.value = false;

      // Naviguer vers la bonne page
      Get.offAllNamed(targetRoute);

      // Si l'établissement n'est pas visible, afficher le message
      if (shouldGoToExplorer) {
        await Future.delayed(Duration(milliseconds: 500));
        Get.snackbar(
          'Profil en attente',
          'Votre établissement est en cours de validation. Explorez l\'application en attendant !',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
          margin: EdgeInsets.all(16),
          borderRadius: 12,
          icon: Icon(Icons.hourglass_empty, color: Colors.white),
        );
      }

      // Vérifier les cadeaux en arrière-plan
      giftCheckFuture.then((gifts) {
        if (gifts.isNotEmpty) {
          Get.dialog(
            CelebrationDialogImproved(
              notifications: gifts,
              onClose: () => Get.back(),
            ),
            barrierDismissible: false,
            useSafeArea: true,
          );
        }
      }).catchError((error) {
        print('🎁 GIFT CHECK ERROR: $error');
      });

      print('🎉 Auto-login successful! Redirecting to: $targetRoute');

    } catch (e) {
      print('❌ Silent login failed: $e');
      UniquesControllers().data.isInAsyncCall.value = false;
      // En cas d'échec de l'auto-connexion, on reste sur la page de login
      // sans afficher de message d'erreur
    }
  }

  void login() async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

      // Sauvegarder les identifiants si "Se souvenir de moi" est coché
      saveCredentials();
      
      // Toujours sauvegarder l'email actuel pour d'autres usages
      UniquesControllers().getStorage.write('email', emailController.text);
      UniquesControllers()
          .getStorage
          .write('password', passwordController.text);

      final userCredential = await UniquesControllers()
          .data
          .firebaseAuth
          .signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );

      final user = userCredential.user;
      if (user == null) {
        UniquesControllers().data.isInAsyncCall.value = false;
        UniquesControllers().data.snackbar(
            'Erreur', 'Impossible de récupérer les informations utilisateur', true);
        return;
      }

      // Vérifier si l'email est vérifié
      if (!user.emailVerified) {
        UniquesControllers().data.isInAsyncCall.value = false;

        // Afficher un dialogue moderne et informatif
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Email non vérifié',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pour accéder à votre compte, vous devez d\'abord vérifier votre adresse email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vérifiez votre boîte mail et vos spams',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Email envoyé à :',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${user.email}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Get.back();
                  await UniquesControllers().data.firebaseAuth.signOut();
                },
                child: Text(
                  'Fermer',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton.icon(
                onPressed: isResendingEmail.value ? null : () async {
                  if (isResendingEmail.value) return;
                  isResendingEmail.value = true;

                  try {
                    // Afficher un loader pendant l'envoi
                    Get.back();
                    UniquesControllers().data.isInAsyncCall.value = true;

                    // Utiliser la Cloud Function pour envoyer l'email personnalisé
                    try {
                      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
                          .httpsCallable('resendVerificationEmail');

                      final result = await callable.call();

                      if (result.data['success'] != true) {
                        throw Exception(result.data['message'] ?? 'Erreur inconnue');
                      }

                      print('✅ Email personnalisé envoyé via Cloud Function');
                    } catch (e) {
                      print('⚠️ Erreur Cloud Function, fallback sur méthode standard: $e');
                      // Fallback sur la méthode standard si la Cloud Function échoue
                      await user.sendEmailVerification();
                    }

                    UniquesControllers().data.isInAsyncCall.value = false;
                    isResendingEmail.value = false;

                    // Afficher un dialogue de succès
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 48,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Email envoyé !',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Un nouvel email de vérification a été envoyé à ${user.email}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer, color: Colors.amber[700], size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Vérifiez dans quelques minutes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Get.back();
                              UniquesControllers().data.firebaseAuth.signOut();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                      barrierDismissible: false,
                    );
                  } catch (e) {
                    Get.back();
                    UniquesControllers().data.isInAsyncCall.value = false;
                    isResendingEmail.value = false;

                    // Afficher un dialogue d'erreur
                    Get.dialog(
                      AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Erreur'),
                          ],
                        ),
                        content: Text(
                          'Impossible d\'envoyer l\'email. Veuillez réessayer plus tard.',
                          style: TextStyle(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Get.back();
                              UniquesControllers().data.firebaseAuth.signOut();
                            },
                            child: Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: Icon(Icons.send, size: 18, color: Colors.white),
                label: Text('Renvoyer l\'email', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );

        return;
      }

      final uid = user.uid;
      UniquesControllers().getStorage.write('currentUserUID', uid);

      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        UniquesControllers().data.isInAsyncCall.value = false;
        UniquesControllers().data.snackbar(
            'Erreur', 'Utilisateur introuvable dans la base de données.', true);
        return;
      }

      final data = doc.data()!;

      final bool isEnabled = data['isEnable'] ?? false;
      if (!isEnabled) {
        UniquesControllers().data.isInAsyncCall.value = false;
        UniquesControllers().data.snackbar(
              'Compte désactivé',
              'Veuillez contacter un administrateur pour activer votre compte.',
              true,
            );
        await UniquesControllers().data.firebaseAuth.signOut();
        return;
      }

      // Vérifier si l'onboarding doit être affiché
      final shouldShowOnboarding =
          await OnboardingScreenController.shouldShowOnboarding();
      if (shouldShowOnboarding) {
        UniquesControllers().data.isInAsyncCall.value = false;
        Get.offAllNamed(Routes.onboarding);
        return;
      }

      // Suite du code existant pour la redirection normale...
      final userTypeID = data['user_type_id'] as String?;
      final userTypeDoc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('user_types')
          .doc(userTypeID)
          .get();
      final userType = userTypeDoc.data()!['name'] as String;

      // Initialiser le service de notifications de cadeaux en parallèle
      print('🎁 GIFT CHECK: Initializing gift notification service...');
      Future<List<GiftNotification>> giftCheckFuture = Future.value([]);

      if (!Get.isRegistered<GiftNotificationServiceSimple>()) {
        await Get.putAsync(() => GiftNotificationServiceSimple().init());
      }

      // Lancer la vérification des cadeaux en arrière-plan (sans await)
      final giftService = Get.find<GiftNotificationServiceSimple>();
      giftCheckFuture = Future(() async {
        print('🎁 GIFT CHECK: Checking for new gifts in background...');
        // Nettoyer d'abord les documents de test qui pourraient exister
        await giftService.cleanTestDocuments();
        // Utiliser la vraie méthode maintenant que la collection est correcte
        final gifts = await giftService.checkForNewGiftsSimple();
        print('🎁 GIFT CHECK: Found ${gifts.length} new gifts/points');
        return gifts;
      });
      
      // Redirection selon le type d'utilisateur
      String targetRoute;
      
      // Pour les établissements, vérifier s'ils sont visibles
      bool shouldGoToExplorer = false;
      
      if (userType == 'Administrateur') {
        targetRoute = Routes.adminUsers;
      } else if (userType == 'Particulier') {
        targetRoute = Routes.shopEstablishment;
      } else if (userType == 'Boutique' || userType == 'Entreprise' || 
                 userType == 'Sponsor' || userType == 'Cine7com' || 
                 userType == 'Association') {
        // Vérifier si l'établissement existe et est visible
        try {
          final establishmentQuery = await UniquesControllers()
              .data
              .firebaseFirestore
              .collection('establishments')
              .where('user_id', isEqualTo: uid)
              .limit(1)
              .get();
          
          if (establishmentQuery.docs.isNotEmpty) {
            final estabData = establishmentQuery.docs.first.data();
            final hasAcceptedContract = estabData['has_accepted_contract'] ?? false;
            final isVisibleOverride = estabData['is_visible_override'] ?? false;
            
            // Pour les associations, vérifier aussi le nombre d'affiliés
            if (userType == 'Association') {
              final affiliatesCount = estabData['affiliates_count'] ?? 0;
              shouldGoToExplorer = hasAcceptedContract && 
                                  (affiliatesCount >= 15 || isVisibleOverride);
            } else {
              // Pour les autres types d'établissements
              shouldGoToExplorer = hasAcceptedContract;
            }
          }
        } catch (e) {
          print('Erreur lors de la vérification de l\'établissement: $e');
        }
        
        // Rediriger vers Explorer si l'établissement est visible, sinon vers le profil
        targetRoute = shouldGoToExplorer ? Routes.shopEstablishment : Routes.proEstablishmentProfile;
      } else {
        UniquesControllers()
            .data
            .snackbar('Erreur', 'Type d\'utilisateur inconnu: $userType', true);
        return;
      }

      // Désactiver le loader juste avant la navigation
      UniquesControllers().data.isInAsyncCall.value = false;

      // Naviguer vers la page cible immédiatement
      print('🎁 GIFT CHECK: Navigating to $targetRoute');
      Get.offAllNamed(targetRoute);

      // Afficher les notifications de cadeaux après la navigation (en arrière-plan)
      Future(() async {
        try {
          // Attendre le résultat de la vérification des cadeaux
          final newGifts = await giftCheckFuture;

          if (newGifts.isNotEmpty) {
            print('🎉 GIFT CHECK: Showing celebration dialog for ${newGifts.length} notifications');
            // Attendre un peu pour que la navigation soit terminée
            await Future.delayed(const Duration(milliseconds: 50));
            if (Get.context != null) {
              print('🎉 GIFT CHECK: Context available, showing dialog...');
              await showCelebrationDialogImproved(Get.context!, newGifts);
              print('🎉 GIFT CHECK: Dialog shown and closed');
            } else {
              print('❌ GIFT CHECK: No context available for showing dialog');
            }
          } else {
            print('ℹ️ GIFT CHECK: No new gifts to show');
          }
        } catch (e) {
          print('❌ GIFT CHECK: Error showing gifts: $e');
        }
      });
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }
}
