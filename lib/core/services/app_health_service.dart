/// App Health Service for monitoring app performance and health
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/core/constants/app_constants.dart';
import 'package:retaillite/main.dart';

/// App health metrics
class AppHealthMetrics {
  final Duration startupTime;
  final String platform;
  final String appVersion;
  final DateTime timestamp;
  final bool isOnline;
  final String? userId;

  const AppHealthMetrics({
    required this.startupTime,
    required this.platform,
    required this.appVersion,
    required this.timestamp,
    required this.isOnline,
    this.userId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'startupTimeMs': startupTime.inMilliseconds,
      'platform': platform,
      'appVersion': appVersion,
      'timestamp': Timestamp.fromDate(timestamp),
      'isOnline': isOnline,
      'userId': userId,
    };
  }

  factory AppHealthMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppHealthMetrics(
      startupTime: Duration(milliseconds: (data['startupTimeMs'] as int?) ?? 0),
      platform: (data['platform'] as String?) ?? 'unknown',
      appVersion: (data['appVersion'] as String?) ?? '0.0.0',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: (data['isOnline'] as bool?) ?? true,
      userId: data['userId'] as String?,
    );
  }
}

/// Service for tracking and reporting app health
class AppHealthService {
  AppHealthService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DateTime? _appStartTime;
  static bool _initialized = false;

  /// Get current platform as string
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

  /// Mark app start time (call at very beginning of main)
  static void markAppStart() {
    _appStartTime = DateTime.now();
  }

  /// Initialize health service and record startup metrics
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Calculate startup time
    final startupTime = _appStartTime != null
        ? DateTime.now().difference(_appStartTime!)
        : const Duration();

    if (kDebugMode) {
      debugPrint('⏱️ App startup time: ${startupTime.inMilliseconds}ms');
    }

    // Don't block the main thread, log in background
    unawaited(_logStartupMetrics(startupTime));
  }

  /// Log startup metrics to Firestore
  static Future<void> _logStartupMetrics(Duration startupTime) async {
    try {
      // Skip logging if user is not authenticated (Firestore rules require auth)
      if (_auth.currentUser == null) {
        if (kDebugMode) {
          debugPrint('⏭️ Skipping health metrics - user not authenticated');
        }
        return;
      }

      final metrics = AppHealthMetrics(
        startupTime: startupTime,
        platform: _platform,
        appVersion: appVersion,
        timestamp: DateTime.now(),
        isOnline: true,
        userId: _auth.currentUser?.uid,
      );

      await _firestore.collection('app_health').add(metrics.toFirestore());

      if (kDebugMode) {
        debugPrint('✅ App health metrics logged');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to log health metrics: $e');
      }
    }
  }

  /// Record a screen load time
  static Future<void> recordScreenLoad(
    String screenName,
    Duration loadTime,
  ) async {
    try {
      await _firestore.collection('screen_performance').add({
        'screenName': screenName,
        'loadTimeMs': loadTime.inMilliseconds,
        'platform': _platform,
        'appVersion': appVersion,
        'userId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to log screen performance: $e');
      }
    }
  }

  /// Get average startup time by platform (for admin)
  static Future<Map<String, double>> getAverageStartupTimes() async {
    try {
      final snapshot = await _firestore
          .collection('app_health')
          .orderBy('timestamp', descending: true)
          .limit(AppConstants.queryLimitAdminAnalytics)
          .get();

      final platformTimes = <String, List<int>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final platform = data['platform'] as String? ?? 'unknown';
        final time = data['startupTimeMs'] as int? ?? 0;

        platformTimes.putIfAbsent(platform, () => []).add(time);
      }

      // Calculate averages
      final averages = <String, double>{};
      for (final entry in platformTimes.entries) {
        if (entry.value.isNotEmpty) {
          averages[entry.key] =
              entry.value.reduce((a, b) => a + b) / entry.value.length;
        }
      }

      return averages;
    } catch (e) {
      debugPrint('❌ Failed to get startup times: $e');
      return {};
    }
  }

  /// Get health summary for admin dashboard
  static Future<Map<String, dynamic>> getHealthSummary() async {
    try {
      // Get last 24 hours of data
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));

      final healthSnapshot = await _firestore
          .collection('app_health')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      final errorSnapshot = await _firestore
          .collection('error_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      // Calculate metrics
      final int totalSessions = healthSnapshot.docs.length;
      final int totalErrors = errorSnapshot.docs.length;

      // Calculate average startup time
      double avgStartup = 0;
      if (healthSnapshot.docs.isNotEmpty) {
        int totalTime = 0;
        for (final doc in healthSnapshot.docs) {
          totalTime += (doc.data()['startupTimeMs'] as int?) ?? 0;
        }
        avgStartup = totalTime / healthSnapshot.docs.length;
      }

      // Platform distribution
      final platforms = <String, int>{};
      for (final doc in healthSnapshot.docs) {
        final platform = (doc.data())['platform'] as String? ?? 'unknown';
        platforms[platform] = (platforms[platform] ?? 0) + 1;
      }

      return {
        'sessionsLast24h': totalSessions,
        'errorsLast24h': totalErrors,
        'avgStartupTimeMs': avgStartup,
        'platformDistribution': platforms,
        'errorRate': totalSessions > 0
            ? (totalErrors / totalSessions * 100)
            : 0,
      };
    } catch (e) {
      debugPrint('❌ Failed to get health summary: $e');
      return {};
    }
  }

  /// Cleanup old health data (keep last 7 days)
  static Future<int> cleanupOldData({int daysOld = 7}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _firestore
          .collection('app_health')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Failed to cleanup old data: $e');
      return 0;
    }
  }
}
