import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/services/product_csv_service.dart';
import 'package:retaillite/core/theme/web_theme.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by shell
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Top Bar: Search + Actions
            Row(
              children: [
                // Search Input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by product name, SKU, or category...',
                        prefixIcon: const Icon(Icons.search),
                        fillColor: Colors.white,
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
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
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
            const SizedBox(height: 24),

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
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(0),
                            child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF9FAFB),
                                ),
                                dataRowMinHeight: 72,
                                horizontalMargin: 24,
                                columnSpacing: 24,
                                columns: [
                                  const DataColumn(
                                    label: Text(
                                      'Product Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: WebTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(
                                      'SKU',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: WebTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  // Category omitted as it doesn't exist in model
                                  const DataColumn(
                                    label: Text(
                                      'Stock Level',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: WebTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(
                                      'Price',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: WebTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: WebTheme.textSecondary,
                                      ),
                                    ),
                                    numeric: true,
                                  ),
                                ],
                                rows: filtered.map((product) {
                                  return DataRow(
                                    cells: [
                                      // Product Name + Image
                                      DataCell(
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: WebTheme.background,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image: product.imageUrl != null
                                                    ? DecorationImage(
                                                        image: NetworkImage(
                                                          product.imageUrl!,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child: product.imageUrl == null
                                                  ? const Icon(
                                                      Icons
                                                          .image_not_supported_outlined,
                                                      color: WebTheme.textMuted,
                                                      size: 20,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: WebTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () => _showAddProductModal(
                                          product: product,
                                        ),
                                      ),
                                      // SKU
                                      DataCell(
                                        Text(
                                          product.barcode ?? 'N/A',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            color: WebTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      // Stock Level with Badge
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                      // Price
                                      DataCell(
                                        Text(
                                          product.price.asCurrency,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: WebTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      // Actions
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          color: WebTheme.textSecondary,
                                          onPressed: () => _showAddProductModal(
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
                        // Pagination Footer (Static for now as per constraints)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Showing 1 to ${filtered.length} of ${filtered.length} results',
                                style: const TextStyle(
                                  color: WebTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton(
                                onPressed: null, // Disabled
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
                                onPressed: null, // Disabled
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
