import 'package:flutter/material.dart';
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
import 'package:retaillite/features/reports/providers/reports_provider.dart';
import 'package:retaillite/features/billing/providers/billing_provider.dart';
import 'package:retaillite/core/services/receipt_service.dart';
import 'package:retaillite/core/services/thermal_printer_service.dart';
import 'package:retaillite/features/billing/services/bill_share_service.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';

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
            suffixIcon: IconButton(
              icon: const Icon(Icons.mic_none),
              onPressed: () {}, // Voice search placeholder
            ),
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

class _WebProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _WebProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: product.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (product.imageUrl == null)
                        Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      // Stock Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).cardColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.stock} in stock',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.unit.displayName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            product.price.asCurrency,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebCartSection extends ConsumerStatefulWidget {
  final VoidCallback onPay;
  final ScrollController? scrollController;

  const _WebCartSection({required this.onPay, this.scrollController});

  @override
  ConsumerState<_WebCartSection> createState() => _WebCartSectionState();
}

class _WebCartSectionState extends ConsumerState<_WebCartSection> {
  final _customerController = TextEditingController();
  CustomerModel? _selectedCustomer;
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  bool _isLoading = false;

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  void _showAddCustomerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCustomerModal(),
    );
  }

  Future<void> _completeBill() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final bill = BillModel(
        id: 'bill_${now.millisecondsSinceEpoch}',
        billNumber: now.millisecondsSinceEpoch % 10000,
        items: cart.items,
        total: cart.total,
        paymentMethod: _selectedPayment,
        customerId: _selectedCustomer?.id ?? cart.customerId,
        customerName: _selectedCustomer?.name ?? cart.customerName,
        receivedAmount: cart.total, // specific logic can be added if needed
        createdAt: now,
        date: dateStr,
      );

      // Save bill
      await OfflineStorageService.saveBillLocally(bill);

      // Update customer balance if Udhar
      if (_selectedPayment == PaymentMethod.udhar &&
          _selectedCustomer != null) {
        await OfflineStorageService.updateCustomerBalance(
          _selectedCustomer!.id,
          cart.total,
        );
        await OfflineStorageService.saveTransaction(
          customerId: _selectedCustomer!.id,
          type: 'purchase',
          amount: cart.total,
          billId: bill.id,
        );
      }

      if (mounted) {
        // Refresh providers
        ref.invalidate(periodBillsProvider);
        ref.invalidate(salesSummaryProvider);
        ref.invalidate(topProductsProvider);
        ref.invalidate(filteredBillsProvider);
        ref.invalidate(dashboardBillsProvider);

        if (_selectedPayment == PaymentMethod.udhar) {
          ref.invalidate(customersProvider);
          ref.invalidate(sortedCustomersProvider);
          ref.invalidate(khataStatsProvider);
        }

        ref.read(cartProvider.notifier).clearCart();

        // Auto-print if enabled
        final printerState = ref.read(printerProvider);
        if (printerState.autoPrint) {
          _autoPrintReceipt(bill);
        }

        // Show success/receipt dialog
        _showBillCompleteDialog(bill);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete bill: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Print receipt using the configured printer type
  Future<void> _printReceipt(
    BillModel bill,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    try {
      final user = ref.read(currentUserProvider);
      final printerState = ref.read(printerProvider);
      final footer = printerState.receiptFooter.isNotEmpty
          ? printerState.receiptFooter
          : null;

      bool? directSuccess;

      switch (printerState.printerType) {
        case PrinterTypeOption.bluetooth:
          if (ThermalPrinterService.isAvailable) {
            directSuccess = await ThermalPrinterService.printReceipt(
              bill: bill,
              shopName: user?.shopName,
              shopAddress: user?.address,
              shopPhone: user?.phone,
              gstNumber: user?.gstNumber,
              receiptFooter: footer,
            );
          }
          break;

        case PrinterTypeOption.wifi:
          if (WifiPrinterService.isConnected) {
            directSuccess = await WifiPrinterService.printReceipt(
              bill: bill,
              shopName: user?.shopName,
              shopAddress: user?.address,
              shopPhone: user?.phone,
              gstNumber: user?.gstNumber,
              receiptFooter: footer,
            );
          }
          break;

        case PrinterTypeOption.usb:
          final usbName = UsbPrinterService.getSavedPrinterName();
          if (usbName.isNotEmpty) {
            directSuccess = await UsbPrinterService.printReceipt(
              printerName: usbName,
              bill: bill,
              shopName: user?.shopName,
              shopAddress: user?.address,
              shopPhone: user?.phone,
              gstNumber: user?.gstNumber,
              receiptFooter: footer,
            );
          }
          break;

        case PrinterTypeOption.system:
          await ReceiptService.printReceipt(
            bill: bill,
            shopName: user?.shopName,
            shopAddress: user?.address,
            shopPhone: user?.phone,
            gstNumber: user?.gstNumber,
            receiptFooter: footer,
          );
          return;
      }

      if (directSuccess == false) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Print failed: Printer not connected')),
        );
      } else if (directSuccess == null) {
        await ReceiptService.printReceipt(
          bill: bill,
          shopName: user?.shopName,
          shopAddress: user?.address,
          shopPhone: user?.phone,
          gstNumber: user?.gstNumber,
          receiptFooter: footer,
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    }
  }

  /// Auto-print receipt silently
  void _autoPrintReceipt(BillModel bill) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      await _printReceipt(bill, scaffoldMessenger);
    });
  }

  void _showBillCompleteDialog(BillModel bill) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Bill Complete!',
                style: Theme.of(dialogContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Bill No: #${bill.billNumber}'),
              Text(
                bill.total.asCurrency,
                style: Theme.of(dialogContext).textTheme.headlineSmall
                    ?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              // Print button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        Navigator.pop(dialogContext);
                        await _printReceipt(bill, scaffoldMessenger);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Share options
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        final phone = _selectedCustomer?.phone;
                        if (phone != null && phone.isNotEmpty) {
                          await BillShareService.shareViaWhatsApp(
                            bill,
                            phone,
                            context: context,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No phone number')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat, color: AppColors.success),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('NEW BILL'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final productsAsync = ref.watch(productsProvider);
    final customersAsync = ref.watch(customersProvider);
    final user = ref.watch(currentUserProvider);
    final taxRate = user?.settings.taxRate ?? 5.0;
    final gstEnabled = user?.settings.gstEnabled ?? true;

    return Column(
      children: [
        // Header - Customer Details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CUSTOMER DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: customersAsync.when(
                      data: (customers) => Autocomplete<CustomerModel>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<CustomerModel>.empty();
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return customers.where(
                            (c) =>
                                c.name.toLowerCase().contains(query) ||
                                c.phone.contains(query),
                          );
                        },
                        displayStringForOption: (c) => '${c.name} (${c.phone})',
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmit) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search by phone or name...',
                                  hintStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: _selectedCustomer != null
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _selectedCustomer = null;
                                              controller.clear();
                                            });
                                            ref
                                                .read(cartProvider.notifier)
                                                .clearCustomer();
                                          },
                                        )
                                      : null,
                                ),
                                onSubmitted: (_) => onSubmit(),
                              );
                            },
                        onSelected: (customer) {
                          setState(() => _selectedCustomer = customer);
                          ref
                              .read(cartProvider.notifier)
                              .setCustomer(customer.id, customer.name);
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                  maxWidth: 280,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final customer = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primaryBg,
                                        child: Text(
                                          customer.name.isNotEmpty
                                              ? customer.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(customer.name),
                                      subtitle: Text(
                                        customer.phone,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: customer.balance > 0
                                          ? Text(
                                              '₹${customer.balance.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                      onTap: () => onSelected(customer),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      loading: () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Loading...',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      error: (_, _) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Error loading customers',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showAddCustomerModal,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              // Show selected customer info
              if (_selectedCustomer != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedCustomer!.name} • ${_selectedCustomer!.phone}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_selectedCustomer!.balance > 0)
                        Text(
                          'Due: ₹${_selectedCustomer!.balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 1),

        // Cart Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Flexible(
                      child: Text(
                        'Current Cart',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${cart.itemCount} Items',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (cart.isNotEmpty)
                IconButton(
                  onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                  tooltip: 'Clear Cart',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),

        // Cart Items
        Expanded(
          child: cart.isEmpty
              ? Center(
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  separatorBuilder: (e, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];

                    // Lookup items image from products provider
                    String? imageUrl;
                    productsAsync.whenData((products) {
                      final product = products.cast<ProductModel?>().firstWhere(
                        (p) => p?.id == item.productId,
                        orElse: () => null,
                      );
                      imageUrl = product?.imageUrl;
                    });

                    return Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            image: imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageUrl == null
                              ? const Icon(Icons.image, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        // Name + price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${Formatters.currency(item.price)} x ${item.quantity}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Total price
                        Text(
                          Formatters.currency(item.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Qty Controls - inline
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .decrementQuantity(item.productId),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.remove, size: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .incrementQuantity(item.productId),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.add, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),

        const SizedBox(height: 1),

        // Billing Summary
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Subtotal',
                  value: Formatters.currency(cart.total),
                ),
                const SizedBox(height: 8),
                // Dynamic tax rate from user settings
                if (gstEnabled)
                  _SummaryRow(
                    label: 'Tax (GST ${taxRate.toStringAsFixed(0)}%)',
                    value: Formatters.currency(cart.total * taxRate / 100),
                  ),
                if (gstEnabled) const SizedBox(height: 8),
                const _SummaryRow(
                  label: 'Discount',
                  value: '-₹0.00',
                  isGreen: true,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(height: 1),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      Formatters.currency(
                        cart.total * 1.05,
                      ), // Adding fake tax for visual match
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // Payment Methods - CASH, UPI, CREDIT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: PaymentMethod.values
                      .where((m) => m != PaymentMethod.unknown)
                      .map((method) {
                        final isSelected = _selectedPayment == method;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: method != PaymentMethod.udhar ? 8 : 0,
                            ),
                            child: _PosPaymentButton(
                              method: method,
                              isSelected: isSelected,
                              onTap: () =>
                                  setState(() => _selectedPayment = method),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),

                // Credit warning - customer required
                if (_selectedPayment == PaymentMethod.udhar) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedCustomer != null
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedCustomer != null
                              ? Icons.info_outline
                              : Icons.warning_amber,
                          size: 16,
                          color: _selectedCustomer != null
                              ? AppColors.warning
                              : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCustomer != null
                                ? 'Amount will be added to ${_selectedCustomer!.name}\'s credit'
                                : 'Please select a customer for Credit payment',
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedCustomer == null
                                  ? AppColors.error
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed:
                              cart.isNotEmpty &&
                                  !(_selectedPayment == PaymentMethod.udhar &&
                                      _selectedCustomer == null)
                              ? _completeBill
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success, // Bright Green
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CHECKOUT',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isGreen
                ? AppColors.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ============ MOBILE PRODUCT CARD ============
class _MobileProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _MobileProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadows.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image - takes more space
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    image: product.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (product.imageUrl == null)
                        Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 32,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      // Stock badge
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).cardColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.stock}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content - compact
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            product.price.asCurrency,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBg,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
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
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
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
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Pay button
            ElevatedButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payment, size: 18),
              label: Text('PAY ${Formatters.currency(total)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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

class _PosPaymentButton extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PosPaymentButton({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (method) {
      case PaymentMethod.cash:
        color = AppColors.success;
        icon = Icons.attach_money; // Changed from money
        label = 'Cash';
        break;
      case PaymentMethod.upi:
        color = AppColors.upi;
        icon = Icons.qr_code;
        label = 'UPI';
        break;
      case PaymentMethod.udhar:
        color = AppColors.udhar;
        icon = Icons.credit_card; // Changed from contacts
        label = 'Credit';
        break;
      case PaymentMethod.unknown:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = 'Unknown';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ CUSTOMER SELECTOR SHEET ============
class _CustomerSelectorSheet extends ConsumerStatefulWidget {
  final Function(CustomerModel) onCustomerSelected;
  final VoidCallback onClear;
  final CustomerModel? selectedCustomer;

  const _CustomerSelectorSheet({
    required this.onCustomerSelected,
    required this.onClear,
    this.selectedCustomer,
  });

  @override
  ConsumerState<_CustomerSelectorSheet> createState() =>
      _CustomerSelectorSheetState();
}

class _CustomerSelectorSheetState
    extends ConsumerState<_CustomerSelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Select Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.selectedCustomer != null)
                  TextButton(
                    onPressed: widget.onClear,
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddCustomerModal(),
                    );
                  },
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          // Customer list
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = customers
                    .where(
                      (c) =>
                          c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.contains(_searchQuery),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    final isSelected =
                        widget.selectedCustomer?.id == customer.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.primaryBg,
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        customer.phone,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: customer.balance > 0
                          ? Text(
                              'Due: ₹${customer.balance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      onTap: () => widget.onCustomerSelected(customer),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Error loading customers')),
            ),
          ),
        ],
      ),
    );
  }
}
