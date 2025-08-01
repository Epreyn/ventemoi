abstract class Routes {
  Routes._();

  static const test = RoutePaths.test;
  static const login = RoutePaths.login;
  static const register = RoutePaths.register;
  static const password = RoutePaths.password;
  static const shopEstablishment = RoutePaths.shopEstablishment;
  static const clientHistory = RoutePaths.clientHistory;
  static const proEstablishmentProfile = RoutePaths.proEstablishmentProfile;
  static const proSells = RoutePaths.proSells;
  static const proPoints = RoutePaths.proPoints;
  static const profile = RoutePaths.profile;
  static const sponsorship = RoutePaths.sponsorship;
  static const adminUsers = RoutePaths.adminUsers;
  static const adminEstablishments = RoutePaths.adminEstablishments;
  static const adminSells = RoutePaths.adminSells;
  static const adminPointsAttributions = RoutePaths.adminPointsAttributions;
  static const adminPointsRequests = RoutePaths.adminPointsRequests;
  static const adminUserTypes = RoutePaths.adminUserTypes;
  static const adminCategories = RoutePaths.adminCategories;
  static const adminEnterpriseCategories = RoutePaths.adminEnterpriseCategories;
  static const adminCommissions = RoutePaths.adminCommissions;
  static const onboarding = RoutePaths.onboarding;
  static const adminMigration = RoutePaths.adminMigration;
}

abstract class RoutePaths {
  RoutePaths._();

  static const test = '/test';
  static const login = '/login';
  static const password = '/password';
  static const register = '/register';
  static const shopEstablishment = '/shop-establishment';
  static const clientHistory = '/client-history';
  static const proEstablishmentProfile = '/pro-establishment-profile';
  static const proSells = '/pro-sells';
  static const proPoints = '/pro-points';
  static const profile = '/profile';
  static const sponsorship = '/sponsorship';
  static const adminUsers = '/admin-users';
  static const adminEstablishments = '/admin-establishments';
  static const adminSells = '/admin-sells';
  static const adminPointsAttributions = '/admin-points-attributions';
  static const adminPointsRequests = '/admin-points-requests';
  static const adminUserTypes = '/admin-user-types';
  static const adminCategories = '/admin-categories';
  static const adminEnterpriseCategories = '/admin-enterprise-categories';
  static const adminCommissions = '/admin-commissions';
  static const onboarding = '/onboarding';
  static const adminMigration = '/admin-migration';
}
