// ignore_for_file: unused_import
part of 'pos_web_screen.dart';

/// Extracted POS web screen widgets (4.1 — split large files)

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
  final _udharAmountController = TextEditingController();
  CustomerModel? _selectedCustomer;
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  bool _isLoading = false;

  double get _udharAmount {
    return double.tryParse(_udharAmountController.text) ?? 0;
  }

  void _syncUdharAmount() {
    if (_selectedPayment == PaymentMethod.udhar && _selectedCustomer != null) {
      final cart = ref.read(cartProvider);
      _udharAmountController.text = cart.total.toInt().toString();
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _udharAmountController.dispose();
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
      final allowed = await UserMetricsService.trackBillCreated();
      if (!allowed) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '🚫 Monthly bill limit reached. Upgrade to Pro for 500 bills/month.',
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Upgrade',
                onPressed: () => context.push(AppRoutes.subscription),
              ),
            ),
          );
        }
        return;
      }

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final bill = BillModel(
        id: generateSafeId('bill'),
        billNumber: await OfflineStorageService.getNextBillNumber(),
        items: cart.items,
        total: cart.total,
        paymentMethod: _selectedPayment,
        customerId: _selectedCustomer?.id ?? cart.customerId,
        customerName: _selectedCustomer?.name ?? cart.customerName,
        receivedAmount: cart.total,
        createdAt: now,
        date: dateStr,
      );

      await OfflineStorageService.saveBillLocally(bill);

      if (_selectedPayment == PaymentMethod.udhar &&
          _selectedCustomer != null) {
        final udharAmount = _udharAmount;
        if (udharAmount <= 0 || udharAmount > cart.total) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  udharAmount <= 0
                      ? 'Enter an amount to add to khata'
                      : 'Khata amount cannot exceed bill total',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        await OfflineStorageService.updateCustomerBalance(
          _selectedCustomer!.id,
          udharAmount,
        );
        await OfflineStorageService.saveTransaction(
          customerId: _selectedCustomer!.id,
          type: 'purchase',
          amount: udharAmount,
          billId: bill.id,
        );
      }

      if (mounted) {
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

        // Low stock notifications (non-blocking)
        final userId = ref.read(authNotifierProvider).user?.id;
        if (userId != null) {
          final products = ref.read(productsProvider).valueOrNull ?? [];
          final productMap = {for (final p in products) p.id: p};
          for (final item in cart.items) {
            final product = productMap[item.productId];
            if (product != null && product.lowStockAlert != null) {
              final remaining = product.stock - item.quantity;
              if (remaining <= product.lowStockAlert! && remaining >= 0) {
                unawaited(
                  NotificationFirestoreService.sendToUser(
                    userId: userId,
                    notification: NotificationModel(
                      id: '',
                      title: 'Low stock alert for ${product.name}',
                      body:
                          'Only $remaining left in stock (threshold: ${product.lowStockAlert})',
                      type: NotificationType.alert,
                      targetType: NotificationTargetType.user,
                      targetUserId: userId,
                      createdAt: DateTime.now(),
                      sentBy: 'system',
                      data: {'route': '/products/${product.id}'},
                    ),
                  ),
                );
              }
            }
          }
        }

        ref.read(cartProvider.notifier).clearCart();

        final printerState = ref.read(printerProvider);
        if (printerState.autoPrint) {
          final messenger = ScaffoldMessenger.of(context);
          unawaited(_printReceipt(bill, messenger));
        }

        _showBillCompleteDialog(bill);
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final isLimitError =
            errorStr.contains('permission-denied') ||
            errorStr.contains('permission_denied') ||
            errorStr.contains('missing or insufficient permissions');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLimitError
                  ? '🚫 Subscription limit reached. Upgrade your plan to continue.'
                  : 'Failed to complete bill: $e',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: isLimitError
                ? SnackBarAction(
                    label: 'Upgrade',
                    textColor: Colors.white,
                    onPressed: () => context.push(AppRoutes.subscription),
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            shopLogoPath: user?.shopLogoPath,
          );
          return;
      }

      if (directSuccess == false) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Print failed: Printer not connected'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _printReceipt(bill, scaffoldMessenger),
            ),
          ),
        );
      } else if (directSuccess == null) {
        await ReceiptService.printReceipt(
          bill: bill,
          shopName: user?.shopName,
          shopAddress: user?.address,
          shopPhone: user?.phone,
          gstNumber: user?.gstNumber,
          receiptFooter: footer,
          shopLogoPath: user?.shopLogoPath,
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    }
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
                          _syncUdharAmount();
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
              : Builder(
                  builder: (context) {
                    final productMap = <String, ProductModel>{};
                    productsAsync.whenData((products) {
                      for (final p in products) {
                        productMap[p.id] = p;
                      }
                    });
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cart.items.length,
                      separatorBuilder: (e, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        final imageUrl = productMap[item.productId]?.imageUrl;
                        return Dismissible(
                          key: ValueKey(item.productId),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => ref
                              .read(cartProvider.notifier)
                              .removeItem(item.productId),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  image: imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: imageUrl == null
                                    ? const Icon(Icons.image, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 10),
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
                              Text(
                                Formatters.currency(item.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
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
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .removeItem(item.productId),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        const SizedBox(height: 1),
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
                        gstEnabled
                            ? cart.total * (1 + taxRate / 100)
                            : cart.total,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
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
                              onTap: () {
                                setState(() => _selectedPayment = method);
                                _syncUdharAmount();
                              },
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
                if (_selectedPayment == PaymentMethod.upi) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (_selectedCustomer == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a customer first'),
                            ),
                          );
                          return;
                        }
                        final upiId = PaymentLinkService.upiId;
                        if (upiId.isEmpty ||
                            !PaymentLinkService.isValidUpiId(upiId)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please set your UPI ID in Settings first',
                              ),
                            ),
                          );
                          return;
                        }
                        final user = ref.read(currentUserProvider);
                        final shopName = (user?.shopName.isNotEmpty == true)
                            ? user!.shopName
                            : 'Store';
                        final amount = cart.total;
                        final payUrl =
                            PaymentLinkService.generatePaymentPageUrl(
                              upiId: upiId,
                              amount: amount,
                              payeeName: shopName,
                              transactionNote: 'Payment to $shopName',
                            );
                        final msg =
                            'Hi ${_selectedCustomer!.name},\n\n'
                            'Your bill amount is *Rs ${amount.toStringAsFixed(0)}*.\n\n'
                            'Pay via UPI:\n'
                            'Click here to pay:\n'
                            '$payUrl\n\n'
                            'Thank you\n'
                            '— $shopName';
                        final phone = '91${_selectedCustomer!.phone}';
                        final url = Uri.https('wa.me', '/$phone', {
                          'text': msg,
                        });
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send Payment Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: const BorderSide(color: AppColors.info),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                if (_selectedPayment == PaymentMethod.udhar) ...[
                  const SizedBox(height: 8),
                  if (_selectedCustomer != null) ...[
                    Text(
                      'Amount to add to ${_selectedCustomer!.name}\'s khata',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _udharAmountController,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: '\u{20B9} ',
                        prefixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                        hintText: '0',
                        filled: true,
                        fillColor: AppColors.warning.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.warning,
                            width: 2,
                          ),
                        ),
                        suffixIcon: TextButton(
                          onPressed: () {
                            _udharAmountController.text = cart.total
                                .toInt()
                                .toString();
                            setState(() {});
                          },
                          child: const Text('Full'),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_udharAmount > 0 && _udharAmount < cart.total) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${(cart.total - _udharAmount).asCurrency} paid now, ${_udharAmount.asCurrency} on credit',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please select a customer for Credit payment',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                            backgroundColor: AppColors.success,
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
        icon = Icons.attach_money;
        label = 'Cash';
      case PaymentMethod.upi:
        color = AppColors.upi;
        icon = Icons.qr_code;
        label = 'UPI';
      case PaymentMethod.udhar:
        color = AppColors.udhar;
        icon = Icons.credit_card;
        label = 'Credit';
      case PaymentMethod.unknown:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = 'Unknown';
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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
