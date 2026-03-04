/// Cart provider tests — CartState, CartNotifier, billing cart logic
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  // ── CartState ──

  group('CartState', () {
    test('default is empty', () {
      const state = CartState();
      expect(state.items, isEmpty);
      expect(state.customerId, isNull);
      expect(state.customerName, isNull);
      expect(state.isEmpty, true);
      expect(state.isNotEmpty, false);
      expect(state.total, 0);
      expect(state.itemCount, 0);
    });

    test('total sums item totals', () {
      const state = CartState(
        items: [
          CartItem(
            productId: 'p1',
            name: 'A',
            price: 10,
            quantity: 2,
            unit: 'pcs',
          ),
          CartItem(
            productId: 'p2',
            name: 'B',
            price: 20,
            quantity: 3,
            unit: 'pcs',
          ),
        ],
      );
      expect(state.total, 80); // 10*2 + 20*3
    });

    test('itemCount sums quantities', () {
      const state = CartState(
        items: [
          CartItem(
            productId: 'p1',
            name: 'A',
            price: 10,
            quantity: 2,
            unit: 'pcs',
          ),
          CartItem(
            productId: 'p2',
            name: 'B',
            price: 20,
            quantity: 3,
            unit: 'pcs',
          ),
        ],
      );
      expect(state.itemCount, 5);
    });

    test('copyWith preserves fields', () {
      const state = CartState(
        items: [
          CartItem(
            productId: 'p1',
            name: 'A',
            price: 10,
            quantity: 1,
            unit: 'pcs',
          ),
        ],
        customerId: 'c1',
        customerName: 'Rahul',
      );
      final copy = state.copyWith();
      expect(copy.items.length, 1);
      expect(copy.customerId, 'c1');
      expect(copy.customerName, 'Rahul');
    });

    test('copyWith overrides items', () {
      const state = CartState();
      final copy = state.copyWith(
        items: [
          const CartItem(
            productId: 'p1',
            name: 'A',
            price: 50,
            quantity: 1,
            unit: 'pcs',
          ),
        ],
      );
      expect(copy.items.length, 1);
      expect(copy.total, 50);
    });

    test('clearCustomer removes customer but keeps items', () {
      const state = CartState(
        items: [
          CartItem(
            productId: 'p1',
            name: 'A',
            price: 10,
            quantity: 1,
            unit: 'pcs',
          ),
        ],
        customerId: 'c1',
        customerName: 'Rahul',
      );
      final cleared = state.clearCustomer();
      expect(cleared.items.length, 1);
      expect(cleared.customerId, isNull);
      expect(cleared.customerName, isNull);
    });
  });

  // ── CartNotifier ──

  group('CartNotifier', () {
    late CartNotifier notifier;

    ProductModel makeProduct({
      String id = 'p1',
      String name = 'Product',
      double price = 100,
      ProductUnit unit = ProductUnit.piece,
    }) {
      return ProductModel(
        id: id,
        name: name,
        price: price,
        stock: 10,
        unit: unit,
        createdAt: DateTime(2024),
      );
    }

    setUp(() {
      notifier = CartNotifier();
    });

    test('initial state is empty', () {
      expect(notifier.state.isEmpty, true);
      expect(notifier.state.total, 0);
    });

    test('addProduct adds new item', () {
      notifier.addProduct(makeProduct(name: 'Rice', price: 50));
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.name, 'Rice');
      expect(notifier.state.items.first.price, 50);
      expect(notifier.state.items.first.quantity, 1);
    });

    test('addProduct increments quantity for existing product', () {
      final product = makeProduct();
      notifier.addProduct(product);
      notifier.addProduct(product);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.quantity, 2);
    });

    test('addProduct with custom quantity', () {
      notifier.addProduct(makeProduct(), quantity: 5);
      expect(notifier.state.items.first.quantity, 5);
    });

    test('addProduct uses product unit shortName', () {
      notifier.addProduct(makeProduct(unit: ProductUnit.kg));
      expect(notifier.state.items.first.unit, 'kg');
    });

    test('addProduct caps at max quantity', () {
      notifier.addProduct(makeProduct(), quantity: 9999);
      notifier.addProduct(makeProduct()); // try to go above 9999
      expect(notifier.state.items.first.quantity, 9999);
    });

    test('updateQuantity changes item quantity', () {
      notifier.addProduct(makeProduct());
      notifier.updateQuantity('p1', 5);
      expect(notifier.state.items.first.quantity, 5);
    });

    test('updateQuantity with zero removes item', () {
      notifier.addProduct(makeProduct());
      notifier.updateQuantity('p1', 0);
      expect(notifier.state.isEmpty, true);
    });

    test('updateQuantity clamps to max', () {
      notifier.addProduct(makeProduct());
      notifier.updateQuantity('p1', 99999);
      expect(notifier.state.items.first.quantity, 9999);
    });

    test('incrementQuantity adds 1', () {
      notifier.addProduct(makeProduct());
      notifier.incrementQuantity('p1');
      expect(notifier.state.items.first.quantity, 2);
    });

    test('incrementQuantity no-op for non-existent product', () {
      notifier.incrementQuantity('nonexistent');
      expect(notifier.state.isEmpty, true);
    });

    test('decrementQuantity subtracts 1', () {
      notifier.addProduct(makeProduct(), quantity: 3);
      notifier.decrementQuantity('p1');
      expect(notifier.state.items.first.quantity, 2);
    });

    test('decrementQuantity to 0 removes item', () {
      notifier.addProduct(makeProduct());
      notifier.decrementQuantity('p1');
      expect(notifier.state.isEmpty, true);
    });

    test('removeItem removes specified product', () {
      notifier.addProduct(makeProduct(name: 'A'));
      notifier.addProduct(makeProduct(id: 'p2', name: 'B'));
      notifier.removeItem('p1');
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.productId, 'p2');
    });

    test('removeItem no-op for non-existent product', () {
      notifier.addProduct(makeProduct());
      notifier.removeItem('nonexistent');
      expect(notifier.state.items.length, 1);
    });

    test('setCustomer updates customer info', () {
      notifier.setCustomer('c1', 'Rahul');
      expect(notifier.state.customerId, 'c1');
      expect(notifier.state.customerName, 'Rahul');
    });

    test('clearCustomer removes customer', () {
      notifier.setCustomer('c1', 'Rahul');
      notifier.clearCustomer();
      expect(notifier.state.customerId, isNull);
      expect(notifier.state.customerName, isNull);
    });

    test('clearCart resets everything', () {
      notifier.addProduct(makeProduct());
      notifier.setCustomer('c1', 'Rahul');
      notifier.clearCart();
      expect(notifier.state.isEmpty, true);
      expect(notifier.state.customerId, isNull);
    });

    test('total updates correctly as items change', () {
      notifier.addProduct(makeProduct(price: 30));
      notifier.addProduct(makeProduct(id: 'p2', price: 50));
      expect(notifier.state.total, 80);
      notifier.updateQuantity('p1', 3);
      expect(notifier.state.total, 140); // 30*3 + 50*1
      notifier.removeItem('p2');
      expect(notifier.state.total, 90); // 30*3
    });

    test('multiple products with different units', () {
      notifier.addProduct(makeProduct(unit: ProductUnit.kg));
      notifier.addProduct(makeProduct(id: 'p2', unit: ProductUnit.liter));
      expect(notifier.state.items[0].unit, 'kg');
      expect(notifier.state.items[1].unit, 'L');
    });
  });
}
