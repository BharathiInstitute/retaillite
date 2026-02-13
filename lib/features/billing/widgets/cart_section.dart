/// Cart section widget for billing screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/shared/widgets/app_button.dart';

class CartSection extends ConsumerWidget {
  final VoidCallback onPay;
  final bool showHeader;

  const CartSection({super.key, required this.onPay, this.showHeader = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty && !showHeader) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: showHeader ? null : AppShadows.medium,
        borderRadius: showHeader
            ? null
            : const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: showHeader ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Header
          if (showHeader) ...[
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.modalPadding(context)),
              decoration: const BoxDecoration(),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Cart', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (cart.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          ref.read(cartProvider.notifier).clearCart(),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            // Collapsed header for mobile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'CART (${cart.itemCount} items)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        ref.read(cartProvider.notifier).clearCart(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Cart items
          if (cart.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cart is empty',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap products to add',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (showHeader)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cart.items.length,
                  separatorBuilder: (e, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _CartItemTile(item: cart.items[index]),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cart.items.length,
                  separatorBuilder: (e, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _CartItemTile(item: cart.items[index]),
                ),
              ),

            // Total and Pay button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items: ${cart.itemCount}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Total: ${Formatters.currency(cart.total)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: '💵 PAY ${Formatters.currency(cart.total)}',

                    onPressed: onPay,
                    backgroundColor: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Product name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${Formatters.currency(item.price)} × ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppShadows.small,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .decrementQuantity(item.productId),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .incrementQuantity(item.productId),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Total
          SizedBox(
            width: 60,
            child: Text(
              Formatters.currency(item.total),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
