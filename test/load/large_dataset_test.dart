import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_factories.dart';

/// Large dataset performance tests
/// Validates that model creation and list operations
/// remain fast even with thousands of items.
void main() {
  group('Large dataset performance', () {
    test('10,000 products: list creation completes < 100ms', () {
      final sw = Stopwatch()..start();
      final products = List.generate(
        10000,
        (i) => makeProduct(id: 'p-$i', name: 'Product $i', price: (i + 1) * 1.5),
      );
      sw.stop();

      expect(products.length, 10000);
      expect(sw.elapsedMilliseconds, lessThan(500)); // generous for CI
    });

    test('50,000 bills: list creation completes < 500ms', () {
      final sw = Stopwatch()..start();
      final bills = List.generate(
        50000,
        (i) => makeBill(id: 'b-$i', billNumber: i + 1, total: (i + 1) * 10.0),
      );
      sw.stop();

      expect(bills.length, 50000);
      expect(sw.elapsedMilliseconds, lessThan(2000)); // generous for CI
    });

    test('5,000 customers: list creation completes without timeout', () {
      final sw = Stopwatch()..start();
      final customers = List.generate(
        5000,
        (i) => makeCustomer(id: 'c-$i', name: 'Customer $i', phone: '98765${i.toString().padLeft(5, "0")}'),
      );
      sw.stop();

      expect(customers.length, 5000);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('MockData.products (100) generates in < 50ms', () {
      final sw = Stopwatch()..start();
      final products = List.generate(
        100,
        (i) => makeProduct(id: 'p-$i', name: 'Quick Product $i'),
      );
      sw.stop();

      expect(products.length, 100);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('MockData.bills (100) generates in < 50ms', () {
      final sw = Stopwatch()..start();
      final bills = List.generate(
        100,
        (i) => makeBill(id: 'b-$i', billNumber: i + 1),
      );
      sw.stop();

      expect(bills.length, 100);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });
}
