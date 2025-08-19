import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReusableButtonController extends GetxController with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  
  final RxBool isHovered = false.obs;
  final RxBool isPressed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDisabled = false.obs;
  
  // Animation settings
  final Duration animationDuration;
  final Curve animationCurve;
  final double pressScale;
  final bool enableAnimation;
  
  ReusableButtonController({
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.pressScale = 0.95,
    this.enableAnimation = true,
  });
  
  @override
  void onInit() {
    super.onInit();
    if (enableAnimation) {
      animationController = AnimationController(
        duration: animationDuration,
        vsync: this,
      );
      scaleAnimation = Tween<double>(
        begin: 1.0,
        end: pressScale,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: animationCurve,
      ));
    }
  }
  
  @override
  void onClose() {
    if (enableAnimation) {
      animationController.dispose();
    }
    super.onClose();
  }
  
  void onHoverEnter() {
    isHovered.value = true;
  }
  
  void onHoverExit() {
    isHovered.value = false;
  }
  
  void onTapDown() {
    if (!isDisabled.value && !isLoading.value) {
      isPressed.value = true;
      if (enableAnimation) {
        animationController.forward();
      }
    }
  }
  
  void onTapUp() {
    if (!isDisabled.value && !isLoading.value) {
      isPressed.value = false;
      if (enableAnimation) {
        animationController.reverse();
      }
    }
  }
  
  void onTapCancel() {
    isPressed.value = false;
    if (enableAnimation) {
      animationController.reverse();
    }
  }
  
  void setLoading(bool value) {
    isLoading.value = value;
    if (value) {
      isDisabled.value = true;
    }
  }
  
  void setDisabled(bool value) {
    isDisabled.value = value;
  }
  
  bool get isInteractive => !isDisabled.value && !isLoading.value;
}