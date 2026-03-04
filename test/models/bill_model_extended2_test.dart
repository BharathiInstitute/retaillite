/// Extended bill model tests — edge cases, serialization, copyWith
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  // ── CartItem edge cases ──

  group('CartItem.fromMap edge cases', () {
    test('handles empty map with defaults', () {
      final item = CartItem.fromMap({});
      expect(item.productId, '');
      expect(item.name, '');
      expect(item.price, 0.0);
      expect(item.quantity, 1);
      expect(item.unit, 'pcs');
    });

    test('handles numeric types gracefully', () {
      final item = CartItem.fromMap({
        'productId': 'p1',
        'name': 'Rice',
        'price': 45, // int instead of double
        'quantity': 2,
        'unit': 'kg',
      });
      expect(item.price, 45.0);
      expect(item.quantity, 2);
    });

    test('toMap roundtrip preserves data', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Sugar',
        price: 40.5,
        quantity: 3,
        unit: 'kg',
      );
      final map = item.toMap();
      final restored = CartItem.fromMap(map);
      expect(restored.productId, 'p1');
      expect(restored.name, 'Sugar');
      expect(restored.price, 40.5);
      expect(restored.quantity, 3);
      expect(restored.unit, 'kg');
    });

    test('total is zero for zero price', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Free Sample',
        price: 0,
        quantity: 5,
        unit: 'pcs',
      );
      expect(item.total, 0);
    });

    test('copyWith preserves all fields when no args', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Oil',
        price: 120,
        quantity: 2,
        unit: 'L',
      );
      final copy = item.copyWith();
      expect(copy.productId, 'p1');
      expect(copy.name, 'Oil');
      expect(copy.price, 120);
      expect(copy.quantity, 2);
      expect(copy.unit, 'L');
    });
  });

  // ── PaymentMethod edge cases ──

  group('PaymentMethod.fromString', () {
    test('parses all known values', () {
      expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('upi'), PaymentMethod.upi);
      expect(PaymentMethod.fromString('udhar'), PaymentMethod.udhar);
      expect(PaymentMethod.fromString('unknown'), PaymentMethod.unknown);
    });

    test('falls back to unknown for invalid values', () {
      expect(PaymentMethod.fromString('bitcoin'), PaymentMethod.unknown);
      expect(PaymentMethod.fromString(''), PaymentMethod.unknown);
      expect(PaymentMethod.fromString('CASH'), PaymentMethod.unknown);
    });

    test('display names are correct', () {
      expect(PaymentMethod.cash.displayName, 'Cash');
      expect(PaymentMethod.upi.displayName, 'UPI');
      expect(PaymentMethod.udhar.displayName, 'Credit');
      expect(PaymentMethod.unknown.displayName, 'Unknown');
    });

    test('emojis are non-empty strings', () {
      for (final method in PaymentMethod.values) {
        expect(method.emoji.isNotEmpty, true);
      }
    });
  });

  // ── BillModel.toMap ──

  group('BillModel.toMap', () {
    BillModel makeBill({
      String id = 'b1',
      int billNumber = 1,
      List<CartItem> items = const [],
      double total = 100,
      PaymentMethod paymentMethod = PaymentMethod.cash,
      String? customerId,
      String? customerName,
      double? receivedAmount,
    }) {
      return BillModel(
        id: id,
        billNumber: billNumber,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        customerId: customerId,
        customerName: customerName,
        receivedAmount: receivedAmount,
        createdAt: DateTime(2024, 6, 15, 10, 30),
        date: '2024-06-15',
      );
    }

    test('includes all fields', () {
      final bill = makeBill(
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Rice',
            price: 50,
            quantity: 2,
            unit: 'kg',
          ),
        ],
        receivedAmount: 120,
        customerId: 'c1',
        customerName: 'Rahul',
      );
      final map = bill.toMap();
      expect(map['id'], 'b1');
      expect(map['billNumber'], 1);
      expect(map['total'], 100);
      expect(map['paymentMethod'], 'cash');
      expect(map['customerId'], 'c1');
      expect(map['customerName'], 'Rahul');
      expect(map['receivedAmount'], 120);
      expect(map['date'], '2024-06-15');
      expect((map['items'] as List).length, 1);
    });

    test('null optional fields serialize as null', () {
      final map = makeBill().toMap();
      expect(map['customerId'], isNull);
      expect(map['customerName'], isNull);
      expect(map['receivedAmount'], isNull);
    });

    test('createdAt serializes as ISO 8601', () {
      final map = makeBill().toMap();
      expect(map['createdAt'], contains('2024-06-15'));
    });

    test('items serialize correctly', () {
      final bill = makeBill(
        items: [
          const CartItem(
            productId: 'p1',
            name: 'A',
            price: 10,
            quantity: 1,
            unit: 'pcs',
          ),
          const CartItem(
            productId: 'p2',
            name: 'B',
            price: 20,
            quantity: 3,
            unit: 'kg',
          ),
        ],
      );
      final map = bill.toMap();
      final items = map['items'] as List;
      expect(items.length, 2);
      expect(items[0]['name'], 'A');
      expect(items[1]['quantity'], 3);
    });
  });

  // ── BillModel.copyWith ──

  group('BillModel.copyWith', () {
    final base = BillModel(
      id: 'b1',
      billNumber: 1,
      items: const [],
      total: 100,
      paymentMethod: PaymentMethod.cash,
      createdAt: DateTime(2024),
      date: '2024-01-01',
    );

    test('preserves all fields when no args', () {
      final copy = base.copyWith();
      expect(copy.id, 'b1');
      expect(copy.billNumber, 1);
      expect(copy.total, 100);
      expect(copy.paymentMethod, PaymentMethod.cash);
      expect(copy.date, '2024-01-01');
    });

    test('overrides specified fields', () {
      final copy = base.copyWith(total: 200, paymentMethod: PaymentMethod.upi);
      expect(copy.total, 200);
      expect(copy.paymentMethod, PaymentMethod.upi);
      // Unchanged fields
      expect(copy.id, 'b1');
      expect(copy.billNumber, 1);
    });

    test('can set customer info', () {
      final copy = base.copyWith(customerId: 'c1', customerName: 'Test');
      expect(copy.customerId, 'c1');
      expect(copy.customerName, 'Test');
    });
  });

  // ── BillModel computed getters ──

  group('BillModel computed getters', () {
    test('changeAmount with exact payment', () {
      final bill = BillModel(
        id: 'b1',
        billNumber: 1,
        items: const [],
        total: 100,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 100,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );
      expect(bill.changeAmount, 0);
    });

    test('changeAmount with overpayment', () {
      final bill = BillModel(
        id: 'b1',
        billNumber: 1,
        items: const [],
        total: 80,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 100,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );
      expect(bill.changeAmount, 20);
    });

    test('changeAmount with underpayment', () {
      final bill = BillModel(
        id: 'b1',
        billNumber: 1,
        items: const [],
        total: 100,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 80,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );
      expect(bill.changeAmount, -20);
    });

    test('itemCount sums quantities', () {
      final bill = BillModel(
        id: 'b1',
        billNumber: 1,
        items: const [
          CartItem(
            productId: 'p1',
            name: 'A',
            price: 10,
            quantity: 3,
            unit: 'pcs',
          ),
          CartItem(
            productId: 'p2',
            name: 'B',
            price: 20,
            quantity: 2,
            unit: 'pcs',
          ),
        ],
        total: 70,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );
      expect(bill.itemCount, 5);
    });

    test('itemCount is zero for empty items', () {
      final bill = BillModel(
        id: 'b1',
        billNumber: 1,
        items: const [],
        total: 0,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime(2024),
        date: '2024-01-01',
      );
      expect(bill.itemCount, 0);
    });
  });
}
