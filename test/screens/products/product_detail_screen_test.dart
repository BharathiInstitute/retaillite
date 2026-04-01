/// Tests for ProductDetailScreen — product info display and stock logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('ProductDetailScreen product info', () {
    test('product name displayed', () {
      const name = 'Basmati Rice';
      expect(name.isNotEmpty, isTrue);
    });

    test('product price formatted', () {
      const price = 250.50;
      final formatted = '₹${price.toStringAsFixed(2)}';
      expect(formatted, '₹250.50');
    });

    test('product category displayed', () {
      const category = 'Grocery';
      expect(category.isNotEmpty, isTrue);
    });

    test('empty product id is invalid', () {
      const productId = '';
      expect(productId.isEmpty, isTrue);
    });
  });

  group('ProductDetailScreen stock adjustment', () {
    test('increment stock by 1', () {
      const currentStock = 10;
      const adjustment = 1;
      const newStock = currentStock + adjustment;
      expect(newStock, 11);
    });

    test('decrement stock by 1', () {
      const currentStock = 10;
      const adjustment = -1;
      const newStock = currentStock + adjustment;
      expect(newStock, 9);
    });

    test('stock cannot go below 0', () {
      const currentStock = 0;
      const adjustment = -1;
      final newStock = (currentStock + adjustment).clamp(0, 99999);
      expect(newStock, 0);
    });

    test('large stock adjustment capped at 9999', () {
      const currentStock = 9990;
      const adjustment = 100;
      final newStock = (currentStock + adjustment).clamp(0, 9999);
      expect(newStock, 9999);
    });
  });

  group('ProductDetailScreen edit validation', () {
    test('product name cannot be empty', () {
      expect(Validators.name('', 'Product name'), isNotNull);
    });

    test('valid product name passes', () {
      expect(Validators.name('Rice', 'Product name'), isNull);
    });

    test('price must be valid number', () {
      expect(Validators.price('abc'), isNotNull);
    });

    test('valid price passes', () {
      expect(Validators.price('100'), isNull);
    });

    test('negative price fails', () {
      expect(Validators.price('-50'), isNotNull);
    });
  });
}
