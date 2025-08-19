import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReusableTextFieldController extends GetxController {
  late TextEditingController textController;
  late FocusNode focusNode;
  
  final RxBool obscureText = false.obs;
  final RxBool hasText = false.obs;
  final RxBool isFocused = false.obs;
  
  // Configuration
  final bool isPasswordField;
  final bool showPasswordToggle;
  final bool showClearButton;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  
  ReusableTextFieldController({
    TextEditingController? controller,
    FocusNode? focusNode,
    bool initialObscureText = false,
    this.isPasswordField = false,
    this.showPasswordToggle = false,
    this.showClearButton = false,
    this.onClear,
    this.onChanged,
  }) {
    textController = controller ?? TextEditingController();
    this.focusNode = focusNode ?? FocusNode();
    obscureText.value = initialObscureText;
  }
  
  @override
  void onInit() {
    super.onInit();
    hasText.value = textController.text.isNotEmpty;
    
    textController.addListener(_onTextChanged);
    focusNode.addListener(_onFocusChanged);
  }
  
  @override
  void onClose() {
    // Only dispose if we created the controllers
    if (Get.arguments?['controller'] == null) {
      textController.dispose();
    }
    if (Get.arguments?['focusNode'] == null) {
      focusNode.dispose();
    }
    super.onClose();
  }
  
  void _onTextChanged() {
    hasText.value = textController.text.isNotEmpty;
    onChanged?.call(textController.text);
  }
  
  void _onFocusChanged() {
    isFocused.value = focusNode.hasFocus;
  }
  
  void togglePasswordVisibility() {
    if (isPasswordField || showPasswordToggle) {
      obscureText.value = !obscureText.value;
    }
  }
  
  void clearText() {
    textController.clear();
    onClear?.call();
    onChanged?.call('');
  }
  
  String get text => textController.text;
  set text(String value) => textController.text = value;
}