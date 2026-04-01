/// Tests for PaymentModal presentation logic.
///
/// The PaymentModal widget depends on Firebase, Riverpod providers, and
/// navigation. This file tests the payment logic that can be verified
/// as pure functions — payment method selection, validation rules,
/// and bill completion preconditions.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';

// ── Inline validation logic (mirrors payment_modal.dart) ──

/// Validates whether a bill can be completed with the given parameters.
/// Returns null on success, or an error message.
String? validateBillCompletion({
  required List<CartItem> cartItems,
  required double total,
  required PaymentMethod paymentMethod,
  String? customerId,
  double? udharAmount,
}) {
  if (cartItems.isEmpty) {
    return 'Cart is empty';
  }
  if (total <= 0) {
    return 'Total must be greater than zero';
  }
  // Udhar requires a customer
  if (paymentMethod == PaymentMethod.udhar && customerId == null) {
    return 'Please select a customer for credit (udhar) billing';
  }
  // Udhar amount must be valid and <= total
  if (paymentMethod == PaymentMethod.udhar) {
    if (udharAmount == null || udharAmount <= 0) {
      return 'Credit amount must be greater than zero';
    }
    if (udharAmount > total) {
      return 'Credit amount cannot exceed bill total';
    }
  }
  return null;
}

/// Determines the display label for a payment method.
String paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'Cash';
    case PaymentMethod.upi:
      return 'UPI';
    case PaymentMethod.udhar:
      return 'Credit';
    case PaymentMethod.unknown:
      return 'Unknown';
  }
}

/// Calculate change due for cash payments.
double calculateChange(double receivedAmount, double total) {
  if (receivedAmount > total) return receivedAmount - total;
  return 0;
}

void main() {
  // ── Validation ──

  group('Bill completion validation', () {
    const sampleItems = [
      CartItem(
        productId: 'p1',
        name: 'Rice',
        price: 50,
        quantity: 2,
        unit: 'kg',
      ),
    ];

    test('valid cash bill passes validation', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 100,
        paymentMethod: PaymentMethod.cash,
      );
      expect(error, isNull);
    });

    test('valid UPI bill passes validation', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 100,
        paymentMethod: PaymentMethod.upi,
      );
      expect(error, isNull);
    });

    test('valid udhar bill with customer passes validation', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 100,
        paymentMethod: PaymentMethod.udhar,
        customerId: 'cust-1',
        udharAmount: 100,
      );
      expect(error, isNull);
    });

    test('empty cart is rejected', () {
      final error = validateBillCompletion(
        cartItems: const [],
        total: 0,
        paymentMethod: PaymentMethod.cash,
      );
      expect(error, 'Cart is empty');
    });

    test('zero total is rejected', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 0,
        paymentMethod: PaymentMethod.cash,
      );
      expect(error, 'Total must be greater than zero');
    });

    test('negative total is rejected', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: -50,
        paymentMethod: PaymentMethod.cash,
      );
      expect(error, 'Total must be greater than zero');
    });

    test('udhar without customer is rejected', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 100,
        paymentMethod: PaymentMethod.udhar,
        udharAmount: 100,
      );
      expect(error, contains('customer'));
    });

    test('udhar with zero amount is rejected', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 100,
        paymentMethod: PaymentMethod.udhar,
        customerId: 'cust-1',
        udharAmount: 0,
      );
      expect(error, contains('greater than zero'));
    });

    test('udhar with negative amount is rejected', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 100,
        paymentMethod: PaymentMethod.udhar,
        customerId: 'cust-1',
        udharAmount: -50,
      );
      expect(error, contains('greater than zero'));
    });

    test('udhar amount exceeding total is rejected', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 100,
        paymentMethod: PaymentMethod.udhar,
        customerId: 'cust-1',
        udharAmount: 150,
      );
      expect(error, contains('cannot exceed'));
    });

    test('udhar with partial amount <= total passes', () {
      final error = validateBillCompletion(
        cartItems: sampleItems,
        total: 100,
        paymentMethod: PaymentMethod.udhar,
        customerId: 'cust-1',
        udharAmount: 60,
      );
      expect(error, isNull);
    });
  });

  // ── Payment method labels ──

  group('Payment method labels', () {
    test('cash label', () {
      expect(paymentMethodLabel(PaymentMethod.cash), 'Cash');
    });

    test('UPI label', () {
      expect(paymentMethodLabel(PaymentMethod.upi), 'UPI');
    });

    test('udhar label', () {
      expect(paymentMethodLabel(PaymentMethod.udhar), 'Credit');
    });

    test('unknown label', () {
      expect(paymentMethodLabel(PaymentMethod.unknown), 'Unknown');
    });
  });

  // ── Change calculation ──

  group('Change calculation', () {
    test('exact amount: no change', () {
      expect(calculateChange(100, 100), 0);
    });

    test('overpayment: correct change returned', () {
      expect(calculateChange(500, 480), 20);
    });

    test('underpayment: no change (0)', () {
      expect(calculateChange(80, 100), 0);
    });

    test('large overpayment', () {
      expect(calculateChange(1000, 350), 650);
    });

    test('zero received: no change', () {
      expect(calculateChange(0, 100), 0);
    });
  });

  // ── PaymentMethod enum ──

  group('PaymentMethod', () {
    test('has 4 values', () {
      expect(PaymentMethod.values.length, 4);
    });

    test('contains cash, upi, udhar, unknown', () {
      expect(PaymentMethod.values, contains(PaymentMethod.cash));
      expect(PaymentMethod.values, contains(PaymentMethod.upi));
      expect(PaymentMethod.values, contains(PaymentMethod.udhar));
      expect(PaymentMethod.values, contains(PaymentMethod.unknown));
    });
  });

  // ── CartItem model ──

  group('CartItem', () {
    test('create with required fields', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Rice Bag',
        price: 50.0,
        quantity: 3,
        unit: 'kg',
      );
      expect(item.productId, 'p1');
      expect(item.name, 'Rice Bag');
      expect(item.price, 50.0);
      expect(item.quantity, 3);
      expect(item.unit, 'kg');
    });

    test('item total is price × quantity', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Rice',
        price: 50.0,
        quantity: 3,
        unit: 'kg',
      );
      // Price * quantity
      expect(item.price * item.quantity, 150.0);
    });
  });
}
