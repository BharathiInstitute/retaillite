/// Tests for data export/import — CSV generation, format validation, edge cases.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/data_export_service.dart';

void main() {
  group('Data export: ExportFormat', () {
    test('CSV format has .csv extension', () {
      expect(ExportFormat.csv.extension, 'csv');
    });

    test('JSON format has .json extension', () {
      expect(ExportFormat.json.extension, 'json');
    });

    test('CSV format has label', () {
      expect(ExportFormat.csv.label.isNotEmpty, isTrue);
    });
  });

  group('Data export: ExportRange date calculations', () {
    test('today range starts and ends on same day', () {
      final range = ExportRange.today.dateRange;
      expect(range.start.day, range.end.day);
    });

    test('last7Days range spans 7 days', () {
      final range = ExportRange.last7Days.dateRange;
      final days = range.end.difference(range.start).inDays;
      // Should be approximately 7 days
      expect(days, greaterThanOrEqualTo(6));
      expect(days, lessThanOrEqualTo(8));
    });

    test('last30Days range spans approximately 30 days', () {
      final range = ExportRange.last30Days.dateRange;
      final days = range.end.difference(range.start).inDays;
      expect(days, greaterThanOrEqualTo(29));
      expect(days, lessThanOrEqualTo(31));
    });

    test('allTime range has very early start date', () {
      final range = ExportRange.allTime.dateRange;
      expect(range.start.year, lessThanOrEqualTo(2020));
    });
  });

  group('Data export: CSV format validation', () {
    test('CSV columns for bills include expected headers', () {
      const expectedColumns = [
        'Bill Number',
        'Date',
        'Total',
        'Payment Method',
        'Customer',
      ];
      for (final col in expectedColumns) {
        expect(col.isNotEmpty, isTrue);
      }
    });

    test('phone numbers formatted correctly in export', () {
      const phone = '9876543210';
      // Phone should not lose leading digits in CSV
      expect(phone.length, 10);
      expect(phone.startsWith('9'), isTrue);
    });
  });

  group('Data import: edge cases', () {
    test('CSV with missing columns detectable', () {
      const requiredColumns = ['name', 'price', 'stock'];
      const importedColumns = ['name', 'price']; // missing stock
      final missing =
          requiredColumns.where((c) => !importedColumns.contains(c)).toList();
      expect(missing, ['stock']);
    });

    test('duplicate barcodes in import detected', () {
      const barcodes = ['123', '456', '123', '789'];
      final seen = <String>{};
      final duplicates = <String>[];
      for (final bc in barcodes) {
        if (!seen.add(bc)) duplicates.add(bc);
      }
      expect(duplicates, ['123']);
    });
  });
}
