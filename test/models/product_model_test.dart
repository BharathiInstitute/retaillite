import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  group('ProductModel', () {
    test('should create product with required fields', () {
      final product = ProductModel(
        id: 'test-id',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        createdAt: DateTime(2024),
      );

      expect(product.id, 'test-id');
      expect(product.name, 'Test Product');
      expect(product.price, 100.0);
      expect(product.stock, 50);
      expect(product.unit, ProductUnit.piece);
    });

    test('should calculate profit correctly', () {
      final product = ProductModel(
        id: 'test-id',
        name: 'Test Product',
        price: 100.0,
        purchasePrice: 70.0,
        stock: 50,
        createdAt: DateTime(2024),
      );

      expect(product.profit, 30.0);
      expect(product.profitPercentage, closeTo(42.86, 0.01));
    });

    test('should return null profit when no purchase price', () {
      final product = ProductModel(
        id: 'test-id',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        createdAt: DateTime(2024),
      );

      expect(product.profit, isNull);
      expect(product.profitPercentage, isNull);
    });

    test('should detect low stock', () {
      final lowStockProduct = ProductModel(
        id: 'test-id',
        name: 'Test Product',
        price: 100.0,
        stock: 3,
        lowStockAlert: 5,
        createdAt: DateTime(2024),
      );

      final normalStockProduct = ProductModel(
        id: 'test-id',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        lowStockAlert: 5,
        createdAt: DateTime(2024),
      );

      expect(lowStockProduct.isLowStock, true);
      expect(normalStockProduct.isLowStock, false);
    });

    test('should detect out of stock', () {
      final outOfStockProduct = ProductModel(
        id: 'test-id',
        name: 'Test Product',
        price: 100.0,
        stock: 0,
        createdAt: DateTime(2024),
      );

      expect(outOfStockProduct.isOutOfStock, true);
      expect(outOfStockProduct.stock, 0);
    });

    test('should serialize to Firestore correctly', () {
      final product = ProductModel(
        id: 'test-id',
        name: 'Test Product',
        price: 100.0,
        purchasePrice: 70.0,
        stock: 50,
        lowStockAlert: 5,
        unit: ProductUnit.kg,
        barcode: '1234567890',
        createdAt: DateTime(2024),
      );

      final map = product.toFirestore();

      expect(map['name'], 'Test Product');
      expect(map['price'], 100.0);
      expect(map['purchasePrice'], 70.0);
      expect(map['stock'], 50);
      expect(map['lowStockAlert'], 5);
      expect(map['unit'], 'kg');
      expect(map['barcode'], '1234567890');
    });
  });

  group('ProductUnit', () {
    test('should have correct display names', () {
      expect(ProductUnit.piece.displayName, 'Piece');
      expect(ProductUnit.kg.displayName, 'Kilogram');
      expect(ProductUnit.gram.displayName, 'Gram');
      expect(ProductUnit.liter.displayName, 'Liter');
      expect(ProductUnit.ml.displayName, 'Milliliter');
      expect(ProductUnit.dozen.displayName, 'Dozen');
      expect(ProductUnit.box.displayName, 'Box');
      expect(ProductUnit.pack.displayName, 'Pack');
    });

    test('should have correct short names', () {
      expect(ProductUnit.piece.shortName, 'pcs');
      expect(ProductUnit.kg.shortName, 'kg');
      expect(ProductUnit.gram.shortName, 'g');
      expect(ProductUnit.liter.shortName, 'L');
      expect(ProductUnit.ml.shortName, 'ml');
      expect(ProductUnit.dozen.shortName, 'dz');
      expect(ProductUnit.box.shortName, 'box');
      expect(ProductUnit.pack.shortName, 'pack');
    });
  });
}
