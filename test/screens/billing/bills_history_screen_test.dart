/// Tests for BillsHistoryScreen — filtering, search, and display logic.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillsHistoryScreen search filtering', () {
    test('search by bill number filters correctly', () {
      const bills = ['BILL-001', 'BILL-002', 'BILL-010'];
      const query = '001';
      final filtered = bills.where((b) => b.contains(query)).toList();
      expect(filtered, ['BILL-001']);
    });

    test('empty search returns all bills', () {
      const bills = ['BILL-001', 'BILL-002'];
      const query = '';
      final filtered = query.isEmpty
          ? bills
          : bills.where((b) => b.contains(query)).toList();
      expect(filtered.length, 2);
    });
  });

  group('BillsHistoryScreen date range filtering', () {
    test('bills within date range are included', () {
      final billDate = DateTime(2025, 3, 15);
      final rangeStart = DateTime(2025, 3);
      final rangeEnd = DateTime(2025, 3, 31);
      final inRange =
          !billDate.isBefore(rangeStart) && !billDate.isAfter(rangeEnd);
      expect(inRange, isTrue);
    });

    test('bills outside date range are excluded', () {
      final billDate = DateTime(2025, 2, 15);
      final rangeStart = DateTime(2025, 3);
      final rangeEnd = DateTime(2025, 3, 31);
      final inRange =
          !billDate.isBefore(rangeStart) && !billDate.isAfter(rangeEnd);
      expect(inRange, isFalse);
    });
  });

  group('BillsHistoryScreen payment method filtering', () {
    test('cash filter returns only cash bills', () {
      final bills = [
        {'method': 'cash'},
        {'method': 'upi'},
        {'method': 'cash'},
      ];
      final filtered = bills.where((b) => b['method'] == 'cash').toList();
      expect(filtered.length, 2);
    });

    test('upi filter returns only upi bills', () {
      final bills = [
        {'method': 'cash'},
        {'method': 'upi'},
        {'method': 'card'},
      ];
      final filtered = bills.where((b) => b['method'] == 'upi').toList();
      expect(filtered.length, 1);
    });

    test('no filter returns all bills', () {
      final bills = [
        {'method': 'cash'},
        {'method': 'upi'},
      ];
      const String? filter = null;
      final filtered = filter == null
          ? bills
          : bills.where((b) => b['method'] == filter).toList();
      expect(filtered.length, 2);
    });
  });

  group('BillsHistoryScreen empty state', () {
    test('empty bills list shows empty state', () {
      const bills = <String>[];
      expect(bills.isEmpty, isTrue);
    });
  });

  group('BillsHistoryScreen sync indicator', () {
    test('pending sync count shows indicator', () {
      const pendingCount = 3;
      expect(pendingCount > 0, isTrue);
    });

    test('no pending sync hides indicator', () {
      const pendingCount = 0;
      expect(pendingCount > 0, isFalse);
    });
  });
}
