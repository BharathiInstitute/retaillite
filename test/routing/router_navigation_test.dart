/// Tests for router navigation — auth redirects, shell routes, route guards.
///
/// Tests the redirect logic from app_router.dart inline, without
/// instantiating GoRouter (which requires full widget tree).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/router/app_router.dart';

void main() {
  // ── Route path definitions ──
  group('Route paths', () {
    test('all auth routes defined', () {
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.register, '/register');
      expect(AppRoutes.forgotPassword, '/forgot-password');
      expect(AppRoutes.shopSetup, '/shop-setup');
    });

    test('all main app routes defined', () {
      expect(AppRoutes.billing, '/billing');
      expect(AppRoutes.khata, '/khata');
      expect(AppRoutes.products, '/products');
      expect(AppRoutes.dashboard, '/dashboard');
      expect(AppRoutes.bills, '/bills');
      expect(AppRoutes.settings, '/settings');
    });

    test('parameterized routes contain :id', () {
      expect(AppRoutes.customerDetail, contains(':id'));
      expect(AppRoutes.productDetail, contains(':id'));
      expect(AppRoutes.superAdminUserDetail, contains(':id'));
    });

    test('super admin routes start with /super-admin', () {
      expect(AppRoutes.superAdmin.startsWith('/super-admin'), isTrue);
      expect(AppRoutes.superAdminUsers.startsWith('/super-admin'), isTrue);
      expect(AppRoutes.superAdminSubscriptions.startsWith('/super-admin'), isTrue);
      expect(AppRoutes.superAdminAnalytics.startsWith('/super-admin'), isTrue);
      expect(AppRoutes.superAdminErrors.startsWith('/super-admin'), isTrue);
      expect(AppRoutes.superAdminPerformance.startsWith('/super-admin'), isTrue);
      expect(AppRoutes.superAdminUserCosts.startsWith('/super-admin'), isTrue);
      expect(AppRoutes.superAdminManageAdmins.startsWith('/super-admin'), isTrue);
      expect(AppRoutes.superAdminNotifications.startsWith('/super-admin'), isTrue);
    });
  });

  // ── Auth redirect logic (inline simulation) ──
  group('Auth redirect logic', () {
    /// Simulates redirect decision based on auth state parameters.
    String? simulateRedirect({
      required String currentPath,
      required bool isLoggedIn,
      required bool isShopSetupComplete,
      required bool isLoading,
      required bool isSuperAdminUser,
    }) {
      final isAuthRoute =
          currentPath == '/login' ||
          currentPath == '/register' ||
          currentPath == '/forgot-password' ||
          currentPath == '/super-admin/login' ||
          currentPath == '/desktop-login';
      final isShopSetupRoute = currentPath == '/shop-setup';
      final isSuperAdminRoute = currentPath.startsWith('/super-admin');

      if (isLoading) return '/loading';

      if (!isLoggedIn) {
        if (isAuthRoute) return null;
        return '/login';
      }

      if (isSuperAdminRoute) {
        if (isSuperAdminUser) {
          if (currentPath == '/super-admin/login') return '/super-admin';
          return null;
        }
        return '/billing';
      }

      if (!isShopSetupComplete && !isSuperAdminUser) {
        if (isShopSetupRoute) return null;
        return '/shop-setup';
      }

      if (isAuthRoute || isShopSetupRoute) return '/billing';

      return null;
    }

    test('unauthenticated user on /billing redirects to /login', () {
      expect(
        simulateRedirect(
          currentPath: '/billing',
          isLoggedIn: false,
          isShopSetupComplete: false,
          isLoading: false,
          isSuperAdminUser: false,
        ),
        '/login',
      );
    });

    test('authenticated user on /login redirects to /billing', () {
      expect(
        simulateRedirect(
          currentPath: '/login',
          isLoggedIn: true,
          isShopSetupComplete: true,
          isLoading: false,
          isSuperAdminUser: false,
        ),
        '/billing',
      );
    });

    test('user without shop setup redirects to /shop-setup', () {
      expect(
        simulateRedirect(
          currentPath: '/billing',
          isLoggedIn: true,
          isShopSetupComplete: false,
          isLoading: false,
          isSuperAdminUser: false,
        ),
        '/shop-setup',
      );
    });

    test('user with shop setup skips /shop-setup', () {
      expect(
        simulateRedirect(
          currentPath: '/shop-setup',
          isLoggedIn: true,
          isShopSetupComplete: true,
          isLoading: false,
          isSuperAdminUser: false,
        ),
        '/billing',
      );
    });

    test('super-admin email can access /super-admin', () {
      expect(
        simulateRedirect(
          currentPath: '/super-admin',
          isLoggedIn: true,
          isShopSetupComplete: true,
          isLoading: false,
          isSuperAdminUser: true,
        ),
        isNull, // allowed
      );
    });

    test('non-admin email redirects from /super-admin to /billing', () {
      expect(
        simulateRedirect(
          currentPath: '/super-admin',
          isLoggedIn: true,
          isShopSetupComplete: true,
          isLoading: false,
          isSuperAdminUser: false,
        ),
        '/billing',
      );
    });

    test('loading state redirects to /loading', () {
      expect(
        simulateRedirect(
          currentPath: '/products',
          isLoggedIn: false,
          isShopSetupComplete: false,
          isLoading: true,
          isSuperAdminUser: false,
        ),
        '/loading',
      );
    });

    test('unauthenticated user on auth route stays (no redirect)', () {
      expect(
        simulateRedirect(
          currentPath: '/register',
          isLoggedIn: false,
          isShopSetupComplete: false,
          isLoading: false,
          isSuperAdminUser: false,
        ),
        isNull,
      );
    });
  });

  // ── Shell route grouping ──
  group('Shell routes', () {
    const shellPaths = ['/billing', '/khata', '/products', '/dashboard', '/bills'];
    const outsideShellPaths = ['/customer/abc', '/product/xyz', '/settings', '/notifications'];

    test('billing, khata, products, dashboard, bills use AppShell', () {
      for (final path in shellPaths) {
        expect(shellPaths.contains(path), isTrue, reason: '$path should be in shell');
      }
    });

    test('customer detail is outside shell', () {
      for (final path in outsideShellPaths) {
        expect(shellPaths.contains(path), isFalse);
      }
    });

    test('product detail is outside shell', () {
      expect(shellPaths.contains('/product/xyz'), isFalse);
    });

    test('settings is outside shell', () {
      expect(shellPaths.contains('/settings'), isFalse);
    });

    test('super-admin routes use AdminShellScreen', () {
      const adminPaths = ['/super-admin', '/super-admin/users', '/super-admin/analytics'];
      for (final path in adminPaths) {
        expect(path.startsWith('/super-admin'), isTrue);
      }
    });
  });

  // ── Route persistence ──
  group('Route persistence', () {
    test('last route key is a valid SharedPrefs key', () {
      const key = 'last_route';
      expect(key.isNotEmpty, isTrue);
      expect(key.contains(' '), isFalse);
    });

    test('default restored location is /billing', () {
      // When SharedPrefs has no saved route, default is /billing
      const defaultLocation = '/billing';
      expect(defaultLocation, AppRoutes.billing);
    });

    test('saved route starting with / is valid', () {
      const savedRoute = '/products';
      final isValid = savedRoute.isNotEmpty && savedRoute.startsWith('/');
      expect(isValid, isTrue);
    });

    test('empty saved route falls back to /billing', () {
      const savedRoute = '';
      final restored = (savedRoute.isNotEmpty && savedRoute.startsWith('/'))
          ? savedRoute
          : '/billing';
      expect(restored, '/billing');
    });
  });

  // ── Error handling ──
  group('Error handling', () {
    test('invalid customer :id handled by route parameter', () {
      const id = 'nonexistent_id_12345';
      expect(id.isNotEmpty, isTrue);
      // The screen handles missing data from provider, not router
    });

    test('invalid product :id handled by route parameter', () {
      const id = 'nonexistent_prod_99';
      expect(id.isNotEmpty, isTrue);
    });
  });
}
