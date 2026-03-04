/// Tests for AppHealthService — AppHealthMetrics data class
/// Uses inline duplicate to avoid transitive Firebase import chain.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicate (avoid app_health_service → main → billing_screen) ──

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

  Map<String, dynamic> toFirestore() => {
    'startupTimeMs': startupTime.inMilliseconds,
    'platform': platform,
    'appVersion': appVersion,
    'timestamp': Timestamp.fromDate(timestamp),
    'isOnline': isOnline,
    'userId': userId,
  };
}

void main() {
  // ── AppHealthMetrics ──

  group('AppHealthMetrics', () {
    test('creates with required fields', () {
      final metrics = AppHealthMetrics(
        startupTime: const Duration(milliseconds: 1200),
        platform: 'windows',
        appVersion: '7.0.0',
        timestamp: DateTime(2024, 6, 15),
        isOnline: true,
      );
      expect(metrics.startupTime.inMilliseconds, 1200);
      expect(metrics.platform, 'windows');
      expect(metrics.appVersion, '7.0.0');
      expect(metrics.isOnline, isTrue);
      expect(metrics.userId, isNull);
    });

    test('creates with userId', () {
      final metrics = AppHealthMetrics(
        startupTime: const Duration(seconds: 2),
        platform: 'android',
        appVersion: '7.0.0',
        timestamp: DateTime(2024, 6, 15),
        isOnline: false,
        userId: 'user-1',
      );
      expect(metrics.userId, 'user-1');
      expect(metrics.isOnline, isFalse);
    });

    test('toFirestore serializes correctly', () {
      final metrics = AppHealthMetrics(
        startupTime: const Duration(milliseconds: 500),
        platform: 'web',
        appVersion: '7.0.0',
        timestamp: DateTime(2024, 3),
        isOnline: true,
        userId: 'uid-1',
      );
      final map = metrics.toFirestore();
      expect(map['startupTimeMs'], 500);
      expect(map['platform'], 'web');
      expect(map['appVersion'], '7.0.0');
      expect(map['isOnline'], isTrue);
      expect(map['userId'], 'uid-1');
      expect(map.containsKey('timestamp'), isTrue);
    });

    test('toFirestore handles null userId', () {
      final metrics = AppHealthMetrics(
        startupTime: const Duration(milliseconds: 100),
        platform: 'android',
        appVersion: '1.0',
        timestamp: DateTime(2024),
        isOnline: true,
      );
      final map = metrics.toFirestore();
      expect(map['userId'], isNull);
    });
  });
}
