/// Product detail screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/products/providers/products_provider.dart';
import 'package:retaillite/features/products/widgets/add_product_modal.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        // Find the product
        ProductModel? product;
        for (final p in products) {
          if (p.id == productId) {
            product = p;
            break;
          }
        }

        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Details')),
            body: const ErrorState(message: 'Product not found'),
          );
        }

        return _ProductDetailView(product: product);
      },
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: ErrorState(
          message: 'Failed to load product',
          onRetry: () => ref.invalidate(productsProvider),
        ),
      ),
    );
  }
}

class _ProductDetailView extends ConsumerStatefulWidget {
  final ProductModel product;

  const _ProductDetailView({required this.product});

  @override
  ConsumerState<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<_ProductDetailView> {
  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductModal(product: widget.product),
    );
  }

  void _showStockAdjustment() {
    final controller = TextEditingController();
    bool isAdd = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adjust Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add / Remove toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Add'),
                      selected: isAdd,
                      onSelected: (v) => setState(() => isAdd = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Remove'),
                      selected: !isAdd,
                      onSelected: (v) => setState(() => isAdd = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(isAdd ? Icons.add : Icons.remove),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Current stock: ${widget.product.stock} ${widget.product.unit.displayName}',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(controller.text) ?? 0;
                if (qty <= 0) return;

                final service = ref.read(productsServiceProvider);
                final newStock = isAdd
                    ? widget.product.stock + qty
                    : (widget.product.stock - qty).clamp(0, 999999);

                await service.updateProduct(
                  widget.product.copyWith(stock: newStock),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAdd
                            ? 'Added $qty ${widget.product.unit.displayName}'
                            : 'Removed $qty ${widget.product.unit.displayName}',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "${widget.product.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final service = ref.read(productsServiceProvider);
    await service.deleteProduct(widget.product.id);

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final profit = product.profit;
    final profitPct = product.profitPercentage;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditModal),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'adjust',
                child: ListTile(
                  leading: Icon(Icons.inventory),
                  title: Text('Adjust Stock'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: AppColors.error),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'adjust') {
                _showStockAdjustment();
              } else if (value == 'delete') {
                _deleteProduct();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.isMobile(context)
                ? double.infinity
                : 800.0,
          ),
          child: ListView(
            padding: EdgeInsets.all(
              ResponsiveHelper.isMobile(context) ? 16 : 24,
            ),
            children: [
              // Main info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  product.unit.displayName,
                                  style: TextStyle(
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      // Price row
                      Row(
                        children: [
                          _InfoTile(
                            label: 'Selling Price',
                            value: product.price.asCurrency,
                            icon: Icons.sell,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 16),
                          if (product.purchasePrice != null)
                            _InfoTile(
                              label: 'Cost Price',
                              value: product.purchasePrice!.asCurrency,
                              icon: Icons.shopping_cart,
                              color: AppColors.warning,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stock card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _InfoTile(
                            label: 'Current Stock',
                            value:
                                '${product.stock} ${product.unit.displayName}',
                            icon: Icons.inventory,
                            color: product.isLowStock
                                ? AppColors.error
                                : AppColors.success,
                          ),
                          const SizedBox(width: 16),
                          _InfoTile(
                            label: 'Low Stock Alert',
                            value:
                                '${product.lowStockAlert} ${product.unit.displayName}',
                            icon: Icons.warning_amber,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                      if (product.isLowStock) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                product.stock == 0
                                    ? 'Out of stock!'
                                    : 'Low stock - Reorder soon',
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Profit card (if purchase price available)
              if (product.purchasePrice != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profit Analysis',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _InfoTile(
                              label: 'Profit per Unit',
                              value: profit != null ? profit.asCurrency : '-',
                              icon: Icons.trending_up,
                              color: (profit ?? 0) > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 16),
                            _InfoTile(
                              label: 'Profit %',
                              value: profitPct != null
                                  ? '${profitPct.toStringAsFixed(1)}%'
                                  : '-',
                              icon: Icons.percent,
                              color: (profitPct ?? 0) > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Additional info
              if (product.barcode != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: const Text('Barcode'),
                    subtitle: Text(product.barcode!),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showStockAdjustment,
            icon: const Icon(Icons.add),
            label: const Text('ADJUST STOCK'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
