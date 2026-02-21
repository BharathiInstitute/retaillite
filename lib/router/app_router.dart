/// App routing configuration using go_router (local mode)
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/screens/desktop_login_screen.dart';
import 'package:retaillite/features/auth/screens/login_screen.dart';
import 'package:retaillite/features/auth/screens/register_screen.dart';
import 'package:retaillite/features/auth/screens/forgot_password_screen.dart';
import 'package:retaillite/features/auth/screens/email_verification_screen.dart';
import 'package:retaillite/features/auth/screens/shop_setup_screen.dart';
import 'package:retaillite/features/billing/screens/billing_screen.dart';
import 'package:retaillite/features/billing/screens/bills_history_screen.dart';
import 'package:retaillite/features/khata/screens/khata_web_screen.dart';
import 'package:retaillite/features/khata/screens/customer_detail_screen.dart';
import 'package:retaillite/features/products/screens/products_web_screen.dart';
import 'package:retaillite/features/products/screens/product_detail_screen.dart';
import 'package:retaillite/features/reports/screens/dashboard_web_screen.dart';
import 'package:retaillite/features/settings/screens/settings_web_screen.dart';
import 'package:retaillite/features/settings/screens/theme_settings_screen.dart';
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
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/widgets/splash_screen.dart';

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String loading = '/loading';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String shopSetup = '/shop-setup';
  static const String emailVerification = '/verify-email';
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

// Super admin emails imported from super_admin_provider.dart (single source of truth)

/// Bridge between Riverpod auth state and GoRouter's refreshListenable.
/// This notifies GoRouter to re-evaluate redirects when auth state changes,
/// WITHOUT recreating the entire GoRouter instance.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, _) {
      notifyListeners();
    });
  }
}

/// Key for persisting the last route in SharedPreferences
const String _lastRouteKey = 'last_route';

/// Read the last saved route from SharedPreferences (sync, prefs already init'd)
String _getRestoredInitialLocation() {
  final saved = OfflineStorageService.prefs?.getString(_lastRouteKey);
  if (saved != null && saved.isNotEmpty && saved.startsWith('/')) {
    debugPrint('🔄 Restoring initial location from SharedPreferences: $saved');
    return saved;
  }
  return AppRoutes.billing;
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = _AuthChangeNotifier(ref);
  ref.onDispose(() => authChangeNotifier.dispose());

  // Use the last saved route as initialLocation.
  // On fresh install this is /billing; after that, it's whatever page the user was on.
  final restoredLocation = _getRestoredInitialLocation();

  // In-memory variable to remember the pre-loading URL during auth initialization.
  // Because initialLocation = restoredLocation, the first redirect sees the correct path.
  String? pendingRedirect;

  return GoRouter(
    initialLocation: restoredLocation,
    debugLogDiagnostics: true,
    // Re-evaluate redirects when auth state changes (no GoRouter recreation)
    refreshListenable: authChangeNotifier,

    redirect: (context, state) {
      // Read auth state inside redirect (not watch — GoRouter is not recreated)
      final authState = ref.read(authNotifierProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isShopSetupComplete = authState.isShopSetupComplete;
      final isEmailVerified = authState.isEmailVerified;
      final isLoading = authState.isLoading;
      final userEmail = authState.user?.email?.toLowerCase().trim() ?? '';
      final isSuperAdminUser = superAdminEmails.contains(userEmail);

      final currentPath = state.matchedLocation;
      final fullUri = state.uri.toString();
      final isLoadingRoute = currentPath == AppRoutes.loading;

      // While auth is initializing, show the loading screen.
      // Capture the current URL so we can restore after auth resolves.
      if (isLoading) {
        if (!isLoadingRoute) {
          pendingRedirect = fullUri;
        }
        return isLoadingRoute ? null : AppRoutes.loading;
      }

      // Auth is resolved — leave the loading screen
      if (isLoadingRoute) {
        if (!isLoggedIn) return AppRoutes.login;
        if (!isEmailVerified && !isSuperAdminUser) {
          return AppRoutes.emailVerification;
        }
        if (!isShopSetupComplete && !isSuperAdminUser) {
          return AppRoutes.shopSetup;
        }
        // Restore the route we captured before going to /loading
        final target = pendingRedirect ?? restoredLocation;
        pendingRedirect = null;
        // If the restored target is a super-admin route, only allow if admin
        if (target.startsWith('/super-admin') && !isSuperAdminUser) {
          return AppRoutes.billing;
        }
        return target;
      }

      final isAuthRoute =
          currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath == AppRoutes.superAdminLogin;
      final isShopSetupRoute = currentPath == AppRoutes.shopSetup;
      final isEmailVerificationRoute =
          currentPath == AppRoutes.emailVerification;
      final isSuperAdminRoute = currentPath.startsWith('/super-admin');
      final isGoingToSuperAdmin = fullUri.startsWith('/super-admin');

      // Not logged in
      if (!isLoggedIn) {
        // Allow auth routes (including super admin login)
        if (isAuthRoute) return null;
        // Redirect to login
        return AppRoutes.login;
      }

      // Allow super admin routes only for authorized admin emails
      if (isSuperAdminRoute || isGoingToSuperAdmin) {
        if (isSuperAdminUser) return null; // Authorized — allow
        return AppRoutes.billing; // Not authorized — send to store
      }

      // Regular user: email not verified
      if (!isEmailVerified) {
        if (isEmailVerificationRoute) return null;
        return AppRoutes.emailVerification;
      }

      // Regular user: Logged in but shop setup not complete
      if (!isShopSetupComplete) {
        // Allow shop setup route
        if (isShopSetupRoute) return null;
        // Redirect email verification to shop setup (already verified)
        if (isEmailVerificationRoute) return AppRoutes.shopSetup;
        // Redirect to shop setup
        return AppRoutes.shopSetup;
      }

      // Logged in and setup complete
      if (isAuthRoute || isShopSetupRoute || isEmailVerificationRoute) {
        // Redirect auth routes to billing
        return AppRoutes.billing;
      }

      // ── Persist current route for restoration after web refresh ──
      // Only save "normal" app routes (not auth, loading, or super-admin)
      if (isLoggedIn &&
          isShopSetupComplete &&
          !isAuthRoute &&
          !isSuperAdminRoute) {
        OfflineStorageService.prefs?.setString(_lastRouteKey, fullUri);
      }

      return null;
    },

    routes: [
      // Loading route — shown while Firebase Auth initializes
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const SplashScreen(message: 'Loading...'),
      ),

      // Auth routes (outside shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => (!kIsWeb && Platform.isWindows)
            ? const DesktopLoginScreen()
            : const LoginScreen(),
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
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
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
                const NoTransitionPage(child: KhataWebScreen()),
          ),
          GoRoute(
            path: AppRoutes.products,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProductsWebScreen()),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardWebScreen()),
          ),
          GoRoute(
            path: AppRoutes.bills,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BillsHistoryScreen()),
          ),
        ],
      ),

      // Settings — full-width (outside shell, has its own side nav)
      GoRoute(
        path: AppRoutes.settingsTab,
        pageBuilder: (context, state) {
          final tab = state.pathParameters['tab'] ?? 'general';
          return NoTransitionPage(child: SettingsWebScreen(initialTab: tab));
        },
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
      // Redirect bare /settings to /settings/general
      GoRoute(
        path: AppRoutes.settings,
        redirect: (context, state) => '/settings/general',
      ),
      GoRoute(
        path: AppRoutes.themeSettings,
        builder: (context, state) => const ThemeSettingsScreen(),
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
