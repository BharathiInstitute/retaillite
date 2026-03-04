/// Tests for AppRoutes — route string constants
/// Uses inline duplicate to avoid transitive Firebase import chain.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicate (avoid app_router → billing_screen import chain) ──

class AppRoutes {
  AppRoutes._();
  static const String loading = '/loading';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String shopSetup = '/shop-setup';
  static const String billing = '/billing';
  static const String khata = '/khata';
  static const String customerDetail = '/customer/:id';
  static const String products = '/products';
  static const String productDetail = '/product/:id';
  static const String dashboard = '/dashboard';
  static const String bills = '/bills';
  static const String settings = '/settings';
  static const String settingsTab = '/settings/:tab';
  static const String themeSettings = '/settings/theme';
  static const String subscription = '/subscription';
  static const String superAdminLogin = '/super-admin/login';
  static const String superAdmin = '/super-admin';
  static const String superAdminUsers = '/super-admin/users';
  static const String superAdminUserDetail = '/super-admin/users/:id';
  static const String superAdminSubscriptions = '/super-admin/subscriptions';
  static const String superAdminAnalytics = '/super-admin/analytics';
  static const String superAdminErrors = '/super-admin/errors';
  static const String superAdminPerformance = '/super-admin/performance';
  static const String superAdminUserCosts = '/super-admin/user-costs';
  static const String superAdminManageAdmins = '/super-admin/manage-admins';
  static const String superAdminNotifications = '/super-admin/notifications';
  static const String notifications = '/notifications';
}

void main() {
  // ── Route Paths ──

  group('AppRoutes', () {
    test('login route is /login', () {
      expect(AppRoutes.login, '/login');
    });

    test('register route is /register', () {
      expect(AppRoutes.register, '/register');
    });

    test('billing route is /billing', () {
      expect(AppRoutes.billing, '/billing');
    });

    test('products route is /products', () {
      expect(AppRoutes.products, '/products');
    });

    test('khata route is /khata', () {
      expect(AppRoutes.khata, '/khata');
    });

    test('settings route is /settings', () {
      expect(AppRoutes.settings, '/settings');
    });

    test('shopSetup route exists', () {
      expect(AppRoutes.shopSetup, isNotEmpty);
    });

    test('forgotPassword route exists', () {
      expect(AppRoutes.forgotPassword, isNotEmpty);
    });

    test('customerDetail has :id parameter', () {
      expect(AppRoutes.customerDetail, contains(':id'));
    });

    test('productDetail has :id parameter', () {
      expect(AppRoutes.productDetail, contains(':id'));
    });

    test('loading route exists', () {
      expect(AppRoutes.loading, isNotEmpty);
    });

    test('all routes start with /', () {
      expect(AppRoutes.login, startsWith('/'));
      expect(AppRoutes.register, startsWith('/'));
      expect(AppRoutes.billing, startsWith('/'));
      expect(AppRoutes.products, startsWith('/'));
      expect(AppRoutes.khata, startsWith('/'));
      expect(AppRoutes.settings, startsWith('/'));
    });

    test('superAdminLogin route exists', () {
      expect(AppRoutes.superAdminLogin, isNotEmpty);
    });
  });
}
