import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';
import 'package:ventemoi/screens/profile_screen/controllers/profile_screen_controller.dart';

import 'core/routes/app_screens.dart';
import 'core/theme/util.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GetStorage.init('Storage');

  await initializeDateFormatting('fr_FR', null);

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
    );
  }
}
