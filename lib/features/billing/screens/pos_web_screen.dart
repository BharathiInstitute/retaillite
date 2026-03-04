import 'dart:async';
import 'package:flutter/material.dart';
import 'package:retaillite/core/utils/id_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/features/billing/widgets/payment_modal.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/features/khata/providers/khata_stats_provider.dart';
import 'package:retaillite/features/khata/widgets/add_customer_modal.dart';
import 'package:retaillite/features/products/providers/products_provider.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/product_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/user_metrics_service.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/router/app_router.dart';
import 'package:retaillite/features/reports/providers/reports_provider.dart';
import 'package:retaillite/features/billing/providers/billing_provider.dart';
import 'package:retaillite/core/services/receipt_service.dart';
import 'package:retaillite/core/services/thermal_printer_service.dart';
import 'package:retaillite/features/billing/services/bill_share_service.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/features/notifications/services/notification_firestore_service.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';

part 'pos_web_widgets.dart';

class PosWebScreen extends ConsumerStatefulWidget {
  const PosWebScreen({super.key});

  @override
  ConsumerState<PosWebScreen> createState() => _PosWebScreenState();
}

class _PosWebScreenState extends ConsumerState<PosWebScreen> {
  String _searchQuery = '';
  CustomerModel? _selectedCustomer;
  final _tabletScaffoldKey = GlobalKey<ScaffoldState>();

  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentModal(),
    );
  }

  void _showCustomerSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerSelectorSheet(
        onCustomerSelected: (customer) {
          setState(() => _selectedCustomer = customer);
          ref
              .read(cartProvider.notifier)
              .setCustomer(customer.id, customer.name);
          Navigator.pop(context);
        },
        onClear: () {
          setState(() => _selectedCustomer = null);
          ref.read(cartProvider.notifier).clearCustomer();
          Navigator.pop(context);
        },
        selectedCustomer: _selectedCustomer,
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _WebCartSection(
            onPay: () {
              Navigator.pop(context);
              _showPaymentModal();
            },
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    // Mobile Layout
    if (isMobile) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // Mobile Header with customer selection
            _buildMobileHeader(),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildMobileSearchBar(),
            ),
            // Product Grid
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  final filtered = _filterProducts(products);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.gridColumns(context),
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _MobileProductCard(
                        product: filtered[index],
                        onTap: () {
                          ref
                              .read(cartProvider.notifier)
                              .addProduct(filtered[index]);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Error loading products')),
              ),
            ),
          ],
        ),
        // Sticky bottom cart bar
        bottomNavigationBar: cart.isEmpty
            ? null
            : _MobileCartBar(
                itemCount: cart.itemCount,
                total: cart.total,
                onTap: _showCartSheet,
                onPay: _showPaymentModal,
              ),
      );
    }

    // Tablet Layout — full-width grid with slide-in cart overlay
    if (isTablet) {
      return Scaffold(
        key: _tabletScaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        endDrawer: SizedBox(
          width: 340,
          child: Drawer(
            child: _WebCartSection(
              onPay: () {
                Navigator.of(context).pop(); // close drawer
                _showPaymentModal();
              },
            ),
          ),
        ),
        body: Builder(
          builder: (scaffoldContext) => Column(
            children: [
              // Search Bar & Filter — reuse desktop search bar with tablet padding
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSearchAndFilter(),
              ),
              // Product Grid — 3 columns, full width
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = _filterProducts(products);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _WebProductCard(
                          product: filtered[index],
                          onTap: () {
                            ref
                                .read(cartProvider.notifier)
                                .addProduct(filtered[index]);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (e, _) =>
                      const Center(child: Text('Error loading products')),
                ),
              ),
            ],
          ),
        ),
        // Floating cart button
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _tabletScaffoldKey.currentState?.openEndDrawer(),
          backgroundColor: AppColors.primary,
          icon: Badge(
            label: Text('${cart.itemCount}'),
            isLabelVisible: cart.itemCount > 0,
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
          label: Text(
            cart.isEmpty ? 'Cart' : cart.total.asCurrency,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Desktop Layout (existing)
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Product Catalog
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Search Bar & Filter
                  _buildSearchAndFilter(),
                  const SizedBox(height: 24),

                  // Product Grid
                  Expanded(
                    child: productsAsync.when(
                      data: (products) {
                        final filtered = _filterProducts(products);
                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              'No products found',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent:
                                    ResponsiveHelper.isDesktopLarge(context)
                                    ? 240
                                    : 220,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _WebProductCard(
                              product: filtered[index],
                              onTap: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addProduct(filtered[index]);
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: LoadingIndicator()),
                      error: (e, _) =>
                          const Center(child: Text('Error loading products')),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Cart
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 340, maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.medium,
              ),
              child: _WebCartSection(onPay: _showPaymentModal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Customer selector button
            Expanded(
              child: GestureDetector(
                onTap: _showCustomerSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedCustomer != null
                        ? AppColors.primaryBg
                        : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: _selectedCustomer != null
                        ? Border.all(color: AppColors.primary)
                        : null,
                    boxShadow: _selectedCustomer == null
                        ? AppShadows.small
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedCustomer != null
                            ? Icons.person
                            : Icons.person_add_outlined,
                        size: 18,
                        color: _selectedCustomer != null
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCustomer?.name ?? 'Add Customer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedCustomer != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _selectedCustomer != null
                                ? AppColors.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Barcode scanner
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppShadows.small,
              ),
              child: const Icon(Icons.qr_code_scanner, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return TextField(
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: const TextStyle(fontSize: 14),
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search item by name or code...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          onChanged: (value) =>
              setState(() => _searchQuery = value.toLowerCase()),
        ),
      ],
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) {
      return p.name.toLowerCase().contains(_searchQuery) ||
          (p.barcode?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }
}
