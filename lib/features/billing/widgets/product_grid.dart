/// Product grid widget for billing screen
library;

import 'package:flutter/material.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
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

    if (isSliver) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
                  : AppColors.dividerLight,
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
                  color: isOutOfStock ? AppColors.textTertiaryLight : null,
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
                      ? AppColors.textTertiaryLight
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
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products from the Products tab',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiaryLight),
          ),
        ],
      ),
    );
  }
}
