import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import 'core/routes/app_screens.dart';
import 'core/theme/util.dart';

import 'features/screen_layout/controllers/screen_layout_controller.dart';
import 'firebase_options.dart';
import 'screens/not_found_screen/view/not_found_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GetStorage.init('Storage');

  await initializeDateFormatting('fr_FR', null);

  Get.put(ScreenLayoutController(), permanent: true);

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, 'Onest', 'Phudu');
    CustomTheme customTheme = CustomTheme(textTheme);

    return GetMaterialApp(
      theme: customTheme.light(),
      locale: const Locale('fr', 'FR'),
      debugShowCheckedModeBanner: false,
      title: 'VENTE MOI',
      initialRoute: AppScreens.initial,
      getPages: AppScreens.routes,
      defaultTransition: Transition.noTransition,
      unknownRoute: GetPage(
        name: '/404',
        page: () => const NotFoundScreen(),
      ),
      // Configuration pour une meilleure gestion des routes et paramètres
      navigatorKey: Get.key,
      navigatorObservers: [GetObserver()],
      // Gestion des paramètres URL et du routing
      routingCallback: (routing) {
        // Les paramètres sont automatiquement extraits par GetX
        // Accessible via Get.parameters['paramName']
        if (routing?.current != null) {
          //debugPrint('Route actuelle: ${routing!.current}');
          //debugPrint('Paramètres: ${Get.parameters}');
        }
      },
      // Pour supporter les deep links sur web
      onGenerateRoute: (settings) {
        // GetX gère automatiquement l'extraction des paramètres
        // Cette méthode est utile pour des cas spéciaux
        return null; // Laisser GetX gérer le routing
      },
    );
  }
}
