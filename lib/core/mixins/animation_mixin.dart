import 'package:flutter/material.dart';
import 'package:get/get.dart';

mixin AnimationMixin on GetxController {
  Duration animationDuration = const Duration(milliseconds: 400);
  Curve animationCurve = Curves.easeInOut;
  RxBool isExpanded = false.obs;
  RxBool isAnimating = false.obs;
  
  Duration animationDelay(int index) => Duration(milliseconds: 100 * index);
  
  void toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }
  
  void startAnimation() {
    isAnimating.value = true;
  }
  
  void endAnimation() {
    isAnimating.value = false;
  }
  
  Future<void> animateWithDelay(Future<void> Function() action, {Duration? delay}) async {
    if (delay != null) {
      await Future.delayed(delay);
    }
    startAnimation();
    await action();
    endAnimation();
  }
}