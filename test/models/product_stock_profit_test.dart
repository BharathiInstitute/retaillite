import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  // ── isLowStock (PROD-006) ──

  group('ProductModel.isLowStock', () {
    test('true when stock <= lowStockAlert', () {
      final product = ProductModel(
        id: 'p1',
        name: 'Rice',
        price: 60,
        stock: 3,
        lowStockAlert: 5,
        createdAt: DateTime(2026),
      );
      expect(product.isLowStock, isTrue);
    });

    test('true when stock equals lowStockAlert', () {
      final product = ProductModel(
        id: 'p2',
        name: 'Sugar',
        price: 40,
        stock: 5,
        lowStockAlert: 5,
        createdAt: DateTime(2026),
      );
      expect(product.isLowStock, isTrue);
    });

    test('false when stock > lowStockAlert', () {
      final product = ProductModel(
        id: 'p3',
        name: 'Dal',
        price: 80,
        stock: 10,
        lowStockAlert: 5,
        createdAt: DateTime(2026),
      );
      expect(product.isLowStock, isFalse);
    });

    test('false when lowStockAlert is null', () {
      final product = ProductModel(
        id: 'p4',
        name: 'Oil',
        price: 120,
        stock: 1,
        createdAt: DateTime(2026),
      );
      expect(product.isLowStock, isFalse);
    });
  });

  // ── isOutOfStock (PROD-007) ──

  group('ProductModel.isOutOfStock', () {
    test('true when stock is 0', () {
      final product = ProductModel(
        id: 'p5',
        name: 'Ghee',
        price: 500,
        stock: 0,
        createdAt: DateTime(2026),
      );
      expect(product.isOutOfStock, isTrue);
    });

    test('true when stock is negative', () {
      final product = ProductModel(
        id: 'p6',
        name: 'Butter',
        price: 60,
        stock: -1,
        createdAt: DateTime(2026),
      );
      expect(product.isOutOfStock, isTrue);
    });

    test('false when stock > 0', () {
      final product = ProductModel(
        id: 'p7',
        name: 'Salt',
        price: 20,
        stock: 50,
        createdAt: DateTime(2026),
      );
      expect(product.isOutOfStock, isFalse);
    });
  });

  // ── profit and profitPercentage (PROD-011) ──

  group('ProductModel.profit', () {
    test('calculates profit per unit', () {
      final product = ProductModel(
        id: 'p8',
        name: 'Rice',
        price: 100,
        purchasePrice: 70,
        stock: 10,
        createdAt: DateTime(2026),
      );
      expect(product.profit, 30.0);
    });

    test('returns null when purchasePrice is null', () {
      final product = ProductModel(
        id: 'p9',
        name: 'Sugar',
        price: 40,
        stock: 10,
        createdAt: DateTime(2026),
      );
      expect(product.profit, isNull);
    });

    test('handles negative profit (loss)', () {
      final product = ProductModel(
        id: 'p10',
        name: 'Loss Item',
        price: 50,
        purchasePrice: 80,
        stock: 5,
        createdAt: DateTime(2026),
      );
      expect(product.profit, -30.0);
    });
  });

  group('ProductModel.profitPercentage', () {
    test('calculates correct percentage', () {
      final product = ProductModel(
        id: 'p11',
        name: 'Rice',
        price: 100,
        purchasePrice: 70,
        stock: 10,
        createdAt: DateTime(2026),
      );
      expect(product.profitPercentage, closeTo(42.86, 0.01));
    });

    test('returns null when purchasePrice is null', () {
      final product = ProductModel(
        id: 'p12',
        name: 'Sugar',
        price: 40,
        stock: 10,
        createdAt: DateTime(2026),
      );
      expect(product.profitPercentage, isNull);
    });

    test('returns null when purchasePrice is 0', () {
      final product = ProductModel(
        id: 'p13',
        name: 'Free',
        price: 100,
        purchasePrice: 0,
        stock: 5,
        createdAt: DateTime(2026),
      );
      expect(product.profitPercentage, isNull);
    });

    test('100% profit when price is double the purchase', () {
      final product = ProductModel(
        id: 'p14',
        name: 'Double',
        price: 200,
        purchasePrice: 100,
        stock: 5,
        createdAt: DateTime(2026),
      );
      expect(product.profitPercentage, 100.0);
    });
  });
}
