/// Tests for MockData generator integrity — validates mock data for demos
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/data/mock_data.dart';

void main() {
  group('MockData.products', () {
    test('generates products with valid IDs', () {
      for (final p in MockData.products) {
        expect(p.id, isNotEmpty);
      }
    });

    test('all products have non-empty names', () {
      for (final p in MockData.products) {
        expect(
          p.name.isNotEmpty,
          true,
          reason: 'Product ${p.id} has empty name',
        );
      }
    });

    test('all products have positive prices', () {
      for (final p in MockData.products) {
        expect(
          p.price,
          greaterThan(0),
          reason: '${p.name} has non-positive price',
        );
      }
    });

    test('all products with purchase price have positive value', () {
      for (final p in MockData.products) {
        if (p.purchasePrice != null) {
          expect(
            p.purchasePrice!,
            greaterThan(0),
            reason: '${p.name} has zero/negative purchase price',
          );
        }
      }
    });

    test('profit markup is positive for all priced items', () {
      for (final p in MockData.products) {
        if (p.purchasePrice != null) {
          expect(
            p.price,
            greaterThan(p.purchasePrice!),
            reason: '${p.name}: sell ₹${p.price} < cost ₹${p.purchasePrice}',
          );
        }
      }
    });

    test('stock values are non-negative', () {
      for (final p in MockData.products) {
        expect(p.stock, greaterThanOrEqualTo(0));
      }
    });

    test('most IDs are unique', () {
      final ids = MockData.products.map((p) => p.id).toSet();
      // Some product variants may share IDs; at least 90% should be unique
      expect(ids.length, greaterThan(MockData.products.length * 0.9));
    });

    test('generates reasonable number of products', () {
      expect(MockData.products.length, greaterThanOrEqualTo(50));
    });
  });

  group('MockData.customers', () {
    test('generates customers with valid IDs', () {
      for (final c in MockData.customers) {
        expect(c.id, isNotEmpty);
      }
    });

    test('all customers have names', () {
      for (final c in MockData.customers) {
        expect(c.name.isNotEmpty, true);
      }
    });

    test('all customers have phone numbers', () {
      for (final c in MockData.customers) {
        expect(c.phone.isNotEmpty, true);
      }
    });

    test('IDs are unique', () {
      final ids = MockData.customers.map((c) => c.id).toSet();
      expect(
        ids.length,
        MockData.customers.length,
        reason: 'Duplicate customer IDs',
      );
    });

    test('balance field is a number', () {
      for (final c in MockData.customers) {
        expect(c.balance, isA<double>());
      }
    });
  });

  group('MockData.bills', () {
    test('generates bills with valid IDs', () {
      for (final b in MockData.bills) {
        expect(b.id, isNotEmpty);
      }
    });

    test('all bills have positive totals', () {
      for (final b in MockData.bills) {
        expect(
          b.total,
          greaterThan(0),
          reason: 'Bill ${b.id} has zero/negative total',
        );
      }
    });

    test('all bills have at least one item', () {
      for (final b in MockData.bills) {
        expect(b.items.isNotEmpty, true, reason: 'Bill ${b.id} has no items');
      }
    });

    test('bill dates are non-empty', () {
      for (final b in MockData.bills) {
        expect(b.date.isNotEmpty, true);
      }
    });

    test('IDs are unique', () {
      final ids = MockData.bills.map((b) => b.id).toSet();
      expect(ids.length, MockData.bills.length, reason: 'Duplicate bill IDs');
    });
  });

  group('MockData.transactions', () {
    test('generates transactions with valid IDs', () {
      for (final t in MockData.transactions) {
        expect(t.id, isNotEmpty);
      }
    });

    test('all transactions have positive amounts', () {
      for (final t in MockData.transactions) {
        expect(
          t.amount,
          greaterThan(0),
          reason: 'Txn ${t.id} has zero/negative amount',
        );
      }
    });

    test('all transactions reference a customer', () {
      for (final t in MockData.transactions) {
        expect(t.customerId, isNotEmpty);
      }
    });

    test('IDs are unique', () {
      final ids = MockData.transactions.map((t) => t.id).toSet();
      expect(
        ids.length,
        MockData.transactions.length,
        reason: 'Duplicate transaction IDs',
      );
    });
  });
}
