import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/product_csv_service.dart';

void main() {
  // ── CsvImportResult ──

  group('CsvImportResult', () {
    test('imported count equals products length', () {
      final result = CsvImportResult(products: []);
      expect(result.imported, 0);
    });

    test('hasErrors when errors list is non-empty', () {
      final result = CsvImportResult(
        products: [],
        errors: ['Row 1: Invalid price'],
      );
      expect(result.hasErrors, isTrue);
    });

    test('no errors when errors list is empty', () {
      final result = CsvImportResult(products: []);
      expect(result.hasErrors, isFalse);
    });

    test('skipped defaults to 0', () {
      final result = CsvImportResult(products: []);
      expect(result.skipped, 0);
    });

    test('errors defaults to empty list', () {
      final result = CsvImportResult(products: []);
      expect(result.errors, isEmpty);
    });
  });

  // ── getSampleCsv ──

  group('ProductCsvService.getSampleCsv', () {
    test('returns non-empty CSV', () {
      final csv = ProductCsvService.getSampleCsv();
      expect(csv, isNotEmpty);
    });

    test('contains header row', () {
      final csv = ProductCsvService.getSampleCsv();
      expect(csv, contains('name'));
      expect(csv, contains('price'));
      expect(csv, contains('stock'));
      expect(csv, contains('unit'));
      expect(csv, contains('barcode'));
    });

    test('contains sample data rows', () {
      final csv = ProductCsvService.getSampleCsv();
      final lines = csv.split('\n');
      // Header + at least 1 data row
      expect(lines.length, greaterThan(1));
    });

    test('has purchasePrice column', () {
      final csv = ProductCsvService.getSampleCsv();
      expect(csv, contains('purchasePrice'));
    });

    test('has lowStockAlert column', () {
      final csv = ProductCsvService.getSampleCsv();
      expect(csv, contains('lowStockAlert'));
    });

    test('sample data has realistic values', () {
      final csv = ProductCsvService.getSampleCsv();
      // Check for at least one product name
      expect(csv, contains('Rice'));
      expect(csv, contains('Salt'));
    });
  });
}
