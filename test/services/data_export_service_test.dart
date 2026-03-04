import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/data_export_service.dart';

void main() {
  group('ExportFormat', () {
    test('csv has correct properties', () {
      expect(ExportFormat.csv.label, 'CSV');
      expect(ExportFormat.csv.extension, 'csv');
      expect(ExportFormat.csv.description, contains('Spreadsheet'));
    });

    test('json has correct properties', () {
      expect(ExportFormat.json.label, 'JSON');
      expect(ExportFormat.json.extension, 'json');
      expect(ExportFormat.json.description, contains('backup'));
    });

    test('all formats covered', () {
      expect(ExportFormat.values.length, 2);
    });
  });

  group('ExportRange', () {
    test('today range starts at midnight', () {
      final range = ExportRange.today.dateRange;
      expect(range.start.hour, 0);
      expect(range.start.minute, 0);
      expect(range.start.second, 0);
    });

    test('today range ends at current time', () {
      final before = DateTime.now();
      final range = ExportRange.today.dateRange;
      final after = DateTime.now();
      // end should be between before and after
      expect(range.end.millisecondsSinceEpoch,
          greaterThanOrEqualTo(before.millisecondsSinceEpoch));
      expect(range.end.millisecondsSinceEpoch,
          lessThanOrEqualTo(after.millisecondsSinceEpoch));
    });

    test('last7Days range spans 7 days', () {
      final range = ExportRange.last7Days.dateRange;
      final diff = range.end.difference(range.start);
      expect(diff.inDays, greaterThanOrEqualTo(7));
    });

    test('last30Days range spans 30 days', () {
      final range = ExportRange.last30Days.dateRange;
      final diff = range.end.difference(range.start);
      expect(diff.inDays, greaterThanOrEqualTo(30));
    });

    test('last90Days range spans 90 days', () {
      final range = ExportRange.last90Days.dateRange;
      final diff = range.end.difference(range.start);
      expect(diff.inDays, greaterThanOrEqualTo(90));
    });

    test('thisMonth starts on 1st of current month', () {
      final range = ExportRange.thisMonth.dateRange;
      final now = DateTime.now();
      expect(range.start.year, now.year);
      expect(range.start.month, now.month);
      expect(range.start.day, 1);
    });

    test('lastMonth ends on last day of previous month', () {
      final range = ExportRange.lastMonth.dateRange;
      final now = DateTime.now();
      final expectedEnd = DateTime(now.year, now.month, 0);
      expect(range.end.day, expectedEnd.day);
      expect(range.end.month, expectedEnd.month);
    });

    test('lastMonth starts on 1st of previous month', () {
      final range = ExportRange.lastMonth.dateRange;
      expect(range.start.day, 1);
    });

    test('allTime starts from 2020', () {
      final range = ExportRange.allTime.dateRange;
      expect(range.start.year, 2020);
      expect(range.start.month, 1);
      expect(range.start.day, 1);
    });

    test('all range values covered', () {
      expect(ExportRange.values.length, 7);
      // Ensure each can compute dateRange without error
      for (final r in ExportRange.values) {
        final range = r.dateRange;
        expect(range.start.isBefore(range.end) || range.start == range.end,
            isTrue,
            reason: '${r.name} start should be before end');
      }
    });
  });

  group('DateTimeRange', () {
    test('includes returns true for date within range', () {
      final range = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      expect(range.includes(DateTime(2026, 6, 15)), isTrue);
    });

    test('includes returns true for start boundary', () {
      final range = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      expect(range.includes(DateTime(2026)), isTrue);
    });

    test('includes returns true for end boundary', () {
      final range = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      expect(range.includes(DateTime(2026, 12, 31)), isTrue);
    });

    test('includes returns false for date before range', () {
      final range = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      expect(range.includes(DateTime(2025, 12, 31)), isFalse);
    });

    test('includes returns false for date after range', () {
      final range = DateTimeRange(
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
      );
      expect(range.includes(DateTime(2027)), isFalse);
    });
  });
}
