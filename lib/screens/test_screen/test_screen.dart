import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../../../features/custom_text_form_field/view/custom_text_form_field.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test iOS TextField'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test 1: TextField basique Flutter
            Text('1. TextField Flutter basique:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'TextField basique',
              ),
            ),

            SizedBox(height: 30),

            // Test 2: TextFormField basique
            Text('2. TextFormField basique:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'TextFormField basique',
              ),
            ),

            SizedBox(height: 30),

            // Test 3: CustomTextFormField sans ScreenLayout
            Text('3. CustomTextFormField (sans ScreenLayout):',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            CustomTextFormField(
              labelText: 'CustomTextFormField',
              tag: 'CustomTextFormField',
              controller: TextEditingController(),
            ),

            SizedBox(height: 30),

            // Test 4: Dans un Form
            Text('4. TextFormField dans Form:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Form(
              child: TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Dans un Form',
                ),
              ),
            ),

            SizedBox(height: 30),

            // Test 5: Avec GestureDetector parent
            Text('5. Avec GestureDetector parent:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.grey[200],
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Avec GestureDetector',
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Bouton pour naviguer vers une page avec ScreenLayout
            ElevatedButton(
              onPressed: () {
                Get.to(() => DebugWithScreenLayout());
              },
              child: Text(
                  'Tester avec ScreenLayout (peut causer erreur si non connecté)'),
            ),

            SizedBox(height: 10),

            // Test progressif du ScreenLayout
            ElevatedButton(
              onPressed: () {
                Get.to(() => ScreenLayoutDebugTest());
              },
              child: Text('Test progressif ScreenLayout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Test progressif pour identifier quel composant du ScreenLayout cause le problème
class ScreenLayoutDebugTest extends StatelessWidget {
  final int testLevel;

  const ScreenLayoutDebugTest({
    super.key,
    this.testLevel = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Level $testLevel'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Configuration actuelle :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            _buildCurrentConfig(),
            SizedBox(height: 30),

            // Les TextFields de test
            _buildTestFields(),

            SizedBox(height: 30),

            // Navigation vers le niveau suivant
            if (testLevel < 5)
              ElevatedButton(
                onPressed: () {
                  Get.to(() => ScreenLayoutDebugTest(testLevel: testLevel + 1));
                },
                child: Text('Tester niveau ${testLevel + 1}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConfig() {
    switch (testLevel) {
      case 1:
        return Text('Scaffold simple (pas de Stack, pas de GestureDetector)');
      case 2:
        return Text('Scaffold + Stack');
      case 3:
        return Text('Scaffold + Stack + GestureDetector vide');
      case 4:
        return Text('Scaffold + Stack + GestureDetector avec onTap');
      case 5:
        return Text('Configuration complète comme ScreenLayout');
      default:
        return Text('Test niveau $testLevel');
    }
  }

  Widget _buildTestFields() {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TextField standard :'),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'TextField test niveau $testLevel',
          ),
        ),
        SizedBox(height: 20),
        Text('TextFormField :'),
        SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'TextFormField test niveau $testLevel',
          ),
        ),
      ],
    );

    // Application progressive des composants
    switch (testLevel) {
      case 1:
        // Juste le contenu
        return content;

      case 2:
        // Avec Stack
        return Stack(
          children: [
            Container(color: Colors.white),
            content,
          ],
        );

      case 3:
        // Avec GestureDetector vide
        return GestureDetector(
          child: Stack(
            children: [
              Container(color: Colors.white),
              content,
            ],
          ),
        );

      case 4:
        // Avec GestureDetector et onTap
        return GestureDetector(
          onTap: () {
            FocusScope.of(Get.context!).unfocus();
          },
          child: Stack(
            children: [
              Container(color: Colors.white),
              content,
            ],
          ),
        );

      case 5:
        // Configuration complète
        return GestureDetector(
          onTap: () {
            FocusScope.of(Get.context!).unfocus();
          },
          behavior: HitTestBehavior.deferToChild,
          child: Stack(
            children: [
              // Background
              Container(color: Colors.white),

              // Contenu avec animations (simulé)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: content,
              ),
            ],
          ),
        );

      default:
        return content;
    }
  }
}

// Page de test avec ScreenLayout
class DebugWithScreenLayout extends StatelessWidget {
  const DebugWithScreenLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenLayout(
      noAppBar: true, // Désactiver l'AppBar qui cause l'erreur
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test avec ScreenLayout:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 20),

            // Test 1: TextField simple
            Text('TextField dans ScreenLayout:'),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'TextField simple',
              ),
            ),

            SizedBox(height: 20),

            // Test 2: CustomTextFormField
            Text('CustomTextFormField dans ScreenLayout:'),
            SizedBox(height: 10),
            CustomTextFormField(
              labelText: 'CustomTextFormField',
              tag: 'CTFF',
              controller: TextEditingController(),
            ),

            SizedBox(height: 20),

            // Test 3: Dans un Form
            Text('Form dans ScreenLayout:'),
            SizedBox(height: 10),
            Form(
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Champ 1',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Champ 2',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
