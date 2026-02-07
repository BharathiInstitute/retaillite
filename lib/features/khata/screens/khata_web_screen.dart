/// Khata Web Screen - Redesigned with master-detail layout
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/core/theme/web_theme.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/features/khata/providers/khata_stats_provider.dart';
import 'package:retaillite/features/khata/widgets/add_customer_modal.dart';
import 'package:retaillite/features/khata/widgets/record_payment_modal.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/transaction_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';
import 'package:url_launcher/url_launcher.dart';

class KhataWebScreen extends ConsumerStatefulWidget {
  const KhataWebScreen({super.key});

  @override
  ConsumerState<KhataWebScreen> createState() => _KhataWebScreenState();
}

class _KhataWebScreenState extends ConsumerState<KhataWebScreen> {
  String _searchQuery = '';
  String? _selectedCustomerId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customersAsync = ref.watch(sortedCustomersProvider);
    final statsAsync = ref.watch(khataStatsProvider);
    final sortOption = ref.watch(customerSortProvider);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = !isDesktop && !isTablet;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(l10n),
            const SizedBox(height: 24),

            // Summary Cards
            statsAsync.when(
              data: (stats) => _buildSummaryCards(stats, isDesktop, isTablet),
              loading: () => const SizedBox(height: 100),
              error: (e, _) => const SizedBox(height: 100),
            ),
            const SizedBox(height: 24),

            // Search and Sort Bar
            _buildSearchSortBar(sortOption),
            const SizedBox(height: 16),

            // Main Content - Master Detail or List only
            Expanded(
              child: customersAsync.when(
                data: (customers) {
                  final filtered = _filterCustomers(customers);

                  if (filtered.isEmpty) {
                    return _buildEmptyState(l10n);
                  }

                  // Mobile: List only
                  if (isMobile) {
                    return _buildCustomerList(filtered, null);
                  }

                  // Tablet/Desktop: Master-Detail
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer List
                      SizedBox(
                        width: isDesktop ? 420 : 340,
                        child: _buildCustomerList(
                          filtered,
                          _selectedCustomerId,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Detail Panel
                      Expanded(
                        child: _selectedCustomerId != null
                            ? _CustomerDetailPanel(
                                customerId: _selectedCustomerId!,
                                onClose: () =>
                                    setState(() => _selectedCustomerId = null),
                              )
                            : _buildSelectCustomerPrompt(),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Error loading data')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Download report
          },
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Download Report'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _showAddCustomerModal,
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Add New Customer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: WebTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(KhataStats stats, bool isDesktop, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Outstanding (Udhaar)',
            value: Formatters.currency(stats.totalOutstanding),
            icon: Icons.trending_up,
            iconColor: AppColors.error,
            subtitle: '${stats.customersWithDue} customers with due',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Collected Today',
            value: Formatters.currency(stats.collectedToday),
            icon: Icons.account_balance_wallet,
            iconColor: AppColors.success,
            subtitle: 'Payments received',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Active Customers',
            value: '${stats.activeCustomers}',
            icon: Icons.people,
            iconColor: AppColors.primary,
            subtitle: 'Total customer base',
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSortBar(CustomerSortOption sortOption) {
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Name or Mobile Number...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: WebTheme.primary),
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CustomerSortOption>(
              value: sortOption,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: const [
                DropdownMenuItem(
                  value: CustomerSortOption.highestDebt,
                  child: Text('Highest Debt First'),
                ),
                DropdownMenuItem(
                  value: CustomerSortOption.recentlyActive,
                  child: Text('Recently Active'),
                ),
                DropdownMenuItem(
                  value: CustomerSortOption.alphabetical,
                  child: Text('Alphabetical A-Z'),
                ),
                DropdownMenuItem(
                  value: CustomerSortOption.oldestDue,
                  child: Text('Oldest Due First'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(customerSortProvider.notifier).state = value;
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerList(List<CustomerModel> customers, String? selectedId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: customers.length,
        separatorBuilder: (e, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final customer = customers[index];
          final isSelected = customer.id == selectedId;
          return _CustomerCard(
            customer: customer,
            isSelected: isSelected,
            onTap: () {
              if (ResponsiveHelper.isDesktop(context) ||
                  ResponsiveHelper.isTablet(context)) {
                setState(() => _selectedCustomerId = customer.id);
              } else {
                // Mobile: Navigate to detail screen
                context.push('/customer/${customer.id}');
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectCustomerPrompt() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Select a customer to view details',
              style: TextStyle(fontSize: 16, color: WebTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: EmptyState(
        icon: Icons.people_outline,
        title: l10n.noCustomers,
        subtitle: l10n.addFirstCustomer,
        actionLabel: l10n.addCustomer,
        onAction: _showAddCustomerModal,
      ),
    );
  }

  List<CustomerModel> _filterCustomers(List<CustomerModel> customers) {
    if (_searchQuery.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
          c.phone.contains(_searchQuery);
    }).toList();
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

// ============ SUMMARY CARD ============
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, color: WebTheme.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ============ CUSTOMER CARD ============
class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.isSelected,
    required this.onTap,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF10B981), // green
      const Color(0xFF8B5CF6), // purple
      const Color(0xFFF59E0B), // amber
      const Color(0xFFEF4444), // red
      const Color(0xFF3B82F6), // blue
      const Color(0xFFEC4899), // pink
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '?';
  }

  String _getLastActivityText(DateTime? lastTransaction) {
    if (lastTransaction == null) return 'No activity';
    final now = DateTime.now();
    final diff = now.difference(lastTransaction);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} week${diff.inDays >= 14 ? "s" : ""} ago';
    }
    return DateFormat('MMM dd').format(lastTransaction);
  }

  @override
  Widget build(BuildContext context) {
    final hasDue = customer.balance > 0;
    final avatarColor = _getAvatarColor(customer.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.success : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              child: Text(
                _getInitials(customer.name),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: avatarColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name & Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: WebTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '+91 ${Formatters.phoneShort(customer.phone)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: WebTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Balance & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'DUE BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    color: WebTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDue ? Formatters.currency(customer.balance) : '₹0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasDue ? AppColors.error : AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDue
                      ? 'Last: ${_getLastActivityText(customer.lastTransactionAt)}'
                      : 'Settled',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasDue ? WebTheme.textMuted : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ CUSTOMER DETAIL PANEL ============
class _CustomerDetailPanel extends ConsumerWidget {
  final String customerId;
  final VoidCallback onClose;

  const _CustomerDetailPanel({required this.customerId, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final transactionsAsync = ref.watch(
      customerTransactionsProvider(customerId),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }
          return Column(
            children: [
              // Customer Header
              _buildCustomerHeader(context, customer),
              const Divider(height: 1),

              // Current Outstanding
              _buildOutstandingSection(customer),
              const Divider(height: 1),

              // Transaction History
              Expanded(
                child: _buildTransactionHistory(context, transactionsAsync),
              ),

              // Action Buttons
              _buildActionButtons(context, customer),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => const Center(child: Text('Error loading customer')),
      ),
    );
  }

  Widget _buildCustomerHeader(BuildContext context, CustomerModel customer) {
    final avatarColor = _getAvatarColor(customer.name);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: avatarColor.withValues(alpha: 0.15),
            child: Text(
              _getInitials(customer.name),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: avatarColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+91 ${Formatters.phoneShort(customer.phone)}',
                  style: TextStyle(fontSize: 14, color: WebTheme.textSecondary),
                ),
              ],
            ),
          ),
          // WhatsApp button
          IconButton(
            onPressed: () => _openWhatsApp(customer.phone),
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            tooltip: 'WhatsApp',
          ),
          // Call button
          IconButton(
            onPressed: () => _makeCall(customer.phone),
            icon: Icon(Icons.phone, color: AppColors.primary),
            tooltip: 'Call',
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingSection(CustomerModel customer) {
    final hasDue = customer.balance > 0;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Current Outstanding',
            style: TextStyle(fontSize: 15, color: WebTheme.textSecondary),
          ),
          Text(
            hasDue ? Formatters.currency(customer.balance) : '₹0',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: hasDue ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(
    BuildContext context,
    AsyncValue<List<TransactionModel>> transactionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            'HISTORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WebTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(color: WebTheme.textMuted),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return _TransactionItem(transaction: tx);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('Error loading transactions')),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, CustomerModel customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Give Udhaar flow
              },
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Give Udhaar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentModal(context, customer),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Receive Pay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
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

  void _openWhatsApp(String phone) async {
    final url = Uri.parse('https://wa.me/91$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _makeCall(String phone) async {
    final url = Uri.parse('tel:+91$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '?';
  }
}

// ============ TRANSACTION ITEM ============
class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPurchase = transaction.type == TransactionType.purchase;
    final color = isPurchase ? AppColors.error : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPurchase ? Icons.add : Icons.remove,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPurchase ? 'Purchase (Credit)' : 'Payment Received',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.note ??
                      (isPurchase ? 'Credit purchase' : 'Cash Payment'),
                  style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                ),
              ],
            ),
          ),
          // Amount & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPurchase ? "+" : "-"} ${Formatters.currency(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd, hh:mm a').format(transaction.createdAt),
                style: TextStyle(fontSize: 11, color: WebTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
