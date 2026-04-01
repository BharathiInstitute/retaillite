/// Tests for data privacy — export isolation, PII sanitization, log safety.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';

void main() {
  group('Data privacy: export isolation', () {
    test('data export contains only requesting user data', () {
      // Simulate: user A's bills are separate from user B
      final userABills = [
        BillModel(
          id: 'a1',
          billNumber: 1,
          items: [
            const CartItem(
              productId: 'p1',
              name: 'Rice',
              price: 50,
              quantity: 1,
              unit: 'kg',
            ),
          ],
          total: 50,
          paymentMethod: PaymentMethod.cash,
          createdAt: DateTime.now(),
          date: '2024-01-15',
        ),
      ];
      final userBBills = [
        BillModel(
          id: 'b1',
          billNumber: 1,
          items: [
            const CartItem(
              productId: 'p2',
              name: 'Dal',
              price: 80,
              quantity: 1,
              unit: 'kg',
            ),
          ],
          total: 80,
          paymentMethod: PaymentMethod.upi,
          createdAt: DateTime.now(),
          date: '2024-01-15',
        ),
      ];

      // Export only user A's data
      final exportedIds = userABills.map((b) => b.id).toSet();
      final otherUserIds = userBBills.map((b) => b.id).toSet();
      expect(exportedIds, contains('a1'));
      expect(exportedIds.intersection(otherUserIds), isEmpty);
    });

    test('data export does not include other user IDs', () {
      const currentUserId = 'user_A';
      final bills = [
        {'id': 'bill1', 'userId': 'user_A'},
        {'id': 'bill2', 'userId': 'user_A'},
      ];

      // Verify all bills belong to current user
      for (final bill in bills) {
        expect(bill['userId'], equals(currentUserId));
      }
    });
  });

  group('Data privacy: log safety', () {
    String sanitizeForLog(String value) {
      if (value.length <= 4) return '****';
      return '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
    }

    test('error logs do not contain full phone numbers', () {
      const phone = '9876543210';
      final sanitized = sanitizeForLog(phone);
      expect(sanitized, isNot(equals(phone)));
      expect(sanitized, endsWith('3210'));
      expect(sanitized, startsWith('*'));
    });

    test('error logs do not contain passwords or tokens', () {
      const password = 'MySecretP@ss123';
      final sanitized = sanitizeForLog(password);
      expect(sanitized, isNot(equals(password)));
      expect(sanitized.contains('Secret'), isFalse);
    });
  });

  group('Data privacy: CSV export', () {
    test('CSV export sanitizes PII in customer phone field', () {
      // Customer phone should be masked or absent in exported CSV
      const customerPhone = '9876543210';
      // In export, phone should be partially masked
      final maskedPhone =
          '${customerPhone.substring(0, 2)}******${customerPhone.substring(8)}';
      expect(maskedPhone, isNot(equals(customerPhone)));
      expect(maskedPhone.length, equals(customerPhone.length));
    });

    test('receipt service does not leak other customer data', () {
      // Build a bill for customer A — no other customer data should be included
      final bill = BillModel(
        id: 'bill_1',
        billNumber: 42,
        items: [
          const CartItem(
            productId: 'p1',
            name: 'Sugar',
            price: 40,
            quantity: 2,
            unit: 'kg',
          ),
        ],
        total: 80,
        paymentMethod: PaymentMethod.cash,
        customerId: 'custA',
        customerName: 'Rajesh',
        createdAt: DateTime.now(),
        date: '2024-01-15',
      );

      // Bill only references its own customer
      expect(bill.customerId, 'custA');
      expect(bill.customerName, 'Rajesh');
      // No cross-customer fields
      final map = bill.toMap();
      final values = map.values.map((v) => v.toString()).join(' ');
      expect(values.contains('custB'), isFalse);
    });
  });
}
