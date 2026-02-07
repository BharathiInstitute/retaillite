/// Error Logging Service for Web and cross-platform error tracking
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/main.dart';

/// Error severity levels
enum ErrorSeverity { warning, error, critical }

/// Error log entry model
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
    };
  }

  factory ErrorLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ErrorLogEntry(
      message: data['message'] ?? 'Unknown error',
      stackTrace: data['stackTrace'],
      platform: data['platform'] ?? 'unknown',
      userId: data['userId'],
      appVersion: data['appVersion'] ?? '0.0.0',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => ErrorSeverity.error,
      ),
      screenName: data['screenName'],
      metadata: data['metadata'],
    );
  }
}

/// Service for logging errors to Firestore (especially for web)
class ErrorLoggingService {
  ErrorLoggingService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _currentScreen;

  /// Set current screen for error context
  static void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
  }

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

  /// Log an error to Firestore
  static Future<void> logError({
    required dynamic error,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final entry = ErrorLogEntry(
        message: error.toString(),
        stackTrace: stackTrace?.toString(),
        platform: _platform,
        userId: _auth.currentUser?.uid,
        appVersion: appVersion,
        timestamp: DateTime.now(),
        severity: severity,
        screenName: _currentScreen,
        metadata: metadata,
      );

      await _firestore.collection('error_logs').add(entry.toFirestore());

      if (kDebugMode) {
        debugPrint(
          '📝 Error logged to Firestore: ${error.toString().substring(0, 100.clamp(0, error.toString().length))}',
        );
      }
    } catch (e) {
      // Silently fail - don't cause more errors while logging errors
      if (kDebugMode) {
        debugPrint('❌ Failed to log error to Firestore: $e');
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

  /// Get recent error logs (for admin dashboard)
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

  /// Get error count by platform (for admin dashboard)
  static Future<Map<String, int>> getErrorCountByPlatform() async {
    try {
      final snapshot = await _firestore.collection('error_logs').get();

      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final platform = (doc.data())['platform'] as String? ?? 'unknown';
        counts[platform] = (counts[platform] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      return {};
    }
  }

  /// Get error count by severity (for admin dashboard)
  static Future<Map<String, int>> getErrorCountBySeverity() async {
    try {
      final snapshot = await _firestore.collection('error_logs').get();

      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final severity = (doc.data())['severity'] as String? ?? 'error';
        counts[severity] = (counts[severity] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      return {};
    }
  }

  /// Delete old error logs (cleanup)
  static Future<int> deleteOldLogs({int daysOld = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _firestore
          .collection('error_logs')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Failed to delete old logs: $e');
      return 0;
    }
  }
}
