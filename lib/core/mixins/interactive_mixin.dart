import 'package:get/get.dart';

mixin InteractiveMixin on GetxController {
  RxBool isHovered = false.obs;
  RxBool isPressed = false.obs;
  RxBool isFocused = false.obs;
  RxBool isDisabled = false.obs;
  RxBool isLoading = false.obs;
  
  void onHoverEnter() => isHovered.value = true;
  void onHoverExit() => isHovered.value = false;
  
  void onTapDown() => isPressed.value = true;
  void onTapUp() => isPressed.value = false;
  void onTapCancel() => isPressed.value = false;
  
  void onFocusGained() => isFocused.value = true;
  void onFocusLost() => isFocused.value = false;
  
  void setDisabled(bool value) => isDisabled.value = value;
  void setLoading(bool value) => isLoading.value = value;
  
  void resetInteraction() {
    isHovered.value = false;
    isPressed.value = false;
    isFocused.value = false;
  }
  
  void resetAll() {
    resetInteraction();
    isDisabled.value = false;
    isLoading.value = false;
  }
  
  bool get isInteractive => !isDisabled.value && !isLoading.value;
}