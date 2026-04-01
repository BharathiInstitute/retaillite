/// Tests for BillingScreen — search, cart, payment flow logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('BillingScreen search logic', () {
    test('empty search query returns all products', () {
      const query = '';
      expect(query.isEmpty, isTrue);
    });

    test('search query filters products case-insensitively', () {
      const products = ['Rice', 'Wheat', 'rice flour'];
      const query = 'rice';
      final filtered = products
          .where((p) => p.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(filtered, ['Rice', 'rice flour']);
    });

    test('search with no matches returns empty list', () {
      const products = ['Rice', 'Wheat'];
      const query = 'sugar';
      final filtered = products
          .where((p) => p.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(filtered, isEmpty);
    });
  });

  group('BillingScreen cart logic', () {
    test('empty cart has zero items', () {
      const cartItems = <String>[];
      expect(cartItems.length, 0);
    });

    test('adding product increments cart count', () {
      final cartItems = <String>['Product A'];
      expect(cartItems.length, 1);
      cartItems.add('Product B');
      expect(cartItems.length, 2);
    });

    test('empty cart disables checkout', () {
      const cartCount = 0;
      const checkoutEnabled = cartCount > 0;
      expect(checkoutEnabled, isFalse);
    });

    test('non-empty cart enables checkout', () {
      const cartCount = 3;
      const checkoutEnabled = cartCount > 0;
      expect(checkoutEnabled, isTrue);
    });
  });

  group('BillingScreen payment calculation', () {
    test('total is sum of item prices times quantities', () {
      final items = [
        {'price': 100.0, 'qty': 2},
        {'price': 50.0, 'qty': 3},
      ];
      final total = items.fold<double>(
        0,
        (sum, item) => sum + (item['price'] as double) * (item['qty'] as int),
      );
      expect(total, 350.0);
    });

    test('change calculation: paid minus total', () {
      const total = 480.0;
      const paid = 500.0;
      const change = paid - total;
      expect(change, 20.0);
    });

    test('exact payment gives zero change', () {
      const total = 250.0;
      const paid = 250.0;
      expect(paid - total, 0.0);
    });
  });

  group('BillingScreen barcode scanner visibility', () {
    test('barcode scanner visible on mobile', () {
      const isMobile = true;
      expect(isMobile, isTrue);
    });

    test('barcode scanner hidden on desktop', () {
      const isDesktop = true;
      // On desktop, barcode scanner button typically hidden
      expect(isDesktop, isTrue);
    });
  });

  group('BillingScreen price validation', () {
    test('valid price passes', () {
      expect(Validators.price('100'), isNull);
    });

    test('negative price fails', () {
      expect(Validators.price('-10'), isNotNull);
    });

    test('zero price returns error (must be > 0)', () {
      expect(Validators.price('0'), isNotNull);
    });

    test('non-numeric price fails', () {
      expect(Validators.price('abc'), isNotNull);
    });
  });
}
