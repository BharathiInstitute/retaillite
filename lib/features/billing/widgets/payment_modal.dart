/// Payment modal for completing bills
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/features/billing/services/bill_share_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/receipt_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';

import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/features/khata/providers/khata_stats_provider.dart';
import 'package:retaillite/features/khata/widgets/add_customer_modal.dart';
import 'package:retaillite/features/reports/providers/reports_provider.dart';

import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/features/billing/providers/billing_provider.dart';
import 'package:retaillite/shared/widgets/app_button.dart';
import 'package:retaillite/shared/widgets/app_text_field.dart';

class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _receivedController = TextEditingController();
  bool _isLoading = false;
  CustomerModel? _selectedCustomer;

  @override
  void dispose() {
    _receivedController.dispose();
    super.dispose();
  }

  double get _receivedAmount {
    return double.tryParse(_receivedController.text) ?? 0;
  }

  Future<void> _completeBill() async {
    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      BillModel bill;

      // Create bill locally
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      bill = BillModel(
        id: 'bill_${now.millisecondsSinceEpoch}',
        billNumber: now.millisecondsSinceEpoch % 10000,
        items: cart.items,
        total: cart.total,
        paymentMethod: _selectedMethod,
        customerId: _selectedCustomer?.id ?? cart.customerId,
        customerName: _selectedCustomer?.name ?? cart.customerName,
        receivedAmount: _selectedMethod == PaymentMethod.cash
            ? _receivedAmount
            : null,
        createdAt: now,
        date: dateStr,
      );

      // Save bill to local storage for Reports
      await OfflineStorageService.saveBillLocally(bill);

      // Update customer khata balance for Udhar payments
      if (_selectedMethod == PaymentMethod.udhar && _selectedCustomer != null) {
        await OfflineStorageService.updateCustomerBalance(
          _selectedCustomer!.id,
          cart.total,
        );

        // Save transaction for customer history
        await OfflineStorageService.saveTransaction(
          customerId: _selectedCustomer!.id,
          type: 'purchase',
          amount: cart.total,
          billId: bill.id,
        );
      }

      if (mounted) {
        // Invalidate reports providers to refresh data
        ref.invalidate(periodBillsProvider);
        ref.invalidate(salesSummaryProvider);
        ref.invalidate(topProductsProvider);
        ref.invalidate(filteredBillsProvider);
        ref.invalidate(dashboardBillsProvider);

        // Invalidate customers if Udhar payment was made
        if (_selectedMethod == PaymentMethod.udhar) {
          ref.invalidate(customersProvider);
          ref.invalidate(sortedCustomersProvider);
          ref.invalidate(khataStatsProvider);
        }

        ref.read(cartProvider.notifier).clearCart();
        Navigator.of(context).pop();
        _showBillCompleteDialog(bill);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create bill: $e'),
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

  void _showBillCompleteDialog(BillModel bill) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Get user info for receipt
        final user = ref.read(currentUserProvider);

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
                        try {
                          await ReceiptService.printReceipt(
                            bill: bill,
                            shopName: user?.shopName,
                            shopAddress: user?.address,
                            shopPhone: user?.phone,
                            gstNumber: user?.gstNumber,
                          );
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Print failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Share options - WhatsApp, SMS, Email
              Row(
                children: [
                  // WhatsApp button
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
                              const SnackBar(
                                content: Text('No customer phone available'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat, color: AppColors.success),
                      label: const Text('WhatsApp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // SMS button (only on mobile)
                  if (!kIsWeb)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final phone = _selectedCustomer?.phone;
                          if (phone != null && phone.isNotEmpty) {
                            await BillShareService.shareViaSms(
                              bill,
                              phone,
                              context: context,
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No customer phone available'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.sms, color: AppColors.primary),
                        label: const Text('SMS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  if (!kIsWeb) const SizedBox(width: 8),
                  // PDF Download button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await BillShareService.downloadPdf(
                          bill,
                          context: context,
                        );
                      },
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: AppColors.upi,
                      ),
                      label: const Text('PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.upi,
                      ),
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

  Widget _buildCustomerSelector() {
    final customersAsync = ref.watch(customersProvider);

    return customersAsync.when(
      data: (customers) {
        if (customers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppShadows.small,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'No customers in Khata. Add from Khata screen.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.small,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CustomerModel?>(
              value: _selectedCustomer,
              hint: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select customer',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              items: [
                // Option to clear selection
                DropdownMenuItem<CustomerModel?>(
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No customer',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Customer list
                ...customers.map(
                  (customer) => DropdownMenuItem<CustomerModel?>(
                    value: customer,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${customer.name} • ${customer.phone}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (customer.balance > 0)
                          Text(
                            customer.balance.asCurrency,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.udhar,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (customer) {
                setState(() => _selectedCustomer = customer);
              },
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        child: const Text(
          'Could not load customers',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final change = _receivedAmount - cart.total;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.payment, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Payment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Total
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Total: '),
                    Text(
                      cart.total.asCurrency,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Customer selection
              Row(
                children: [
                  Text(
                    'Customer (Optional)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.person_add, size: 20),
                    tooltip: 'Add Customer',
                    onPressed: () {
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
              _buildCustomerSelector(),
              const SizedBox(height: 12),

              // Payment method selection
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Row(
                children: PaymentMethod.values
                    .where((m) => m != PaymentMethod.unknown)
                    .map((method) {
                      final isSelected = _selectedMethod == method;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: method != PaymentMethod.udhar ? 8 : 0,
                          ),
                          child: _PaymentMethodButton(
                            method: method,
                            isSelected: isSelected,
                            onTap: () =>
                                setState(() => _selectedMethod = method),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Cash received (only for cash)
              if (_selectedMethod == PaymentMethod.cash) ...[
                CurrencyTextField(
                  label: 'Received Amount',
                  controller: _receivedController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                // Quick amount buttons
                Wrap(
                  spacing: 8,
                  children:
                      [50, 100, 200, 500].map((amount) {
                        return ActionChip(
                          label: Text('₹$amount'),
                          onPressed: () {
                            _receivedController.text = amount.toString();
                            setState(() {});
                          },
                        );
                      }).toList()..add(
                        ActionChip(
                          label: const Text('Exact'),
                          onPressed: () {
                            _receivedController.text = cart.total
                                .toInt()
                                .toString();
                            setState(() {});
                          },
                        ),
                      ),
                ),
                if (_receivedAmount >= cart.total) ...[
                  const SizedBox(height: 8),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Return: '),
                        Text(
                          change.asCurrency,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],

              // Udhar warning/validation
              if (_selectedMethod == PaymentMethod.udhar) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedCustomer != null
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedCustomer != null
                          ? AppColors.warning.withValues(alpha: 0.3)
                          : AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedCustomer != null
                            ? Icons.info_outline
                            : Icons.warning_amber,
                        color: _selectedCustomer != null
                            ? AppColors.warning
                            : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCustomer != null
                              ? '${cart.total.asCurrency} will be added to ${_selectedCustomer!.name}\'s khata'
                              : 'Please select a customer for Udhar payment',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _selectedCustomer == null
                                    ? AppColors.error
                                    : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Complete button
              AppButton(
                label: 'COMPLETE BILL',
                onPressed:
                    (_selectedMethod == PaymentMethod.udhar &&
                        _selectedCustomer == null)
                    ? null
                    : _completeBill,
                isLoading: _isLoading,
                backgroundColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color {
    switch (method) {
      case PaymentMethod.cash:
        return AppColors.cash;
      case PaymentMethod.upi:
        return AppColors.upi;
      case PaymentMethod.udhar:
        return AppColors.udhar;
      case PaymentMethod.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? _color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: _color, width: 2) : null,
            boxShadow: isSelected ? null : AppShadows.small,
          ),
          child: Column(
            children: [
              Text(method.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                method.displayName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? _color : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
