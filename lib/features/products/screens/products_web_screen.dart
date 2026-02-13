import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/product_csv_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/products/providers/products_provider.dart';
import 'package:retaillite/features/products/widgets/add_product_modal.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';

class ProductsWebScreen extends ConsumerStatefulWidget {
  const ProductsWebScreen({super.key});

  @override
  ConsumerState<ProductsWebScreen> createState() => _ProductsWebScreenState();
}

class _ProductsWebScreenState extends ConsumerState<ProductsWebScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final productsAsync = ref.watch(productsProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by shell
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 16.0 : 16.0)),
        child: Column(
          children: [
            // Top Bar: Search + Actions
            if (isMobile) ...[
              // Mobile: Stacked layout
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Theme.of(context).cardColor,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleImportCsv(),
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Import CSV'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddProductModal(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addProduct),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Desktop: Original single row
              Row(
                children: [
                  // Search Input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by product name, SKU, or category...',
                          prefixIcon: const Icon(Icons.search),
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.toLowerCase()),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Actions
                  OutlinedButton.icon(
                    onPressed: () => _handleImportCsv(),
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import CSV'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddProductModal(),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addProduct),
                  ),
                ],
              ),
            ],
            SizedBox(height: isMobile ? 12 : 16),

            // Main Content: Data Table Card
            Expanded(
              child: Card(
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
                        actionLabel: _searchQuery.isEmpty
                            ? l10n.addProduct
                            : null,
                        onAction: _searchQuery.isEmpty
                            ? () => _showAddProductModal()
                            : null,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isMobile) ...[
                          // Mobile: Card-based list
                          Expanded(
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = filtered[index];
                                return _MobileProductCard(
                                  product: product,
                                  onEdit: () =>
                                      _showAddProductModal(product: product),
                                );
                              },
                            ),
                          ),
                          // Mobile pagination footer
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${filtered.length} products',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        'Prev',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: null,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        'Next',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Desktop: DataTable
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(0),
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                                  headingRowHeight: 44,
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 56,
                                  horizontalMargin: 16,
                                  columnSpacing: 16,
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'Product Name',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'SKU',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Category',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Stock Level',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Price',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                  ],
                                  rows: filtered.map((product) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  image:
                                                      product.imageUrl != null
                                                      ? DecorationImage(
                                                          image: NetworkImage(
                                                            product.imageUrl!,
                                                          ),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child: product.imageUrl == null
                                                    ? Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.outline,
                                                        size: 16,
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          onTap: () => _showAddProductModal(
                                            product: product,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            product.barcode ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            product.category ?? '—',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: product.category != null
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: product.isOutOfStock
                                                  ? AppColors.error.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : (product.isLowStock
                                                        ? AppColors.warning
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                        : AppColors.success
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              product.isOutOfStock
                                                  ? 'Out of stock'
                                                  : (product.isLowStock
                                                        ? '${product.stock} (Low)'
                                                        : '${product.stock} in stock'),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: product.isOutOfStock
                                                    ? AppColors.error
                                                    : (product.isLowStock
                                                          ? AppColors.warning
                                                          : AppColors.success),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            product.price.asCurrency,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            onPressed: () =>
                                                _showAddProductModal(
                                                  product: product,
                                                ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          // Desktop pagination footer
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            decoration: const BoxDecoration(),
                            child: Row(
                              children: [
                                Text(
                                  'Showing 1 to ${filtered.length} of ${filtered.length} results',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton(
                                  onPressed: null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Previous'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (error, _) => ErrorState(
                    message: l10n.somethingWentWrong,
                    onRetry: () => ref.invalidate(productsProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Logic copied from products_screen.dart
  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var result = products;
    // Simple filter support (only search implemented in UI header for simplicity)
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

  Future<void> _handleImportCsv() async {
    // Reuse import logic
    try {
      final result = await ProductCsvService.importProducts();
      // final l10n = context.l10n; // Future: use for i18n

      if (result.imported == 0 && result.errors.isEmpty) {
        return;
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
  }
}

/// Mobile-friendly product card for list display
class _MobileProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;

  const _MobileProductCard({required this.product, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.small,
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                image: product.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl == null
                  ? Icon(
                      Icons.image_not_supported_outlined,
                      color: Theme.of(context).colorScheme.outline,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Stock Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.isOutOfStock
                              ? AppColors.error.withValues(alpha: 0.1)
                              : (product.isLowStock
                                    ? AppColors.warning.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.isOutOfStock
                              ? 'Out'
                              : (product.isLowStock
                                    ? '${product.stock} low'
                                    : '${product.stock} in stock'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: product.isOutOfStock
                                ? AppColors.error
                                : (product.isLowStock
                                      ? AppColors.warning
                                      : AppColors.success),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price and Edit
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.price.asCurrency,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
