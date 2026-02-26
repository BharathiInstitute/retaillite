import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/router/app_router.dart';

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
