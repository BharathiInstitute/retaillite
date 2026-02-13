/// Product grid widget for billing screen
library;

import 'package:flutter/material.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/models/product_model.dart';

class ProductGrid extends StatelessWidget {
  final List<dynamic> products;
  final Function(ProductModel) onProductTap;
  final bool isSliver;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.isSliver = true,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return isSliver
          ? const SliverFillRemaining(child: _EmptyProducts())
          : const _EmptyProducts();
    }

    final spacing = ResponsiveHelper.spacing(context);
    final cardHeight = ResponsiveHelper.productCardHeight(context);
    final screenWidth = ResponsiveHelper.screenWidth(context);
    final cols = ResponsiveHelper.gridColumns(context);
    final cardWidth = (screenWidth - (cols + 1) * spacing) / cols;

    if (isSliver) {
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: cardWidth / cardHeight,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ProductTile(
            product: products[index] as ProductModel,
            onTap: () => onProductTap(products[index] as ProductModel),
          ),
          childCount: products.length,
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(ResponsiveHelper.pagePadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: cardWidth / cardHeight,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _ProductTile(
        product: products[index] as ProductModel,
        onTap: () => onProductTap(products[index] as ProductModel),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isOutOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutOfStock
                  ? AppColors.error.withValues(alpha: 0.3)
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Product icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getEmoji(product.name),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Product name
              Text(
                product.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isOutOfStock
                      ? Theme.of(context).colorScheme.outline
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),

              // Price
              Text(
                product.price.asCurrency,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isOutOfStock
                      ? Theme.of(context).colorScheme.outline
                      : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Out of stock badge
              if (isOutOfStock)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'OUT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('atta') || lower.contains('flour')) return '🍚';
    if (lower.contains('salt') || lower.contains('namak')) return '🧂';
    if (lower.contains('oil') || lower.contains('tel')) return '🛢️';
    if (lower.contains('dal') || lower.contains('lentil')) return '🫘';
    if (lower.contains('soap') || lower.contains('sabun')) return '🧼';
    if (lower.contains('biscuit') || lower.contains('cookie')) return '🍪';
    if (lower.contains('tea') || lower.contains('chai')) return '🍵';
    if (lower.contains('shampoo')) return '🧴';
    if (lower.contains('sugar') || lower.contains('cheeni')) return '🍬';
    if (lower.contains('rice') || lower.contains('chawal')) return '🍚';
    if (lower.contains('milk') || lower.contains('doodh')) return '🥛';
    return '📦';
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products from the Products tab',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
