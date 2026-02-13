/// Customer detail screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/payment_link_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/features/khata/widgets/add_customer_modal.dart';
import 'package:retaillite/features/khata/widgets/give_udhaar_modal.dart';
import 'package:retaillite/features/khata/widgets/record_payment_modal.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/transaction_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final transactionsAsync = ref.watch(
      customerTransactionsProvider(customerId),
    );

    return customerAsync.when(
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Details')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final isMobile = ResponsiveHelper.isMobile(context);
        final maxWidth = isMobile ? double.infinity : 800.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customer Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditModal(context, customer),
                tooltip: 'Edit Details',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmation(context, ref, customer);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Delete Customer',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                customer.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              customer.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📞 ${Formatters.phone(customer.phone)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (customer.address != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '📍 ${customer.address}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Balance card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: customer.hasDue
                            ? const LinearGradient(
                                colors: [AppColors.error, Color(0xFFDC2626)],
                              )
                            : AppColors.successGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'कुल बाकी (Total Due)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            customer.balance.abs().asCurrency,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (!customer.hasDue)
                            const Text(
                              '✅ Fully Paid',
                              style: TextStyle(color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Transactions section
                    Text(
                      'TRANSACTIONS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),

                    transactionsAsync.when(
                      data: (transactions) {
                        if (transactions.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('No transactions yet')),
                            ),
                          );
                        }

                        return Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder: (e, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) => _TransactionTile(
                              transaction: transactions[index],
                            ),
                          ),
                        );
                      },
                      loading: () => const LoadingIndicator(),
                      error: (e, _) =>
                          const Text('Failed to load transactions'),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          bottomSheet: _buildBottomSheet(context, ref, customer),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const LoadingIndicator(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const ErrorState(message: 'Failed to load customer'),
      ),
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    WidgetRef ref,
    CustomerModel customer,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: AppShadows.medium,
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (customer.hasDue)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendPaymentLink(context, ref, customer),
                  icon: const Icon(Icons.link),
                  label: const Text('PAY LINK'),
                ),
              ),
            if (customer.hasDue) const SizedBox(width: 8),
            if (customer.hasDue)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendWhatsAppReminder(context, customer),
                  icon: const Icon(Icons.message),
                  label: const Text('REMIND'),
                ),
              ),
            if (customer.hasDue) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showUdhaarModal(context, customer),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('UDHAAR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentModal(context, customer),
                icon: const Icon(Icons.currency_rupee),
                label: const Text('PAYMENT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendWhatsAppReminder(
    BuildContext context,
    CustomerModel customer,
  ) async {
    final message = Uri.encodeComponent(
      'नमस्ते ${customer.name},\n\n'
      'आपके ₹${customer.balance.toStringAsFixed(0)} बाकी हैं।\n'
      'कृपया जल्द भुगतान करें।\n\n'
      'धन्यवाद 🙏',
    );
    final phone = '91${customer.phone}';
    final url = Uri.parse('whatsapp://send?phone=$phone&text=$message');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Try web WhatsApp
        final webUrl = Uri.parse('https://wa.me/$phone?text=$message');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditModal(BuildContext context, CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCustomerModal(customer: customer),
    );
  }

  void _showPaymentModal(BuildContext context, CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordPaymentModal(customer: customer),
    );
  }

  void _showUdhaarModal(BuildContext context, CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiveUdhaarModal(customer: customer),
    );
  }

  /// Send a payment link via WhatsApp
  void _sendPaymentLink(
    BuildContext context,
    WidgetRef ref,
    CustomerModel customer,
  ) async {
    final shopName = ref.read(currentUserProvider)?.shopName;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Creating payment link...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final result = await PaymentLinkService.createPaymentLink(
      amount: customer.balance,
      customerName: customer.name,
      customerPhone: customer.phone,
      description: 'Khata balance payment',
      shopName: shopName,
    );

    if (!context.mounted) return;

    if (result.success && result.paymentLink != null) {
      // Share via WhatsApp
      final success = await PaymentLinkService.shareViaWhatsApp(
        paymentLink: result.paymentLink!,
        amount: customer.balance,
        customerPhone: customer.phone,
        shopName: shopName,
        customerName: customer.name,
      );

      if (!success && context.mounted) {
        // Fallback to generic share
        await PaymentLinkService.shareGeneric(
          paymentLink: result.paymentLink!,
          amount: customer.balance,
          shopName: shopName,
          customerName: customer.name,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to create payment link'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    CustomerModel customer,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
          'Are you sure you want to delete ${customer.name}? '
          'This action cannot be undone and will remove all their transaction history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog

              try {
                await ref
                    .read(khataServiceProvider)
                    .deleteCustomer(customer.id);

                ref.invalidate(customersProvider);

                navigator.pop(); // Go back to list
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Customer deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete customer: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPurchase = transaction.type == TransactionType.purchase;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPurchase
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        child: Icon(
          isPurchase ? Icons.shopping_cart : Icons.payments,
          color: isPurchase ? AppColors.error : AppColors.success,
          size: 20,
        ),
      ),
      title: Text(transaction.type.displayName),
      subtitle: Text(
        transaction.createdAt.formattedDateTime,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '${isPurchase ? '+' : '-'}${transaction.amount.asCurrency}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isPurchase ? AppColors.error : AppColors.success,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
