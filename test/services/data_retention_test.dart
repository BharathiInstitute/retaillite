import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/data_retention_service.dart';

void main() {
  // ── RetentionPeriod enum ──

  group('RetentionPeriod', () {
    test('has all expected values', () {
      expect(RetentionPeriod.values.length, 4);
      expect(RetentionPeriod.values, contains(RetentionPeriod.days30));
      expect(RetentionPeriod.values, contains(RetentionPeriod.days90));
      expect(RetentionPeriod.values, contains(RetentionPeriod.year1));
      expect(RetentionPeriod.values, contains(RetentionPeriod.forever));
    });

    test('days30 is 30 days', () {
      expect(RetentionPeriod.days30.days, 30);
      expect(RetentionPeriod.days30.neverExpires, isFalse);
    });

    test('days90 is 90 days', () {
      expect(RetentionPeriod.days90.days, 90);
      expect(RetentionPeriod.days90.neverExpires, isFalse);
    });

    test('year1 is 365 days', () {
      expect(RetentionPeriod.year1.days, 365);
      expect(RetentionPeriod.year1.neverExpires, isFalse);
    });

    test('forever never expires', () {
      expect(RetentionPeriod.forever.days, -1);
      expect(RetentionPeriod.forever.neverExpires, isTrue);
    });

    test('all have labels', () {
      for (final period in RetentionPeriod.values) {
        expect(period.label, isNotEmpty);
      }
    });

    test('all have descriptions', () {
      for (final period in RetentionPeriod.values) {
        expect(period.description, isNotEmpty);
      }
    });
  });

  group('RetentionPeriod.cutoffDate', () {
    test('forever returns null', () {
      expect(RetentionPeriod.forever.cutoffDate, isNull);
    });

    test('days30 returns date ~30 days ago', () {
      final cutoff = RetentionPeriod.days30.cutoffDate!;
      final daysAgo = DateTime.now().difference(cutoff).inDays;
      expect(daysAgo, closeTo(30, 1));
    });

    test('days90 returns date ~90 days ago', () {
      final cutoff = RetentionPeriod.days90.cutoffDate!;
      final daysAgo = DateTime.now().difference(cutoff).inDays;
      expect(daysAgo, closeTo(90, 1));
    });

    test('year1 returns date ~365 days ago', () {
      final cutoff = RetentionPeriod.year1.cutoffDate!;
      final daysAgo = DateTime.now().difference(cutoff).inDays;
      expect(daysAgo, closeTo(365, 1));
    });
  });

  group('RetentionPeriod.fromDays', () {
    test('returns days30 for 30', () {
      expect(RetentionPeriod.fromDays(30), RetentionPeriod.days30);
    });

    test('returns days90 for 90', () {
      expect(RetentionPeriod.fromDays(90), RetentionPeriod.days90);
    });

    test('returns year1 for 365', () {
      expect(RetentionPeriod.fromDays(365), RetentionPeriod.year1);
    });

    test('returns forever for -1', () {
      expect(RetentionPeriod.fromDays(-1), RetentionPeriod.forever);
    });

    test('defaults to days90 for unknown value', () {
      expect(RetentionPeriod.fromDays(999), RetentionPeriod.days90);
    });

    test('defaults to days90 for 0', () {
      expect(RetentionPeriod.fromDays(0), RetentionPeriod.days90);
    });
  });

  // ── CleanupResult ──

  group('CleanupResult', () {
    test('totalDeleted aggregates bills and expenses', () {
      const result = CleanupResult(
        billsDeleted: 10,
        expensesDeleted: 5,
        bytesFreed: 0,
      );
      expect(result.totalDeleted, 15);
    });

    test('totalDeleted is zero for empty cleanup', () {
      const result = CleanupResult(
        billsDeleted: 0,
        expensesDeleted: 0,
        bytesFreed: 0,
      );
      expect(result.totalDeleted, 0);
    });

    test('bytesFreedFormatted shows bytes', () {
      const result = CleanupResult(
        billsDeleted: 0,
        expensesDeleted: 0,
        bytesFreed: 500,
      );
      expect(result.bytesFreedFormatted, '500 B');
    });

    test('bytesFreedFormatted shows KB', () {
      const result = CleanupResult(
        billsDeleted: 0,
        expensesDeleted: 0,
        bytesFreed: 2048,
      );
      expect(result.bytesFreedFormatted, '2.0 KB');
    });

    test('bytesFreedFormatted shows MB', () {
      const result = CleanupResult(
        billsDeleted: 0,
        expensesDeleted: 0,
        bytesFreed: 1048576, // 1 MB
      );
      expect(result.bytesFreedFormatted, '1.0 MB');
    });

    test('skipped defaults to false', () {
      const result = CleanupResult(
        billsDeleted: 0,
        expensesDeleted: 0,
        bytesFreed: 0,
      );
      expect(result.skipped, isFalse);
    });

    test('dryRun defaults to false', () {
      const result = CleanupResult(
        billsDeleted: 0,
        expensesDeleted: 0,
        bytesFreed: 0,
      );
      expect(result.dryRun, isFalse);
    });

    test('skipped result has reason', () {
      const result = CleanupResult(
        billsDeleted: 0,
        expensesDeleted: 0,
        bytesFreed: 0,
        skipped: true,
        reason: 'Retention set to forever',
      );
      expect(result.skipped, isTrue);
      expect(result.reason, 'Retention set to forever');
    });

    test('dryRun result shows what would be deleted', () {
      const result = CleanupResult(
        billsDeleted: 50,
        expensesDeleted: 20,
        bytesFreed: 512000,
        dryRun: true,
      );
      expect(result.dryRun, isTrue);
      expect(result.totalDeleted, 70);
      expect(result.bytesFreedFormatted, '500.0 KB');
    });
  });
}
