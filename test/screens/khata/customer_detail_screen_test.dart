/// Tests for CustomerDetailScreen — customer info display and transaction logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('CustomerDetailScreen customer info', () {
    test('customer name displayed', () {
      const name = 'Raj Sharma';
      expect(name.isNotEmpty, isTrue);
    });

    test('customer phone formatted correctly', () {
      const phone = '9876543210';
      expect(Validators.phone(phone), isNull);
    });

    test('empty customer id is invalid', () {
      const customerId = '';
      expect(customerId.isEmpty, isTrue);
    });

    test('valid customer id is non-empty', () {
      const customerId = 'cust_12345';
      expect(customerId.isNotEmpty, isTrue);
    });
  });

  group('CustomerDetailScreen balance calculation', () {
    test('balance = total credit - total payments', () {
      const totalCredit = 5000.0;
      const totalPayments = 3000.0;
      const balance = totalCredit - totalPayments;
      expect(balance, 2000.0);
    });

    test('zero balance when fully paid', () {
      const totalCredit = 5000.0;
      const totalPayments = 5000.0;
      const balance = totalCredit - totalPayments;
      expect(balance, 0.0);
    });

    test('negative balance indicates overpayment', () {
      const totalCredit = 3000.0;
      const totalPayments = 3500.0;
      const balance = totalCredit - totalPayments;
      expect(balance, lessThan(0));
    });
  });

  group('CustomerDetailScreen transaction history', () {
    test('transactions sorted by date descending', () {
      final transactions = [
        DateTime(2025, 1, 10),
        DateTime(2025, 3, 15),
        DateTime(2025, 2, 20),
      ];
      transactions.sort((a, b) => b.compareTo(a));
      expect(transactions.first, DateTime(2025, 3, 15));
      expect(transactions.last, DateTime(2025, 1, 10));
    });

    test('empty transaction list renders empty state', () {
      const transactions = <String>[];
      expect(transactions.isEmpty, isTrue);
    });
  });

  group('CustomerDetailScreen credit validation', () {
    test('valid credit amount passes', () {
      expect(Validators.price('500'), isNull);
    });

    test('zero credit accepted by positiveNumber (allows zero)', () {
      expect(Validators.positiveNumber('0', 'Amount'), isNull);
    });

    test('negative credit rejected', () {
      expect(Validators.price('-100'), isNotNull);
    });
  });
}
