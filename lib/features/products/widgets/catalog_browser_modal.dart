/// Catalog browser modal for adding products from pre-built catalog
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/services/product_catalog_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/products/providers/products_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';

class CatalogBrowserModal extends ConsumerStatefulWidget {
  const CatalogBrowserModal({super.key});

  @override
  ConsumerState<CatalogBrowserModal> createState() =>
      _CatalogBrowserModalState();
}

class _CatalogBrowserModalState extends ConsumerState<CatalogBrowserModal> {
  ProductCategory _selectedCategory = ProductCategory.grocery;
  final Set<CatalogProduct> _selectedProducts = {};
  String _searchQuery = '';
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final products = _searchQuery.isEmpty
        ? ProductCatalogService.getProductsByCategory(_selectedCategory)
        : ProductCatalogService.searchProducts(_searchQuery);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
            ),
            child: Row(
              children: [
                const Icon(Icons.store, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.productCatalog,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_selectedProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedProducts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Category tabs (only show when not searching)
          if (_searchQuery.isEmpty)
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: ProductCategory.values.length,
                itemBuilder: (context, index) {
                  final cat = ProductCategory.values[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Product list
          Expanded(
            child: products.isEmpty
                ? Center(child: Text(l10n.noProducts))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isSelected = _selectedProducts.contains(product);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedProducts.add(product);
                              } else {
                                _selectedProducts.remove(product);
                              }
                            });
                          },
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.suggestedPrice.asCurrency} / ${product.unit.shortName}',
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(product.category),
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Add button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_selectedProducts.isNotEmpty) ...[
                  TextButton(
                    onPressed: () => setState(() => _selectedProducts.clear()),
                    child: Text(l10n.clear),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _selectedProducts.isEmpty || _isAdding
                        ? null
                        : _addSelectedProducts,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _selectedProducts.isEmpty
                          ? l10n.selectProducts
                          : '${l10n.addProduct} (${_selectedProducts.length})',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.kirana:
        return Icons.store;
      case ProductCategory.grocery:
        return Icons.rice_bowl;
      case ProductCategory.dairy:
        return Icons.egg;
      case ProductCategory.snacks:
        return Icons.fastfood;
      case ProductCategory.personal:
        return Icons.face;
      case ProductCategory.cleaning:
        return Icons.cleaning_services;
    }
  }

  Future<void> _addSelectedProducts() async {
    setState(() => _isAdding = true);

    try {
      final service = ref.read(productsServiceProvider);
      int added = 0;

      for (final catalogProduct in _selectedProducts) {
        final product = catalogProduct.toProductModel(stock: 0);
        await service.addProduct(product);
        added++;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $added products'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }
}
