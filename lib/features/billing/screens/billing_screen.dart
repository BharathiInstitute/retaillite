/// Main billing screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/services/barcode_scanner_service.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';
import 'package:retaillite/features/billing/widgets/cart_section.dart';
import 'package:retaillite/features/billing/widgets/payment_modal.dart';
import 'package:retaillite/features/billing/widgets/product_grid.dart';
import 'package:retaillite/features/billing/screens/pos_web_screen.dart';
import 'package:retaillite/features/products/providers/products_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';
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

  Future<void> _scanBarcode() async {
    final l10n = context.l10n;
    final code = await BarcodeScannerService.scanBarcode(context);
    if (code == null) return;

    // Search for product by barcode
    final products = ref.read(productsProvider).value ?? [];
    dynamic foundProduct;

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
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final cart = ref.watch(cartProvider);
    final productsAsync = ref.watch(productsProvider);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: (isDesktop || isTablet)
          ? null
          : AppBar(
              title: Row(
                children: [
                  const Icon(Icons.store, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user?.shopName ?? l10n.appName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Show notifications
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
      body: isDesktop
          ? const PosWebScreen()
          : isTablet
          ? _buildTabletLayout(productsAsync, cart)
          : _buildMobileLayout(productsAsync, cart),
      floatingActionButton: cart.isNotEmpty && !isDesktop && !isTablet
          ? FloatingActionButton.extended(
              onPressed: _showPaymentModal,
              icon: const Icon(Icons.payment),
              label: Text(
                '${l10n.pay.toUpperCase()} ${Formatters.currency(cart.total)}',
              ),
            )
          : null,
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
                    final filtered = _filterProducts(products);
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
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
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
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
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
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
                        height: 48,
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

  Widget _buildProductCard(dynamic product) {
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

        // Products and Cart
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final filtered = _filterProducts(products);
              return CustomScrollView(
                slivers: [
                  // Product Grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: ProductGrid(
                      products: filtered,
                      onProductTap: (product) {
                        ref.read(cartProvider.notifier).addProduct(product);
                      },
                    ),
                  ),

                  // Cart Section (if items present)
                  if (cart.isNotEmpty)
                    SliverToBoxAdapter(
                      child: CartSection(onPay: _showPaymentModal),
                    ),

                  // Bottom padding for FAB
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
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

  Widget _buildSearchBar() {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
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

  List<dynamic> _filterProducts(List<dynamic> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) {
      final product = p;
      return product.name.toLowerCase().contains(_searchQuery) ||
          (product.barcode?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }
}
