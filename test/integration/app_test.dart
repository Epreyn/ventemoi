import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ventemoi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Login flow test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Vérifier que l'écran de connexion s'affiche
      expect(find.text('Connexion'), findsWidgets);

      // Trouver et remplir le champ email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Trouver et remplir le champ mot de passe
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Vérifier que les valeurs ont été entrées
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Navigate to register screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Trouver et cliquer sur le bouton d'inscription
      final registerButton = find.text('INSCRIPTION');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Vérifier qu'on est sur l'écran d'inscription
        expect(find.textContaining('Inscription'), findsWidgets);
      }
    });

    testWidgets('Password visibility toggle test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Entrer un mot de passe
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'myPassword');
      await tester.pumpAndSettle();

      // Trouver et cliquer sur l'icône de visibilité
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon);
        await tester.pumpAndSettle();

        // Vérifier que l'icône a changé
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      }
    });
  });
}