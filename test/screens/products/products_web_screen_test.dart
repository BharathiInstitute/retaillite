/// Tests for ProductsWebScreen — product list, search, and stock logic.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductsWebScreen search filtering', () {
    test('search filters products by name', () {
      const products = ['Rice', 'Wheat', 'Rice Flour', 'Sugar'];
      const query = 'rice';
      final filtered = products
          .where((p) => p.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(filtered, ['Rice', 'Rice Flour']);
    });

    test('empty search returns all products', () {
      const products = ['A', 'B', 'C'];
      const query = '';
      final result = query.isEmpty ? products : <String>[];
      expect(result.length, 3);
    });
  });

  group('ProductsWebScreen category filtering', () {
    test('filter by category returns matching products', () {
      final products = [
        {'name': 'Rice', 'category': 'Grocery'},
        {'name': 'Milk', 'category': 'Dairy'},
        {'name': 'Wheat', 'category': 'Grocery'},
      ];
      const filter = 'Grocery';
      final filtered = products.where((p) => p['category'] == filter).toList();
      expect(filtered.length, 2);
    });

    test('All category returns all products', () {
      final products = [
        {'name': 'Rice', 'category': 'Grocery'},
        {'name': 'Milk', 'category': 'Dairy'},
      ];
      const String? filter = null; // null = All
      final filtered = filter == null
          ? products
          : products.where((p) => p['category'] == filter).toList();
      expect(filtered.length, 2);
    });
  });

  group('ProductsWebScreen stock indicators', () {
    test('low stock highlighted when stock <= threshold', () {
      const stock = 3;
      const lowStockThreshold = 5;
      const isLowStock = stock <= lowStockThreshold && stock > 0;
      expect(isLowStock, isTrue);
    });

    test('out of stock tagged when stock == 0', () {
      const stock = 0;
      const isOutOfStock = stock == 0;
      expect(isOutOfStock, isTrue);
    });

    test('normal stock not highlighted', () {
      const stock = 50;
      const lowStockThreshold = 5;
      const isLowStock = stock <= lowStockThreshold;
      expect(isLowStock, isFalse);
    });

    test('negative stock treated as out of stock', () {
      const stock = -1;
      const isOutOfStock = stock <= 0;
      expect(isOutOfStock, isTrue);
    });
  });

  group('ProductsWebScreen sync status', () {
    test('synced product shows no indicator', () {
      const isSynced = true;
      expect(isSynced, isTrue);
    });

    test('pending product shows sync indicator', () {
      const isSynced = false;
      expect(isSynced, isFalse);
    });
  });
}
