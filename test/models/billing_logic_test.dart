/// Billing logic tests — CartItem, BillModel, PaymentMethod
///
/// Extends existing bill_model_test with computation edge cases,
/// serialization round-trips and multi-item scenarios.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import '../helpers/test_factories.dart';

void main() {
  // ── PaymentMethod ──

  group('PaymentMethod', () {
    test('fromString parses all valid values', () {
      expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('upi'), PaymentMethod.upi);
      expect(PaymentMethod.fromString('udhar'), PaymentMethod.udhar);
    });

    test('fromString falls back to unknown for invalid value', () {
      expect(PaymentMethod.fromString('bitcoin'), PaymentMethod.unknown);
      expect(PaymentMethod.fromString(''), PaymentMethod.unknown);
    });

    test('all enum values have display names', () {
      for (final pm in PaymentMethod.values) {
        expect(pm.displayName, isNotEmpty);
        expect(pm.emoji, isNotEmpty);
      }
    });

    test('enum names are unique', () {
      final names = PaymentMethod.values.map((e) => e.name).toSet();
      expect(names.length, PaymentMethod.values.length);
    });
  });

  // ── CartItem ──

  group('CartItem', () {
    test('total = price * quantity', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Rice',
        price: 50.0,
        quantity: 3,
        unit: 'kg',
      );
      expect(item.total, 150.0);
    });

    test('total is 0 when quantity is 0', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Rice',
        price: 50.0,
        quantity: 0,
        unit: 'kg',
      );
      expect(item.total, 0.0);
    });

    test('total with fractional price', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Pencil',
        price: 5.50,
        quantity: 4,
        unit: 'pcs',
      );
      expect(item.total, 22.0);
    });

    test('copyWith updates quantity only', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Rice',
        price: 50.0,
        quantity: 1,
        unit: 'kg',
      );
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.price, 50.0); // unchanged
      expect(updated.name, 'Rice'); // unchanged
    });

    test('toMap → fromMap round-trip', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Sugar',
        price: 45.0,
        quantity: 2,
        unit: 'kg',
      );
      final restored = CartItem.fromMap(item.toMap());
      expect(restored.productId, 'p1');
      expect(restored.name, 'Sugar');
      expect(restored.price, 45.0);
      expect(restored.quantity, 2);
      expect(restored.unit, 'kg');
    });

    test('fromMap handles missing fields gracefully', () {
      final item = CartItem.fromMap({});
      expect(item.productId, '');
      expect(item.name, '');
      expect(item.price, 0.0);
      expect(item.quantity, 1);
      expect(item.unit, 'pcs');
    });
  });

  // ── BillModel ──

  group('BillModel', () {
    test('changeAmount = receivedAmount - total', () {
      final bill = makeBill(total: 450, receivedAmount: 500);
      expect(bill.changeAmount, 50.0);
    });

    test('changeAmount is 0 for exact payment', () {
      final bill = makeBill();
      expect(bill.changeAmount, 0.0);
    });

    test('changeAmount is negative when underpaid', () {
      final bill = makeBill(total: 200, receivedAmount: 150);
      expect(bill.changeAmount, -50.0);
    });

    test('itemCount sums all item quantities', () {
      final bill = makeBill(
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
          CartItem(
            productId: 'p3',
            name: 'C',
            price: 5,
            quantity: 5,
            unit: 'pcs',
          ),
        ],
      );
      expect(bill.itemCount, 10); // 3 + 2 + 5
    });

    test('itemCount is 0 for empty items list', () {
      final bill = makeBill(items: const []);
      expect(bill.itemCount, 0);
    });

    test('copyWith preserves unchanged fields', () {
      final bill = makeBill(
        id: 'b1',
        billNumber: 42,
        total: 500,
      );
      final updated = bill.copyWith(paymentMethod: PaymentMethod.upi);

      expect(updated.id, 'b1');
      expect(updated.billNumber, 42);
      expect(updated.total, 500);
      expect(updated.paymentMethod, PaymentMethod.upi);
    });

    test('copyWith updates multiple fields', () {
      final bill = makeBill();
      final updated = bill.copyWith(
        total: 999.0,
        customerName: 'Rajesh',
        paymentMethod: PaymentMethod.udhar,
      );
      expect(updated.total, 999.0);
      expect(updated.customerName, 'Rajesh');
      expect(updated.paymentMethod, PaymentMethod.udhar);
    });

    test('toMap includes all fields', () {
      final bill = makeBill(
        id: 'bill-99',
        billNumber: 99,
        total: 750,
        paymentMethod: PaymentMethod.upi,
        customerId: 'c1',
        customerName: 'Sita',
      );
      final map = bill.toMap();

      expect(map['id'], 'bill-99');
      expect(map['billNumber'], 99);
      expect(map['total'], 750);
      expect(map['paymentMethod'], 'upi');
      expect(map['customerId'], 'c1');
      expect(map['customerName'], 'Sita');
      expect(map['items'], isA<List<dynamic>>());
    });

    test('toFirestore excludes id', () {
      final bill = makeBill();
      final map = bill.toFirestore();
      expect(map.containsKey('id'), false);
    });
  });

  // ── Bulk billing scenarios ──

  group('Bulk billing at scale', () {
    test('makeBills generates correct count', () {
      final bills = makeBills(100);
      expect(bills.length, 100);
    });

    test('makeBills have unique ids', () {
      final bills = makeBills(50);
      final ids = bills.map((b) => b.id).toSet();
      expect(ids.length, 50);
    });

    test('makeBills have sequential bill numbers', () {
      final bills = makeBills(10);
      for (int i = 0; i < 10; i++) {
        expect(bills[i].billNumber, i + 1);
      }
    });

    test('bills with mixed payment methods', () {
      final cash = makeBill();
      final upi = makeBill(paymentMethod: PaymentMethod.upi);
      final credit = makeBill(paymentMethod: PaymentMethod.udhar);

      expect(cash.paymentMethod, PaymentMethod.cash);
      expect(upi.paymentMethod, PaymentMethod.upi);
      expect(credit.paymentMethod, PaymentMethod.udhar);
    });

    test('total from 500 bills can be summed without overflow', () {
      final bills = makeBills(500);
      final totalRevenue = bills.fold<double>(0, (sum, b) => sum + b.total);
      expect(totalRevenue, greaterThan(0));
      expect(totalRevenue.isFinite, true);
    });
  });
}
