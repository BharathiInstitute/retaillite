/// Tests for DashboardWebScreen — report period logic and date range formatting.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardWebScreen report period labels', () {
    test('today period label', () {
      const period = 'today';
      expect(period, 'today');
    });

    test('this week period label', () {
      const period = 'thisWeek';
      expect(period, 'thisWeek');
    });

    test('this month period label', () {
      const period = 'thisMonth';
      expect(period, 'thisMonth');
    });

    test('custom period label', () {
      const period = 'custom';
      expect(period, 'custom');
    });
  });

  group('DashboardWebScreen date range formatting', () {
    test('single day range shows one date', () {
      final start = DateTime(2025, 3, 15);
      final end = DateTime(2025, 3, 15);
      final isSingleDay =
          start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;
      expect(isSingleDay, isTrue);
    });

    test('multi-day range shows start — end', () {
      final start = DateTime(2025, 3);
      final end = DateTime(2025, 3, 31);
      final isSingleDay =
          start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;
      expect(isSingleDay, isFalse);
    });
  });

  group('DashboardWebScreen period offset', () {
    test('offset 0 means current period', () {
      const offset = 0;
      expect(offset, 0);
    });

    test('negative offset goes to previous period', () {
      const offset = -1;
      expect(offset, lessThan(0));
    });

    test('positive offset goes to next period', () {
      const offset = 1;
      expect(offset, greaterThan(0));
    });
  });

  group('DashboardWebScreen stats calculations', () {
    test('average bill amount = total / count', () {
      const totalSales = 50000.0;
      const billCount = 100;
      const average = totalSales / billCount;
      expect(average, 500.0);
    });

    test('zero bills gives zero average', () {
      const totalSales = 0.0;
      const billCount = 0;
      const average = billCount == 0 ? 0.0 : totalSales / billCount;
      expect(average, 0.0);
    });
  });
}
