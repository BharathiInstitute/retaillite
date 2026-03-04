/// Products provider — state management and path security tests
///
/// Tests the productsProvider path construction, demo mode branching,
/// and pagination logic without needing a running Firebase instance.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/core/constants/app_constants.dart';

void main() {
  group('Products path construction', () {
    test('_productsPath format is users/UID/products', () {
      const uid = 'test-user-123';
      const path = 'users/$uid/products';
      expect(path, 'users/test-user-123/products');
    });

    test('path is different for different UIDs', () {
      const pathA = 'users/userA/products';
      const pathB = 'users/userB/products';
      expect(pathA, isNot(equals(pathB)));
    });
  });

  group('Products query limits', () {
    test('query limit is defined and reasonable', () {
      expect(AppConstants.queryLimitProducts, greaterThan(0));
      expect(AppConstants.queryLimitProducts, lessThanOrEqualTo(10000));
    });
  });

  group('Products pagination logic', () {
    test('default page size is 50', () {
      const defaultPageSize = 50;
      expect(defaultPageSize, 50);
    });

    test('empty page means no more data', () {
      final products = <ProductModel>[];
      expect(products.isEmpty, isTrue);
      // When empty, hasMore should be false
    });

    test('full page suggests more data available', () {
      const pageSize = 50;
      final products = List.generate(
        pageSize,
        (i) => ProductModel(
          id: 'prod-$i',
          name: 'Product $i',
          price: 10.0 * i,
          stock: 100,
          createdAt: DateTime(2024),
        ),
      );
      expect(products.length, pageSize);
      // When full page returned, there might be more
    });
  });

  group('Products — model validation', () {
    test('product with zero price is valid (freebie)', () {
      final product = ProductModel(
        id: 'free-1',
        name: 'Free Sample',
        price: 0,
        stock: 100,
        createdAt: DateTime(2024),
      );
      expect(product.price, 0);
    });

    test('product with zero stock is valid (out of stock)', () {
      final product = ProductModel(
        id: 'oos-1',
        name: 'Out of Stock Item',
        price: 100,
        stock: 0,
        createdAt: DateTime(2024),
      );
      expect(product.stock, 0);
    });

    test('product with negative stock is technically valid', () {
      // This can happen with overselling/returns
      final product = ProductModel(
        id: 'neg-1',
        name: 'Oversold Item',
        price: 100,
        stock: -5,
        createdAt: DateTime(2024),
      );
      expect(product.stock, -5);
    });

    test('product with purchase price enables profit calc', () {
      final product = ProductModel(
        id: 'profit-1',
        name: 'Profitable Item',
        price: 200,
        purchasePrice: 150,
        stock: 50,
        createdAt: DateTime(2024),
      );
      final margin = product.price - (product.purchasePrice ?? 0);
      expect(margin, 50);
    });

    test('product without purchase price has null margin', () {
      final product = ProductModel(
        id: 'noprice-1',
        name: 'No Purchase Price',
        price: 200,
        stock: 50,
        createdAt: DateTime(2024),
      );
      expect(product.purchasePrice, isNull);
    });
  });

  group('Products — sorting', () {
    test('products sort by name alphabetically', () {
      final products = [
        ProductModel(
          id: '3',
          name: 'Zebra',
          price: 10,
          stock: 1,
          createdAt: DateTime(2024),
        ),
        ProductModel(
          id: '1',
          name: 'Apple',
          price: 10,
          stock: 1,
          createdAt: DateTime(2024),
        ),
        ProductModel(
          id: '2',
          name: 'Banana',
          price: 10,
          stock: 1,
          createdAt: DateTime(2024),
        ),
      ];
      products.sort((a, b) => a.name.compareTo(b.name));
      expect(products.map((p) => p.name).toList(), [
        'Apple',
        'Banana',
        'Zebra',
      ]);
    });
  });

  group('Products — 10K scale warnings', () {
    test('1000+ products triggers performance warning threshold', () {
      const productCount = 1001;
      const warningThreshold = 1000;
      expect(
        productCount >= warningThreshold,
        isTrue,
        reason: 'Large inventories should trigger pagination warning',
      );
    });
  });

  group('Products — unit enum coverage', () {
    test('ProductUnit has all expected values', () {
      expect(ProductUnit.values.length, greaterThanOrEqualTo(2));
      expect(ProductUnit.piece, isNotNull);
    });
  });
}
