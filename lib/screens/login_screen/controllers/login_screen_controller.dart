import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';
import 'dart:math' as math;
import 'dart:async';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/routes/app_routes.dart';
import '../../onboarding_screen/controllers/onboarding_screen_controller.dart';
import '../models/particles.dart';

class LoginScreenController extends GetxController {
  String pageTitle = 'Connexion';

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
  double maxWith = 350.0;

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

  // Variables d'animation
  RxDouble logoScale = 0.0.obs;
  RxDouble logoRotation = (-0.1).obs;
  RxDouble logoPulse = 1.0.obs;
  RxDouble formOpacity = 0.0.obs;
  RxDouble formSlideOffset = 0.05.obs;
  RxDouble backgroundAngle = 0.0.obs;
  RxDouble shapeAnimation = 0.0.obs;
  RxDouble lightPosition = 0.0.obs;
  RxBool isPasswordVisible = false.obs;

  // Particules
  final List<Particle> particles = [];
  RxInt particleUpdate = 0.obs;

  // Timers pour contrôler les animations
  Timer? _backgroundTimer;
  Timer? _shapeTimer;
  Timer? _lightTimer;
  Timer? _pulseTimer;
  Timer? _particleTimer;

  @override
  void onInit() {
    super.onInit();

    // Créer les particules
    _createParticles();

    // Démarrer les animations initiales
    _startInitialAnimations();

    // Démarrer les animations continues avec des timers contrôlés
    _startContinuousAnimations();
  }

  void _createParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.02 + 0.01,
        opacity: random.nextDouble() * 0.5 + 0.1,
      ));
    }
  }

  void _startInitialAnimations() {
    // Animation du logo
    Future.delayed(Duration.zero, () {
      logoScale.value = 1.0;
      logoRotation.value = 0.0;
    });

    // Animation du formulaire
    Future.delayed(const Duration(milliseconds: 500), () {
      formOpacity.value = 1.0;
      formSlideOffset.value = 0.0;
    });
  }

  void _startContinuousAnimations() {
    // Animation du background (mise à jour toutes les 100ms)
    _backgroundTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      backgroundAngle.value += 0.02;
      if (backgroundAngle.value >= 2 * math.pi) {
        backgroundAngle.value = 0;
      }
    });

    // Animation des formes (mise à jour toutes les 50ms)
    _shapeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      shapeAnimation.value += 0.01;
      if (shapeAnimation.value >= 2 * math.pi) {
        shapeAnimation.value = 0;
      }
    });

    // Animation de la lumière (mise à jour toutes les 80ms)
    _lightTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      lightPosition.value += 0.02;
      if (lightPosition.value >= 2 * math.pi) {
        lightPosition.value = 0;
      }
    });

    // Animation de pulsation du logo (mise à jour toutes les 2 secondes)
    _pulseTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      logoPulse.value = logoPulse.value == 1.0 ? 1.05 : 1.0;
    });

    // Animation des particules (mise à jour toutes les 50ms)
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      particleUpdate.value++;
    });
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void passwordScreenOnPressed() {
    Get.offNamed(Routes.password);
  }

  void registerScreenOnPressed() {
    Get.offNamed(Routes.register);
  }

  void login() async {
    try {
      UniquesControllers().data.isInAsyncCall.value = true;

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

      // NOUVEAU: Vérifier si l'onboarding doit être affiché
      final shouldShowOnboarding =
          await OnboardingScreenController.shouldShowOnboarding();
      if (shouldShowOnboarding) {
        Get.toNamed(Routes.onboarding);
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

      switch (userType) {
        case 'Administrateur':
          Get.toNamed(Routes.adminUsers);
          break;
        case 'Particulier':
          Get.toNamed(Routes.shopEstablishment);
          break;
        case 'Entreprise':
          Get.toNamed(Routes.shopEstablishment);
          break;
        case 'Boutique':
          Get.toNamed(Routes.shopEstablishment);
          break;
        case 'Association':
          Get.toNamed(Routes.shopEstablishment);
          break;
        default:
          Get.toNamed(Routes.login);
          break;
      }
    } catch (e) {
      UniquesControllers().data.isInAsyncCall.value = false;
      UniquesControllers()
          .data
          .snackbar('Erreur lors de la connexion', e.toString(), true);
    }
  }

  @override
  void onReady() {
    super.onReady();
    emailController.text = UniquesControllers().getStorage.read('email') ?? '';
    passwordController.text =
        UniquesControllers().getStorage.read('password') ?? '';
  }

  @override
  void onClose() {
    // Nettoyer tous les timers
    _backgroundTimer?.cancel();
    _shapeTimer?.cancel();
    _lightTimer?.cancel();
    _pulseTimer?.cancel();
    _particleTimer?.cancel();

    // Disposer les controllers
    emailController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}
