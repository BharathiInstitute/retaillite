import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/data_export_service.dart';

void main() {
  // ── ExportFormat enum ──

  group('ExportFormat', () {
    test('csv has correct extension', () {
      expect(ExportFormat.csv.extension, 'csv');
    });

    test('json has correct extension', () {
      expect(ExportFormat.json.extension, 'json');
    });

    test('each format has a label', () {
      for (final format in ExportFormat.values) {
        expect(format.label, isNotEmpty);
      }
    });

    test('each format has a description', () {
      for (final format in ExportFormat.values) {
        expect(format.description, isNotEmpty);
      }
    });
  });

  // ── ExportRange enum ──

  group('ExportRange.toDateRange', () {
    test('today returns same-day range', () {
      final range = ExportRange.today.dateRange;
      final now = DateTime.now();
      expect(range.start.year, now.year);
      expect(range.start.month, now.month);
      expect(range.start.day, now.day);
      expect(range.end.year, now.year);
    });

    test('last7Days starts 7 days ago', () {
      final range = ExportRange.last7Days.dateRange;
      final now = DateTime.now();
      final diff = now.difference(range.start).inDays;
      expect(diff, greaterThanOrEqualTo(6));
      expect(diff, lessThanOrEqualTo(7));
    });

    test('last30Days starts 30 days ago', () {
      final range = ExportRange.last30Days.dateRange;
      final now = DateTime.now();
      final diff = now.difference(range.start).inDays;
      expect(diff, greaterThanOrEqualTo(29));
      expect(diff, lessThanOrEqualTo(30));
    });

    test('last90Days starts 90 days ago', () {
      final range = ExportRange.last90Days.dateRange;
      final now = DateTime.now();
      final diff = now.difference(range.start).inDays;
      expect(diff, greaterThanOrEqualTo(89));
      expect(diff, lessThanOrEqualTo(90));
    });

    test('thisMonth starts on first of current month', () {
      final range = ExportRange.thisMonth.dateRange;
      final now = DateTime.now();
      expect(range.start.year, now.year);
      expect(range.start.month, now.month);
      expect(range.start.day, 1);
    });

    test('lastMonth starts on first of previous month', () {
      final range = ExportRange.lastMonth.dateRange;
      final now = DateTime.now();
      final expectedMonth = now.month == 1 ? 12 : now.month - 1;
      expect(range.start.month, expectedMonth);
      expect(range.start.day, 1);
    });

    test('allTime starts from 2020', () {
      final range = ExportRange.allTime.dateRange;
      expect(range.start.year, 2020);
    });

    test('all ranges have label', () {
      for (final range in ExportRange.values) {
        expect(range.label, isNotEmpty);
      }
    });
  });

  // ── DateTimeRange ──

  group('DateTimeRange.includes', () {
    test('includes date within range', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(range.includes(DateTime(2026, 1, 15)), isTrue);
    });

    test('includes start date', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(range.includes(DateTime(2026, 1)), isTrue);
    });

    test('excludes date before range', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(range.includes(DateTime(2025, 12, 31)), isFalse);
    });

    test('excludes date after range', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1),
        end: DateTime(2026, 1, 31),
      );
      expect(range.includes(DateTime(2026, 2)), isFalse);
    });
  });

  // ── ExportResult ──

  group('ExportResult', () {
    test('success result has path and no error', () {
      const result = ExportResult(
        success: true,
        filePath: '/path/to/file.csv',
        recordCount: 100,
        format: ExportFormat.csv,
      );
      expect(result.success, isTrue);
      expect(result.filePath, '/path/to/file.csv');
      expect(result.recordCount, 100);
      expect(result.format, ExportFormat.csv);
      expect(result.error, isNull);
    });

    test('failure result has error message', () {
      const result = ExportResult(success: false, error: 'Failed to export');
      expect(result.success, isFalse);
      expect(result.error, 'Failed to export');
      expect(result.filePath, isNull);
    });
  });
}
