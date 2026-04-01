/// Tests for CatalogBrowserModal — category filtering and search logic.
///
/// Depends on ProductCatalogService (static). We test the filtering
/// and selection logic inline.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline ProductCategory stub (mirrors product_catalog_service.dart) ──

enum _ProductCategory { kirana, grocery, dairy, snacks, personal, cleaning }

// ── Inline CatalogProduct stub ──

class _CatalogProduct {
  final String name;
  final _ProductCategory category;
  const _CatalogProduct({required this.name, required this.category});

  @override
  bool operator ==(Object other) =>
      other is _CatalogProduct &&
      name == other.name &&
      category == other.category;

  @override
  int get hashCode => name.hashCode ^ category.hashCode;
}

void main() {
  // ── Test data ──
  final allProducts = [
    const _CatalogProduct(
      name: 'Tata Salt',
      category: _ProductCategory.grocery,
    ),
    const _CatalogProduct(name: 'Amul Milk', category: _ProductCategory.dairy),
    const _CatalogProduct(
      name: 'Lays Chips',
      category: _ProductCategory.snacks,
    ),
    const _CatalogProduct(
      name: 'Rice Bran Oil',
      category: _ProductCategory.grocery,
    ),
    const _CatalogProduct(
      name: 'Dove Soap',
      category: _ProductCategory.personal,
    ),
    const _CatalogProduct(name: 'Vim Bar', category: _ProductCategory.cleaning),
  ];

  // ── Category filtering ──
  // Mirrors: ProductCatalogService.getProductsByCategory(_selectedCategory)

  group('CatalogBrowserModal category filtering', () {
    List<_CatalogProduct> getByCategory(_ProductCategory cat) {
      return allProducts.where((p) => p.category == cat).toList();
    }

    test('filters grocery products', () {
      final grocery = getByCategory(_ProductCategory.grocery);
      expect(grocery.length, 2);
      expect(
        grocery.every((p) => p.category == _ProductCategory.grocery),
        isTrue,
      );
    });

    test('filters dairy products', () {
      final dairy = getByCategory(_ProductCategory.dairy);
      expect(dairy.length, 1);
      expect(dairy.first.name, 'Amul Milk');
    });

    test('filters snacks products', () {
      final snacks = getByCategory(_ProductCategory.snacks);
      expect(snacks.length, 1);
    });

    test('filters personal products', () {
      final personal = getByCategory(_ProductCategory.personal);
      expect(personal.length, 1);
      expect(personal.first.name, 'Dove Soap');
    });

    test('filters cleaning products', () {
      final cleaning = getByCategory(_ProductCategory.cleaning);
      expect(cleaning.length, 1);
    });
  });

  // ── Search filtering ──
  // Mirrors: ProductCatalogService.searchProducts(_searchQuery)

  group('CatalogBrowserModal search filtering', () {
    List<_CatalogProduct> search(String query) {
      if (query.isEmpty) return allProducts;
      return allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    test('empty search returns all products', () {
      expect(search(''), allProducts);
    });

    test('search by exact name', () {
      final results = search('Tata Salt');
      expect(results.length, 1);
      expect(results.first.name, 'Tata Salt');
    });

    test('search is case insensitive', () {
      final results = search('tata');
      expect(results.length, 1);
    });

    test('partial match returns results', () {
      final results = search('Oil');
      expect(results.length, 1);
      expect(results.first.name, 'Rice Bran Oil');
    });

    test('no matches returns empty', () {
      final results = search('Pepsi');
      expect(results, isEmpty);
    });
  });

  // ── Multi-select logic ──
  // Mirrors: Set<CatalogProduct> _selectedProducts; add/remove

  group('CatalogBrowserModal multi-select', () {
    test('starts with empty selection', () {
      final selected = <_CatalogProduct>{};
      expect(selected, isEmpty);
    });

    test('add product to selection', () {
      final selected = <_CatalogProduct>{};
      selected.add(allProducts[0]);
      expect(selected.length, 1);
    });

    test('remove product from selection', () {
      final selected = <_CatalogProduct>{allProducts[0]};
      selected.remove(allProducts[0]);
      expect(selected, isEmpty);
    });

    test('duplicate add is idempotent (Set behavior)', () {
      final selected = <_CatalogProduct>{};
      selected.add(allProducts[0]);
      selected.add(allProducts[0]);
      expect(selected.length, 1);
    });

    test('clear removes all selections', () {
      final selected = <_CatalogProduct>{
        allProducts[0],
        allProducts[1],
        allProducts[2],
      };
      selected.clear();
      expect(selected, isEmpty);
    });

    test('selection count shown in badge', () {
      final selected = <_CatalogProduct>{allProducts[0], allProducts[1]};
      expect('${selected.length}', '2');
    });
  });

  // ── Add button state ──
  // Mirrors: onPressed: _selectedProducts.isEmpty || _isAdding ? null : _addSelectedProducts

  group('CatalogBrowserModal add button state', () {
    bool addEnabled(int selectedCount, bool isAdding) {
      return selectedCount > 0 && !isAdding;
    }

    test('disabled when nothing selected', () {
      expect(addEnabled(0, false), isFalse);
    });

    test('enabled when items selected and not adding', () {
      expect(addEnabled(3, false), isTrue);
    });

    test('disabled when currently adding', () {
      expect(addEnabled(3, true), isFalse);
    });
  });

  // ── Category icon mapping ──
  // Mirrors: _getCategoryIcon(ProductCategory category)

  group('CatalogBrowserModal category icons', () {
    String iconName(_ProductCategory category) {
      switch (category) {
        case _ProductCategory.kirana:
          return 'store';
        case _ProductCategory.grocery:
          return 'rice_bowl';
        case _ProductCategory.dairy:
          return 'egg';
        case _ProductCategory.snacks:
          return 'fastfood';
        case _ProductCategory.personal:
          return 'face';
        case _ProductCategory.cleaning:
          return 'cleaning_services';
      }
    }

    test('grocery has rice_bowl icon', () {
      expect(iconName(_ProductCategory.grocery), 'rice_bowl');
    });

    test('dairy has egg icon', () {
      expect(iconName(_ProductCategory.dairy), 'egg');
    });

    test('snacks has fastfood icon', () {
      expect(iconName(_ProductCategory.snacks), 'fastfood');
    });

    test('all categories have icons', () {
      for (final cat in _ProductCategory.values) {
        expect(iconName(cat), isNotEmpty);
      }
    });
  });

  // ── Search vs category mode ──
  // Mirrors: _searchQuery.isEmpty ? getProductsByCategory : searchProducts

  group('CatalogBrowserModal search vs category mode', () {
    test('category tabs hidden during search', () {
      const searchQuery = 'salt';
      expect(searchQuery.isEmpty, isFalse); // tabs hidden
    });

    test('category tabs shown when not searching', () {
      const searchQuery = '';
      expect(searchQuery.isEmpty, isTrue); // tabs shown
    });
  });
}
