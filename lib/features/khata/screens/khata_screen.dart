/// Khata (Credit Book) screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/services/bill_sharing_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/features/khata/widgets/add_customer_modal.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/features/khata/screens/khata_web_screen.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> {
  String _filter = 'all'; // all, due, paid
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customersAsync = ref.watch(customersProvider);

    // Use web screen for tablet and desktop (master-detail layout)
    if (ResponsiveHelper.isDesktop(context) ||
        ResponsiveHelper.isTablet(context)) {
      return const KhataWebScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.khata),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddCustomerModal(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '${l10n.search} ${l10n.customer.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // Total due summary
          customersAsync.when(
            data: (customers) {
              final totalDue = customers.fold<double>(
                0,
                (sum, c) => sum + (c.balance > 0 ? c.balance : 0),
              );
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalDue,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      totalDue.asCurrency,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.allCustomers,
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.withDue,
                  isSelected: _filter == 'due',
                  onTap: () => setState(() => _filter = 'due'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.paid,
                  isSelected: _filter == 'paid',
                  onTap: () => setState(() => _filter = 'paid'),
                ),
              ],
            ),
          ),

          // Customer list
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = _filterCustomers(customers);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: l10n.noCustomers,
                    subtitle: l10n.addFirstCustomer,
                    actionLabel: l10n.addCustomer,
                    onAction: _showAddCustomerModal,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _CustomerCard(
                    customer: filtered[index],
                    onTap: () =>
                        context.push('/customer/${filtered[index].id}'),
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorState(
                message: l10n.somethingWentWrong,
                onRetry: () => ref.invalidate(customersProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Send reminder to all
        },
        icon: const Icon(Icons.message),
        label: Text(l10n.sendReminder),
      ),
    );
  }

  List<CustomerModel> _filterCustomers(List<CustomerModel> customers) {
    var result = customers;

    // Apply filter
    if (_filter == 'due') {
      result = result.where((c) => c.balance > 0).toList();
    } else if (_filter == 'paid') {
      result = result.where((c) => c.balance <= 0).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result.where((c) {
        return c.name.toLowerCase().contains(_searchQuery) ||
            c.phone.contains(_searchQuery);
      }).toList();
    }

    return result;
  }

  void _showAddCustomerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCustomerModal(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.dividerLight,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final CustomerModel customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hasDue = customer.balance > 0;
    final daysAgo = customer.daysSinceLastTransaction;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '📞 ${Formatters.phoneShort(customer.phone)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hasDue
                            ? '${l10n.balance}: ${customer.balance.asCurrency}'
                            : '${l10n.paid} ✅',
                        style: TextStyle(
                          color: hasDue ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (daysAgo != null && daysAgo > 0)
                        Text(
                          l10n.daysAgo(daysAgo),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: daysAgo > 30
                                    ? AppColors.error
                                    : AppColors.textTertiaryLight,
                              ),
                        ),
                    ],
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (hasDue) ...[
                const SizedBox(height: 12),
                // Share buttons row
                Row(
                  children: [
                    // WhatsApp button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _sendWhatsAppReminder(context, customer),
                        icon: const Icon(
                          Icons.chat,
                          size: 16,
                          color: AppColors.success,
                        ),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // SMS button (only on mobile)
                    if (BillSharingService.isSmsAvailable)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _sendSmsReminder(context, customer),
                          icon: const Icon(
                            Icons.sms,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            'SMS',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                          ),
                        ),
                      ),
                    if (BillSharingService.isSmsAvailable)
                      const SizedBox(width: 4),
                    // Email button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendEmailReminder(context, customer),
                        icon: const Icon(
                          Icons.email,
                          size: 16,
                          color: AppColors.upi,
                        ),
                        label: const Text(
                          'Email',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.upi,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Payment button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to customer detail for payment
                      context.push('/customer/${customer.id}');
                    },
                    icon: const Icon(Icons.currency_rupee, size: 18),
                    label: Text(l10n.payment),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Send WhatsApp reminder to customer
  void _sendWhatsAppReminder(
    BuildContext context,
    CustomerModel customer,
  ) async {
    final message = _formatReminderMessage(customer);
    final phone = customer.phone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.length == 10 ? '91$phone' : phone;

    final url = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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

  /// Send SMS reminder to customer
  void _sendSmsReminder(BuildContext context, CustomerModel customer) async {
    final message = _formatReminderMessage(customer);
    final phone = customer.phone.replaceAll(RegExp(r'\D'), '');

    final url = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');

    try {
      await launchUrl(url);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open SMS'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Send Email reminder
  void _sendEmailReminder(BuildContext context, CustomerModel customer) async {
    final message = _formatReminderMessage(customer);
    final subject = Uri.encodeComponent(
      'Payment Reminder - ${customer.balance.asCurrency} Due',
    );
    final body = Uri.encodeComponent(message);

    final url = Uri.parse('mailto:?subject=$subject&body=$body');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Format reminder message
  String _formatReminderMessage(CustomerModel customer) {
    return 'Hello ${customer.name},\n\n'
        'You have a pending balance of ₹${customer.balance.toStringAsFixed(0)}.\n'
        'Please make the payment at your earliest convenience.\n\n'
        'Thank you! 🙏';
  }
}
