/// Tests for ProductCatalogService — categories, search, catalog integrity
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/product_catalog_service.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  // ── ProductCategory enum ──

  group('ProductCategory', () {
    test('has 6 categories', () {
      expect(ProductCategory.values.length, 6);
    });

    test('all have English names', () {
      for (final cat in ProductCategory.values) {
        expect(cat.name, isNotEmpty);
      }
    });

    test('all have Hindi names', () {
      for (final cat in ProductCategory.values) {
        expect(cat.hindiName, isNotEmpty);
      }
    });

    test('kirana is first', () {
      expect(ProductCategory.values.first, ProductCategory.kirana);
    });
  });

  // ── CatalogProduct ──

  group('CatalogProduct', () {
    test('creates with required fields', () {
      const p = CatalogProduct(
        name: 'Rice 1kg',
        suggestedPrice: 120,
        category: ProductCategory.grocery,
      );
      expect(p.name, 'Rice 1kg');
      expect(p.suggestedPrice, 120);
      expect(p.unit, ProductUnit.piece); // default
      expect(p.barcode, isNull);
    });

    test('creates with custom unit and barcode', () {
      const p = CatalogProduct(
        name: 'Milk 500ml',
        suggestedPrice: 30,
        unit: ProductUnit.liter,
        category: ProductCategory.dairy,
        barcode: '8901234567890',
      );
      expect(p.unit, ProductUnit.liter);
      expect(p.barcode, '8901234567890');
    });

    test('toProductModel creates with default stock 0', () {
      const cp = CatalogProduct(
        name: 'Sugar 1kg',
        suggestedPrice: 48,
        category: ProductCategory.grocery,
      );
      final pm = cp.toProductModel();
      expect(pm.name, 'Sugar 1kg');
      expect(pm.price, 48);
      expect(pm.stock, 0);
      expect(pm.id, isEmpty);
    });

    test('toProductModel accepts custom price and stock', () {
      const cp = CatalogProduct(
        name: 'Oil 1L',
        suggestedPrice: 120,
        category: ProductCategory.grocery,
      );
      final pm = cp.toProductModel(customPrice: 130, stock: 10);
      expect(pm.price, 130);
      expect(pm.stock, 10);
    });

    test('toProductModel inherits barcode', () {
      const cp = CatalogProduct(
        name: 'Biscuit',
        suggestedPrice: 20,
        category: ProductCategory.snacks,
        barcode: '123',
      );
      final pm = cp.toProductModel();
      expect(pm.barcode, '123');
    });

    test('toProductModel sets lowStockAlert to 5', () {
      const cp = CatalogProduct(
        name: 'Soap',
        suggestedPrice: 40,
        category: ProductCategory.personal,
      );
      final pm = cp.toProductModel();
      expect(pm.lowStockAlert, 5);
    });
  });

  // ── ProductCatalogService ──

  group('ProductCatalogService', () {
    test('categories returns all ProductCategory values', () {
      expect(ProductCatalogService.categories, ProductCategory.values);
    });

    test('allProducts is non-empty', () {
      expect(ProductCatalogService.allProducts, isNotEmpty);
    });

    test('allProducts has at least 50 items', () {
      expect(
        ProductCatalogService.allProducts.length,
        greaterThanOrEqualTo(50),
      );
    });

    test('all products have non-empty names', () {
      for (final p in ProductCatalogService.allProducts) {
        expect(p.name, isNotEmpty, reason: 'Product with empty name');
      }
    });

    test('all products have positive prices', () {
      for (final p in ProductCatalogService.allProducts) {
        expect(
          p.suggestedPrice,
          greaterThan(0),
          reason: '${p.name} has non-positive price',
        );
      }
    });

    test('getProductsByCategory returns only matching category', () {
      final grocery = ProductCatalogService.getProductsByCategory(
        ProductCategory.grocery,
      );
      expect(grocery, isNotEmpty);
      for (final p in grocery) {
        expect(p.category, ProductCategory.grocery);
      }
    });

    test('every category has at least 1 product', () {
      for (final cat in ProductCategory.values) {
        final products = ProductCatalogService.getProductsByCategory(cat);
        expect(products, isNotEmpty, reason: '${cat.name} has no products');
      }
    });

    test('searchProducts is case-insensitive', () {
      final results = ProductCatalogService.searchProducts('RICE');
      expect(results, isNotEmpty);
      final resultsLower = ProductCatalogService.searchProducts('rice');
      expect(results.length, resultsLower.length);
    });

    test('searchProducts returns empty for nonsense query', () {
      final results = ProductCatalogService.searchProducts('xyznonexistent123');
      expect(results, isEmpty);
    });

    test('searchProducts returns matching products', () {
      final results = ProductCatalogService.searchProducts('sugar');
      for (final p in results) {
        expect(p.name.toLowerCase(), contains('sugar'));
      }
    });
  });
}
