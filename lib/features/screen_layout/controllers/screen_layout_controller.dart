import 'package:get/get.dart';

class ScreenLayoutController extends GetxController {
  // Instance singleton pour garder le même contrôleur dans toute l'app
  static ScreenLayoutController? _instance;

  static ScreenLayoutController get instance {
    _instance ??= Get.put(ScreenLayoutController(), permanent: true);
    return _instance!;
  }

  // Valeurs STATIQUES pour chaque vague (0.0 à 1.0)
  // Ces valeurs donnent une position fixe aux vagues
  RxDouble wave1Progress = 0.3.obs; // Position fixe vague 1
  RxDouble wave2Progress = 0.7.obs; // Position fixe vague 2
  RxDouble wave3Progress = 0.5.obs; // Position fixe vague 3
  RxDouble wave4Progress = 0.2.obs; // Position fixe vague 4

  @override
  void onInit() {
    super.onInit();
    // Plus d'animations ! Les vagues restent statiques
  }

  @override
  void onClose() {
    _instance = null;
    super.onClose();
  }
}
