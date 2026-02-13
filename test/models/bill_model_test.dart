import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  group('CartItem', () {
    test('should create cart item with required fields', () {
      const item = CartItem(
        productId: 'prod-1',
        name: 'Test Product',
        price: 50.0,
        quantity: 2,
        unit: 'pc',
      );

      expect(item.productId, 'prod-1');
      expect(item.name, 'Test Product');
      expect(item.price, 50.0);
      expect(item.quantity, 2);
      expect(item.unit, 'pc');
    });

    test('should calculate total correctly', () {
      const item = CartItem(
        productId: 'prod-1',
        name: 'Test Product',
        price: 50.0,
        quantity: 3,
        unit: 'pc',
      );

      expect(item.total, 150.0);
    });

    test('should copy with new quantity', () {
      const item = CartItem(
        productId: 'prod-1',
        name: 'Test Product',
        price: 50.0,
        quantity: 2,
        unit: 'pc',
      );

      final updated = item.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(updated.productId, 'prod-1');
      expect(updated.name, 'Test Product');
      expect(updated.total, 250.0);
    });

    test('should serialize to map correctly', () {
      const item = CartItem(
        productId: 'prod-1',
        name: 'Test Product',
        price: 50.0,
        quantity: 2,
        unit: 'kg',
      );

      final map = item.toMap();

      expect(map['productId'], 'prod-1');
      expect(map['name'], 'Test Product');
      expect(map['price'], 50.0);
      expect(map['quantity'], 2);
      expect(map['unit'], 'kg');
    });

    test('should deserialize from map correctly', () {
      final map = {
        'productId': 'prod-1',
        'name': 'Test Product',
        'price': 50.0,
        'quantity': 2,
        'unit': 'kg',
      };

      final item = CartItem.fromMap(map);

      expect(item.productId, 'prod-1');
      expect(item.name, 'Test Product');
      expect(item.price, 50.0);
      expect(item.quantity, 2);
      expect(item.unit, 'kg');
    });
  });

  group('BillModel', () {
    test('should create bill with required fields', () {
      final bill = BillModel(
        id: 'bill-1',
        billNumber: 101,
        items: const [
          CartItem(
            productId: 'prod-1',
            name: 'Product 1',
            price: 100.0,
            quantity: 2,
            unit: 'pc',
          ),
        ],
        total: 200.0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );

      expect(bill.id, 'bill-1');
      expect(bill.billNumber, 101);
      expect(bill.items.length, 1);
      expect(bill.total, 200.0);
      expect(bill.paymentMethod, PaymentMethod.cash);
    });

    test('should calculate change amount correctly', () {
      final bill = BillModel(
        id: 'bill-1',
        billNumber: 101,
        items: const [],
        total: 150.0,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 200.0,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );

      expect(bill.changeAmount, 50.0);
    });

    test('should return null change when no received amount', () {
      final bill = BillModel(
        id: 'bill-1',
        billNumber: 101,
        items: const [],
        total: 150.0,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );

      expect(bill.changeAmount, isNull);
    });

    test('should calculate item count correctly', () {
      final bill = BillModel(
        id: 'bill-1',
        billNumber: 101,
        items: const [
          CartItem(
            productId: 'prod-1',
            name: 'Product 1',
            price: 100.0,
            quantity: 2,
            unit: 'pc',
          ),
          CartItem(
            productId: 'prod-2',
            name: 'Product 2',
            price: 50.0,
            quantity: 3,
            unit: 'pc',
          ),
        ],
        total: 350.0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );

      expect(bill.itemCount, 5); // 2 + 3
    });
  });

  group('PaymentMethod', () {
    test('should have correct display names', () {
      expect(PaymentMethod.cash.displayName, 'Cash');
      expect(PaymentMethod.upi.displayName, 'UPI');
      expect(PaymentMethod.udhar.displayName, 'Credit');
    });

    test('should have correct emojis', () {
      expect(PaymentMethod.cash.emoji, '💵');
      expect(PaymentMethod.upi.emoji, '📱');
      expect(PaymentMethod.udhar.emoji, '💳');
    });

    test('should parse from string correctly', () {
      expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('upi'), PaymentMethod.upi);
      expect(PaymentMethod.fromString('udhar'), PaymentMethod.udhar);
      expect(
        PaymentMethod.fromString('unknown_value'),
        PaymentMethod.unknown,
      ); // default fallback for unknown values
    });
  });
}
