/// Tests for BarcodeLookupService — BarcodeProduct parsing, isValidBarcode
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/barcode_lookup_service.dart';

void main() {
  // ── BarcodeProduct construction ──

  group('BarcodeProduct', () {
    test('creates with required fields', () {
      const product = BarcodeProduct(barcode: '8901234567890', name: 'Rice');
      expect(product.barcode, '8901234567890');
      expect(product.name, 'Rice');
      expect(product.brand, isNull);
      expect(product.imageUrl, isNull);
      expect(product.mrp, isNull);
      expect(product.category, isNull);
      expect(product.quantity, isNull);
    });

    test('creates with all fields', () {
      const product = BarcodeProduct(
        barcode: '8901234567890',
        name: 'Basmati Rice',
        brand: 'India Gate',
        imageUrl: 'https://example.com/rice.jpg',
        mrp: 250.0,
        category: 'Grains',
        quantity: '5kg',
      );
      expect(product.brand, 'India Gate');
      expect(product.mrp, 250.0);
      expect(product.quantity, '5kg');
    });
  });

  // ── displayName ──

  group('BarcodeProduct.displayName', () {
    test('returns brand + name when brand present', () {
      const product = BarcodeProduct(
        barcode: '123',
        name: 'Tea',
        brand: 'Tata',
      );
      expect(product.displayName, 'Tata Tea');
    });

    test('returns name only when brand is null', () {
      const product = BarcodeProduct(barcode: '123', name: 'Rice');
      expect(product.displayName, 'Rice');
    });

    test('returns name only when brand is empty', () {
      const product = BarcodeProduct(barcode: '123', name: 'Oil', brand: '');
      expect(product.displayName, 'Oil');
    });
  });

  // ── fromOpenFoodFacts ──

  group('BarcodeProduct.fromOpenFoodFacts', () {
    test('parses complete product data', () {
      final json = {
        'product': {
          'product_name': 'Chocolate',
          'brands': 'Cadbury',
          'image_front_small_url': 'https://img.com/choc.jpg',
          'categories': 'Snacks',
          'quantity': '100g',
        },
      };
      final product = BarcodeProduct.fromOpenFoodFacts('1234', json);
      expect(product.barcode, '1234');
      expect(product.name, 'Chocolate');
      expect(product.brand, 'Cadbury');
      expect(product.imageUrl, 'https://img.com/choc.jpg');
      expect(product.category, 'Snacks');
      expect(product.quantity, '100g');
    });

    test('falls back to product_name_en when product_name is null', () {
      final json = {
        'product': {'product_name_en': 'Butter', 'brands': 'Amul'},
      };
      final product = BarcodeProduct.fromOpenFoodFacts('5678', json);
      expect(product.name, 'Butter');
    });

    test('returns Unknown Product when no name fields', () {
      final json = {
        'product': {'brands': 'SomeBrand'},
      };
      final product = BarcodeProduct.fromOpenFoodFacts('9999', json);
      expect(product.name, 'Unknown Product');
    });

    test('returns Unknown Product when product is null', () {
      final json = <String, dynamic>{'product': null};
      final product = BarcodeProduct.fromOpenFoodFacts('0000', json);
      expect(product.name, 'Unknown Product');
      expect(product.brand, isNull);
    });

    test('falls back to image_url when image_front_small_url is null', () {
      final json = {
        'product': {
          'product_name': 'Milk',
          'image_url': 'https://img.com/fallback.jpg',
        },
      };
      final product = BarcodeProduct.fromOpenFoodFacts('1111', json);
      expect(product.imageUrl, 'https://img.com/fallback.jpg');
    });

    test('imageUrl is null when no image fields', () {
      final json = {
        'product': {'product_name': 'Water'},
      };
      final product = BarcodeProduct.fromOpenFoodFacts('2222', json);
      expect(product.imageUrl, isNull);
    });
  });

  // ── isValidBarcode ──

  group('BarcodeLookupService.isValidBarcode', () {
    test('EAN-8 is valid (8 digits)', () {
      expect(BarcodeLookupService.isValidBarcode('12345678'), isTrue);
    });

    test('EAN-13 is valid (13 digits)', () {
      expect(BarcodeLookupService.isValidBarcode('8901234567890'), isTrue);
    });

    test('UPC-A is valid (12 digits)', () {
      expect(BarcodeLookupService.isValidBarcode('012345678901'), isTrue);
    });

    test('14 digits is valid', () {
      expect(BarcodeLookupService.isValidBarcode('12345678901234'), isTrue);
    });

    test('7 digits is too short', () {
      expect(BarcodeLookupService.isValidBarcode('1234567'), isFalse);
    });

    test('15 digits is too long', () {
      expect(BarcodeLookupService.isValidBarcode('123456789012345'), isFalse);
    });

    test('empty string is invalid', () {
      expect(BarcodeLookupService.isValidBarcode(''), isFalse);
    });

    test('strips non-digit characters before validating', () {
      expect(BarcodeLookupService.isValidBarcode('8901-2345-67890'), isTrue);
    });

    test('whitespace-only is invalid', () {
      expect(BarcodeLookupService.isValidBarcode('   '), isFalse);
    });

    test('leading/trailing spaces are trimmed', () {
      expect(BarcodeLookupService.isValidBarcode('  12345678  '), isTrue);
    });
  });
}
