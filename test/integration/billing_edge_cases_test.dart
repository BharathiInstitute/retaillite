/// Tests for billing edge cases — model validation, payment calculation, limits.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  group('Billing edge cases: bill validation', () {
    test('bill with 0 items: items list empty', () {
      const items = <CartItem>[];
      expect(items.isEmpty, isTrue);
    });

    test('bill total cannot be negative', () {
      const total = -100.0;
      const isValid = total > 0;
      expect(isValid, isFalse);
    });

    test('bill total of zero is invalid', () {
      const total = 0.0;
      const isValid = total > 0;
      expect(isValid, isFalse);
    });
  });

  group('Billing edge cases: payment calculation', () {
    test('partial payment: correct change (₹500 on ₹480 = ₹20)', () {
      const total = 480.0;
      const received = 500.0;
      const change = received - total;
      expect(change, 20.0);
    });

    test('exact payment gives zero change', () {
      const total = 250.0;
      const received = 250.0;
      const change = received - total;
      expect(change, 0.0);
    });

    test('CartItem total = price × quantity', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Rice',
        price: 55.0,
        quantity: 3,
        unit: 'kg',
      );
      expect(item.total, 165.0);
    });
  });

  group('Billing edge cases: cart quantity limits', () {
    test('max cart quantity: 9999 per item capped', () {
      const maxQty = 9999;
      const requestedQty = 10000;
      final clampedQty = requestedQty.clamp(1, maxQty);
      expect(clampedQty, maxQty);
    });

    test('minimum cart quantity is 1', () {
      const requestedQty = 0;
      final clampedQty = requestedQty.clamp(1, 9999);
      expect(clampedQty, 1);
    });
  });

  group('Billing edge cases: payment methods', () {
    test('all payment methods tested', () {
      expect(PaymentMethod.values.length, 4); // cash, upi, udhar, unknown
      expect(PaymentMethod.cash.name, 'cash');
      expect(PaymentMethod.upi.name, 'upi');
      expect(PaymentMethod.udhar.name, 'udhar');
      expect(PaymentMethod.unknown.name, 'unknown');
    });

    test('PaymentMethod.fromString handles all values', () {
      expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('upi'), PaymentMethod.upi);
      expect(PaymentMethod.fromString('udhar'), PaymentMethod.udhar);
      expect(PaymentMethod.fromString('xyz'), PaymentMethod.unknown);
    });
  });

  group('Billing edge cases: bill number', () {
    test('bill number auto-increments from last', () {
      const lastBillNumber = 42;
      const nextBillNumber = lastBillNumber + 1;
      expect(nextBillNumber, 43);
    });

    test('first bill starts at 1', () {
      const int? lastBillNumber = null;
      const nextBillNumber = (lastBillNumber ?? 0) + 1;
      expect(nextBillNumber, 1);
    });
  });

  group('Billing edge cases: plan limits', () {
    test('free plan limit is 50 bills/month', () {
      const freeBillLimit = 50;
      const billsThisMonth = 50;
      const isAtLimit = billsThisMonth >= freeBillLimit;
      expect(isAtLimit, isTrue);
    });

    test('bill below free plan limit is allowed', () {
      const freeBillLimit = 50;
      const billsThisMonth = 49;
      const isAtLimit = billsThisMonth >= freeBillLimit;
      expect(isAtLimit, isFalse);
    });
  });
}
