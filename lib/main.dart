import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/app.dart';
import 'package:retaillite/core/config/app_check_config.dart';
import 'package:retaillite/core/services/app_health_service.dart';
import 'package:retaillite/core/services/connectivity_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/payment_link_service.dart';
import 'package:retaillite/core/services/sync_settings_service.dart';
import 'package:retaillite/core/services/windows_update_service.dart';
import 'package:retaillite/core/utils/error_handler.dart';
import 'package:retaillite/core/widgets/force_update_screen.dart';
import 'package:retaillite/core/widgets/maintenance_screen.dart';
import 'package:retaillite/core/widgets/splash_screen.dart';
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
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase first (required by other services)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check — protects all Firebase services
    // On web, skip App Check if reCAPTCHA key is not configured (avoids JS interop crash)
    if (!kIsWeb || AppCheckConfig.isWebConfigured) {
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
    } else {
      debugPrint('ℹ️ Skipping App Check on web (no reCAPTCHA key configured)');
    }

    // Initialize Crashlytics (not supported on web)
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }

    // Initialize global error handling
    ErrorHandler.initialize();

    // Initialize Remote Config with defaults
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
    });
    await remoteConfig.fetchAndActivate();

    // Apply Remote Config values
    final merchantUpiId = remoteConfig.getString('merchant_upi_id');
    if (merchantUpiId.isNotEmpty) {
      PaymentLinkService.setUpiId(merchantUpiId);
    }

    // ─── Check maintenance mode ───
    if (remoteConfig.getBool('maintenance_mode')) {
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
    final minVersion = remoteConfig.getString('min_app_version');
    if (_isVersionLower(appVersion, minVersion)) {
      runApp(
        ForceUpdateScreen(
          currentVersion: appVersion,
          requiredVersion: minVersion,
          updateUrl: remoteConfig.getString('force_update_url'),
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
    ]);

    // Launch the main app
    runApp(const ProviderScope(child: LiteApp()));

    // Zero-click auto-update: check + download in background.
    // If an update is found, a watchdog installs it when the user closes the app.
    unawaited(WindowsUpdateService.runBackgroundUpdateCheck());
  } catch (error, stack) {
    // Show error screen with retry option
    debugPrint('❌ App initialization failed: $error');
    debugPrint('Stack: $stack');

    if (!kIsWeb) {
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
