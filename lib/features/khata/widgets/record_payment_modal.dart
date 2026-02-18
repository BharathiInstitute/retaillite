import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/razorpay_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/features/khata/providers/khata_stats_provider.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/transaction_model.dart';
import 'package:retaillite/shared/widgets/app_button.dart';

class RecordPaymentModal extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const RecordPaymentModal({super.key, required this.customer});

  @override
  ConsumerState<RecordPaymentModal> createState() => _RecordPaymentModalState();
}

class _RecordPaymentModalState extends ConsumerState<RecordPaymentModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMode = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount {
    return double.tryParse(_amountController.text) ?? 0;
  }

  Future<void> _recordPayment() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_amount > widget.customer.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount exceeds customer balance'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // For online payment, use Razorpay
    if (_paymentMode == 'online') {
      await _processOnlinePayment();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isDemoMode = ref.read(isDemoModeProvider);

      if (isDemoMode) {
        // Demo mode: Update in-memory data
        DemoDataService.updateCustomerBalance(
          widget.customer.id,
          -_amount, // Negative to reduce balance
        );
        // Add transaction to demo data
        DemoDataService.addTransaction(
          customerId: widget.customer.id,
          type: TransactionType.payment,
          amount: _amount,
          note: _noteController.text.isEmpty
              ? _paymentMode
              : '$_paymentMode: ${_noteController.text}',
        );
      } else {
        // Real mode: Save to Firestore
        // 1. Update customer balance (subtract payment)
        await OfflineStorageService.updateCustomerBalance(
          widget.customer.id,
          -_amount, // Negative to reduce balance
        );

        // 2. Save payment transaction
        await OfflineStorageService.saveTransaction(
          customerId: widget.customer.id,
          type: 'payment',
          amount: _amount,
          note: _noteController.text.isEmpty
              ? _paymentMode
              : '$_paymentMode: ${_noteController.text}',
        );
      }

      // 3. Invalidate providers to refresh UI immediately
      ref.invalidate(customerProvider(widget.customer.id));
      ref.invalidate(customerTransactionsProvider(widget.customer.id));
      ref.invalidate(customersProvider);
      ref.invalidate(sortedCustomersProvider);
      ref.invalidate(khataStatsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ${_amount.asCurrency} recorded'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
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

  /// Process online payment via Razorpay
  Future<void> _processOnlinePayment() async {
    RazorpayService.instance.openCheckout(
      amount: _amount,
      customerName: widget.customer.name,
      customerPhone: widget.customer.phone,
      description: 'Khata payment collection',
      onComplete: (result) async {
        if (!mounted) return;

        if (result.success) {
          setState(() => _isLoading = true);

          try {
            // 1. Update customer balance
            await OfflineStorageService.updateCustomerBalance(
              widget.customer.id,
              -_amount,
            );

            // 2. Save transaction with Razorpay ID
            await OfflineStorageService.saveTransaction(
              customerId: widget.customer.id,
              type: 'payment',
              amount: _amount,
              note: 'Online: ${result.paymentId}',
            );

            // 3. Invalidate providers
            ref.invalidate(customerProvider(widget.customer.id));
            ref.invalidate(customerTransactionsProvider(widget.customer.id));
            ref.invalidate(customersProvider);
            ref.invalidate(sortedCustomersProvider);
            ref.invalidate(khataStatsProvider);

            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment of ${_amount.asCurrency} collected!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to record payment: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Payment failed'),
              backgroundColor: result.errorCode == 'CANCELLED'
                  ? AppColors.warning
                  : AppColors.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.customer.balance;

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
                  Icon(Icons.currency_rupee, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Record Payment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        widget.customer.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customer.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'बाकी: ${balance.asCurrency}',
                            style: TextStyle(
                              color: balance > 0
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount Received',
                  prefixText: '₹ ',
                  hintText: '0.00',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Quick amount buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickAmountChip(
                    label: '₹100',
                    onTap: () {
                      _amountController.text = '100';
                      setState(() {});
                    },
                  ),
                  _QuickAmountChip(
                    label: '₹500',
                    onTap: () {
                      _amountController.text = '500';
                      setState(() {});
                    },
                  ),
                  _QuickAmountChip(
                    label: '₹1000',
                    onTap: () {
                      _amountController.text = '1000';
                      setState(() {});
                    },
                  ),
                  _QuickAmountChip(
                    label: 'Full Amount',
                    onTap: () {
                      _amountController.text = balance.toStringAsFixed(0);
                      setState(() {});
                    },
                    isHighlighted: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment mode selection
              Text(
                'Payment Mode',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PaymentModeButton(
                      label: 'Cash',
                      icon: Icons.payments,
                      isSelected: _paymentMode == 'cash',
                      onTap: () => setState(() => _paymentMode = 'cash'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PaymentModeButton(
                      label: 'UPI',
                      icon: Icons.qr_code,
                      isSelected: _paymentMode == 'upi',
                      onTap: () => setState(() => _paymentMode = 'upi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PaymentModeButton(
                      label: 'Online',
                      icon: Icons.credit_card,
                      isSelected: _paymentMode == 'online',
                      onTap: () => setState(() => _paymentMode = 'online'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note input
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g., Partial payment',
                ),
              ),
              const SizedBox(height: 24),

              // New balance preview
              if (_amount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New Balance: '),
                      Text(
                        (balance - _amount).asCurrency,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: (balance - _amount) > 0
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

              // Submit button
              AppButton(
                label: '✅ RECORD PAYMENT',
                onPressed: _amount > 0 ? _recordPayment : null,
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

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _QuickAmountChip({
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isHighlighted
          ? AppColors.success.withValues(alpha: 0.2)
          : null,
      side: isHighlighted ? const BorderSide(color: AppColors.success) : null,
    );
  }
}

class _PaymentModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : null),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : null,
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
