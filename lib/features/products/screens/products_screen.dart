/// Products management screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/services/product_csv_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/features/products/providers/products_provider.dart';
import 'package:retaillite/features/products/screens/products_web_screen.dart';
import 'package:retaillite/features/products/widgets/add_product_modal.dart';
import 'package:retaillite/features/products/widgets/catalog_browser_modal.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final productsAsync = ref.watch(productsProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);

    // Use Web Screen for Desktop and Tablet
    final deviceType = ResponsiveHelper.getDeviceType(context);
    if (deviceType == DeviceType.desktop || deviceType == DeviceType.tablet) {
      return const ProductsWebScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.products),
        actions: [
          if (lowStockProducts.isNotEmpty)
            Badge(
              label: Text('${lowStockProducts.length}'),
              child: IconButton(
                icon: const Icon(Icons.warning_amber),
                onPressed: () {
                  setState(() => _filter = 'low');
                },
              ),
            ),
          // Import/Export menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) =>
                _handleMenuAction(value, productsAsync.value ?? []),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'catalog',
                child: ListTile(
                  leading: const Icon(Icons.store),
                  title: Text(l10n.productCatalog),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(l10n.exportProducts),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(l10n.importProducts),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    // TODO: Open scanner
                  },
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(l10n.allProducts, 'all'),
                const SizedBox(width: 8),
                _buildFilterChip(l10n.lowStock, 'low'),
                const SizedBox(width: 8),
                _buildFilterChip(l10n.outOfStock, 'out'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Product list
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = _filterProducts(products);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.noProducts,
                    subtitle: _searchQuery.isEmpty
                        ? l10n.addFirstProduct
                        : l10n.noData,
                    actionLabel: _searchQuery.isEmpty ? l10n.addProduct : null,
                    onAction: _searchQuery.isEmpty
                        ? () => _showAddProductModal()
                        : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _ProductCard(
                    product: filtered[index],
                    onEdit: () =>
                        _showAddProductModal(product: filtered[index]),
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorState(
                message: l10n.somethingWentWrong,
                onRetry: () => ref.invalidate(productsProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductModal(),
        icon: const Icon(Icons.add),
        label: Text(l10n.addProduct),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.dividerLight,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var result = products;

    // Apply filter
    if (_filter == 'low') {
      result = result.where((p) => p.isLowStock && !p.isOutOfStock).toList();
    } else if (_filter == 'out') {
      result = result.where((p) => p.isOutOfStock).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            (p.barcode?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return result;
  }

  void _showAddProductModal({ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductModal(product: product),
    );
  }

  /// Handle import/export menu actions
  Future<void> _handleMenuAction(
    String action,
    List<ProductModel> products,
  ) async {
    final l10n = context.l10n;

    switch (action) {
      case 'catalog':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const CatalogBrowserModal(),
        );
        break;

      case 'export':
        if (products.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.noProducts)));
          return;
        }
        try {
          await ProductCsvService.exportProducts(products);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export failed: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
        break;

      case 'import':
        try {
          final result = await ProductCsvService.importProducts();
          if (result.imported == 0 && result.errors.isEmpty) {
            return; // User cancelled
          }

          if (result.hasErrors) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.errors.first),
                  backgroundColor: AppColors.warning,
                ),
              );
            }
            return;
          }

          // Add imported products
          final service = ref.read(productsServiceProvider);
          int added = 0;
          for (final product in result.products) {
            await service.addProduct(product);
            added++;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported $added products'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import failed: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
        break;
    }
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onEdit;

  const _ProductCard({required this.product, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final l10n = context.l10n; // Future: use for localization
    final stockColor = product.isOutOfStock
        ? AppColors.error
        : product.isLowStock
        ? AppColors.warning
        : AppColors.success;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          product.price.asCurrency,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        if (product.purchasePrice != null)
                          Text(
                            '(Profit: ${product.profit?.asCurrency ?? ''})',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.success),
                          ),
                      ],
                    ),
                    if (product.barcode != null)
                      Text(
                        '🏷️ ${product.barcode}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                  ],
                ),
              ),

              // Stock indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${product.stock}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: stockColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product.unit.shortName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: stockColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
