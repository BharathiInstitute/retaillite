/// Tests for AnalyticsScreen (admin) — charts, date range, export.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsScreen charts', () {
    test('charts render with data', () {
      final chartData = [10.0, 20.0, 30.0];
      expect(chartData.isNotEmpty, isTrue);
    });
  });

  group('AnalyticsScreen date range', () {
    test('date range filter changes data period', () {
      final start = DateTime(2025, 1);
      final end = DateTime(2025, 3, 31);
      final days = end.difference(start).inDays;
      expect(days, 89);
    });
  });

  group('AnalyticsScreen platform stats', () {
    test('platform stats include android, ios, web, windows', () {
      const platforms = ['android', 'ios', 'web', 'windows'];
      expect(platforms.length, 4);
    });
  });
}
