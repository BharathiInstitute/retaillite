import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  late CartNotifier cart;

  final productA = ProductModel(
    id: 'p1',
    name: 'Rice 1kg',
    price: 60.0,
    stock: 100,
    unit: ProductUnit.kg,
    createdAt: DateTime(2024),
  );

  final productB = ProductModel(
    id: 'p2',
    name: 'Sugar 500g',
    price: 40.0,
    stock: 50,
    createdAt: DateTime(2024),
  );

  setUp(() {
    cart = CartNotifier();
  });

  group('CartState', () {
    test('should start empty', () {
      expect(cart.state.isEmpty, true);
      expect(cart.state.isNotEmpty, false);
      expect(cart.state.total, 0.0);
      expect(cart.state.itemCount, 0);
      expect(cart.state.customerId, isNull);
      expect(cart.state.customerName, isNull);
    });
  });

  group('addProduct', () {
    test('should add a new product', () {
      cart.addProduct(productA);

      expect(cart.state.items.length, 1);
      expect(cart.state.items.first.productId, 'p1');
      expect(cart.state.items.first.name, 'Rice 1kg');
      expect(cart.state.items.first.price, 60.0);
      expect(cart.state.items.first.quantity, 1);
      expect(cart.state.items.first.unit, 'kg');
    });

    test('should add multiple different products', () {
      cart.addProduct(productA);
      cart.addProduct(productB);

      expect(cart.state.items.length, 2);
      expect(cart.state.total, 100.0); // 60 + 40
      expect(cart.state.itemCount, 2);
    });

    test('should increment quantity for existing product', () {
      cart.addProduct(productA);
      cart.addProduct(productA);

      expect(cart.state.items.length, 1); // still 1 item
      expect(cart.state.items.first.quantity, 2);
      expect(cart.state.total, 120.0); // 60 * 2
      expect(cart.state.itemCount, 2);
    });

    test('should add with custom quantity', () {
      cart.addProduct(productA, quantity: 5);

      expect(cart.state.items.first.quantity, 5);
      expect(cart.state.total, 300.0); // 60 * 5
    });

    test('should accumulate quantity on repeated adds', () {
      cart.addProduct(productA, quantity: 3);
      cart.addProduct(productA, quantity: 2);

      expect(cart.state.items.length, 1);
      expect(cart.state.items.first.quantity, 5);
      expect(cart.state.total, 300.0);
    });
  });

  group('updateQuantity', () {
    test('should update item quantity', () {
      cart.addProduct(productA);
      cart.updateQuantity('p1', 10);

      expect(cart.state.items.first.quantity, 10);
      expect(cart.state.total, 600.0);
    });

    test('should remove item when quantity set to 0', () {
      cart.addProduct(productA);
      cart.updateQuantity('p1', 0);

      expect(cart.state.isEmpty, true);
    });

    test('should remove item when quantity set to negative', () {
      cart.addProduct(productA);
      cart.updateQuantity('p1', -1);

      expect(cart.state.isEmpty, true);
    });
  });

  group('incrementQuantity / decrementQuantity', () {
    test('should increment by 1', () {
      cart.addProduct(productA);
      cart.incrementQuantity('p1');

      expect(cart.state.items.first.quantity, 2);
    });

    test('should decrement by 1', () {
      cart.addProduct(productA, quantity: 3);
      cart.decrementQuantity('p1');

      expect(cart.state.items.first.quantity, 2);
    });

    test('should remove item when decremented to 0', () {
      cart.addProduct(productA);
      cart.decrementQuantity('p1');

      expect(cart.state.isEmpty, true);
    });
  });

  group('removeItem', () {
    test('should remove specific item', () {
      cart.addProduct(productA);
      cart.addProduct(productB);
      cart.removeItem('p1');

      expect(cart.state.items.length, 1);
      expect(cart.state.items.first.productId, 'p2');
    });

    test('should handle removing non-existent item', () {
      cart.addProduct(productA);
      cart.removeItem('non-existent');

      expect(cart.state.items.length, 1); // unchanged
    });
  });

  group('customer management', () {
    test('should set customer', () {
      cart.setCustomer('cust-1', 'Rahul Sharma');

      expect(cart.state.customerId, 'cust-1');
      expect(cart.state.customerName, 'Rahul Sharma');
    });

    test('should clear customer but keep items', () {
      cart.addProduct(productA);
      cart.setCustomer('cust-1', 'Rahul');
      cart.clearCustomer();

      expect(cart.state.customerId, isNull);
      expect(cart.state.customerName, isNull);
      expect(cart.state.items.length, 1); // items preserved
    });
  });

  group('clearCart', () {
    test('should clear everything', () {
      cart.addProduct(productA);
      cart.addProduct(productB);
      cart.setCustomer('cust-1', 'Test');
      cart.clearCart();

      expect(cart.state.isEmpty, true);
      expect(cart.state.customerId, isNull);
      expect(cart.state.customerName, isNull);
      expect(cart.state.total, 0.0);
    });
  });

  group('total calculations', () {
    test('should calculate correct total with mixed items', () {
      cart.addProduct(productA, quantity: 3); // 60 * 3 = 180
      cart.addProduct(productB, quantity: 2); // 40 * 2 = 80

      expect(cart.state.total, 260.0);
      expect(cart.state.itemCount, 5); // 3 + 2
    });

    test('should update total after quantity change', () {
      cart.addProduct(productA, quantity: 2); // 120
      expect(cart.state.total, 120.0);

      cart.updateQuantity('p1', 5); // 300
      expect(cart.state.total, 300.0);
    });

    test('should update total after item removal', () {
      cart.addProduct(productA); // 60
      cart.addProduct(productB); // 40
      expect(cart.state.total, 100.0);

      cart.removeItem('p1');
      expect(cart.state.total, 40.0);
    });
  });
}
