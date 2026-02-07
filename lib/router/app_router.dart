/// App routing configuration using go_router (local mode)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/screens/login_screen.dart';
import 'package:retaillite/features/auth/screens/register_screen.dart';
import 'package:retaillite/features/auth/screens/forgot_password_screen.dart';
import 'package:retaillite/features/auth/screens/shop_setup_screen.dart';
import 'package:retaillite/features/billing/screens/billing_screen.dart';
import 'package:retaillite/features/khata/screens/khata_screen.dart';
import 'package:retaillite/features/khata/screens/customer_detail_screen.dart';
import 'package:retaillite/features/products/screens/products_screen.dart';
import 'package:retaillite/features/products/screens/product_detail_screen.dart';
import 'package:retaillite/features/reports/screens/reports_screen.dart';
import 'package:retaillite/features/settings/screens/settings_screen.dart';
import 'package:retaillite/features/shell/app_shell.dart';
import 'package:retaillite/features/super_admin/screens/super_admin_dashboard_screen.dart';
import 'package:retaillite/features/super_admin/screens/users_list_screen.dart';
import 'package:retaillite/features/super_admin/screens/user_detail_screen.dart';
import 'package:retaillite/features/super_admin/screens/subscriptions_screen.dart';
import 'package:retaillite/features/super_admin/screens/analytics_screen.dart';
import 'package:retaillite/features/super_admin/screens/errors_screen.dart';
import 'package:retaillite/features/super_admin/screens/performance_screen.dart';
import 'package:retaillite/features/super_admin/screens/user_costs_screen.dart';
import 'package:retaillite/features/super_admin/screens/super_admin_login_screen.dart';

/// Route paths
class AppRoutes {
  AppRoutes._();

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
  static const String settings = '/settings';

  // Super Admin routes
  static const String superAdminLogin = '/super-admin/login';
  static const String superAdmin = '/super-admin';
  static const String superAdminUsers = '/super-admin/users';
  static const String superAdminUserDetail = '/super-admin/users/:id';
  static const String superAdminSubscriptions = '/super-admin/subscriptions';
  static const String superAdminAnalytics = '/super-admin/analytics';
  static const String superAdminErrors = '/super-admin/errors';
  static const String superAdminPerformance = '/super-admin/performance';
  static const String superAdminUserCosts = '/super-admin/user-costs';
}

/// Super admin emails whitelist (used for routing)
const List<String> _superAdminEmails = [
  'kehsaram001@gmail.com',
  'admin@retaillite.com',
  'bharathiinstitute1@gmail.com',
  'bharahiinstitute1@gmail.com',
];

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final isLoggedIn = authState.isLoggedIn;
  final isShopSetupComplete = authState.isShopSetupComplete;
  final isLoading = authState.isLoading;

  // Check if current user is a super admin (check email against whitelist)
  final userEmail = authState.user?.email?.toLowerCase().trim() ?? '';
  final isSuperAdminUser = _superAdminEmails.contains(userEmail);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      // Wait for auth to initialize
      if (isLoading) {
        return null;
      }

      final currentPath = state.matchedLocation;
      final fullUri = state.uri.toString();

      final isAuthRoute =
          currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath == AppRoutes.superAdminLogin;
      final isShopSetupRoute = currentPath == AppRoutes.shopSetup;
      final isSuperAdminRoute = currentPath.startsWith('/super-admin');
      final isGoingToSuperAdmin = fullUri.startsWith('/super-admin');

      // Not logged in
      if (!isLoggedIn) {
        // Allow auth routes (including super admin login)
        if (isAuthRoute) return null;
        // Redirect to login
        return AppRoutes.login;
      }

      // IMPORTANT: Always allow super admin routes for logged in users
      // The SuperAdminDashboardScreen itself will verify admin privileges
      if (isSuperAdminRoute || isGoingToSuperAdmin) {
        return null;
      }

      // Super admin user - redirect to admin dashboard when on auth/setup routes
      if (isSuperAdminUser) {
        if (isAuthRoute || isShopSetupRoute) {
          return AppRoutes.superAdmin; // Redirect super admin to admin panel
        }
        // Allow other routes
        return null;
      }

      // Regular user: Logged in but shop setup not complete
      if (!isShopSetupComplete) {
        // Allow shop setup route
        if (isShopSetupRoute) return null;
        // Redirect to shop setup
        return AppRoutes.shopSetup;
      }

      // Logged in and setup complete
      if (isAuthRoute || isShopSetupRoute) {
        // Allow /register if coming from demo mode (user wants to convert)
        if (authState.isDemoMode && currentPath == AppRoutes.register) {
          return null;
        }
        // Redirect regular auth routes to billing
        return AppRoutes.billing;
      }

      return null;
    },

    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.shopSetup,
        builder: (context, state) => const ShopSetupScreen(),
      ),

      // Main app shell with tabs
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.billing,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BillingScreen()),
          ),
          GoRoute(
            path: AppRoutes.khata,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: KhataScreen()),
          ),
          GoRoute(
            path: AppRoutes.products,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProductsScreen()),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsScreen()),
          ),
        ],
      ),

      // Detail screens (outside shell)
      GoRoute(
        path: AppRoutes.customerDetail,
        builder: (context, state) {
          final customerId = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: customerId);
        },
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Super Admin routes
      GoRoute(
        path: AppRoutes.superAdminLogin,
        builder: (context, state) => const SuperAdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdmin,
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminUsers,
        builder: (context, state) => const UsersListScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminUserDetail,
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return UserDetailScreen(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.superAdminSubscriptions,
        builder: (context, state) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminAnalytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminErrors,
        builder: (context, state) => const ErrorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminPerformance,
        builder: (context, state) => const PerformanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminUserCosts,
        builder: (context, state) => const UserCostsScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
