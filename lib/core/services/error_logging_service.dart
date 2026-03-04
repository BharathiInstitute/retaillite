/// Error Logging Service for Web and cross-platform error tracking
library;

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/core/services/connectivity_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/utils/platform_utils.dart';
import 'package:retaillite/main.dart';

/// Error severity levels
enum ErrorSeverity { warning, error, critical }

/// Error log entry model with full context
class ErrorLogEntry {
  final String message;
  final String? stackTrace;
  final String platform;
  final String? userId;
  final String appVersion;
  final DateTime timestamp;
  final ErrorSeverity severity;
  final String? screenName;
  final Map<String, dynamic>? metadata;

  // ── New context fields ──
  final String? route;
  final String? widgetContext;
  final String? library;
  final String? errorType;
  final String? widgetInfo;
  final double? screenWidth;
  final double? screenHeight;
  final String? connectivity;
  final String? lifecycleState;
  final String? buildMode;
  final String? sessionId;
  final String? userEmail;
  final String? shopName;
  final bool resolved;
  final String? errorHash;

  const ErrorLogEntry({
    required this.message,
    this.stackTrace,
    required this.platform,
    this.userId,
    required this.appVersion,
    required this.timestamp,
    required this.severity,
    this.screenName,
    this.metadata,
    this.route,
    this.widgetContext,
    this.library,
    this.errorType,
    this.widgetInfo,
    this.screenWidth,
    this.screenHeight,
    this.connectivity,
    this.lifecycleState,
    this.buildMode,
    this.sessionId,
    this.userEmail,
    this.shopName,
    this.resolved = false,
    this.errorHash,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'stackTrace': stackTrace,
      'platform': platform,
      'userId': userId,
      'appVersion': appVersion,
      'timestamp': Timestamp.fromDate(timestamp),
      'severity': severity.name,
      'screenName': screenName,
      'metadata': metadata,
      'route': route,
      'widgetContext': widgetContext,
      'library': library,
      'errorType': errorType,
      'widgetInfo': widgetInfo,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'connectivity': connectivity,
      'lifecycleState': lifecycleState,
      'buildMode': buildMode,
      'sessionId': sessionId,
      'userEmail': userEmail,
      'shopName': shopName,
      'resolved': resolved,
      'errorHash': errorHash,
    };
  }

  factory ErrorLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ErrorLogEntry(
      message: (data['message'] as String?) ?? 'Unknown error',
      stackTrace: data['stackTrace'] as String?,
      platform: (data['platform'] as String?) ?? 'unknown',
      userId: data['userId'] as String?,
      appVersion: (data['appVersion'] as String?) ?? '0.0.0',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => ErrorSeverity.error,
      ),
      screenName: data['screenName'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      route: data['route'] as String?,
      widgetContext: data['widgetContext'] as String?,
      library: data['library'] as String?,
      errorType: data['errorType'] as String?,
      widgetInfo: data['widgetInfo'] as String?,
      screenWidth: (data['screenWidth'] as num?)?.toDouble(),
      screenHeight: (data['screenHeight'] as num?)?.toDouble(),
      connectivity: data['connectivity'] as String?,
      lifecycleState: data['lifecycleState'] as String?,
      buildMode: data['buildMode'] as String?,
      sessionId: data['sessionId'] as String?,
      userEmail: data['userEmail'] as String?,
      shopName: data['shopName'] as String?,
      resolved: (data['resolved'] as bool?) ?? false,
      errorHash: data['errorHash'] as String?,
    );
  }

  /// Format all error info into a copyable text report with full context.
  /// This is the single source of truth for error reports shared via
  /// clipboard, email, or bug tickets.
  String toCopyText() {
    final buf = StringBuffer();
    final severityIcon = severity == ErrorSeverity.critical
        ? '🔴'
        : severity == ErrorSeverity.error
        ? '🟠'
        : '🟡';

    buf.writeln('$severityIcon ERROR REPORT');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('Severity:      ${severity.name}');
    buf.writeln('Platform:      $platform');
    buf.writeln('App Version:   $appVersion');
    if (buildMode != null) buf.writeln('Build Mode:    $buildMode');
    if (sessionId != null) buf.writeln('Session:       $sessionId');
    if (errorHash != null) buf.writeln('Error Hash:    $errorHash');
    buf.writeln(
      'Time:          ${timestamp.day}/${timestamp.month}/${timestamp.year} '
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}',
    );
    if (connectivity != null) buf.writeln('Connectivity:  $connectivity');
    if (lifecycleState != null) buf.writeln('Lifecycle:     $lifecycleState');
    buf.writeln('Resolved:      ${resolved ? 'Yes' : 'No'}');
    buf.writeln();

    buf.writeln('📍 LOCATION');
    if (route != null) buf.writeln('Route:         $route');
    if (screenName != null) buf.writeln('Screen:        $screenName');
    if (widgetContext != null) buf.writeln('Widget:        $widgetContext');
    if (library != null) buf.writeln('Library:       $library');
    if (screenWidth != null && screenHeight != null) {
      buf.writeln(
        'Screen Size:   ${screenWidth!.toInt()}×${screenHeight!.toInt()}',
      );
    }
    buf.writeln();

    buf.writeln('💬 ERROR');
    if (errorType != null) buf.writeln('Type:          $errorType');
    buf.writeln('Message:       $message');
    buf.writeln();

    if (widgetInfo != null && widgetInfo!.isNotEmpty) {
      buf.writeln('🔧 WIDGET INFO');
      buf.writeln(widgetInfo);
      buf.writeln();
    }

    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buf.writeln('📜 STACK TRACE');
      buf.writeln(stackTrace);
      buf.writeln();
    }

    // Custom metadata (extra context passed at log time)
    if (metadata != null && metadata!.isNotEmpty) {
      buf.writeln('🗂️ METADATA');
      for (final entry in metadata!.entries) {
        buf.writeln('${entry.key}: ${entry.value}');
      }
      buf.writeln();
    }

    buf.writeln('👤 USER');
    if (userEmail != null) buf.writeln('Email:         $userEmail');
    if (shopName != null) buf.writeln('Shop:          $shopName');
    if (userId != null) buf.writeln('User ID:       $userId');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return buf.toString();
  }
}

/// Grouped error for deduplication display
class GroupedError {
  final ErrorLogEntry latestEntry;
  final String? docId;
  final int count;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int affectedUsers;

  const GroupedError({
    required this.latestEntry,
    this.docId,
    required this.count,
    required this.firstSeen,
    required this.lastSeen,
    required this.affectedUsers,
  });
}

/// Service for logging errors to Firestore (all platforms)
class ErrorLoggingService {
  ErrorLoggingService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _currentScreen;
  static String? _sessionId;

  // ── Pre-Firebase Crash Capture ──

  /// Save a crash that occurred before Firebase was initialized.
  /// Uses SharedPreferences (already initialized before Firebase).
  static Future<void> savePreFirebaseCrash(
    dynamic error,
    StackTrace? stack,
  ) async {
    try {
      final prefs = OfflineStorageService.prefs;
      if (prefs == null) {
        // SharedPreferences not ready yet — last resort: write to debugPrint
        debugPrint('🔴 PRE-FIREBASE CRASH (no prefs): $error');
        return;
      }
      final entry = {
        'message': error.toString(),
        'stackTrace': stack?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _platformStatic,
        'context': 'pre_firebase_init',
      };
      final existing = prefs.getStringList(_preFirebaseCrashKey) ?? [];
      existing.add(jsonEncode(entry));
      await prefs.setStringList(_preFirebaseCrashKey, existing);
      debugPrint('📦 Pre-Firebase crash saved locally (${existing.length})');
    } catch (e) {
      debugPrint('🔴 Failed to save pre-Firebase crash: $e');
    }
  }

  /// Flush pre-Firebase crashes to Firestore (call after Firebase is ready).
  static Future<void> flushPreFirebaseCrashes() async {
    try {
      final prefs = OfflineStorageService.prefs;
      if (prefs == null) return;
      final queue = prefs.getStringList(_preFirebaseCrashKey);
      if (queue == null || queue.isEmpty) return;

      debugPrint('📤 Flushing ${queue.length} pre-Firebase crashes...');
      for (final jsonStr in queue) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        await logError(
          error: data['message'] ?? 'Pre-Firebase crash',
          severity: ErrorSeverity.critical,
          metadata: {
            'context': 'pre_firebase_init',
            'originalTimestamp': data['timestamp'],
            'originalStackTrace': data['stackTrace'],
            'platform': data['platform'],
          },
        );
      }
      await prefs.setStringList(_preFirebaseCrashKey, []);
      debugPrint('✅ Flushed ${queue.length} pre-Firebase crashes');
    } catch (e) {
      debugPrint('❌ Failed to flush pre-Firebase crashes: $e');
    }
  }

  // ── Crash Detection (Heartbeat) ──

  /// Mark that the app started (clear clean-exit flag).
  /// Call at the very start of main().
  static Future<void> markAppStarted() async {
    try {
      final prefs = OfflineStorageService.prefs;
      if (prefs == null) return;

      // Check if previous session exited cleanly
      final wasClean = prefs.getBool(_cleanExitKey) ?? true;
      if (!wasClean) {
        // Previous session crashed or was killed
        debugPrint('⚠️ Previous session did not exit cleanly — crash detected');
        final lastTimestamp = prefs.getString('${_cleanExitKey}_ts');
        await logError(
          error: 'Ungraceful shutdown detected (app was killed or crashed)',
          severity: ErrorSeverity.warning,
          metadata: {
            'context': 'crash_detection',
            'lastHeartbeat': lastTimestamp,
            'platform': _platformStatic,
          },
        );
      }

      // Set flag to false (will be set to true on clean exit)
      await prefs.setBool(_cleanExitKey, false);
      await prefs.setString(
        '${_cleanExitKey}_ts',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('⚠️ markAppStarted failed: $e');
    }
  }

  /// Mark that the app is exiting cleanly.
  /// Call from AppLifecycleState.detached or dispose.
  static Future<void> markCleanExit() async {
    try {
      final prefs = OfflineStorageService.prefs;
      if (prefs == null) return;
      await prefs.setBool(_cleanExitKey, true);
    } catch (_) {}
  }

  /// Static platform detection (delegates to shared utility)
  static String get _platformStatic => currentPlatformName;

  /// Offline error queue key
  static const String _offlineQueueKey = 'pending_error_logs';
  static const int _maxQueueSize = 200;

  /// Pre-Firebase crash storage key (errors before Firebase.initializeApp)
  static const String _preFirebaseCrashKey = 'pre_firebase_crash';

  /// Clean-exit flag key (for crash detection)
  static const String _cleanExitKey = 'app_clean_exit';

  /// Set current screen for error context
  static void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
  }

  /// Set session ID (called once at app start)
  static void setSessionId(String id) {
    _sessionId = id;
  }

  /// Get current platform as string (delegates to shared utility)
  static String get _platform => currentPlatformName;

  /// Get current build mode
  static String get _buildMode {
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }

  /// Generate a simple error hash for deduplication
  static String _generateErrorHash(String message) {
    // Normalize: remove numbers/hex/dynamic parts for better grouping
    final normalized = message
        .replaceAll(RegExp(r'#[a-fA-F0-9]+'), '#XXX')
        .replaceAll(RegExp(r'\d+\.?\d*'), 'N')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Simple hash: use hashCode (no crypto needed for grouping)
    return normalized.hashCode.toRadixString(36);
  }

  /// Log an error to Firestore with full context
  static Future<void> logError({
    required dynamic error,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = error.toString();
      final shopName = OfflineStorageService.prefs?.getString('shop_name');

      final entry = ErrorLogEntry(
        message: message,
        stackTrace: stackTrace?.toString(),
        platform: _platform,
        userId: _auth.currentUser?.uid,
        appVersion: appVersion,
        timestamp: DateTime.now(),
        severity: severity,
        screenName: _currentScreen,
        metadata: metadata,
        route: metadata?['route'] as String? ?? _currentScreen,
        widgetContext: metadata?['widgetContext'] as String?,
        library: metadata?['library'] as String?,
        errorType: metadata?['errorType'] as String?,
        widgetInfo: metadata?['widgetInfo'] as String?,
        screenWidth: metadata?['screenWidth'] as double?,
        screenHeight: metadata?['screenHeight'] as double?,
        connectivity:
            metadata?['connectivity'] as String? ??
            ConnectivityService.currentStatus.name,
        lifecycleState: metadata?['lifecycleState'] as String?,
        buildMode: metadata?['buildMode'] as String? ?? _buildMode,
        sessionId: metadata?['sessionId'] as String? ?? _sessionId,
        userEmail:
            metadata?['userEmail'] as String? ?? _auth.currentUser?.email,
        shopName: metadata?['shopName'] as String? ?? shopName,
        // resolved defaults to false
        errorHash: _generateErrorHash(message),
      );

      // Try to write to Firestore
      if (ConnectivityService.isOnline) {
        await _firestore.collection('error_logs').add(entry.toFirestore());

        // D1-4: Increment pre-aggregated counters for dashboard reads
        await _firestore.collection('error_logs_meta').doc('counts').set({
          'platform': {_platform: FieldValue.increment(1)},
          'severity': {severity.name: FieldValue.increment(1)},
        }, SetOptions(merge: true));

        // Also flush any queued offline errors
        await flushOfflineQueue();
      } else {
        // Offline: queue locally
        _queueOfflineError(entry);
      }

      if (kDebugMode) {
        debugPrint(
          '📝 Error logged: ${message.substring(0, 100.clamp(0, message.length))}',
        );
      }
    } catch (e) {
      // Silently fail — don't cause more errors while logging errors
      if (kDebugMode) {
        debugPrint('❌ Failed to log error: $e');
      }
    }
  }

  /// Queue an error locally when offline
  static void _queueOfflineError(ErrorLogEntry entry) {
    try {
      final prefs = OfflineStorageService.prefs;
      if (prefs == null) return;

      final existing = prefs.getStringList(_offlineQueueKey) ?? [];

      // Cap at max queue size (drop oldest)
      if (existing.length >= _maxQueueSize) {
        existing.removeAt(0);
      }

      existing.add(
        jsonEncode(
          entry.toFirestore()
            ..['timestamp'] = entry.timestamp.toIso8601String(),
        ),
      );
      prefs.setStringList(_offlineQueueKey, existing);

      if (kDebugMode) {
        debugPrint('📦 Error queued offline (${existing.length} pending)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to queue offline error: $e');
      }
    }
  }

  /// Flush queued offline errors to Firestore
  static Future<void> flushOfflineQueue() async {
    try {
      final prefs = OfflineStorageService.prefs;
      if (prefs == null) return;

      final queue = prefs.getStringList(_offlineQueueKey);
      if (queue == null || queue.isEmpty) return;

      if (kDebugMode) {
        debugPrint('📤 Flushing ${queue.length} queued errors to Firestore...');
      }

      final batch = _firestore.batch();
      for (final jsonStr in queue) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        // Convert ISO string back to Timestamp
        if (data['timestamp'] is String) {
          data['timestamp'] = Timestamp.fromDate(
            DateTime.parse(data['timestamp'] as String),
          );
        }
        batch.set(_firestore.collection('error_logs').doc(), data);
      }
      await batch.commit();

      // Clear queue
      await prefs.setStringList(_offlineQueueKey, []);

      if (kDebugMode) {
        debugPrint('✅ Flushed ${queue.length} queued errors');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to flush offline queue: $e');
      }
    }
  }

  /// Log a warning (non-critical issue)
  static Future<void> logWarning(
    String message, {
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      error: message,
      severity: ErrorSeverity.warning,
      metadata: metadata,
    );
  }

  /// Log a critical error (app crash equivalent)
  static Future<void> logCritical({
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      error: error,
      stackTrace: stackTrace,
      severity: ErrorSeverity.critical,
      metadata: metadata,
    );
  }

  /// Get recent errors grouped by errorHash for deduplication
  static Future<List<GroupedError>> getGroupedErrors({
    int limit = 100,
    ErrorSeverity? severityFilter,
    String? platformFilter,
    bool hideResolved = true,
  }) async {
    try {
      Query query = _firestore
          .collection('error_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (severityFilter != null) {
        query = query.where('severity', isEqualTo: severityFilter.name);
      }
      if (platformFilter != null) {
        query = query.where('platform', isEqualTo: platformFilter);
      }
      if (hideResolved) {
        query = query.where('resolved', isEqualTo: false);
      }

      final snapshot = await query.get();
      final entries = snapshot.docs
          .map((d) => MapEntry(d.id, ErrorLogEntry.fromFirestore(d)))
          .toList();

      // Group by errorHash
      final groups = <String, List<MapEntry<String, ErrorLogEntry>>>{};
      for (final entry in entries) {
        final hash = entry.value.errorHash ?? entry.value.message;
        groups.putIfAbsent(hash, () => []).add(entry);
      }

      // Convert to GroupedError list
      return groups.values.map((group) {
        group.sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));
        final latest = group.first;
        final userIds = group
            .map((e) => e.value.userId)
            .whereType<String>()
            .toSet();
        return GroupedError(
          latestEntry: latest.value,
          docId: latest.key,
          count: group.length,
          firstSeen: group.last.value.timestamp,
          lastSeen: group.first.value.timestamp,
          affectedUsers: userIds.length,
        );
      }).toList()..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    } catch (e) {
      debugPrint('❌ Failed to get grouped errors: $e');
      return [];
    }
  }

  /// Get recent error logs (legacy — still used by some providers)
  static Future<List<ErrorLogEntry>> getRecentErrors({
    int limit = 50,
    ErrorSeverity? severityFilter,
    String? platformFilter,
  }) async {
    try {
      Query query = _firestore
          .collection('error_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (severityFilter != null) {
        query = query.where('severity', isEqualTo: severityFilter.name);
      }
      if (platformFilter != null) {
        query = query.where('platform', isEqualTo: platformFilter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((d) => ErrorLogEntry.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get error logs: $e');
      return [];
    }
  }

  /// Mark an error as resolved
  static Future<void> markResolved(String docId) async {
    try {
      await _firestore.collection('error_logs').doc(docId).update({
        'resolved': true,
      });
    } catch (e) {
      debugPrint('❌ Failed to mark resolved: $e');
    }
  }

  /// Mark all errors with same hash as resolved
  static Future<int> markAllResolvedByHash(String errorHash) async {
    try {
      final snapshot = await _firestore
          .collection('error_logs')
          .where('errorHash', isEqualTo: errorHash)
          .where('resolved', isEqualTo: false)
          .limit(
            400,
          ) // D10: Cap batch size to stay within Firestore batch limit
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'resolved': true});
      }
      await batch.commit();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Failed to mark all resolved: $e');
      return 0;
    }
  }

  /// Get error count by platform (from pre-aggregated counter doc — D1-4)
  static Future<Map<String, int>> getErrorCountByPlatform() async {
    try {
      final doc = await _firestore
          .collection('error_logs_meta')
          .doc('counts')
          .get();
      final data = doc.data();
      if (data == null) return {};

      final platformMap = data['platform'] as Map<String, dynamic>? ?? {};
      return platformMap.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      return {};
    }
  }

  /// Get error count by severity (from pre-aggregated counter doc — D1-4)
  static Future<Map<String, int>> getErrorCountBySeverity() async {
    try {
      final doc = await _firestore
          .collection('error_logs_meta')
          .doc('counts')
          .get();
      final data = doc.data();
      if (data == null) return {};

      final severityMap = data['severity'] as Map<String, dynamic>? ?? {};
      return severityMap.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      return {};
    }
  }

  /// Get daily error counts for trend chart (last N days)
  static Future<Map<DateTime, int>> getDailyErrorCounts({int days = 7}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection('error_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
          .orderBy('timestamp')
          .limit(5000) // D10: Cap reads for trend chart
          .get();

      final counts = <DateTime, int>{};
      // Initialize all days to 0
      for (var i = 0; i < days; i++) {
        final day = DateTime.now().subtract(Duration(days: days - 1 - i));
        final key = DateTime(day.year, day.month, day.day);
        counts[key] = 0;
      }
      // Count errors per day
      for (final doc in snapshot.docs) {
        final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (ts != null) {
          final key = DateTime(ts.year, ts.month, ts.day);
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      debugPrint('❌ Failed to get daily error counts: $e');
      return {};
    }
  }

  /// Delete old error logs (cleanup) — paginated in batches of 450
  static Future<int> deleteOldLogs({int daysOld = 30}) async {
    int totalDeleted = 0;
    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));

      while (true) {
        final snapshot = await _firestore
            .collection('error_logs')
            .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
            .limit(450)
            .get();

        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        totalDeleted += snapshot.docs.length;

        // If we got fewer than 450, we're done
        if (snapshot.docs.length < 450) break;
      }

      return totalDeleted;
    } catch (e) {
      debugPrint('❌ Failed to delete old logs: $e');
      return totalDeleted;
    }
  }
}
