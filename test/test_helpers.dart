import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

/// Helper pour créer une app de test avec GetX
Widget createTestApp(Widget child) {
  return GetMaterialApp(
    home: child,
  );
}

/// Helper pour pump et settle avec timeout
Future<void> pumpAndSettleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    timeout,
  );
}

/// Helper pour trouver et taper sur un widget par texte
Future<void> tapByText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Helper pour entrer du texte dans un champ
Future<void> enterTextInField(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Helper pour vérifier qu'un widget existe
void expectWidgetExists(Finder finder, {int count = 1}) {
  if (count == 1) {
    expect(finder, findsOneWidget);
  } else {
    expect(finder, findsNWidgets(count));
  }
}

/// Helper pour nettoyer GetX après les tests
void cleanupGetX() {
  Get.reset();
}

/// Mock classes communes
class MockBuildContext extends Mock implements BuildContext {}

/// Helper pour créer des données de test
class TestData {
  static Map<String, dynamic> createTestUser({
    String? id,
    String? email,
    String? name,
  }) {
    return {
      'id': id ?? 'test_user_123',
      'email': email ?? 'test@example.com',
      'name': name ?? 'Test User',
      'user_type_id': 'type_1',
      'image_url': 'https://example.com/image.jpg',
      'isEnable': true,
      'isVisible': true,
      'personal_address': '123 Test Street',
    };
  }

  static Map<String, dynamic> createTestEstablishment({
    String? id,
    String? name,
    String? address,
  }) {
    return {
      'id': id ?? 'test_establishment_123',
      'name': name ?? 'Test Shop',
      'address': address ?? '456 Shop Street',
      'category': 'restaurant',
      'isActive': true,
    };
  }
}