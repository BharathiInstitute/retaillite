import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/product_csv_service.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  group('CsvImportResult', () {
    test('imported returns product count', () {
      final result = CsvImportResult(
        products: [
          ProductModel(
            id: '1',
            name: 'Rice',
            price: 100,
            stock: 10,
            unit: ProductUnit.kg,
            createdAt: DateTime.now(),
          ),
        ],
        skipped: 2,
      );
      expect(result.imported, 1);
      expect(result.skipped, 2);
    });

    test('hasErrors returns true when errors exist', () {
      final result = CsvImportResult(
        products: [],
        errors: ['Row 2: bad price'],
      );
      expect(result.hasErrors, isTrue);
    });

    test('hasErrors returns false when no errors', () {
      final result = CsvImportResult(products: []);
      expect(result.hasErrors, isFalse);
    });
  });

  group('ProductCsvService._productsToCsv / _parseCsv round-trip', () {
    test('getSampleCsv returns valid CSV with headers', () {
      final csv = ProductCsvService.getSampleCsv();
      expect(csv, contains('name,price,purchasePrice,stock,unit,barcode,lowStockAlert'));
      expect(csv, contains('Rice Basmati 5kg'));
      expect(csv, contains('Tata Salt 1kg'));
    });

    test('getSampleCsv has correct number of data rows', () {
      final csv = ProductCsvService.getSampleCsv();
      final lines = csv.trim().split('\n');
      expect(lines.length, 5); // 1 header + 4 data rows
    });
  });

  group('ProductCsvService column headers', () {
    test('sample CSV first line matches expected headers', () {
      final csv = ProductCsvService.getSampleCsv();
      final firstLine = csv.split('\n').first;
      expect(firstLine, 'name,price,purchasePrice,stock,unit,barcode,lowStockAlert');
    });
  });
}
