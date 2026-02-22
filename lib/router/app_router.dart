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
import 'package:retaillite/features/super_admin/screens/manage_admins_screen.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';
import 'package:retaillite/features/super_admin/screens/super_admin_login_screen.dart';
import 'package:retaillite/features/super_admin/screens/notifications_admin_screen.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/features/notifications/screens/notifications_screen.dart';
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
  static const String superAdminManageAdmins = '/super-admin/manage-admins';
  static const String superAdminNotifications = '/super-admin/notifications';
  static const String notifications = '/notifications';
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
        if (isSuperAdminUser) {
          // Already logged in admin on login page → go to dashboard
          if (currentPath == AppRoutes.superAdminLogin) {
            return '/super-admin';
          }
          return null; // Authorized — allow
        }
        return AppRoutes.billing; // Not authorized — send to store
      }

      // Regular user: Logged in but shop setup not complete
      // Super admins bypass shop setup entirely
      if (!isShopSetupComplete && !isSuperAdminUser) {
        // Allow shop setup route
        if (isShopSetupRoute) return null;
        // Redirect to shop setup
        return AppRoutes.shopSetup;
      }

      // Logged in and setup complete (or super admin)
      if (isAuthRoute || isShopSetupRoute) {
        // Redirect auth routes to billing
        return AppRoutes.billing;
      }

      // ── Persist current route for restoration after web refresh ──
      // Save all app routes (including super-admin dashboard, but not auth/login pages)
      if (isLoggedIn && !isAuthRoute) {
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

      // User notifications inbox (outside main shell)
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Super Admin login (outside shell)
      GoRoute(
        path: AppRoutes.superAdminLogin,
        builder: (context, state) => const SuperAdminLoginScreen(),
      ),

      // Super Admin pages (inside admin shell with persistent sidebar)
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.superAdmin,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SuperAdminDashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.superAdminUsers,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UsersListScreen()),
          ),
          GoRoute(
            path: AppRoutes.superAdminUserDetail,
            pageBuilder: (context, state) {
              final userId = state.pathParameters['id']!;
              return NoTransitionPage(child: UserDetailScreen(userId: userId));
            },
          ),
          GoRoute(
            path: AppRoutes.superAdminSubscriptions,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SubscriptionsScreen()),
          ),
          GoRoute(
            path: AppRoutes.superAdminAnalytics,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: AppRoutes.superAdminErrors,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ErrorsScreen()),
          ),
          GoRoute(
            path: AppRoutes.superAdminPerformance,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PerformanceScreen()),
          ),
          GoRoute(
            path: AppRoutes.superAdminUserCosts,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UserCostsScreen()),
          ),
          GoRoute(
            path: AppRoutes.superAdminManageAdmins,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ManageAdminsScreen()),
          ),
          GoRoute(
            path: AppRoutes.superAdminNotifications,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationsAdminScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
