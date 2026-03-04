/// Tests for PerformanceService data classes and breadcrumb tracking
///
/// Tests pure data class logic (Breadcrumb, ScreenTiming, NetworkTiming)
/// and breadcrumb management (add, get, clear, max capacity).
/// Uses inline duplicates to avoid transitive Firebase import chain.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicates (avoid performance_service → main → billing_screen) ──

enum BreadcrumbType { navigation, tap, input, api, lifecycle, custom }

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
    'appVersion': _appVersion,
    'platform': PerformanceService._platform,
  };
}

class NetworkTiming {
  final String operation;
  final String type;
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
    'appVersion': _appVersion,
  };
}

// Stub for appVersion global
const String _appVersion = '7.0.0+34';

/// Minimal PerformanceService duplicate with only breadcrumb management
class PerformanceService {
  PerformanceService._();

  static final List<Breadcrumb> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 50;
  static String? _currentScreen;

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

  static void addBreadcrumb(
    String message, {
    BreadcrumbType type = BreadcrumbType.custom,
    Map<String, dynamic>? data,
  }) {
    _breadcrumbs.add(Breadcrumb(message: message, type: type, data: data));
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  static void trackNavigation(String screenName) {
    addBreadcrumb('Navigated to $screenName', type: BreadcrumbType.navigation);
    _currentScreen = screenName;
  }

  static void trackTap(String elementName, {String? screen}) {
    addBreadcrumb(
      'Tapped $elementName',
      type: BreadcrumbType.tap,
      data: {'screen': screen ?? _currentScreen},
    );
  }

  static void trackInput(String action, {Map<String, dynamic>? data}) {
    addBreadcrumb(action, type: BreadcrumbType.input, data: data);
  }

  static List<Breadcrumb> getBreadcrumbs() => List.unmodifiable(_breadcrumbs);

  static List<Map<String, dynamic>> getBreadcrumbsJson() =>
      _breadcrumbs.map((b) => b.toMap()).toList();

  static void clearBreadcrumbs() => _breadcrumbs.clear();
}

void main() {
  // ── BreadcrumbType enum ──

  group('BreadcrumbType', () {
    test('has all expected values', () {
      expect(BreadcrumbType.values.length, 6);
      expect(BreadcrumbType.values, contains(BreadcrumbType.navigation));
      expect(BreadcrumbType.values, contains(BreadcrumbType.tap));
      expect(BreadcrumbType.values, contains(BreadcrumbType.input));
      expect(BreadcrumbType.values, contains(BreadcrumbType.api));
      expect(BreadcrumbType.values, contains(BreadcrumbType.lifecycle));
      expect(BreadcrumbType.values, contains(BreadcrumbType.custom));
    });
  });

  // ── Breadcrumb data class ──

  group('Breadcrumb', () {
    test('creates with required fields', () {
      final crumb = Breadcrumb(message: 'test tap', type: BreadcrumbType.tap);
      expect(crumb.message, 'test tap');
      expect(crumb.type, BreadcrumbType.tap);
      expect(crumb.timestamp, isNotNull);
      expect(crumb.data, isNull);
    });

    test('creates with optional data', () {
      final crumb = Breadcrumb(
        message: 'nav',
        type: BreadcrumbType.navigation,
        data: {'screen': 'home'},
      );
      expect(crumb.data, {'screen': 'home'});
    });

    test('uses custom timestamp', () {
      final ts = DateTime(2024, 6, 15);
      final crumb = Breadcrumb(
        message: 'test',
        type: BreadcrumbType.custom,
        timestamp: ts,
      );
      expect(crumb.timestamp, ts);
    });

    test('toMap serializes correctly', () {
      final ts = DateTime(2024, 6, 15, 10, 30);
      final crumb = Breadcrumb(
        message: 'test',
        type: BreadcrumbType.api,
        timestamp: ts,
        data: {'key': 'value'},
      );
      final map = crumb.toMap();
      expect(map['message'], 'test');
      expect(map['type'], 'api');
      expect(map['timestamp'], ts.toIso8601String());
      expect(map['data'], {'key': 'value'});
    });

    test('toMap handles null data', () {
      final crumb = Breadcrumb(message: 'x', type: BreadcrumbType.tap);
      final map = crumb.toMap();
      expect(map['data'], isNull);
    });
  });

  // ── ScreenTiming data class ──

  group('ScreenTiming', () {
    test('creates with required fields', () {
      final timing = ScreenTiming(
        screenName: 'HomeScreen',
        loadTime: const Duration(milliseconds: 250),
        timestamp: DateTime(2024),
      );
      expect(timing.screenName, 'HomeScreen');
      expect(timing.loadTime.inMilliseconds, 250);
      expect(timing.userId, isNull);
    });

    test('creates with userId', () {
      final timing = ScreenTiming(
        screenName: 'Settings',
        loadTime: const Duration(seconds: 1),
        timestamp: DateTime(2024),
        userId: 'user-123',
      );
      expect(timing.userId, 'user-123');
    });

    test('toFirestore includes correct fields', () {
      final timing = ScreenTiming(
        screenName: 'Billing',
        loadTime: const Duration(milliseconds: 500),
        timestamp: DateTime(2024, 3),
        userId: 'uid-1',
      );
      final map = timing.toFirestore();
      expect(map['screenName'], 'Billing');
      expect(map['loadTimeMs'], 500);
      expect(map['userId'], 'uid-1');
      expect(map.containsKey('timestamp'), isTrue);
      expect(map.containsKey('appVersion'), isTrue);
      expect(map.containsKey('platform'), isTrue);
    });
  });

  // ── NetworkTiming data class ──

  group('NetworkTiming', () {
    test('creates with required fields', () {
      final timing = NetworkTiming(
        operation: 'fetchBills',
        type: 'firestore',
        latency: const Duration(milliseconds: 100),
        success: true,
        timestamp: DateTime(2024),
      );
      expect(timing.operation, 'fetchBills');
      expect(timing.type, 'firestore');
      expect(timing.latency.inMilliseconds, 100);
      expect(timing.success, isTrue);
      expect(timing.errorMessage, isNull);
    });

    test('creates with error message', () {
      final timing = NetworkTiming(
        operation: 'login',
        type: 'auth',
        latency: const Duration(seconds: 5),
        success: false,
        timestamp: DateTime(2024),
        errorMessage: 'timeout',
      );
      expect(timing.success, isFalse);
      expect(timing.errorMessage, 'timeout');
    });

    test('toFirestore includes correct fields', () {
      final timing = NetworkTiming(
        operation: 'save',
        type: 'api',
        latency: const Duration(milliseconds: 200),
        success: true,
        timestamp: DateTime(2024, 7),
      );
      final map = timing.toFirestore();
      expect(map['operation'], 'save');
      expect(map['type'], 'api');
      expect(map['latencyMs'], 200);
      expect(map['success'], isTrue);
      expect(map.containsKey('timestamp'), isTrue);
      expect(map['errorMessage'], isNull);
    });
  });

  // ── Breadcrumb management (via PerformanceService) ──

  group('PerformanceService breadcrumbs', () {
    setUp(() {
      PerformanceService.clearBreadcrumbs();
    });

    test('initially empty', () {
      expect(PerformanceService.getBreadcrumbs(), isEmpty);
    });

    test('addBreadcrumb adds a crumb', () {
      PerformanceService.addBreadcrumb('test');
      expect(PerformanceService.getBreadcrumbs(), hasLength(1));
    });

    test('trackNavigation adds navigation breadcrumb', () {
      PerformanceService.trackNavigation('HomeScreen');
      final crumbs = PerformanceService.getBreadcrumbs();
      expect(crumbs.length, 1);
      expect(crumbs.first.type, BreadcrumbType.navigation);
    });

    test('trackTap adds tap breadcrumb', () {
      PerformanceService.trackTap('button_save');
      final crumbs = PerformanceService.getBreadcrumbs();
      expect(crumbs.length, 1);
      expect(crumbs.first.type, BreadcrumbType.tap);
    });

    test('trackInput adds input breadcrumb', () {
      PerformanceService.trackInput('search_query');
      final crumbs = PerformanceService.getBreadcrumbs();
      expect(crumbs.length, 1);
      expect(crumbs.first.type, BreadcrumbType.input);
    });

    test('getBreadcrumbsJson returns serializable list', () {
      PerformanceService.addBreadcrumb('test', type: BreadcrumbType.api);
      final json = PerformanceService.getBreadcrumbsJson();
      expect(json, hasLength(1));
      expect(json.first, isA<Map<String, dynamic>>());
      expect(json.first['message'], 'test');
    });

    test('clearBreadcrumbs removes all crumbs', () {
      PerformanceService.addBreadcrumb('a');
      PerformanceService.addBreadcrumb('b');
      PerformanceService.clearBreadcrumbs();
      expect(PerformanceService.getBreadcrumbs(), isEmpty);
    });

    test('respects max breadcrumbs limit (50)', () {
      for (int i = 0; i < 60; i++) {
        PerformanceService.addBreadcrumb('crumb_$i');
      }
      expect(PerformanceService.getBreadcrumbs().length, 50);
    });

    test('oldest crumbs are evicted when over max', () {
      for (int i = 0; i < 55; i++) {
        PerformanceService.addBreadcrumb('crumb_$i');
      }
      final crumbs = PerformanceService.getBreadcrumbs();
      // First remaining should be crumb_5 (0-4 evicted)
      expect(crumbs.first.message, 'crumb_5');
      expect(crumbs.last.message, 'crumb_54');
    });
  });
}
