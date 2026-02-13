import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/shared/widgets/app_button.dart';

/// Modal to give Udhaar (credit) to a customer
/// Similar to RecordPaymentModal but ADDS to balance instead of subtracting
class GiveUdhaarModal extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const GiveUdhaarModal({super.key, required this.customer});

  @override
  ConsumerState<GiveUdhaarModal> createState() => _GiveUdhaarModalState();
}

class _GiveUdhaarModalState extends ConsumerState<GiveUdhaarModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
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

  Future<void> _giveUdhaar() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Update customer balance (ADD credit - positive amount)
      await OfflineStorageService.updateCustomerBalance(
        widget.customer.id,
        _amount, // Positive to increase balance (customer owes more)
      );

      // 2. Save credit transaction
      await OfflineStorageService.saveTransaction(
        customerId: widget.customer.id,
        type: 'purchase',
        amount: _amount,
        note: _noteController.text.isEmpty
            ? 'Credit given'
            : _noteController.text,
      );

      // 3. Invalidate providers to refresh UI
      ref.invalidate(customerProvider(widget.customer.id));
      ref.invalidate(customerTransactionsProvider(widget.customer.id));
      ref.invalidate(customersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Udhaar of ${_amount.asCurrency} given to ${widget.customer.name}',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to give udhaar: $e'),
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
            left: ResponsiveHelper.modalPadding(context),
            right: ResponsiveHelper.modalPadding(context),
            top: ResponsiveHelper.modalPadding(context),
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                ResponsiveHelper.modalPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Give Udhaar (Credit)',
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.error,
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
                            'Current बाकी: ${balance.asCurrency}',
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
                  labelText: 'Credit Amount',
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
                    label: '₹2000',
                    onTap: () {
                      _amountController.text = '2000';
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note input
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Reason / Note',
                  hintText: 'e.g., Grocery items, Bill #123',
                ),
              ),
              const SizedBox(height: 24),

              // New balance preview
              if (_amount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      const Text('New बाकी: '),
                      Text(
                        (balance + _amount).asCurrency,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

              // Submit button
              AppButton(
                label: '➖ GIVE UDHAAR',
                onPressed: _amount > 0 ? _giveUdhaar : null,
                isLoading: _isLoading,
                backgroundColor: AppColors.error,
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

  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
