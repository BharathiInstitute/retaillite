/// Extended ProductModel & CustomerModel tests
///
/// Testing computed properties, sentinel copyWith, edge cases for
/// stock management & Khata overdue logic at scale.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/models/customer_model.dart';
import '../helpers/test_factories.dart';

void main() {
  // ── ProductUnit ──

  group('ProductUnit', () {
    test('fromString parses name correctly', () {
      expect(ProductUnit.fromString('piece'), ProductUnit.piece);
      expect(ProductUnit.fromString('kg'), ProductUnit.kg);
      expect(ProductUnit.fromString('gram'), ProductUnit.gram);
      expect(ProductUnit.fromString('liter'), ProductUnit.liter);
      expect(ProductUnit.fromString('ml'), ProductUnit.ml);
      expect(ProductUnit.fromString('pack'), ProductUnit.pack);
      expect(ProductUnit.fromString('box'), ProductUnit.box);
      expect(ProductUnit.fromString('dozen'), ProductUnit.dozen);
    });

    test('fromString falls back to unknown for invalid value', () {
      expect(ProductUnit.fromString('barrel'), ProductUnit.unknown);
      expect(ProductUnit.fromString(''), ProductUnit.unknown);
    });

    test('all units have displayName and shortName', () {
      for (final unit in ProductUnit.values) {
        expect(unit.displayName, isNotEmpty);
        expect(unit.shortName, isNotEmpty);
      }
    });

    test('fromString can match by shortName', () {
      expect(ProductUnit.fromString('pcs'), ProductUnit.piece);
      expect(ProductUnit.fromString('g'), ProductUnit.gram);
      expect(ProductUnit.fromString('L'), ProductUnit.liter);
    });
  });

  // ── ProductModel computed properties ──

  group('ProductModel computed properties', () {
    test('isLowStock is true when stock <= lowStockAlert', () {
      final product = makeProduct(stock: 5, lowStockAlert: 10);
      expect(product.isLowStock, true);
    });

    test('isLowStock is true when stock == lowStockAlert', () {
      final product = makeProduct(stock: 10, lowStockAlert: 10);
      expect(product.isLowStock, true);
    });

    test('isLowStock is false when stock > lowStockAlert', () {
      final product = makeProduct(stock: 15, lowStockAlert: 10);
      expect(product.isLowStock, false);
    });

    test('isLowStock is false when lowStockAlert is null', () {
      final product = makeProduct(stock: 0);
      expect(product.isLowStock, false);
    });

    test('isOutOfStock is true when stock is 0', () {
      final product = makeProduct(stock: 0);
      expect(product.isOutOfStock, true);
    });

    test('isOutOfStock is true when stock is negative', () {
      final product = makeProduct(stock: -1);
      expect(product.isOutOfStock, true);
    });

    test('isOutOfStock is false when stock > 0', () {
      final product = makeProduct(stock: 1);
      expect(product.isOutOfStock, false);
    });

    test('profit calculates correctly', () {
      final product = makeProduct(purchasePrice: 60);
      expect(product.profit, 40.0);
    });

    test('profit is null when purchasePrice is null', () {
      final product = makeProduct();
      expect(product.profit, isNull);
    });

    test('profit can be negative (selling at loss)', () {
      final product = makeProduct(price: 50, purchasePrice: 80);
      expect(product.profit, -30.0);
    });

    test('profitPercentage calculates correctly', () {
      final product = makeProduct(price: 120, purchasePrice: 100);
      expect(product.profitPercentage, 20.0);
    });

    test('profitPercentage is null when no purchasePrice', () {
      final product = makeProduct();
      expect(product.profitPercentage, isNull);
    });

    test('profitPercentage is null when purchasePrice is 0', () {
      final product = makeProduct(purchasePrice: 0);
      expect(product.profitPercentage, isNull);
    });
  });

  // ── ProductModel copyWith with sentinel ──

  group('ProductModel copyWith sentinel pattern', () {
    test('preserves nullable fields when not specified', () {
      final product = makeProduct(
        purchasePrice: 80,
        barcode: '123456',
        category: 'Grocery',
      );
      final updated = product.copyWith(name: 'Changed');

      expect(updated.purchasePrice, 80);
      expect(updated.barcode, '123456');
      expect(updated.category, 'Grocery');
    });

    test('can clear nullable field to null', () {
      final product = makeProduct(
        purchasePrice: 80,
        barcode: '123456',
        category: 'Grocery',
      );
      final updated = product.copyWith(
        purchasePrice: null,
        barcode: null,
        category: null,
      );

      expect(updated.purchasePrice, isNull);
      expect(updated.barcode, isNull);
      expect(updated.category, isNull);
    });

    test('can set nullable field from null to value', () {
      final product = makeProduct();
      final updated = product.copyWith(purchasePrice: 50.0, barcode: '999888');

      expect(updated.purchasePrice, 50.0);
      expect(updated.barcode, '999888');
    });

    test('preserves id and createdAt', () {
      final product = makeProduct(id: 'p-fixed');
      final updated = product.copyWith(name: 'New Name');

      expect(updated.id, 'p-fixed');
      expect(updated.createdAt, product.createdAt);
    });

    test('sets updatedAt on copyWith', () {
      final product = makeProduct();
      final updated = product.copyWith(stock: 99);
      expect(updated.updatedAt, isNotNull);
    });
  });

  // ── CustomerModel computed properties ──

  group('CustomerModel', () {
    test('hasDue is true when balance > 0', () {
      final customer = makeCustomer(balance: 500);
      expect(customer.hasDue, true);
    });

    test('hasDue is false when balance is 0', () {
      final customer = makeCustomer();
      expect(customer.hasDue, false);
    });

    test('hasDue is false when balance is negative', () {
      final customer = makeCustomer(balance: -100);
      expect(customer.hasDue, false);
    });

    test('daysSinceLastTransaction is null when no transaction', () {
      final customer = makeCustomer();
      expect(customer.daysSinceLastTransaction, isNull);
    });

    test('daysSinceLastTransaction calculates correctly', () {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final customer = makeCustomer(lastTransactionAt: thirtyDaysAgo);
      expect(customer.daysSinceLastTransaction, 30);
    });

    test('daysSinceLastTransaction is 0 for today', () {
      final customer = makeCustomer(lastTransactionAt: DateTime.now());
      expect(customer.daysSinceLastTransaction, 0);
    });

    test('isOverdue uses 30-day default threshold', () {
      final recentCustomer = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 29)),
      );
      expect(recentCustomer.isOverdue, false);

      final overdueCustomer = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 31)),
      );
      expect(overdueCustomer.isOverdue, true);
    });

    test('isOverdueAfter uses custom threshold', () {
      final customer = makeCustomer(
        lastTransactionAt: DateTime.now().subtract(const Duration(days: 15)),
      );
      expect(customer.isOverdueAfter(10), true);
      expect(customer.isOverdueAfter(20), false);
    });

    test('isOverdueAfter returns false when no last transaction', () {
      final customer = makeCustomer();
      expect(customer.isOverdueAfter(30), false);
    });

    test('defaultOverdueDays constant is 30', () {
      expect(CustomerModel.defaultOverdueDays, 30);
    });

    test('copyWith preserves id and createdAt', () {
      final customer = makeCustomer(id: 'c-fixed', name: 'Original');
      final updated = customer.copyWith(name: 'Changed');

      expect(updated.id, 'c-fixed');
      expect(updated.name, 'Changed');
      expect(updated.createdAt, customer.createdAt);
    });

    test('copyWith sets updatedAt', () {
      final customer = makeCustomer();
      final updated = customer.copyWith(balance: 100);
      expect(updated.updatedAt, isNotNull);
    });

    test('copyWith updates balance', () {
      final customer = makeCustomer();
      final withDebt = customer.copyWith(balance: 1500);
      expect(withDebt.balance, 1500);
      expect(withDebt.hasDue, true);
    });
  });

  // ── Scale: 10K subscribers with products ──

  group('Scale: product catalog', () {
    test('100 products can be created and checked', () {
      final products = List.generate(
        100,
        (i) => makeProduct(
          id: 'p-$i',
          name: 'Product $i',
          stock: i,
          lowStockAlert: 10,
          price: 100.0 + i,
          purchasePrice: 60.0 + i,
        ),
      );

      final lowStock = products.where((p) => p.isLowStock).length;
      expect(lowStock, 11); // stock 0-10 inclusive

      final outOfStock = products.where((p) => p.isOutOfStock).length;
      expect(outOfStock, 1); // stock 0 only

      final profitable = products
          .where((p) => p.profit != null && p.profit! > 0)
          .length;
      expect(profitable, 100); // all have purchase price
    });
  });

  group('Scale: customer khata', () {
    test('overdue customers can be filtered', () {
      final customers = List.generate(10, (i) {
        return makeCustomer(
          id: 'c-$i',
          name: 'Customer $i',
          balance: i * 100.0,
          lastTransactionAt: DateTime.now().subtract(Duration(days: i * 10)),
        );
      });

      final withDue = customers.where((c) => c.hasDue).length;
      expect(withDue, 9); // all except balance=0

      final overdue = customers.where((c) => c.isOverdue).length;
      expect(overdue, greaterThanOrEqualTo(4)); // days > 30
    });
  });
}
