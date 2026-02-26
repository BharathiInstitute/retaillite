import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/expense_model.dart';

void main() {
  // ── BillModel.changeAmount (BILL-013) ──

  group('BillModel.changeAmount', () {
    test('calculates change correctly', () {
      final bill = BillModel(
        id: 'b1',
        billNumber: 1,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Rice',
            price: 60,
            quantity: 5,
            unit: 'kg',
          ),
        ],
        total: 300,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 500,
        createdAt: DateTime.now(),
        date: '2026-02-25',
      );
      expect(bill.changeAmount, 200.0);
    });

    test('returns 0 when exact amount paid', () {
      final bill = BillModel(
        id: 'b2',
        billNumber: 2,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Sugar',
            price: 40,
            quantity: 1,
            unit: 'kg',
          ),
        ],
        total: 40,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 40,
        createdAt: DateTime.now(),
        date: '2026-02-25',
      );
      expect(bill.changeAmount, 0.0);
    });

    test('returns null when receivedAmount is null', () {
      final bill = BillModel(
        id: 'b3',
        billNumber: 3,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Oil',
            price: 120,
            quantity: 1,
            unit: 'bottle',
          ),
        ],
        total: 120,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime.now(),
        date: '2026-02-25',
      );
      expect(bill.changeAmount, isNull);
    });
  });

  // ── Cash payment bill (BILL-010) ──

  group('Cash payment bill', () {
    test('has paymentMethod cash in toMap', () {
      final bill = BillModel(
        id: 'b4',
        billNumber: 4,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Rice',
            price: 60,
            quantity: 2,
            unit: 'kg',
          ),
        ],
        total: 120,
        paymentMethod: PaymentMethod.cash,
        receivedAmount: 200,
        createdAt: DateTime(2026, 2, 25),
        date: '2026-02-25',
      );
      final map = bill.toMap();
      expect(map['paymentMethod'], 'cash');
      expect(map['receivedAmount'], 200);
      expect(map['total'], 120);
    });
  });

  // ── UPI payment bill (BILL-011) ──

  group('UPI payment bill', () {
    test('has paymentMethod upi', () {
      final bill = BillModel(
        id: 'b5',
        billNumber: 5,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Dal',
            price: 80,
            quantity: 1,
            unit: 'kg',
          ),
        ],
        total: 80,
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2026, 2, 25),
        date: '2026-02-25',
      );
      expect(bill.toMap()['paymentMethod'], 'upi');
    });
  });

  // ── Credit (udhar) bill (BILL-012) ──

  group('Credit bill', () {
    test('has paymentMethod udhar and customer set', () {
      final bill = BillModel(
        id: 'b6',
        billNumber: 6,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Atta',
            price: 50,
            quantity: 2,
            unit: 'kg',
          ),
        ],
        total: 100,
        paymentMethod: PaymentMethod.udhar,
        customerId: 'cust_1',
        customerName: 'Rajesh Kumar',
        createdAt: DateTime(2026, 2, 25),
        date: '2026-02-25',
      );
      final map = bill.toMap();
      expect(map['paymentMethod'], 'udhar');
      expect(map['customerId'], 'cust_1');
      expect(map['customerName'], 'Rajesh Kumar');
    });
  });

  // ── BillModel.itemCount ──

  group('BillModel.itemCount', () {
    test('sums all item quantities', () {
      final bill = BillModel(
        id: 'b7',
        billNumber: 7,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'A',
            price: 10,
            quantity: 3,
            unit: 'pcs',
          ),
          const CartItem(
            productId: 'p2',
            name: 'B',
            price: 20,
            quantity: 2,
            unit: 'pcs',
          ),
        ],
        total: 70,
        paymentMethod: PaymentMethod.cash,
        createdAt: DateTime.now(),
        date: '2026-02-25',
      );
      expect(bill.itemCount, 5);
    });
  });

  // ── ExpenseModel (BILL-022, BILL-023) ──

  group('ExpenseModel', () {
    test('creates expense with category', () {
      final expense = ExpenseModel(
        id: 'e1',
        amount: 5000,
        category: ExpenseCategory.rent,
        description: 'Monthly rent',
        paymentMethod: PaymentMethod.upi,
        createdAt: DateTime(2026, 2, 25),
        date: '2026-02-25',
      );
      expect(expense.amount, 5000);
      expect(expense.category, ExpenseCategory.rent);
      expect(expense.description, 'Monthly rent');
    });

    test('each category has a displayName', () {
      for (final cat in ExpenseCategory.values) {
        expect(cat.displayName, isNotEmpty);
      }
    });
  });

  // ── PaymentMethod enum ──

  group('PaymentMethod', () {
    test('fromString returns correct enum', () {
      expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('upi'), PaymentMethod.upi);
      expect(PaymentMethod.fromString('udhar'), PaymentMethod.udhar);
    });

    test('fromString returns unknown for invalid value', () {
      expect(PaymentMethod.fromString('bitcoin'), PaymentMethod.unknown);
    });

    test('displayName is set for all values', () {
      for (final pm in PaymentMethod.values) {
        expect(pm.displayName, isNotEmpty);
      }
    });
  });
}
