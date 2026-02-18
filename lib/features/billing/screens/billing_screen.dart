/// Main billing screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/services/barcode_scanner_service.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';
import 'package:retaillite/features/billing/widgets/payment_modal.dart';
import 'package:retaillite/features/billing/screens/pos_web_screen.dart';
import 'package:retaillite/features/products/providers/products_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/router/app_router.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentModal(),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Consumer(
            builder: (context, ref, _) =>
                _buildCartSheetContent(scrollController, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSheetContent(
    ScrollController scrollController,
    WidgetRef ref,
  ) {
    final l10n = context.l10n;
    final cart = ref.watch(cartProvider);

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cart (${cart.itemCount} items)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (cart.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).clearCart();
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n.clear,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        // Cart items
        Expanded(
          child: cart.isEmpty
              ? Center(child: Text(l10n.emptyCart))
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(item, ref);
                  },
                ),
        ),
        // Footer
        if (cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.total,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        Formatters.currency(cart.total),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showPaymentModal();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(l10n.pay.toUpperCase()),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.currency(item.price)} x ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(item.total),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .decrementQuantity(item.productId),
                  icon: const Icon(Icons.remove, size: 16),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .incrementQuantity(item.productId),
                  icon: const Icon(Icons.add, size: 16),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final l10n = context.l10n;
    final code = await BarcodeScannerService.scanBarcode(context);
    if (code == null) return;

    // Search for product by barcode
    final products = ref.read(productsProvider).value ?? [];
    ProductModel? foundProduct;

    for (final p in products) {
      if (p.barcode == code) {
        foundProduct = p;
        break;
      }
    }

    if (foundProduct != null) {
      ref.read(cartProvider.notifier).addProduct(foundProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.add} ${foundProduct.name}')),
        );
      }
    } else {
      // Product not found, offer to add
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.barcode} "$code" ${l10n.noData}'),
            action: SnackBarAction(
              label: l10n.add.toUpperCase(),
              onPressed: () =>
                  context.push('${AppRoutes.products}?barcode=$code'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // l10n is declared in each sub-layout method
    final cart = ref.watch(cartProvider);
    final productsAsync = ref.watch(productsProvider);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // At narrow tablet (< 768px), the 320px cart panel leaves too little
    // space for product cards. Use mobile layout instead.
    final useTabletLayout = isTablet && screenWidth >= 768;
    final useMobileLayout = !isDesktop && !useTabletLayout;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Dismiss keyboard on back press
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: isDesktop
              ? const PosWebScreen()
              : useTabletLayout
              ? _buildTabletLayout(productsAsync, cart)
              : _buildMobileLayout(productsAsync, cart),
        ),
        // Mobile + narrow tablet: sticky cart bar at bottom
        bottomNavigationBar: useMobileLayout && cart.isNotEmpty
            ? _MobileCartBar(
                itemCount: cart.itemCount,
                total: cart.total,
                onTap: _showCartSheet,
                onPay: _showPaymentModal,
              )
            : null,
      ),
    );
  }

  Widget _buildTabletLayout(
    AsyncValue<List<dynamic>> productsAsync,
    CartState cart,
  ) {
    final l10n = context.l10n;

    return Row(
      children: [
        // Products section (60%)
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = _filterProducts(
                      products.cast<ProductModel>(),
                    );
                    final spacing = ResponsiveHelper.spacing(context);
                    final cols = ResponsiveHelper.gridColumns(context);
                    return GridView.builder(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.pagePadding(context),
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: 0.7,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _buildProductCard(product);
                      },
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
        ),
        // Cart section (40%)
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    const SizedBox(width: 8),
                    Text(
                      'Cart (${cart.itemCount})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (cart.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            ref.read(cartProvider.notifier).clearCart(),
                        child: Text(l10n.clear),
                      ),
                  ],
                ),
              ),
              // Cart items
              Expanded(
                child: cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.emptyCart,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          Formatters.currency(item.price),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .decrementQuantity(item.productId),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .incrementQuantity(item.productId),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Footer with total and pay button
              if (cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.total,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            Formatters.currency(cart.total),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: ResponsiveHelper.buttonHeight(context),
                        child: ElevatedButton.icon(
                          onPressed: _showPaymentModal,
                          icon: const Icon(Icons.payment),
                          label: Text(l10n.pay.toUpperCase()),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(cartProvider.notifier).addProduct(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.inventory_2_outlined, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(product.price),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    AsyncValue<List<dynamic>> productsAsync,
    CartState cart,
  ) {
    final l10n = context.l10n;

    return Column(
      children: [
        // Search bar
        _buildSearchBar(),

        // Products only (cart is now in sticky bottom bar)
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final filtered = _filterProducts(products.cast<ProductModel>());
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  80,
                ), // 80 for cart bar
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  return _buildMobileProductCard(product);
                },
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
    );
  }

  Widget _buildMobileProductCard(ProductModel product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => ref.read(cartProvider.notifier).addProduct(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image - compact
            Expanded(
              flex: 3,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.inventory_2_outlined, size: 32),
                      ),
              ),
            ),
            // Content - compact with text truncation
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            Formatters.currency(product.price),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: l10n.searchProducts,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    FocusScope.of(context).unfocus();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _scanBarcode(),
              ),
            ],
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) {
      final product = p;
      return product.name.toLowerCase().contains(_searchQuery) ||
          (product.barcode?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }
}

// ============ MOBILE CART BAR ============
class _MobileCartBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const _MobileCartBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cart info - tappable to expand
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CART ($itemCount items)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              Formatters.currency(total),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Pay button
            ElevatedButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('PAY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
