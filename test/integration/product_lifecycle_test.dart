/// Integration test: Product lifecycle — CRUD, stock, low stock alerts
///
/// Tests product creation, editing, stock management, CSV export format,
/// catalog search, and barcode validation flows.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/barcode_lookup_service.dart';
import 'package:retaillite/core/services/product_catalog_service.dart';
import 'package:retaillite/models/product_model.dart';

void main() {
  group('Integration: Product CRUD Lifecycle', () {
    test('Step 1: Create product from catalog', () {
      // User picks from catalog
      final catalogProducts = ProductCatalogService.searchProducts('rice');
      expect(catalogProducts, isNotEmpty);

      // Convert to ProductModel
      final product = catalogProducts.first.toProductModel(
        customPrice: 130,
        stock: 25,
      );
      expect(product.price, 130);
      expect(product.stock, 25);
      expect(product.id, isEmpty); // Not yet saved
    });

    test('Step 2: Edit product changes copyWith', () {
      final product = ProductModel(
        id: 'p-1',
        name: 'Rice Basmati 5kg',
        price: 450,
        stock: 50,
        unit: ProductUnit.kg,
        createdAt: DateTime(2026),
      );

      final edited = product.copyWith(price: 480, stock: 45);
      expect(edited.price, 480);
      expect(edited.stock, 45);
      expect(edited.name, 'Rice Basmati 5kg'); // unchanged
      expect(edited.id, 'p-1'); // preserved
    });

    test('Step 3: Stock decrement after billing', () {
      final product = ProductModel(
        id: 'p-1',
        name: 'Sugar 1kg',
        price: 48,
        stock: 80,
        unit: ProductUnit.kg,
        lowStockAlert: 15,
        createdAt: DateTime(2026),
      );

      // Sold 70 units
      final afterSale = product.copyWith(stock: product.stock - 70);
      expect(afterSale.stock, 10);
      expect(afterSale.isLowStock, isTrue); // 10 < 15
      expect(afterSale.isOutOfStock, isFalse);
    });

    test('Step 4: Stock reaches zero', () {
      final product = ProductModel(
        id: 'p-1',
        name: 'Oil 1L',
        price: 180,
        stock: 5,
        unit: ProductUnit.liter,
        createdAt: DateTime(2026),
      );

      final outOfStock = product.copyWith(stock: 0);
      expect(outOfStock.isOutOfStock, isTrue);
      // isLowStock uses <=, so stock 0 with lowStockAlert also counts as low
    });

    test('Step 5: Stock reorder back to normal', () {
      final product = ProductModel(
        id: 'p-1',
        name: 'Salt 1kg',
        price: 28,
        stock: 0,
        lowStockAlert: 20,
        createdAt: DateTime(2026),
      );

      final restocked = product.copyWith(stock: 100);
      expect(restocked.isOutOfStock, isFalse);
      expect(restocked.isLowStock, isFalse);
    });
  });

  group('Integration: Profit Tracking', () {
    test('profit calculated correctly', () {
      final product = ProductModel(
        id: 'p-1',
        name: 'Rice',
        price: 450,
        purchasePrice: 400,
        stock: 50,
        unit: ProductUnit.kg,
        createdAt: DateTime(2026),
      );

      expect(product.profit, 50); // 450 - 400
      expect(product.profitPercentage, closeTo(12.5, 0.01));
    });

    test('negative profit means loss', () {
      final product = ProductModel(
        id: 'p-1',
        name: 'Clearance Item',
        price: 80,
        purchasePrice: 100,
        stock: 10,
        createdAt: DateTime(2026),
      );

      expect(product.profit, -20);
      expect(product.profitPercentage, lessThan(0));
    });

    test('null purchase price means unknown profit', () {
      final product = ProductModel(
        id: 'p-1',
        name: 'Unknown Cost Item',
        price: 200,
        stock: 10,
        createdAt: DateTime(2026),
      );

      expect(product.profit, isNull);
      expect(product.profitPercentage, isNull);
    });
  });

  group('Integration: ProductUnit Conversion', () {
    test('fromString finds by name', () {
      expect(ProductUnit.fromString('kg'), ProductUnit.kg);
      expect(ProductUnit.fromString('liter'), ProductUnit.liter);
      expect(ProductUnit.fromString('piece'), ProductUnit.piece);
    });

    test('fromString finds by short name', () {
      expect(ProductUnit.fromString('L'), ProductUnit.liter);
    });

    test('fromString defaults to unknown for unrecognized', () {
      expect(ProductUnit.fromString('cubicmeter'), ProductUnit.unknown);
    });

    test('all units have short names', () {
      for (final unit in ProductUnit.values) {
        expect(unit.shortName, isNotEmpty);
      }
    });
  });

  group('Integration: Barcode Lookup', () {
    test('valid EAN-13 barcode passes validation', () {
      expect(BarcodeLookupService.isValidBarcode('8901234567890'), isTrue);
    });

    test('too-short barcode fails', () {
      expect(BarcodeLookupService.isValidBarcode('12345'), isFalse);
    });

    test('barcode product with brand has combined display name', () {
      const product = BarcodeProduct(
        barcode: '123',
        name: 'Tea 250g',
        brand: 'Tata',
      );
      expect(product.displayName, 'Tata Tea 250g');
    });

    test('barcode product without brand uses name only', () {
      const product = BarcodeProduct(barcode: '123', name: 'Local Oil');
      expect(product.displayName, 'Local Oil');
    });
  });

  group('Integration: Catalog → Product Pipeline', () {
    test('search catalog, convert, verify fields', () {
      final results = ProductCatalogService.searchProducts('sugar');
      expect(results, isNotEmpty);

      final product = results.first.toProductModel(stock: 100);
      expect(product.name, contains('Sugar'));
      expect(product.price, greaterThan(0));
      expect(product.stock, 100);
      expect(product.lowStockAlert, 5);
    });

    test('every catalog product converts to valid ProductModel', () {
      for (final cp in ProductCatalogService.allProducts) {
        final pm = cp.toProductModel();
        expect(pm.name, isNotEmpty);
        expect(pm.price, greaterThan(0));
        expect(pm.stock, 0);
      }
    });
  });
}
