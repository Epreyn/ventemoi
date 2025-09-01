import 'package:get/get.dart';
import 'package:ventemoi/screens/admin_commissions_screen/view/admin_commissions_screen.dart';
import 'package:ventemoi/screens/admin_offers_screen/view/admin_offers_screen.dart';
import 'package:ventemoi/screens/admin_establishments_screen/view/admin_establishments_screen.dart';
import 'package:ventemoi/screens/admin_points_requests_screen/view/admin_points_requests_screen.dart';
import 'package:ventemoi/screens/admin_sells_screen/view/admin_sells_screen.dart';
import 'package:ventemoi/screens/sponsorship_screen/view/sponsorship_screen.dart';
import 'package:ventemoi/screens/test_screen/test_screen.dart';

import '../../screens/admin_categories_screen/view/admin_categories_screen.dart';
import '../../screens/admin_enterprise_categories_screen/view/admin_enterprise_categories_screen.dart';
import '../../screens/admin_migration_screen/view/admin_migration_screen.dart';
import '../../screens/admin_points_attributions_screen/view/admin_points_attributions_screen.dart';
import '../../screens/admin_user_types_screen/view/admin_user_types_screen.dart';
import '../../screens/admin_users_screen/view/admin_users_screen.dart';
import '../../screens/client_history_screen/view/client_history_screen.dart';
import '../../screens/login_screen/view/login_screen.dart';
import '../../screens/onboarding_screen/view/onboarding_screen.dart';
import '../../screens/password_screen/view/password_screen.dart';
import '../../screens/pro_establishment_profile_screen/view/pro_establishment_profile_screen.dart';
import '../../screens/pro_points_screen/view/pro_points_screen.dart';
import '../../screens/pro_request_offer_screen/view/pro_request_offer_screen.dart';
import '../../screens/pro_sells_screen/view/pro_sells_screen.dart';
import '../../screens/profile_screen/view/profile_screen.dart';
import '../../screens/register_screen/view/register_screen.dart';
import '../../screens/shop_establishment_screen/view/shop_establishment_screen.dart';
import '../../screens/quotes_screen/view/quotes_screen.dart';
import 'app_routes.dart';

class AppScreens {
  AppScreens._();

  static const initial = Routes.login;

  static final routes = [
    GetPage(
      name: RoutePaths.test,
      page: () => const TestScreen(),
    ),
    GetPage(
      name: RoutePaths.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: RoutePaths.password,
      page: () => const PasswordScreen(),
    ),
    GetPage(
      name: RoutePaths.register,
      page: () => const RegisterScreen(),
      parameters: {
        'token': Get.parameters['token'] ?? '',
        'email': Get.parameters['email'] ?? '',
        'code': Get.parameters['code'] ?? '',
      },
    ),
    GetPage(
      name: RoutePaths.shopEstablishment,
      page: () => const ShopEstablishmentScreen(),
    ),
    GetPage(
      name: RoutePaths.quotes,
      page: () => const QuotesScreen(),
    ),
    GetPage(
      name: RoutePaths.clientHistory,
      page: () => const ClientHistoryScreen(),
    ),
    GetPage(
      name: RoutePaths.proEstablishmentProfile,
      page: () => const ProEstablishmentProfileScreen(),
    ),
    GetPage(
      name: RoutePaths.proSells,
      page: () => const ProSellsScreen(),
    ),
    GetPage(
      name: RoutePaths.proPoints,
      page: () => const ProPointsScreen(),
    ),
    GetPage(
      name: RoutePaths.proRequestOffer,
      page: () => const ProRequestOfferScreen(),
    ),
    GetPage(
      name: RoutePaths.profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: RoutePaths.sponsorship,
      page: () => const SponsorshipScreen(),
    ),
    GetPage(
      name: RoutePaths.adminUsers,
      page: () => const AdminUsersScreen(),
    ),
    GetPage(
      name: RoutePaths.adminEstablishments,
      page: () => const AdminEstablishmentsScreen(),
    ),
    GetPage(
      name: RoutePaths.adminSells,
      page: () => const AdminSellsScreen(),
    ),
    GetPage(
      name: RoutePaths.adminPointsAttributions,
      page: () => const AdminPointsAttributionsScreen(),
    ),
    GetPage(
      name: RoutePaths.adminPointsRequests,
      page: () => const AdminPointsRequestsScreen(),
    ),
    GetPage(
      name: RoutePaths.adminUserTypes,
      page: () => const AdminUserTypesScreen(),
    ),
    GetPage(
      name: RoutePaths.adminCategories,
      page: () => const AdminCategoriesScreen(),
    ),
    GetPage(
      name: RoutePaths.adminEnterpriseCategories,
      page: () => const AdminEnterpriseCategoriesScreen(),
    ),
    GetPage(
      name: RoutePaths.adminCommissions,
      page: () => const AdminCommissionsScreen(),
    ),
    GetPage(
      name: RoutePaths.adminOffers,
      page: () => const AdminOffersScreen(),
    ),
    GetPage(
      name: RoutePaths.onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: RoutePaths.adminMigration,
      page: () => AdminMigrationScreen(),
    ),
  ];
}
