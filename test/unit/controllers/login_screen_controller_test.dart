import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ventemoi/screens/login_screen/controllers/login_screen_controller.dart';

void main() {
  group('LoginScreenController Tests', () {
    late LoginScreenController controller;

    setUp(() {
      Get.testMode = true;
      controller = LoginScreenController();
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    test('should initialize with correct default values', () {
      expect(controller.pageTitle, 'Connexion');
      expect(controller.emailLabel, 'Email');
      expect(controller.passwordLabel, 'Mot de Passe');
      expect(controller.isPasswordVisible.value, false);
      expect(controller.rememberMe.value, false);
    });

    test('should toggle password visibility', () {
      expect(controller.isPasswordVisible.value, false);
      
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible.value, true);
      
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible.value, false);
    });

    test('should have proper text controllers', () {
      expect(controller.emailController, isNotNull);
      expect(controller.passwordController, isNotNull);
      
      controller.emailController.text = 'test@example.com';
      expect(controller.emailController.text, 'test@example.com');
      
      controller.passwordController.text = 'password123';
      expect(controller.passwordController.text, 'password123');
    });

    test('should have proper focus nodes', () {
      expect(controller.emailFocusNode, isNotNull);
      expect(controller.passwordFocusNode, isNotNull);
    });

    test('should toggle remember me', () {
      expect(controller.rememberMe.value, false);
      
      controller.rememberMe.value = true;
      expect(controller.rememberMe.value, true);
      
      controller.rememberMe.value = false;
      expect(controller.rememberMe.value, false);
    });
  });
}