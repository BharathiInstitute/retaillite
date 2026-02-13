/// Sync Settings Service for configurable data synchronization
///
/// Manages sync intervals and tracks sync status
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:retaillite/core/services/web_persistence_stub.dart'
    if (dart.library.html) 'package:retaillite/core/services/web_persistence.dart';

/// Sync interval options
enum SyncInterval {
  realtime('Real-time', Duration.zero),
  hourly('Every Hour', Duration(hours: 1)),
  daily('Daily', Duration(days: 1)),
  weekly('Weekly', Duration(days: 7)),
  manual('Manual Only', Duration(days: 365)); // Effectively manual

  final String displayName;
  final Duration duration;

  const SyncInterval(this.displayName, this.duration);
}

/// Sync status for UI display
enum SyncStatus { idle, syncing, success, error }

/// Service for managing sync settings and triggering syncs
class SyncSettingsService {
  static const String _syncIntervalKey = 'sync_interval';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _pendingSyncKey = 'pending_sync_count';

  static SharedPreferences? _prefs;
  static SyncStatus _status = SyncStatus.idle;
  static DateTime? _lastSyncTime;
  static int _pendingSyncCount = 0;

  /// Check if service is initialized
  static bool get isInitialized => _prefs != null;

  /// Initialize the service
  /// Called early from main() BEFORE any other Firestore access
  static Future<void> initializeFirestorePersistence() async {
    try {
      if (kIsWeb) {
        await enableWebPersistence();
      } else {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        debugPrint('✅ Firebase offline mode enabled with unlimited cache');
      }
    } catch (e) {
      debugPrint('⚠️ Firestore persistence setup: $e');
    }
  }

  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadLastSyncTime();
      _pendingSyncCount = _prefs?.getInt(_pendingSyncKey) ?? 0;

      // Check if auto-sync is needed (run in background, don't block)
      unawaited(checkAndAutoSync());
    } catch (e) {
      debugPrint('❌ SyncSettingsService init error: $e');
    }
  }

  /// Load last sync time from preferences
  static void _loadLastSyncTime() {
    final lastSyncMs = _prefs?.getInt(_lastSyncKey);
    if (lastSyncMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }
  }

  /// Get current sync interval
  static SyncInterval getSyncInterval() {
    if (_prefs == null) {
      return SyncInterval.realtime; // Default if not initialized
    }
    final index = _prefs?.getInt(_syncIntervalKey) ?? 0;
    if (index >= 0 && index < SyncInterval.values.length) {
      return SyncInterval.values[index];
    }
    return SyncInterval.realtime;
  }

  /// Set sync interval
  static Future<void> setSyncInterval(SyncInterval interval) async {
    await _prefs?.setInt(_syncIntervalKey, interval.index);
    debugPrint('Sync interval set to: ${interval.displayName}');
  }

  /// Get last sync time
  static DateTime? get lastSyncTime => _lastSyncTime;

  /// Get sync status
  static SyncStatus get status => _status;

  /// Get pending sync count
  static int get pendingSyncCount => _pendingSyncCount;

  /// Check if sync is needed based on interval
  static bool isSyncNeeded() {
    final interval = getSyncInterval();

    // Real-time mode - always syncs automatically
    if (interval == SyncInterval.realtime) {
      return false; // Firebase handles this
    }

    // Manual mode - never auto-sync
    if (interval == SyncInterval.manual) {
      return false;
    }

    // Check if enough time has passed
    if (_lastSyncTime == null) {
      return true;
    }

    final timeSinceSync = DateTime.now().difference(_lastSyncTime!);
    return timeSinceSync >= interval.duration;
  }

  /// Check and trigger auto-sync if needed
  static Future<void> checkAndAutoSync() async {
    if (isSyncNeeded()) {
      await syncNow();
    }
  }

  /// Manually trigger sync
  static Future<bool> syncNow() async {
    if (_status == SyncStatus.syncing) {
      return false; // Already syncing
    }

    _status = SyncStatus.syncing;
    debugPrint('🔄 Starting sync...');

    try {
      // Wait for pending writes to complete (with timeout to prevent blocking)
      await FirebaseFirestore.instance.waitForPendingWrites().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Sync timeout - proceeding anyway');
        },
      );

      // Clear pending count
      _pendingSyncCount = 0;
      await _prefs?.setInt(_pendingSyncKey, 0);

      // Update last sync time
      _lastSyncTime = DateTime.now();
      await _prefs?.setInt(_lastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);

      _status = SyncStatus.success;
      debugPrint('✅ Sync completed successfully');
      return true;
    } catch (e) {
      _status = SyncStatus.error;
      debugPrint('❌ Sync failed: $e');
      return false;
    }
  }

  /// Increment pending sync count (call when data is written offline)
  static Future<void> incrementPendingSync() async {
    _pendingSyncCount++;
    await _prefs?.setInt(_pendingSyncKey, _pendingSyncCount);
  }

  /// Format last sync time for display
  static String getLastSyncDisplay() {
    if (_lastSyncTime == null) {
      return 'Never synced';
    }

    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
  }

  /// Check if currently in offline mode
  static Future<bool> isOffline() async {
    try {
      // Try to fetch from server
      await FirebaseFirestore.instance
          .collection('_ping')
          .doc('test')
          .get(const GetOptions(source: Source.server));
      return false;
    } catch (e) {
      return true;
    }
  }

  /// Get sync mode description
  static String getSyncModeDescription() {
    final interval = getSyncInterval();
    switch (interval) {
      case SyncInterval.realtime:
        return 'Data syncs immediately when connected';
      case SyncInterval.hourly:
        return 'Data syncs every hour';
      case SyncInterval.daily:
        return 'Data syncs once per day';
      case SyncInterval.weekly:
        return 'Data syncs once per week';
      case SyncInterval.manual:
        return 'Data only syncs when you tap "Sync Now"';
    }
  }
}
