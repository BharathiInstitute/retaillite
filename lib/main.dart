import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/app.dart';
import 'package:retaillite/core/config/app_check_config.dart';
import 'package:retaillite/core/services/android_update_service.dart';
import 'package:retaillite/core/services/app_health_service.dart';
import 'package:retaillite/core/services/connectivity_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/payment_link_service.dart';
import 'package:retaillite/core/services/sync_settings_service.dart';
import 'package:retaillite/core/services/windows_update_service.dart';
import 'package:retaillite/core/config/remote_config_state.dart';
import 'package:retaillite/core/utils/error_handler.dart';
import 'package:retaillite/core/widgets/force_update_screen.dart';
import 'package:retaillite/core/widgets/maintenance_screen.dart';
import 'package:retaillite/core/widgets/splash_screen.dart';
import 'package:retaillite/features/notifications/services/notification_service.dart';
import 'package:retaillite/features/notifications/services/windows_notification_service.dart';
import 'package:retaillite/firebase_options.dart';

/// App version info
const String appVersion = '1.0.0';
const int appBuildNumber = 1;

void main() {
  // Mark app start time for health metrics
  AppHealthService.markAppStart();

  // Show splash screen immediately while initializing
  runApp(const SplashScreen(message: 'Starting...'));

  // Initialize app in background
  _initializeApp();
}

/// Initialize all services and launch main app
Future<void> _initializeApp() async {
  // Check if running on Windows (Crashlytics/AppCheck not supported)
  final isWindows = !kIsWeb && Platform.isWindows;

  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase first (required by other services)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register FCM background handler (must be top-level function)
    if (!isWindows) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await NotificationService.setForegroundOptions();
    }

    // Initialize Firebase App Check — protects all Firebase services
    // Skip on web (if no reCAPTCHA key) and Windows (not supported)
    if (!isWindows && (!kIsWeb || AppCheckConfig.isWebConfigured)) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerWeb: AppCheckConfig.isWebConfigured
              ? ReCaptchaEnterpriseProvider(AppCheckConfig.recaptchaSiteKey)
              : null,
        );
      } catch (e) {
        debugPrint('⚠️ Firebase App Check activation failed: $e');
        // Non-fatal: app can still work without App Check in debug mode
      }
    } else if (isWindows) {
      debugPrint('ℹ️ Skipping App Check on Windows (not supported)');
    } else {
      debugPrint('ℹ️ Skipping App Check on web (no reCAPTCHA key configured)');
    }

    // Initialize Crashlytics (not supported on web or Windows)
    if (!kIsWeb && !isWindows) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }

    // Initialize global error handling
    ErrorHandler.initialize();

    // Initialize Remote Config with defaults
    String merchantUpiId = '';
    bool maintenanceMode = false;
    String minVersion = '';
    String forceUpdateUrl = '';

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults(const {
        'maintenance_mode': false,
        'min_app_version': '1.0.0',
        'force_update': false,
        'force_update_url': '',
        'kill_switch_payments': false,
        'merchant_upi_id': '',
        'latest_version': '',
        'announcement': '',
      });
      await remoteConfig.fetchAndActivate();

      // Apply Remote Config values
      merchantUpiId = remoteConfig.getString('merchant_upi_id');
      maintenanceMode = remoteConfig.getBool('maintenance_mode');
      minVersion = remoteConfig.getString('min_app_version');
      forceUpdateUrl = remoteConfig.getString('force_update_url');

      // Soft nudge + announcements (non-blocking)
      RemoteConfigState.latestVersion = remoteConfig.getString(
        'latest_version',
      );
      RemoteConfigState.announcement = remoteConfig.getString('announcement');
    } catch (e) {
      debugPrint('⚠️ Remote Config initialization failed: $e');
      // Non-fatal: app can work without Remote Config
    }

    if (merchantUpiId.isNotEmpty) {
      PaymentLinkService.setUpiId(merchantUpiId);
    }

    // ─── Check maintenance mode ───
    if (maintenanceMode) {
      runApp(
        MaintenanceScreen(
          onRetry: () {
            runApp(const SplashScreen(message: 'Checking...'));
            _initializeApp();
          },
        ),
      );
      return;
    }

    // ─── Check force update ───
    if (_isVersionLower(appVersion, minVersion)) {
      runApp(
        ForceUpdateScreen(
          currentVersion: appVersion,
          requiredVersion: minVersion,
          updateUrl: forceUpdateUrl,
        ),
      );
      return;
    }

    // Enable Firestore persistence BEFORE any other Firestore access
    await SyncSettingsService.initializeFirestorePersistence();

    // Run independent initializations in PARALLEL for faster startup
    await Future.wait([
      OfflineStorageService.initialize(),
      PrinterStorage.initialize(),
      SyncSettingsService.initialize(),
      ConnectivityService.initialize(),
      AppHealthService.initialize(),
      WindowsNotificationService.init(),
    ]);

    // Launch the main app
    runApp(const ProviderScope(child: LiteApp()));

    // ─── Update System ───
    // Windows: 5-layer silent → dialog → force
    unawaited(WindowsUpdateService.runBackgroundUpdateCheck());
    // Android: Google Play in-app updates (flexible)
    unawaited(AndroidUpdateService.checkForUpdate());
    // Layer 4 dialog: triggered from app.dart (needs BuildContext)
    // Layer 5 force update: handled above via Remote Config
  } catch (error, stack) {
    // Show error screen with retry option
    debugPrint('❌ App initialization failed: $error');
    debugPrint('Stack: $stack');

    if (!kIsWeb && !isWindows) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
      );
    }
    ErrorHandler.report(error, stack);

    // Show error splash with retry button
    runApp(
      SplashScreen(
        showError: true,
        errorMessage:
            'Failed to start app: ${error.toString().split('\n').first}',
        onRetry: () {
          runApp(const SplashScreen(message: 'Retrying...'));
          _initializeApp();
        },
      ),
    );
  }
}

/// Compare two semver strings. Returns true if [current] < [minimum].
bool _isVersionLower(String current, String minimum) {
  if (minimum.isEmpty) return false;
  try {
    final currentParts = current.split('.').map(int.parse).toList();
    final minimumParts = minimum.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final m = i < minimumParts.length ? minimumParts[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false; // equal
  } catch (_) {
    return false; // malformed version string — don't block
  }
}
