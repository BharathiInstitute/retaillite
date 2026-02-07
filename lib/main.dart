import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/app.dart';
import 'package:retaillite/core/services/app_health_service.dart';
import 'package:retaillite/core/services/connectivity_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/sync_settings_service.dart';
import 'package:retaillite/core/utils/error_handler.dart';
import 'package:retaillite/firebase_options.dart';

/// App version info
const String appVersion = '1.0.0';
const int appBuildNumber = 1;

void main() async {
  // Mark app start time for health metrics
  AppHealthService.markAppStart();

  // Run app in error zone to catch all errors
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Crashlytics (not supported on web)
      if (!kIsWeb) {
        // Pass all uncaught Flutter errors to Crashlytics
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;

        // Enable Crashlytics collection
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );
      }

      // Initialize global error handling (includes web error logging)
      ErrorHandler.initialize();

      // Initialize offline storage (SharedPreferences for settings)
      await OfflineStorageService.initialize();
      await PrinterStorage.initialize();

      // Initialize sync settings (enables Firebase offline mode)
      await SyncSettingsService.initialize();

      // Initialize connectivity monitoring
      await ConnectivityService.initialize();

      // Initialize app health service (logs startup metrics)
      await AppHealthService.initialize();

      runApp(const ProviderScope(child: LiteApp()));
    },
    (error, stack) {
      // Catch errors that escape the Flutter framework
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      ErrorHandler.report(error, stack);
    },
  );
}
