/// Android in-app update service using Google Play In-App Updates API
///
/// Uses flexible update for normal updates (non-blocking banner)
/// and immediate update for critical/force updates (blocking).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AndroidUpdateService {
  AndroidUpdateService._();

  /// Check for updates and trigger appropriate flow.
  ///
  /// [forceImmediate] — set to true when min_app_version requires a force update
  static Future<void> checkForUpdate({bool forceImmediate = false}) async {
    // Only runs on Android
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        debugPrint('✅ Android: App is up to date');
        return;
      }

      debugPrint(
        '🔄 Android: Update available (availability: ${info.updateAvailability})',
      );

      // Use immediate update for force updates or high-priority updates
      if (forceImmediate && info.immediateUpdateAllowed) {
        debugPrint('🔄 Android: Starting immediate (blocking) update');
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // Use flexible update for normal updates (non-blocking)
      if (info.flexibleUpdateAllowed) {
        debugPrint('🔄 Android: Starting flexible (non-blocking) update');
        await InAppUpdate.startFlexibleUpdate();
        // Complete the update when downloaded
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }

      // Fallback to immediate if flexible not allowed
      if (info.immediateUpdateAllowed) {
        debugPrint('🔄 Android: Flexible not allowed, using immediate update');
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('⚠️ Android Update check failed: $e');
      // Non-fatal: don't crash the app if update check fails
    }
  }
}
