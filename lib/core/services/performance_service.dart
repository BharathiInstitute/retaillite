/// Performance Service - Comprehensive app performance tracking
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/main.dart';

/// Breadcrumb types for tracking user actions
enum BreadcrumbType { navigation, tap, input, api, lifecycle, custom }

/// A breadcrumb representing a user action
class Breadcrumb {
  final String message;
  final BreadcrumbType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  Breadcrumb({
    required this.message,
    required this.type,
    DateTime? timestamp,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'message': message,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };
}

/// Screen load timing data
class ScreenTiming {
  final String screenName;
  final Duration loadTime;
  final DateTime timestamp;
  final String? userId;

  ScreenTiming({
    required this.screenName,
    required this.loadTime,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toFirestore() => {
    'screenName': screenName,
    'loadTimeMs': loadTime.inMilliseconds,
    'timestamp': Timestamp.fromDate(timestamp),
    'userId': userId,
    'appVersion': appVersion,
    'platform': PerformanceService._platform,
  };

  factory ScreenTiming.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScreenTiming(
      screenName: (data['screenName'] as String?) ?? 'unknown',
      loadTime: Duration(milliseconds: (data['loadTimeMs'] as int?) ?? 0),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] as String?,
    );
  }
}

/// Network request timing data
class NetworkTiming {
  final String operation;
  final String type; // firestore, auth, api
  final Duration latency;
  final bool success;
  final DateTime timestamp;
  final String? errorMessage;

  NetworkTiming({
    required this.operation,
    required this.type,
    required this.latency,
    required this.success,
    required this.timestamp,
    this.errorMessage,
  });

  Map<String, dynamic> toFirestore() => {
    'operation': operation,
    'type': type,
    'latencyMs': latency.inMilliseconds,
    'success': success,
    'timestamp': Timestamp.fromDate(timestamp),
    'errorMessage': errorMessage,
    'platform': PerformanceService._platform,
    'appVersion': appVersion,
  };
}

/// Comprehensive performance monitoring service
class PerformanceService {
  PerformanceService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Breadcrumb trail (last 50 actions)
  static final List<Breadcrumb> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 50;

  /// Screen timing cache for batch upload
  static final List<ScreenTiming> _screenTimings = [];
  static final List<NetworkTiming> _networkTimings = [];

  /// Current screen being tracked
  static String? _currentScreen;
  static DateTime? _screenStartTime;

  /// Get platform string
  static String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BREADCRUMBS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Add a breadcrumb for user action tracking
  static void addBreadcrumb(
    String message, {
    BreadcrumbType type = BreadcrumbType.custom,
    Map<String, dynamic>? data,
  }) {
    _breadcrumbs.add(Breadcrumb(message: message, type: type, data: data));

    // Keep only last N breadcrumbs
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('🍞 Breadcrumb: $message');
    }
  }

  /// Navigation breadcrumb (screen change)
  static void trackNavigation(String screenName) {
    addBreadcrumb('Navigated to $screenName', type: BreadcrumbType.navigation);
    _currentScreen = screenName;
  }

  /// Tap/interaction breadcrumb
  static void trackTap(String elementName, {String? screen}) {
    addBreadcrumb(
      'Tapped $elementName',
      type: BreadcrumbType.tap,
      data: {'screen': screen ?? _currentScreen},
    );
  }

  /// Input breadcrumb (form submission, etc.)
  static void trackInput(String action, {Map<String, dynamic>? data}) {
    addBreadcrumb(action, type: BreadcrumbType.input, data: data);
  }

  /// Get current breadcrumb trail
  static List<Breadcrumb> getBreadcrumbs() => List.unmodifiable(_breadcrumbs);

  /// Get breadcrumbs as JSON (for crash reports)
  static List<Map<String, dynamic>> getBreadcrumbsJson() {
    return _breadcrumbs.map((b) => b.toMap()).toList();
  }

  /// Clear breadcrumbs
  static void clearBreadcrumbs() => _breadcrumbs.clear();

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN LOAD TIMING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start tracking screen load time
  static void startScreenTiming(String screenName) {
    _currentScreen = screenName;
    _screenStartTime = DateTime.now();
    trackNavigation(screenName);
  }

  /// End screen load timing and record
  static void endScreenTiming(String screenName) {
    if (_screenStartTime == null || _currentScreen != screenName) return;

    final loadTime = DateTime.now().difference(_screenStartTime!);

    final timing = ScreenTiming(
      screenName: screenName,
      loadTime: loadTime,
      timestamp: DateTime.now(),
      userId: _auth.currentUser?.uid,
    );

    _screenTimings.add(timing);

    if (kDebugMode) {
      final color = loadTime.inMilliseconds > 500 ? '🟡' : '🟢';
      debugPrint(
        '$color Screen "$screenName" loaded in ${loadTime.inMilliseconds}ms',
      );
    }

    // Batch upload every 5 timings
    if (_screenTimings.length >= 5) {
      _uploadScreenTimings();
    }

    _screenStartTime = null;
  }

  /// Upload screen timings to Firestore
  static Future<void> _uploadScreenTimings() async {
    if (_screenTimings.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection('screen_performance');

      for (final timing in _screenTimings) {
        batch.set(collection.doc(), timing.toFirestore());
      }

      await batch.commit();
      _screenTimings.clear();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to upload screen timings: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NETWORK MONITORING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track a network/API operation
  static Future<T> trackOperation<T>(
    String operationName,
    String type,
    Future<T> Function() operation,
  ) async {
    final startTime = DateTime.now();
    bool success = true;
    String? errorMessage;

    try {
      return await operation();
    } catch (e) {
      success = false;
      errorMessage = e.toString();
      rethrow;
    } finally {
      final latency = DateTime.now().difference(startTime);

      _networkTimings.add(
        NetworkTiming(
          operation: operationName,
          type: type,
          latency: latency,
          success: success,
          timestamp: DateTime.now(),
          errorMessage: errorMessage,
        ),
      );

      addBreadcrumb(
        '$type: $operationName (${latency.inMilliseconds}ms)',
        type: BreadcrumbType.api,
        data: {'success': success, 'latencyMs': latency.inMilliseconds},
      );

      if (kDebugMode) {
        final icon = success ? '✅' : '❌';
        debugPrint('$icon $type.$operationName: ${latency.inMilliseconds}ms');
      }

      // Upload when we have enough data
      if (_networkTimings.length >= 10) {
        unawaited(_uploadNetworkTimings());
      }
    }
  }

  /// Upload network timings to Firestore
  static Future<void> _uploadNetworkTimings() async {
    if (_networkTimings.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection('network_metrics');

      for (final timing in _networkTimings) {
        batch.set(collection.doc(), timing.toFirestore());
      }

      await batch.commit();
      _networkTimings.clear();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to upload network timings: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN DASHBOARD DATA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get screen performance summary (for admin dashboard)
  static Future<Map<String, dynamic>> getScreenPerformanceSummary() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));

      final snapshot = await _firestore
          .collection('screen_performance')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      if (snapshot.docs.isEmpty) {
        return {'screens': {}, 'avgLoadTime': 0};
      }

      // Group by screen name and calculate averages
      final screenStats = <String, List<int>>{};
      int totalTime = 0;
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final screenName = data['screenName'] as String? ?? 'unknown';
        final loadTime = data['loadTimeMs'] as int? ?? 0;

        screenStats.putIfAbsent(screenName, () => []).add(loadTime);
        totalTime += loadTime;
        count++;
      }

      // Calculate averages per screen
      final screenAverages = <String, int>{};
      for (final entry in screenStats.entries) {
        if (entry.value.isNotEmpty) {
          screenAverages[entry.key] =
              entry.value.reduce((a, b) => a + b) ~/ entry.value.length;
        }
      }

      return {
        'screens': screenAverages,
        'avgLoadTime': count > 0 ? totalTime ~/ count : 0,
        'totalMeasurements': count,
      };
    } catch (e) {
      debugPrint('❌ Failed to get screen performance: $e');
      return {'screens': {}, 'avgLoadTime': 0};
    }
  }

  /// Get network health summary (for admin dashboard)
  static Future<Map<String, dynamic>> getNetworkHealthSummary() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));

      final snapshot = await _firestore
          .collection('network_metrics')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      if (snapshot.docs.isEmpty) {
        return {'operations': {}, 'avgLatency': 0, 'successRate': 100};
      }

      // Group by operation type
      final typeStats = <String, List<Map<String, dynamic>>>{};
      int totalSuccess = 0;
      int totalCount = 0;
      int totalLatency = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'unknown';
        final latency = data['latencyMs'] as int? ?? 0;
        final success = data['success'] as bool? ?? true;

        typeStats.putIfAbsent(type, () => []).add({
          'latency': latency,
          'success': success,
        });

        totalLatency += latency;
        if (success) totalSuccess++;
        totalCount++;
      }

      // Calculate per-type stats
      final typeAverages = <String, Map<String, dynamic>>{};
      for (final entry in typeStats.entries) {
        int typeTotal = 0;
        int typeSuccess = 0;
        for (final op in entry.value) {
          typeTotal += op['latency'] as int;
          if (op['success'] as bool) typeSuccess++;
        }
        typeAverages[entry.key] = {
          'avgLatency': entry.value.isNotEmpty
              ? typeTotal ~/ entry.value.length
              : 0,
          'successRate': entry.value.isNotEmpty
              ? (typeSuccess / entry.value.length * 100).round()
              : 100,
          'count': entry.value.length,
        };
      }

      return {
        'operations': typeAverages,
        'avgLatency': totalCount > 0 ? totalLatency ~/ totalCount : 0,
        'successRate': totalCount > 0
            ? (totalSuccess / totalCount * 100).round()
            : 100,
        'totalRequests': totalCount,
      };
    } catch (e) {
      debugPrint('❌ Failed to get network health: $e');
      return {'operations': {}, 'avgLatency': 0, 'successRate': 100};
    }
  }

  /// Get crash-free users percentage (for admin dashboard)
  static Future<Map<String, dynamic>> getCrashFreeStats() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));

      // Get unique users from health metrics
      final healthSnapshot = await _firestore
          .collection('app_health')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      // Get users who had errors
      final errorSnapshot = await _firestore
          .collection('error_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .where('severity', isEqualTo: 'critical')
          .get();

      final totalUsers = healthSnapshot.docs
          .map((d) => (d.data())['userId'])
          .where((id) => id != null)
          .toSet()
          .length;

      final usersWithCrashes = errorSnapshot.docs
          .map((d) => (d.data())['userId'])
          .where((id) => id != null)
          .toSet()
          .length;

      final crashFreeUsers = totalUsers > 0 ? totalUsers - usersWithCrashes : 0;

      final crashFreePercent = totalUsers > 0
          ? (crashFreeUsers / totalUsers * 100)
          : 100.0;

      return {
        'crashFreePercent': crashFreePercent,
        'totalUsers': totalUsers,
        'usersWithCrashes': usersWithCrashes,
        'crashFreeUsers': crashFreeUsers,
      };
    } catch (e) {
      debugPrint('❌ Failed to get crash-free stats: $e');
      return {'crashFreePercent': 100.0, 'totalUsers': 0};
    }
  }

  /// Flush all pending data (call on app close)
  static Future<void> flush() async {
    await _uploadScreenTimings();
    await _uploadNetworkTimings();
  }
}
