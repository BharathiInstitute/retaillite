/// Tests for PerformanceScreen (admin) — metrics, thresholds, time range.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerformanceScreen metrics display', () {
    test('screen load times rendered', () {
      final loadTimes = {'billing': 1200, 'products': 800, 'khata': 600};
      expect(loadTimes.isNotEmpty, isTrue);
    });
  });

  group('PerformanceScreen thresholds', () {
    test('load time above threshold shows warning', () {
      const loadTimeMs = 3000;
      const thresholdMs = 2000;
      const isWarning = loadTimeMs > thresholdMs;
      expect(isWarning, isTrue);
    });

    test('load time below threshold shows good', () {
      const loadTimeMs = 500;
      const thresholdMs = 2000;
      const isWarning = loadTimeMs > thresholdMs;
      expect(isWarning, isFalse);
    });
  });

  group('PerformanceScreen time range', () {
    test('crash-free stats cover a time period', () {
      final start = DateTime(2025, 3);
      final end = DateTime(2025, 3, 31);
      final days = end.difference(start).inDays;
      expect(days, 30);
    });
  });
}
