import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/classes/controller_mixin.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/onboarding_page.dart';
import '../../../core/routes/app_routes.dart';

class OnboardingScreenController extends GetxController with ControllerMixin {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final RxList<OnboardingPage> pages = <OnboardingPage>[].obs;

  // Pour stocker si l'onboarding a été vu
  final GetStorage storage = GetStorage('Storage');
  static const String onboardingKey = 'onboarding_completed';

  String userTypeName = '';

  @override
  void onInit() {
    super.onInit();
    _loadUserTypeAndPages();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> _loadUserTypeAndPages() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    // Récupérer le type d'utilisateur
    userTypeName = await getUserTypeNameByUserId(uid);

    // Charger les pages selon le type
    pages.value = _getPagesForUserType(userTypeName);
  }

  List<OnboardingPage> _getPagesForUserType(String userType) {
    switch (userType) {
      case 'Particulier':
        return [
          OnboardingPage(
            title: 'Bienvenue sur VenteMoi',
            description:
                'Découvrez une nouvelle façon de faire vos achats tout en soutenant des associations locales.',
            imagePath: 'images/onboarding/particulier_1.png',
          ),
          OnboardingPage(
            title: 'Gagnez des Points',
            description:
                'Recevez des points de la part des entreprises partenaires et utilisez-les dans nos boutiques.',
            imagePath: 'images/onboarding/particulier_2.png',
          ),
          OnboardingPage(
            title: 'Soutenez les Associations',
            description:
                'Faites des dons directs aux associations de votre choix avec vos points.',
            imagePath: 'images/onboarding/particulier_3.png',
          ),
          OnboardingPage(
            title: 'Parrainez vos Proches',
            description:
                'Invitez vos amis et gagnez des points bonus lorsqu\'ils rejoignent la communauté.',
            imagePath: 'images/onboarding/particulier_4.png',
            buttonText: 'Commencer',
          ),
        ];

      case 'Boutique':
        return [
          OnboardingPage(
            title: 'Bienvenue Partenaire Boutique',
            description:
                'Rejoignez notre réseau de boutiques solidaires et développez votre clientèle.',
            imagePath: 'images/onboarding/boutique_1.png',
          ),
          OnboardingPage(
            title: 'Gérez vos Bons',
            description:
                'Créez et gérez facilement vos bons d\'achat depuis votre espace dédié.',
            imagePath: 'images/onboarding/boutique_2.png',
          ),
          OnboardingPage(
            title: 'Suivez vos Ventes',
            description:
                'Consultez vos statistiques de vente en temps réel et validez les bons clients.',
            imagePath: 'images/onboarding/boutique_3.png',
          ),
          OnboardingPage(
            title: 'Développez votre Activité',
            description:
                'Attirez de nouveaux clients grâce à notre système de points et de parrainage.',
            imagePath: 'images/onboarding/boutique_4.png',
            buttonText: 'Configurer ma Boutique',
          ),
        ];

      case 'Association':
        return [
          OnboardingPage(
            title: 'Bienvenue Association',
            description:
                'VenteMoi vous aide à collecter des dons de manière innovante et solidaire.',
            imagePath: 'images/onboarding/association_1.png',
          ),
          OnboardingPage(
            title: 'Recevez des Dons',
            description:
                'Les particuliers peuvent vous faire des dons directs avec leurs points.',
            imagePath: 'images/onboarding/association_2.png',
          ),
          OnboardingPage(
            title: 'Gérez votre Profil',
            description:
                'Présentez votre association et vos projets pour encourager les dons.',
            imagePath: 'images/onboarding/association_3.png',
          ),
          OnboardingPage(
            title: 'Suivez vos Donations',
            description:
                'Consultez l\'historique de vos dons reçus et remerciez vos donateurs.',
            imagePath: 'images/onboarding/association_4.png',
            buttonText: 'Configurer mon Association',
          ),
        ];

      case 'Entreprise':
        return [
          OnboardingPage(
            title: 'Bienvenue Entreprise Partenaire',
            description:
                'Fidélisez vos clients en leur offrant des points VenteMoi.',
            imagePath: 'images/onboarding/entreprise_1.png',
          ),
          OnboardingPage(
            title: 'Attribuez des Points',
            description:
                'Récompensez vos clients en leur attribuant des points selon vos critères.',
            imagePath: 'images/onboarding/entreprise_2.png',
          ),
          OnboardingPage(
            title: 'Commission Transparente',
            description:
                'Notre système de commission est clair et adapté à votre volume d\'affaires.',
            imagePath: 'images/onboarding/entreprise_3.png',
          ),
          OnboardingPage(
            title: 'Développez votre RSE',
            description:
                'Participez à l\'économie solidaire locale et renforcez votre image de marque.',
            imagePath: 'images/onboarding/entreprise_4.png',
            buttonText: 'Configurer mon Entreprise',
          ),
        ];

      case 'Administrateur':
        return [
          OnboardingPage(
            title: 'Espace Administrateur',
            description:
                'Bienvenue dans l\'interface d\'administration de VenteMoi.',
            imagePath: 'images/onboarding/admin_1.png',
          ),
          OnboardingPage(
            title: 'Gestion Complète',
            description:
                'Gérez les utilisateurs, les établissements et suivez toutes les transactions.',
            imagePath: 'images/onboarding/admin_2.png',
          ),
          OnboardingPage(
            title: 'Statistiques Détaillées',
            description:
                'Accédez aux tableaux de bord et aux rapports d\'activité de la plateforme.',
            imagePath: 'images/onboarding/admin_3.png',
            buttonText: 'Accéder au Dashboard',
          ),
        ];

      default:
        return [
          OnboardingPage(
            title: 'Bienvenue sur VenteMoi',
            description:
                'Le Don des Affaires - Une nouvelle façon de consommer solidaire.',
            imagePath: 'images/onboarding/default.png',
            buttonText: 'Commencer',
          ),
        ];
    }
  }

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      completeOnboarding();
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() {
    completeOnboarding();
  }

  void completeOnboarding() async {
    // Marquer l'onboarding comme complété
    await storage.write(onboardingKey, true);

    // Rediriger selon le type d'utilisateur
    _navigateToAppropriateScreen();
  }

  void _navigateToAppropriateScreen() {
    // Si c'est une boutique/association/entreprise sans établissement configuré
    if (userTypeName == 'Boutique' ||
        userTypeName == 'Association' ||
        userTypeName == 'Entreprise') {
      _checkEstablishmentProfile();
    } else {
      // Redirection normale selon le type
      switch (userTypeName) {
        case 'Administrateur':
          Get.offAllNamed(Routes.adminUsers);
          break;
        case 'Particulier':
          Get.offAllNamed(Routes.shopEstablishment);
          break;
        default:
          Get.offAllNamed(Routes.shopEstablishment);
          break;
      }
    }
  }

  Future<void> _checkEstablishmentProfile() async {
    final uid = UniquesControllers().data.firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    final estDoc = await UniquesControllers()
        .data
        .firebaseFirestore
        .collection('establishments')
        .where('user_id', isEqualTo: uid)
        .limit(1)
        .get();

    if (estDoc.docs.isEmpty ||
        estDoc.docs.first.data()['name']?.isEmpty == true) {
      // Profil établissement non configuré => rediriger vers la configuration
      Get.offAllNamed(Routes.proEstablishmentProfile);
    } else {
      Get.offAllNamed(Routes.shopEstablishment);
    }
  }

  // Vérifier si l'onboarding doit être affiché
  static Future<bool> shouldShowOnboarding() async {
    final storage = GetStorage('Storage');
    final hasCompleted =
        storage.read(OnboardingScreenController.onboardingKey) ?? false;
    return !hasCompleted;
  }

  // Réinitialiser l'onboarding (utile pour les tests ou dans les paramètres)
  static Future<void> resetOnboarding() async {
    final storage = GetStorage('Storage');
    await storage.remove(OnboardingScreenController.onboardingKey);
  }
}
