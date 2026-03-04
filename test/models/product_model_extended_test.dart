/// Extended product model tests — copyWith sentinel, profitPercentage, units
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  ProductModel make({
    String id = 'p1',
    String name = 'Test Product',
    double price = 100,
    double? purchasePrice,
    int stock = 10,
    int? lowStockAlert,
    String? barcode,
    String? imageUrl,
    String? category,
    ProductUnit unit = ProductUnit.piece,
  }) {
    return ProductModel(
      id: id,
      name: name,
      price: price,
      purchasePrice: purchasePrice,
      stock: stock,
      lowStockAlert: lowStockAlert,
      barcode: barcode,
      imageUrl: imageUrl,
      category: category,
      unit: unit,
      createdAt: DateTime(2024),
    );
  }

  // ── ProductUnit.fromString ──

  group('ProductUnit.fromString', () {
    test('matches by name', () {
      expect(ProductUnit.fromString('piece'), ProductUnit.piece);
      expect(ProductUnit.fromString('kg'), ProductUnit.kg);
      expect(ProductUnit.fromString('gram'), ProductUnit.gram);
      expect(ProductUnit.fromString('liter'), ProductUnit.liter);
      expect(ProductUnit.fromString('ml'), ProductUnit.ml);
      expect(ProductUnit.fromString('pack'), ProductUnit.pack);
      expect(ProductUnit.fromString('box'), ProductUnit.box);
      expect(ProductUnit.fromString('dozen'), ProductUnit.dozen);
    });

    test('matches by shortName', () {
      expect(ProductUnit.fromString('pcs'), ProductUnit.piece);
      expect(ProductUnit.fromString('g'), ProductUnit.gram);
      expect(ProductUnit.fromString('L'), ProductUnit.liter);
      expect(ProductUnit.fromString('dz'), ProductUnit.dozen);
    });

    test('falls back to unknown for invalid', () {
      expect(ProductUnit.fromString(''), ProductUnit.unknown);
      expect(ProductUnit.fromString('bottle'), ProductUnit.unknown);
      expect(ProductUnit.fromString('PIECE'), ProductUnit.unknown);
    });

    test('all units have non-empty displayName and shortName', () {
      for (final unit in ProductUnit.values) {
        expect(unit.displayName.isNotEmpty, true);
        expect(unit.shortName.isNotEmpty, true);
      }
    });
  });

  // ── profitPercentage edge cases ──

  group('ProductModel.profitPercentage', () {
    test('null when no purchase price', () {
      expect(make().profitPercentage, isNull);
    });

    test('null when purchase price is zero', () {
      expect(make(purchasePrice: 0).profitPercentage, isNull);
    });

    test('correct for typical margin', () {
      final p = make(price: 120, purchasePrice: 100);
      expect(p.profitPercentage, closeTo(20, 0.01));
    });

    test('negative for loss', () {
      final p = make(price: 80, purchasePrice: 100);
      expect(p.profitPercentage, closeTo(-20, 0.01));
    });

    test('zero for break-even', () {
      final p = make(purchasePrice: 100);
      expect(p.profitPercentage, closeTo(0, 0.01));
    });

    test('high margin', () {
      final p = make(price: 200, purchasePrice: 50);
      expect(p.profitPercentage, closeTo(300, 0.01));
    });
  });

  // ── isLowStock edge cases ──

  group('ProductModel.isLowStock', () {
    test('false when lowStockAlert is null', () {
      expect(make(stock: 0).isLowStock, false);
    });

    test('true when stock equals alert', () {
      expect(make(stock: 5, lowStockAlert: 5).isLowStock, true);
    });

    test('true when stock below alert', () {
      expect(make(stock: 2, lowStockAlert: 5).isLowStock, true);
    });

    test('false when stock above alert', () {
      expect(make(lowStockAlert: 5).isLowStock, false);
    });

    test('true when stock zero with any alert', () {
      expect(make(stock: 0, lowStockAlert: 1).isLowStock, true);
    });
  });

  // ── isOutOfStock ──

  group('ProductModel.isOutOfStock', () {
    test('true for zero stock', () {
      expect(make(stock: 0).isOutOfStock, true);
    });

    test('true for negative stock', () {
      expect(make(stock: -1).isOutOfStock, true);
    });

    test('false for positive stock', () {
      expect(make(stock: 1).isOutOfStock, false);
    });
  });

  // ── copyWith sentinel pattern ──

  group('ProductModel.copyWith', () {
    test('preserves all fields when no args', () {
      final p = make(
        name: 'Rice',
        price: 50,
        purchasePrice: 40,
        stock: 100,
        lowStockAlert: 10,
        barcode: '1234',
        imageUrl: 'https://example.com/img.jpg',
        category: 'Grocery',
        unit: ProductUnit.kg,
      );
      final copy = p.copyWith();
      expect(copy.name, 'Rice');
      expect(copy.price, 50);
      expect(copy.purchasePrice, 40);
      expect(copy.stock, 100);
      expect(copy.lowStockAlert, 10);
      expect(copy.barcode, '1234');
      expect(copy.imageUrl, 'https://example.com/img.jpg');
      expect(copy.category, 'Grocery');
      expect(copy.unit, ProductUnit.kg);
    });

    test('overrides simple fields', () {
      final p = make(name: 'Rice', price: 50);
      final copy = p.copyWith(name: 'Sugar', price: 60);
      expect(copy.name, 'Sugar');
      expect(copy.price, 60);
    });

    test('can set nullable field to null (sentinel pattern)', () {
      final p = make(purchasePrice: 40, barcode: '123', category: 'Food');
      final copy = p.copyWith(
        purchasePrice: null,
        barcode: null,
        category: null,
      );
      expect(copy.purchasePrice, isNull);
      expect(copy.barcode, isNull);
      expect(copy.category, isNull);
    });

    test('can clear lowStockAlert via null', () {
      final p = make(lowStockAlert: 10);
      final copy = p.copyWith(lowStockAlert: null);
      expect(copy.lowStockAlert, isNull);
    });

    test('can clear imageUrl via null', () {
      final p = make(imageUrl: 'https://example.com/img.jpg');
      final copy = p.copyWith(imageUrl: null);
      expect(copy.imageUrl, isNull);
    });

    test('updatedAt is set to now on copy', () {
      final p = make();
      final before = DateTime.now();
      final copy = p.copyWith(name: 'New');
      final after = DateTime.now();

      expect(copy.updatedAt, isNotNull);
      expect(
        copy.updatedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        copy.updatedAt!.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('preserves id and createdAt', () {
      final p = make();
      final copy = p.copyWith(name: 'New');
      expect(copy.id, 'p1');
      expect(copy.createdAt, p.createdAt);
    });

    test('unit can be changed', () {
      final p = make();
      final copy = p.copyWith(unit: ProductUnit.kg);
      expect(copy.unit, ProductUnit.kg);
    });
  });

  // ── profit ──

  group('ProductModel.profit', () {
    test('null when no purchase price', () {
      expect(make().profit, isNull);
    });

    test('positive for markup', () {
      expect(make(price: 120, purchasePrice: 100).profit, 20);
    });

    test('negative for loss', () {
      expect(make(price: 80, purchasePrice: 100).profit, -20);
    });

    test('zero for same price', () {
      expect(make(purchasePrice: 100).profit, 0);
    });
  });
}
