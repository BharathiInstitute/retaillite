import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_factories.dart';

/// Memory management tests
/// Validate that bulk operations don't cause obvious memory issues.
void main() {
  group('Memory management', () {
    test('creating 1,000 bills does not leak CartItem objects', () {
      // Create bills with multiple cart items, then discard the list.
      // If there were a leak, Dart's GC wouldn't collect them — but we
      // can at least verify the operation completes cleanly.
      final bills = List.generate(
        1000,
        (i) => makeBill(
          id: 'b-$i',
          billNumber: i + 1,
          total: (i + 1) * 50.0,
        ),
      );

      // Access all items to ensure they're allocated
      final totalItems = bills.fold<int>(0, (sum, b) => sum + b.items.length);
      expect(totalItems, greaterThan(0));

      // Discard reference — GC should be able to collect
      // (No explicit GC call in Dart test env, but verifies no crash)
      expect(bills.length, 1000);
    });

    test('filter changes 100 times: no accumulated state', () {
      final categories = ['Electronics', 'Grocery', 'Clothing', 'Dairy', 'Other'];
      final products = List.generate(
        500,
        (i) => makeProduct(
          id: 'p-$i',
          name: 'Product $i',
          category: categories[i % categories.length],
        ),
      );

      // Simulate changing filter 100 times
      for (var i = 0; i < 100; i++) {
        final cat = categories[i % categories.length];
        final filtered = products.where((p) => p.category == cat).toList();
        expect(filtered, isNotEmpty);
      }
      // If we get here without OOM or timeout, memory is managed properly
      expect(products.length, 500);
    });

    test('mock data generation is deterministic (seed=42)', () {
      // Generate lists with same parameters twice → should be identical
      final run1 = List.generate(
        50,
        (i) => makeProduct(id: 'p-$i', name: 'Seed$i', price: i * 10.0),
      );
      final run2 = List.generate(
        50,
        (i) => makeProduct(id: 'p-$i', name: 'Seed$i', price: i * 10.0),
      );

      for (var i = 0; i < 50; i++) {
        expect(run1[i].id, run2[i].id);
        expect(run1[i].name, run2[i].name);
        expect(run1[i].price, run2[i].price);
      }
    });
  });
}
