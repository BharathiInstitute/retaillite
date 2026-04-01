/// Tests for search across modules — products, customers, bills.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Product search ──
  group('Search: products', () {
    final products = [
      {'name': 'Rice', 'barcode': '8901234567890', 'category': 'Grocery'},
      {
        'name': 'Wheat Flour',
        'barcode': '8901234567891',
        'category': 'Grocery',
      },
      {'name': 'Milk', 'barcode': '8901234567892', 'category': 'Dairy'},
      {'name': 'Paneer', 'barcode': null, 'category': 'Dairy'},
    ];

    test('search by name (partial, case-insensitive)', () {
      const query = 'ric';
      final results = products
          .where(
            (p) => (p['name'] as String).toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
      expect(results.length, 1);
      expect(results.first['name'], 'Rice');
    });

    test('search by barcode (exact match)', () {
      const barcode = '8901234567891';
      final results = products.where((p) => p['barcode'] == barcode).toList();
      expect(results.length, 1);
      expect(results.first['name'], 'Wheat Flour');
    });

    test('search by category', () {
      const category = 'Dairy';
      final results = products.where((p) => p['category'] == category).toList();
      expect(results.length, 2);
    });

    test('search with no matches returns empty', () {
      const query = 'chocolate';
      final results = products
          .where(
            (p) => (p['name'] as String).toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
      expect(results, isEmpty);
    });
  });

  // ── Customer search ──
  group('Search: customers', () {
    final customers = [
      {'name': 'Raj Sharma', 'phone': '9876543210'},
      {'name': 'Priya Singh', 'phone': '9876543211'},
      {'name': 'राजेश कुमार', 'phone': '9876543212'}, // Hindi
    ];

    test('search by name (Hindi characters)', () {
      const query = 'राजेश';
      final results = customers
          .where((c) => (c['name'] as String).contains(query))
          .toList();
      expect(results.length, 1);
      expect(results.first['name'], 'राजेश कुमार');
    });

    test('search by phone (partial)', () {
      const query = '3211';
      final results = customers
          .where((c) => (c['phone'] as String).contains(query))
          .toList();
      expect(results.length, 1);
      expect(results.first['name'], 'Priya Singh');
    });

    test('search by name (case insensitive)', () {
      const query = 'raj';
      final results = customers
          .where(
            (c) => (c['name'] as String).toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
      expect(results.length, 1);
      expect(results.first['name'], 'Raj Sharma');
    });
  });

  // ── Bill search ──
  group('Search: bills', () {
    final bills = [
      {
        'number': 'BILL-001',
        'customer': 'Raj Sharma',
        'date': DateTime(2025, 3, 15),
      },
      {
        'number': 'BILL-002',
        'customer': 'Priya Singh',
        'date': DateTime(2025, 3, 20),
      },
      {
        'number': 'BILL-003',
        'customer': 'Raj Sharma',
        'date': DateTime(2025, 4),
      },
    ];

    test('search by bill number', () {
      const query = 'BILL-002';
      final results = bills
          .where((b) => (b['number'] as String).contains(query))
          .toList();
      expect(results.length, 1);
    });

    test('search by customer name', () {
      const query = 'Raj';
      final results = bills
          .where(
            (b) => (b['customer'] as String).toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
      expect(results.length, 2);
    });

    test('search across date range', () {
      final start = DateTime(2025, 3);
      final end = DateTime(2025, 3, 31);
      final results = bills.where((b) {
        final date = b['date'] as DateTime;
        return !date.isBefore(start) && !date.isAfter(end);
      }).toList();
      expect(results.length, 2); // BILL-001 and BILL-002
    });
  });
}
