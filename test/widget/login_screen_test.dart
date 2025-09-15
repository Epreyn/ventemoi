import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ventemoi/screens/login_screen/view/login_screen.dart';
import 'package:ventemoi/screens/login_screen/controllers/login_screen_controller.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('should display login form elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connexion'), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      Get.put(LoginScreenController());
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final controller = Get.find<LoginScreenController>();
      expect(controller.isPasswordVisible.value, false);

      final visibilityButton = find.byIcon(Icons.visibility_off);
      if (visibilityButton.evaluate().isNotEmpty) {
        await tester.tap(visibilityButton);
        await tester.pump();
        expect(controller.isPasswordVisible.value, true);
      }
    });

    testWidgets('should enter text in email and password fields', (WidgetTester tester) async {
      Get.put(LoginScreenController());
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');

      await tester.pump();

      final controller = Get.find<LoginScreenController>();
      expect(controller.emailController.text, 'test@example.com');
      expect(controller.passwordController.text, 'password123');
    });

    testWidgets('should find connection button', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CONNEXION'), findsOneWidget);
    });

    testWidgets('should find register button', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('INSCRIPTION'), findsOneWidget);
    });
  });
}