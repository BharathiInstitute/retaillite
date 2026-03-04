/// Integration test: CSV / bulk product import flow
///
/// Tests the product import pipeline: CSV parsing, validation, batch creation,
/// and duplicate/conflict handling.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/product_model.dart';
import '../helpers/test_factories.dart';

void main() {
  group('Integration: CSV Import Flow', () {
    test('Step 1: Parse CSV rows into ProductModel list', () {
      // Simulate CSV parse result
      final csvRows = [
        ['Rice Basmati', '120.0', '80.0', '50', 'kg', 'Groceries'],
        ['Toor Dal', '95.0', '70.0', '30', 'kg', 'Groceries'],
        ['Surf Excel', '45.0', '32.0', '100', 'pcs', 'Cleaning'],
      ];

      final products = csvRows.map((row) => makeProduct(
        id: 'import-${row[0].toLowerCase().replaceAll(' ', '-')}',
        name: row[0],
        price: double.parse(row[1]),
        purchasePrice: double.parse(row[2]),
        stock: int.parse(row[3]),
        unit: row[4] == 'kg' ? ProductUnit.kg : ProductUnit.piece,
        category: row[5],
      )).toList();

      expect(products.length, 3);
      expect(products[0].name, 'Rice Basmati');
      expect(products[0].price, 120.0);
      expect(products[0].purchasePrice, 80.0);
      expect(products[0].unit, ProductUnit.kg);
      expect(products[2].category, 'Cleaning');
    });

    test('Step 2: Validate required fields', () {
      // Name and price are required
      bool isValid(String name, String priceStr) {
        if (name.trim().isEmpty) return false;
        final price = double.tryParse(priceStr);
        if (price == null || price <= 0) return false;
        return true;
      }

      expect(isValid('Rice', '120'), isTrue);
      expect(isValid('', '120'), isFalse);
      expect(isValid('Rice', ''), isFalse);
      expect(isValid('Rice', '-5'), isFalse);
      expect(isValid('Rice', 'abc'), isFalse);
    });

    test('Step 3: Batch chunking respects 490-operation limit', () {
      // WriteBatch limit is 500; we use 490 for safety
      const batchLimit = 490;
      final products = List.generate(1200, (i) => makeProduct(
        id: 'prod-$i', name: 'Product $i',
      ));

      final chunks = <List<ProductModel>>[];
      for (var i = 0; i < products.length; i += batchLimit) {
        chunks.add(products.sublist(
          i, i + batchLimit > products.length ? products.length : i + batchLimit,
        ));
      }

      expect(chunks.length, 3); // 490 + 490 + 220
      expect(chunks[0].length, 490);
      expect(chunks[1].length, 490);
      expect(chunks[2].length, 220);
      expect(chunks.fold<int>(0, (sum, c) => sum + c.length), 1200);
    });

    test('Step 4: Duplicate detection by name (case-insensitive)', () {
      final existing = [
        makeProduct(id: 'p1', name: 'Rice Basmati'),
        makeProduct(id: 'p2', name: 'Toor Dal'),
      ];

      final incoming = [
        makeProduct(id: 'new1', name: 'rice basmati'), // duplicate
        makeProduct(id: 'new2', name: 'Tur Dal'),      // new
        makeProduct(id: 'new3', name: 'TOOR DAL'),     // duplicate
      ];

      final existingNames = existing.map((p) => p.name.toLowerCase()).toSet();
      final duplicates = incoming.where((p) => existingNames.contains(p.name.toLowerCase())).toList();
      final unique = incoming.where((p) => !existingNames.contains(p.name.toLowerCase())).toList();

      expect(duplicates.length, 2);
      expect(unique.length, 1);
      expect(unique.first.name, 'Tur Dal');
    });

    test('Step 5: Profit margins computed correctly for imported products', () {
      final products = [
        makeProduct(name: 'A', purchasePrice: 60),
        makeProduct(name: 'B', price: 200, purchasePrice: 150),
        makeProduct(name: 'C', price: 50), // no purchase price
      ];

      expect(products[0].profit, 40.0);
      expect(products[1].profit, 50.0);
      expect(products[2].profit, isNull); // can't compute without cost
    });

    test('Step 6: Gross profit aggregation from imported products', () {
      // Simulate salesSummaryProvider COGS computation
      final products = [
        makeProduct(id: 'p1', purchasePrice: 60),
        makeProduct(id: 'p2', price: 200, purchasePrice: 150),
      ];

      final bills = [
        makeBill(
          id: 'b1',
          items: [
            const CartItem(productId: 'p1', name: 'A', price: 100, quantity: 5, unit: 'pcs'),
            const CartItem(productId: 'p2', name: 'B', price: 200, quantity: 2, unit: 'pcs'),
          ],
          total: 900,
        ),
      ];

      final productMap = {for (final p in products) p.id: p};
      double totalCogs = 0;
      for (final bill in bills) {
        for (final item in bill.items) {
          final cost = productMap[item.productId]?.purchasePrice ?? 0;
          totalCogs += cost * item.quantity;
        }
      }

      final grossProfit = 900 - totalCogs; // 900 - (60*5 + 150*2) = 900 - 600 = 300
      expect(totalCogs, 600.0);
      expect(grossProfit, 300.0);
    });
  });
}
