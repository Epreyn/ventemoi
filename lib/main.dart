import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import 'core/models/payment_listener.dart';
import 'core/models/stripe_service.dart';
import 'core/routes/app_screens.dart';
import 'core/services/stripe_payment_manager.dart';
import 'core/theme/util.dart';

import 'features/screen_layout/controllers/screen_layout_controller.dart';
import 'firebase_options.dart';
import 'screens/not_found_screen/view/not_found_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Get.putAsync(() async => StripeService());
  Get.put(StripePaymentManager());
  Get.put(PaymentListenerController());

  await GetStorage.init('Storage');

  await initializeDateFormatting('fr_FR', null);

  Get.put(ScreenLayoutController(), permanent: true);

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, 'Questrial', 'Questrial');
    CustomTheme customTheme = CustomTheme(textTheme);

    return GetMaterialApp(
      theme: customTheme.light(),
      locale: const Locale('fr', 'FR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      debugShowCheckedModeBanner: false,
      title: 'VENTE MOI',
      initialRoute: AppScreens.initial,
      getPages: AppScreens.routes,
      defaultTransition: Transition.noTransition,
      transitionDuration: const Duration(milliseconds: 0),
      unknownRoute: GetPage(
        name: '/404',
        page: () => const NotFoundScreen(),
      ),
      navigatorKey: Get.key,
      navigatorObservers: [GetObserver()],
      onGenerateRoute: (settings) {
        return null;
      },
    );
  }
}
