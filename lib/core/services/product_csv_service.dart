/// CSV Import/Export service for products
library;

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:share_plus/share_plus.dart';

/// Result of CSV import
class CsvImportResult {
  final List<ProductModel> products;
  final int skipped;
  final List<String> errors;

  CsvImportResult({
    required this.products,
    this.skipped = 0,
    this.errors = const [],
  });

  int get imported => products.length;
  bool get hasErrors => errors.isNotEmpty;
}

/// Service for CSV import/export of products
class ProductCsvService {
  /// CSV column headers
  static const List<String> _headers = [
    'name',
    'price',
    'purchasePrice',
    'stock',
    'unit',
    'barcode',
    'lowStockAlert',
  ];

  /// Export products to CSV and share
  static Future<void> exportProducts(List<ProductModel> products) async {
    try {
      final csvData = _productsToCsv(products);

      // Get temp directory
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/products_export_$timestamp.csv');

      await file.writeAsString(csvData);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], subject: 'Products Export');

      debugPrint('✅ Exported ${products.length} products to CSV');
    } catch (e) {
      debugPrint('❌ CSV export error: $e');
      rethrow;
    }
  }

  /// Export products to CSV and save to downloads
  static Future<String?> exportToDownloads(List<ProductModel> products) async {
    try {
      final csvData = _productsToCsv(products);

      // Let user pick save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Products CSV',
        fileName: 'products_${DateTime.now().millisecondsSinceEpoch}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(csvData);
        debugPrint('✅ Saved CSV to: $result');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('❌ CSV save error: $e');
      rethrow;
    }
  }

  /// Import products from CSV file
  static Future<CsvImportResult> importProducts() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return CsvImportResult(products: []);
      }

      String csvContent;
      if (result.files.first.bytes != null) {
        csvContent = String.fromCharCodes(result.files.first.bytes!);
      } else if (result.files.first.path != null) {
        csvContent = await File(result.files.first.path!).readAsString();
      } else {
        return CsvImportResult(products: [], errors: ['Could not read file']);
      }

      return _parseCsv(csvContent);
    } catch (e) {
      debugPrint('❌ CSV import error: $e');
      return CsvImportResult(products: [], errors: ['Import failed: $e']);
    }
  }

  /// Convert products to CSV string
  static String _productsToCsv(List<ProductModel> products) {
    final rows = <List<dynamic>>[_headers];

    for (final p in products) {
      rows.add([
        p.name,
        p.price,
        p.purchasePrice ?? '',
        p.stock,
        p.unit.name,
        p.barcode ?? '',
        p.lowStockAlert ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Parse CSV string to products
  static CsvImportResult _parseCsv(String csvContent) {
    final products = <ProductModel>[];
    final errors = <String>[];
    int skipped = 0;

    try {
      final rows = const CsvToListConverter(eol: '\n').convert(csvContent);

      if (rows.isEmpty) {
        return CsvImportResult(products: [], errors: ['Empty CSV file']);
      }

      // Get header row
      final headerRow = rows.first
          .map((e) => e.toString().toLowerCase().trim())
          .toList();

      // Find column indices
      final nameIdx = headerRow.indexOf('name');
      final priceIdx = headerRow.indexOf('price');
      final purchasePriceIdx = headerRow.indexOf('purchaseprice');
      final stockIdx = headerRow.indexOf('stock');
      final unitIdx = headerRow.indexOf('unit');
      final barcodeIdx = headerRow.indexOf('barcode');
      final lowStockIdx = headerRow.indexOf('lowstockalert');

      if (nameIdx == -1 || priceIdx == -1) {
        return CsvImportResult(
          products: [],
          errors: ['CSV must have "name" and "price" columns'],
        );
      }

      // Parse data rows
      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.isEmpty) {
            skipped++;
            continue;
          }

          final name = _getCell(row, nameIdx);
          final priceStr = _getCell(row, priceIdx);

          if (name.isEmpty || priceStr.isEmpty) {
            skipped++;
            continue;
          }

          final price = double.tryParse(priceStr);
          if (price == null) {
            errors.add('Row $i: Invalid price "$priceStr"');
            skipped++;
            continue;
          }

          final product = ProductModel(
            id: '', // Will be assigned by Firestore
            name: name,
            price: price,
            purchasePrice: purchasePriceIdx >= 0
                ? double.tryParse(_getCell(row, purchasePriceIdx))
                : null,
            stock: stockIdx >= 0
                ? int.tryParse(_getCell(row, stockIdx)) ?? 0
                : 0,
            unit: unitIdx >= 0
                ? ProductUnit.fromString(_getCell(row, unitIdx))
                : ProductUnit.piece,
            barcode: barcodeIdx >= 0 ? _getCell(row, barcodeIdx) : null,
            lowStockAlert: lowStockIdx >= 0
                ? int.tryParse(_getCell(row, lowStockIdx))
                : null,
            createdAt: DateTime.now(),
          );

          products.add(product);
        } catch (e) {
          errors.add('Row $i: $e');
          skipped++;
        }
      }

      debugPrint('✅ Parsed ${products.length} products, skipped $skipped');
      return CsvImportResult(
        products: products,
        skipped: skipped,
        errors: errors,
      );
    } catch (e) {
      return CsvImportResult(products: [], errors: ['Parse error: $e']);
    }
  }

  /// Safely get cell value
  static String _getCell(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    final value = row[index];
    if (value == null) return '';
    return value.toString().trim();
  }

  /// Get sample CSV template
  static String getSampleCsv() {
    return '''name,price,purchasePrice,stock,unit,barcode,lowStockAlert
Rice Basmati 5kg,450,400,50,kg,,10
Tata Salt 1kg,28,24,100,piece,8901725181116,20
Sugar 1kg,48,42,80,kg,,15
Cooking Oil 1L,180,165,30,liter,,5''';
  }
}
