/// Tests for ErrorLoggingService — ErrorSeverity, ErrorLogEntry, GroupedError
///
/// Tests pure data class logic and serialization.
/// Uses inline duplicates to avoid transitive Firebase import chain.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicates (avoid error_logging_service → main → billing_screen) ──

enum ErrorSeverity { warning, error, critical }

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

  Map<String, dynamic> toFirestore() => {
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

void main() {
  // ── ErrorSeverity enum ──

  group('ErrorSeverity', () {
    test('has 3 values', () {
      expect(ErrorSeverity.values.length, 3);
    });

    test('warning is available', () {
      expect(ErrorSeverity.warning, isNotNull);
      expect(ErrorSeverity.warning.name, 'warning');
    });

    test('error is available', () {
      expect(ErrorSeverity.error, isNotNull);
      expect(ErrorSeverity.error.name, 'error');
    });

    test('critical is available', () {
      expect(ErrorSeverity.critical, isNotNull);
      expect(ErrorSeverity.critical.name, 'critical');
    });
  });

  // ── ErrorLogEntry ──

  group('ErrorLogEntry', () {
    ErrorLogEntry makeEntry({
      String message = 'test error',
      String platform = 'windows',
      String appVersion = '7.0.0',
      ErrorSeverity severity = ErrorSeverity.error,
      DateTime? timestamp,
      String? stackTrace,
      String? userId,
      String? screenName,
      Map<String, dynamic>? metadata,
      String? route,
      String? errorType,
      bool resolved = false,
      String? errorHash,
    }) {
      return ErrorLogEntry(
        message: message,
        platform: platform,
        appVersion: appVersion,
        severity: severity,
        timestamp: timestamp ?? DateTime(2024, 6, 15, 10, 30),
        stackTrace: stackTrace,
        userId: userId,
        screenName: screenName,
        metadata: metadata,
        route: route,
        errorType: errorType,
        resolved: resolved,
        errorHash: errorHash,
      );
    }

    test('creates with required fields', () {
      final entry = makeEntry();
      expect(entry.message, 'test error');
      expect(entry.platform, 'windows');
      expect(entry.severity, ErrorSeverity.error);
      expect(entry.resolved, isFalse);
    });

    test('creates with all optional fields', () {
      final entry = makeEntry(
        stackTrace: 'at line 42',
        userId: 'user-1',
        screenName: 'BillingScreen',
        metadata: {'key': 'val'},
        route: '/billing',
        errorType: 'FormatException',
        resolved: true,
        errorHash: 'abc123',
      );
      expect(entry.stackTrace, 'at line 42');
      expect(entry.userId, 'user-1');
      expect(entry.screenName, 'BillingScreen');
      expect(entry.metadata, {'key': 'val'});
      expect(entry.route, '/billing');
      expect(entry.errorType, 'FormatException');
      expect(entry.resolved, isTrue);
      expect(entry.errorHash, 'abc123');
    });

    test('toFirestore serializes all fields', () {
      final entry = makeEntry(
        userId: 'u1',
        screenName: 'Home',
        errorHash: 'h1',
      );
      final map = entry.toFirestore();

      expect(map['message'], 'test error');
      expect(map['platform'], 'windows');
      expect(map['appVersion'], '7.0.0');
      expect(map['severity'], 'error');
      expect(map['userId'], 'u1');
      expect(map['screenName'], 'Home');
      expect(map['resolved'], isFalse);
      expect(map['errorHash'], 'h1');
      expect(map.containsKey('timestamp'), isTrue);
    });

    test('toFirestore handles null optional fields', () {
      final entry = makeEntry();
      final map = entry.toFirestore();

      expect(map['stackTrace'], isNull);
      expect(map['userId'], isNull);
      expect(map['screenName'], isNull);
      expect(map['metadata'], isNull);
      expect(map['route'], isNull);
      expect(map['errorType'], isNull);
      expect(map['errorHash'], isNull);
    });

    test('toCopyText includes severity icons', () {
      final critical = makeEntry(severity: ErrorSeverity.critical);
      expect(critical.toCopyText(), contains('🔴'));

      final error = makeEntry();
      expect(error.toCopyText(), contains('🟠'));

      final warning = makeEntry(severity: ErrorSeverity.warning);
      expect(warning.toCopyText(), contains('🟡'));
    });

    test('toCopyText includes message', () {
      final entry = makeEntry(message: 'Something went wrong');
      expect(entry.toCopyText(), contains('Something went wrong'));
    });

    test('toCopyText includes platform', () {
      final entry = makeEntry(platform: 'android');
      expect(entry.toCopyText(), contains('android'));
    });

    test('toCopyText includes user info when present', () {
      final entry = ErrorLogEntry(
        message: 'err',
        platform: 'web',
        appVersion: '1.0',
        severity: ErrorSeverity.error,
        timestamp: DateTime(2024),
        userEmail: 'test@example.com',
        shopName: 'My Shop',
        userId: 'uid-1',
      );
      final text = entry.toCopyText();
      expect(text, contains('test@example.com'));
      expect(text, contains('My Shop'));
      expect(text, contains('uid-1'));
    });

    test('toCopyText includes stack trace when present', () {
      final entry = makeEntry(stackTrace: '#0 main() at line 1');
      expect(entry.toCopyText(), contains('#0 main() at line 1'));
    });

    test('toCopyText omits absent optional fields', () {
      final entry = makeEntry();
      final text = entry.toCopyText();
      expect(text, isNot(contains('Route:')));
      expect(text, isNot(contains('Screen:')));
      expect(text, isNot(contains('Widget:')));
    });

    test('toCopyText includes screen info when present', () {
      final entry = ErrorLogEntry(
        message: 'err',
        platform: 'web',
        appVersion: '1.0',
        severity: ErrorSeverity.error,
        timestamp: DateTime(2024),
        screenName: 'Billing',
        route: '/billing',
        screenWidth: 1920,
        screenHeight: 1080,
      );
      final text = entry.toCopyText();
      expect(text, contains('Billing'));
      expect(text, contains('/billing'));
      expect(text, contains('1920×1080'));
    });

    test('toCopyText includes errorHash when present', () {
      final entry = makeEntry(errorHash: 'abc123hash');
      final text = entry.toCopyText();
      expect(text, contains('Error Hash:'));
      expect(text, contains('abc123hash'));
    });

    test('toCopyText omits errorHash when null', () {
      final entry = makeEntry();
      final text = entry.toCopyText();
      expect(text, isNot(contains('Error Hash:')));
    });

    test('toCopyText includes resolved status', () {
      final resolved = makeEntry(resolved: true);
      expect(resolved.toCopyText(), contains('Resolved:      Yes'));

      final unresolved = makeEntry();
      expect(unresolved.toCopyText(), contains('Resolved:      No'));
    });

    test('toCopyText includes metadata when present', () {
      final entry = makeEntry(
        metadata: {'context': 'pre_firebase_init', 'retryCount': 3},
      );
      final text = entry.toCopyText();
      expect(text, contains('METADATA'));
      expect(text, contains('context: pre_firebase_init'));
      expect(text, contains('retryCount: 3'));
    });

    test('toCopyText omits metadata section when empty', () {
      final entry = makeEntry(metadata: {});
      final text = entry.toCopyText();
      expect(text, isNot(contains('METADATA')));
    });

    test('toCopyText omits metadata section when null', () {
      final entry = makeEntry();
      final text = entry.toCopyText();
      expect(text, isNot(contains('METADATA')));
    });
  });

  // ── GroupedError ──

  group('GroupedError', () {
    test('creates with required fields', () {
      final entry = ErrorLogEntry(
        message: 'err',
        platform: 'web',
        appVersion: '1.0',
        severity: ErrorSeverity.error,
        timestamp: DateTime(2024),
      );
      final grouped = GroupedError(
        latestEntry: entry,
        count: 5,
        firstSeen: DateTime(2024),
        lastSeen: DateTime(2024, 1, 15),
        affectedUsers: 3,
      );
      expect(grouped.count, 5);
      expect(grouped.affectedUsers, 3);
      expect(grouped.docId, isNull);
    });

    test('creates with docId', () {
      final entry = ErrorLogEntry(
        message: 'err',
        platform: 'web',
        appVersion: '1.0',
        severity: ErrorSeverity.error,
        timestamp: DateTime(2024),
      );
      final grouped = GroupedError(
        latestEntry: entry,
        docId: 'doc-123',
        count: 1,
        firstSeen: DateTime(2024),
        lastSeen: DateTime(2024),
        affectedUsers: 1,
      );
      expect(grouped.docId, 'doc-123');
    });
  });
}
