import 'package:flutter/animation.dart';
import 'package:get/get.dart';

class CustomAnimationController extends GetxController {
  Duration baseDuration = const Duration(milliseconds: 500);
  Curve baseCurve = Curves.easeInOut;

  Duration? delay;

  RxDouble opacity = 0.0.obs;
  RxDouble scale = 0.5.obs;

  double? xStartPosition;
  double? yStartPosition;
  double? zStartPosition;

  RxDouble xTranslation = 0.0.obs;
  RxDouble yTranslation = 0.0.obs;
  RxDouble zTranslation = 0.0.obs;

  CustomAnimationController({
    this.delay,
    this.xStartPosition,
    this.yStartPosition,
    this.zStartPosition,
  }) {
    resetAnimation();
  }

  void resetAnimation() {
    opacity.value = 0.0;
    scale.value = 0.5;
    xTranslation.value = xStartPosition ?? 0.0;
    yTranslation.value = yStartPosition ?? 0.0;
    zTranslation.value = zStartPosition ?? 0.0;
    startAnimation();
  }

  void startAnimation() {
    if (delay != null) {
      Future.delayed(delay!, () {
        defineEndOpacity();
        defineEndScale();
        defineEndTranslation();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 0), () {
        defineEndOpacity();
        defineEndScale();
        defineEndTranslation();
      });
    }
  }

  void defineEndOpacity() {
    opacity.value = 1.0;
  }

  void defineEndScale() {
    scale.value = 1.0;
  }

  void defineEndTranslation() {
    xTranslation.value = 0.0;
    yTranslation.value = 0.0;
    zTranslation.value = 0.0;
  }

  // @override
  // void onInit() {
  //   super.onInit();
  //
  //   opacity.value = 0.0;
  //   scale.value = 0.5;
  //
  //   xTranslation.value = xStartPosition ?? 0.0;
  //   yTranslation.value = yStartPosition ?? 0.0;
  //   zTranslation.value = zStartPosition ?? 0.0;
  // }

  // @override
  // void onReady() {
  //   super.onReady();
  //
  //   if (delay != null) {
  //     Future.delayed(delay!, () {
  //       defineEndOpacity();
  //       defineEndScale();
  //       defineEndTranslation();
  //     });
  //   } else {
  //     defineEndOpacity();
  //     defineEndScale();
  //     defineEndTranslation();
  //   }
  // }
}
