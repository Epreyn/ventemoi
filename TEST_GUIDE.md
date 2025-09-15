# Guide des Tests - VenteMoi

## 📋 Vue d'ensemble

Ce guide explique comment utiliser et créer des tests pour l'application VenteMoi.

## 🏗️ Structure des Tests

```
test/
├── unit/                 # Tests unitaires
│   ├── models/          # Tests des modèles de données
│   └── controllers/     # Tests des contrôleurs
├── widget/              # Tests de widgets
├── integration/         # Tests d'intégration
├── fixtures/            # Données de test
└── test_helpers.dart    # Fonctions utilitaires
```

## 🚀 Exécution des Tests

### Tous les tests
```bash
flutter test
```

### Tests unitaires uniquement
```bash
flutter test test/unit/
```

### Tests de widgets uniquement
```bash
flutter test test/widget/
```

### Tests d'intégration
```bash
flutter test test/integration/
```

### Avec couverture de code
```bash
flutter test --coverage
```

### Script automatisé
```bash
./run_tests.sh
```

## 📝 Création de Nouveaux Tests

### 1. Test Unitaire (Modèle)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ventemoi/core/models/your_model.dart';

void main() {
  group('YourModel Tests', () {
    test('should create instance with correct values', () {
      final model = YourModel(
        id: 'test123',
        name: 'Test',
      );
      
      expect(model.id, 'test123');
      expect(model.name, 'Test');
    });
  });
}
```

### 2. Test de Contrôleur
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ventemoi/screens/your_screen/controllers/your_controller.dart';

void main() {
  group('YourController Tests', () {
    late YourController controller;

    setUp(() {
      Get.testMode = true;
      controller = YourController();
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    test('should initialize correctly', () {
      expect(controller.someProperty, expectedValue);
    });
  });
}
```

### 3. Test de Widget
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ventemoi/screens/your_screen/view/your_screen.dart';

void main() {
  group('YourScreen Widget Tests', () {
    testWidgets('should display expected widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: YourScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Expected Text'), findsOneWidget);
      expect(find.byType(YourWidget), findsOneWidget);
    });
  });
}
```

## 🎯 Bonnes Pratiques

1. **Isolation** : Chaque test doit être indépendant
2. **Nommage** : Utilisez des noms descriptifs commençant par "should"
3. **AAA Pattern** : Arrange, Act, Assert
4. **Mocks** : Utilisez Mockito pour simuler les dépendances
5. **Coverage** : Visez au moins 80% de couverture de code

## 🐛 Tests pour Bugs Spécifiques

Créez des tests de régression pour chaque bug corrigé :

```dart
test('should handle specific bug scenario', () {
  // Reproduire le scénario qui causait le bug
  // Vérifier que le bug est corrigé
});
```

## 📊 Rapport de Couverture

Après avoir exécuté les tests avec `--coverage`, ouvrez :
```
coverage/html/index.html
```

## 🔧 Dépendances de Test

Les dépendances suivantes sont configurées dans `pubspec.yaml` :
- `flutter_test` : Framework de test Flutter
- `test` : Framework de test Dart
- `mockito` : Génération de mocks
- `build_runner` : Génération de code
- `integration_test` : Tests d'intégration

## 💡 Conseils

- Exécutez les tests avant chaque commit
- Ajoutez des tests pour chaque nouvelle fonctionnalité
- Créez des tests de régression pour chaque bug corrigé
- Utilisez les helpers dans `test_helpers.dart`
- Gardez les tests simples et lisibles

## 🚨 Commandes Utiles

```bash
# Nettoyer et reconstruire
flutter clean && flutter pub get

# Générer les mocks
flutter pub run build_runner build

# Lancer un test spécifique
flutter test test/unit/models/user_test.dart

# Tests avec output verbeux
flutter test -v

# Tests en mode debug
flutter test --dart-define=DEBUG=true
```