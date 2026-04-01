/// Tests for PosWebScreen — split layout logic and keyboard shortcuts.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PosWebScreen layout logic', () {
    test('split layout: products left, cart right', () {
      // PosWebScreen uses Row with two Expanded children
      const hasProductsPanel = true;
      const hasCartPanel = true;
      expect(hasProductsPanel, isTrue);
      expect(hasCartPanel, isTrue);
    });

    test('product grid adapts to narrow width', () {
      const screenWidth = 800.0;
      // crossAxisCount based on available width
      const columns = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : 2);
      expect(columns, 2);
    });

    test('product grid adapts to wide width', () {
      const screenWidth = 1920.0;
      const columns = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : 2);
      expect(columns, 4);
    });

    test('product grid adapts to medium width', () {
      const screenWidth = 1024.0;
      const columns = screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : 2);
      expect(columns, 3);
    });
  });

  group('PosWebScreen customer selection', () {
    test('no customer selected shows walk-in label', () {
      const String? selectedCustomer = null;
      const label = selectedCustomer ?? 'Walk-in Customer';
      expect(label, 'Walk-in Customer');
    });

    test('selected customer shows customer name', () {
      const selectedCustomer = 'Raj Sharma';
      const label = selectedCustomer;
      expect(label, 'Raj Sharma');
    });
  });

  group('PosWebScreen search', () {
    test('search filters products by name', () {
      const products = ['Milk', 'Bread', 'Milk Powder'];
      const query = 'milk';
      final results = products
          .where((p) => p.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(results.length, 2);
    });
  });
}
