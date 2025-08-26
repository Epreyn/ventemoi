// lib/screens/login_screen/controllers/login_screen_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';
import '../../onboarding_screen/controllers/onboarding_screen_controller.dart';

class LoginScreenController extends GetxController {
  String pageTitle = 'Connexion';

  // ⚠️ AJOUT DES FOCUSNODES
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

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
  final GetStorage storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // Charger les identifiants sauvegardés au démarrage
    loadSavedCredentials();
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
      
      if (savedRememberMe && savedEmail != null && savedPassword != null) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberMe.value = true;
      }
    } catch (e) {
    }
  }
  
  // Sauvegarder ou supprimer les identifiants selon le choix
  void saveCredentials() {
    if (rememberMe.value) {
      storage.write('saved_email', emailController.text);
      storage.write('saved_password', passwordController.text);
      storage.write('remember_me', true);
    } else {
      storage.remove('saved_email');
      storage.remove('saved_password');
      storage.write('remember_me', false);
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

      final uid = userCredential.user!.uid;
      UniquesControllers().getStorage.write('currentUserUID', uid);

      final doc = await UniquesControllers()
          .data
          .firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();
      UniquesControllers().data.isInAsyncCall.value = false;

      if (!doc.exists) {
        UniquesControllers().data.snackbar(
            'Erreur', 'Utilisateur introuvable dans la base de données.', true);
        return;
      }

      final data = doc.data()!;

      final bool isEnabled = data['isEnable'] ?? false;
      if (!isEnabled) {
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

      // Redirection selon le type d'utilisateur
      if (userType == 'Administrateur') {
        Get.offAllNamed(Routes.adminUsers);
      } else if (userType == 'Particulier') {
        Get.offAllNamed(Routes.shopEstablishment);
      } else if (userType == 'Boutique') {
        Get.offAllNamed(Routes.proEstablishmentProfile);
      } else if (userType == 'Entreprise') {
        Get.offAllNamed(Routes.proEstablishmentProfile);
      } else {
        UniquesControllers()
            .data
            .snackbar('Erreur', 'Type d\'utilisateur inconnu.', true);
      }
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers().data.snackbar('Erreur', e.toString(), true);
    }
  }
}
