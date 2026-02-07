/// Payment modal for completing bills
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/services/bill_sharing_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/payment_link_service.dart';
import 'package:retaillite/core/services/receipt_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/billing/providers/cart_provider.dart';

import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/features/reports/providers/reports_provider.dart';

import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
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

    // For UPI payment, create and send payment link
    if (_selectedMethod == PaymentMethod.upi) {
      await _processUpiPaymentLink(cart);
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

        // Invalidate customers if Udhar payment was made
        if (_selectedMethod == PaymentMethod.udhar) {
          ref.invalidate(customersProvider);
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

  /// Process UPI payment via payment link (create link, send, wait for payment)
  Future<void> _processUpiPaymentLink(CartState cart) async {
    final user = ref.read(currentUserProvider);
    final customerName =
        _selectedCustomer?.name ?? cart.customerName ?? 'Customer';
    final customerPhone = _selectedCustomer?.phone;

    // Check if customer has phone number
    if (customerPhone == null || customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number required for UPI payment link'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create payment link
      final result = await PaymentLinkService.createPaymentLink(
        amount: cart.total,
        customerName: customerName,
        customerPhone: customerPhone,
        description: 'Bill payment at ${user?.shopName ?? 'Store'}',
        shopName: user?.shopName,
      );

      if (!result.success || result.paymentLink == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to create payment link'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Show sending dialog and send link
      if (mounted) {
        await _showPaymentLinkDialog(
          cart: cart,
          paymentLink: result.paymentLink!,
          customerName: customerName,
          customerPhone: customerPhone,
          shopName: user?.shopName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  /// Show payment link dialog with share options
  Future<void> _showPaymentLinkDialog({
    required CartState cart,
    required String paymentLink,
    required String customerName,
    required String customerPhone,
    String? shopName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.link, color: AppColors.upi),
              SizedBox(width: 8),
              Text('Payment Link Ready'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ${cart.total.asCurrency}'),
              Text('Customer: $customerName'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.upi.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.upi),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Send the link to customer. Mark as paid after customer confirms payment.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Send via WhatsApp
                final sent = await PaymentLinkService.shareViaWhatsApp(
                  paymentLink: paymentLink,
                  amount: cart.total,
                  customerPhone: customerPhone,
                  shopName: shopName,
                  customerName: customerName,
                );
                if (!sent && dialogContext.mounted) {
                  // Fallback to generic share
                  await PaymentLinkService.shareGeneric(
                    paymentLink: paymentLink,
                    amount: cart.total,
                    shopName: shopName,
                    customerName: customerName,
                  );
                }
              },
              icon: const Icon(Icons.send),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              label: const Text('Send Link'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.check_circle),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.upi),
              label: const Text('Payment Done'),
            ),
          ],
        );
      },
    );

    // If payment confirmed, create bill
    if (result == true && mounted) {
      await _completeBillAfterPayment(cart, PaymentMethod.upi);
    }
  }

  /// Complete bill after payment confirmation
  Future<void> _completeBillAfterPayment(
    CartState cart,
    PaymentMethod method,
  ) async {
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
        paymentMethod: method,
        customerId: _selectedCustomer?.id ?? cart.customerId,
        customerName: _selectedCustomer?.name ?? cart.customerName,
        receivedAmount: cart.total,
        createdAt: now,
        date: dateStr,
      );

      // Save bill
      await OfflineStorageService.saveBillLocally(bill);

      if (mounted) {
        ref.invalidate(periodBillsProvider);
        ref.invalidate(salesSummaryProvider);
        ref.invalidate(topProductsProvider);

        ref.read(cartProvider.notifier).clearCart();
        Navigator.of(context).pop();
        _showBillCompleteDialog(bill);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment received successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bill: $e'),
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Print failed: $e')),
                            );
                          }
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
                        // Get customer phone
                        final phone = _selectedCustomer?.phone;
                        if (phone != null && phone.isNotEmpty) {
                          final success = await BillSharingService.sendWhatsApp(
                            phone: phone,
                            bill: bill,
                            shopName: user?.shopName,
                          );
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open WhatsApp'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
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
                  if (BillSharingService.isSmsAvailable)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final phone = _selectedCustomer?.phone;
                          if (phone != null && phone.isNotEmpty) {
                            final success = await BillSharingService.sendSMS(
                              phone: phone,
                              bill: bill,
                              shopName: user?.shopName,
                            );
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open SMS'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
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
                        icon: const Icon(Icons.sms, color: AppColors.primary),
                        label: const Text('SMS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  if (BillSharingService.isSmsAvailable)
                    const SizedBox(width: 8),
                  // Email button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        try {
                          await BillSharingService.sendEmail(
                            bill: bill,
                            shopName: user?.shopName,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not open email: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.email, color: AppColors.upi),
                      label: const Text('Email'),
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
              color: AppColors.textSecondaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dividerLight),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'No customers in Khata. Add from Khata screen.',
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CustomerModel?>(
              value: _selectedCustomer,
              hint: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select customer',
                    style: TextStyle(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
              isExpanded: true,
              items: [
                // Option to clear selection
                DropdownMenuItem<CustomerModel?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No customer',
                        style: TextStyle(color: AppColors.textSecondaryLight),
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
                          radius: 14,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (customer.balance > 0)
                                Text(
                                  'Balance: ${customer.balance.asCurrency}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.udhar,
                                  ),
                                ),
                            ],
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
        child: Text(
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
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.payment, color: AppColors.primary),
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
              const SizedBox(height: 8),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Total: '),
                    Text(
                      cart.total.asCurrency,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Customer selection
              Text(
                'Customer (Optional)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              _buildCustomerSelector(),
              const SizedBox(height: 20),

              // Payment method selection
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _selectedMethod == method;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: method != PaymentMethod.udhar ? 8 : 0,
                      ),
                      child: _PaymentMethodButton(
                        method: method,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedMethod = method),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Cash received (only for cash)
              if (_selectedMethod == PaymentMethod.cash) ...[
                CurrencyTextField(
                  label: 'Received Amount',
                  controller: _receivedController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
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
                label: '✅ COMPLETE BILL',
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _color : AppColors.dividerLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(method.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                method.displayName,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
