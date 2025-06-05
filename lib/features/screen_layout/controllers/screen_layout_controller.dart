import 'package:get/get.dart';
import 'dart:async';

class ScreenLayoutController extends GetxController {
  // Instance singleton pour garder le même contrôleur dans toute l'app
  static ScreenLayoutController? _instance;

  static ScreenLayoutController get instance {
    _instance ??= Get.put(ScreenLayoutController(), permanent: true);
    return _instance!;
  }

  // Valeurs d'animation pour chaque vague (0.0 à 1.0)
  RxDouble wave1Progress = 0.0.obs;
  RxDouble wave2Progress = 0.0.obs;
  RxDouble wave3Progress = 0.0.obs;
  RxDouble wave4Progress = 0.0.obs;

  Timer? _animationTimer;
  bool _isAnimating = false;

  @override
  void onInit() {
    super.onInit();
    _startAnimations();
  }

  void _startAnimations() {
    if (_isAnimating) return; // Éviter de démarrer plusieurs fois

    _isAnimating = true;

    // Timer qui update toutes les 16ms (~60fps)
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // Chaque vague a sa propre vitesse
      wave1Progress.value = (wave1Progress.value + 0.001) % 1.0; // Plus lent
      wave2Progress.value = (wave2Progress.value + 0.0008) % 1.0; // Très lent
      wave3Progress.value = (wave3Progress.value + 0.0012) % 1.0; // Moyen
      wave4Progress.value = (wave4Progress.value + 0.002) % 1.0; // Plus rapide
    });
  }

  void pauseAnimations() {
    _animationTimer?.cancel();
    _isAnimating = false;
  }

  void resumeAnimations() {
    if (!_isAnimating) {
      _startAnimations();
    }
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    _isAnimating = false;
    _instance = null;
    super.onClose();
  }
}
