/// Reports screen with daily/weekly summaries
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/services/bill_sharing_service.dart';
import 'package:retaillite/core/utils/color_utils.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/khata/providers/khata_provider.dart';
import 'package:retaillite/features/reports/providers/reports_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/sales_summary_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';
import 'package:share_plus/share_plus.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/features/reports/screens/dashboard_web_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final topProductsAsync = ref.watch(topProductsProvider);
    final billsAsync = ref.watch(periodBillsProvider);

    // Use Web Dashboard for Desktop and Tablet
    if (ResponsiveHelper.isDesktop(context) ||
        ResponsiveHelper.isTablet(context)) {
      return const DashboardWebScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period selector
            Row(
              children: ReportPeriod.values.map((period) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PeriodChip(
                    label: _getPeriodLabel(l10n, period),
                    isSelected: selectedPeriod == period,
                    onTap: () =>
                        ref.read(selectedPeriodProvider.notifier).state =
                            period,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Summary section
            summaryAsync.when(
              data: (summary) => _buildSummarySection(context, summary),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => ErrorState(
                message: l10n.somethingWentWrong,
                onRetry: () => ref.invalidate(salesSummaryProvider),
              ),
            ),

            const SizedBox(height: 24),

            // Recent bills section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT BILLS',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                billsAsync.when(
                  data: (bills) => Text(
                    '${bills.length} bills',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            billsAsync.when(
              data: (bills) => _buildBillsList(context, bills),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: Text(l10n.somethingWentWrong)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Top products section
            Text(
              l10n.topSellingProducts.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),

            topProductsAsync.when(
              data: (products) => _buildTopProductsCard(context, products),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: Text(l10n.somethingWentWrong)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n.exportPdf} coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(l10n.exportPdf),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReport(context, ref),
                    icon: const Icon(Icons.share),
                    label: Text(l10n.share),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsList(BuildContext context, List<BillModel> bills) {
    if (bills.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No bills yet',
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show max 10 bills, sorted by date descending
    final sortedBills = List<BillModel>.from(bills)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayBills = sortedBills.take(10).toList();

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayBills.length,
        separatorBuilder: (e, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final bill = displayBills[index];
          return _BillListItem(
            bill: bill,
            onTap: () => _showBillDetailsPopup(context, bill),
          );
        },
      ),
    );
  }

  void _showBillDetailsPopup(BuildContext context, BillModel bill) {
    showDialog(
      context: context,
      builder: (context) => BillDetailsPopup(bill: bill),
    );
  }

  String _getPeriodLabel(AppLocalizations l10n, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return l10n.today;
      case ReportPeriod.week:
        return l10n.thisWeek;
      case ReportPeriod.month:
        return l10n.thisMonth;
      case ReportPeriod.custom:
        return 'Custom';
    }
  }

  Widget _buildSummarySection(BuildContext context, SalesSummary summary) {
    final l10n = context.l10n;

    return Column(
      children: [
        // Total sales card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                l10n.totalSales,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                summary.totalSales.asCurrency,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.billCount} ${l10n.billing.toLowerCase()} • ${l10n.averageBill} ${summary.avgBillValue.asCurrency}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.payments,
                label: l10n.cash,
                value: summary.cashAmount.asCurrency,
                percentage: '${summary.cashPercentage.toStringAsFixed(0)}%',
                color: AppColors.cash,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.qr_code,
                label: l10n.upi,
                value: summary.upiAmount.asCurrency,
                percentage: '${summary.upiPercentage.toStringAsFixed(0)}%',
                color: AppColors.upi,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.pending_actions,
                label: l10n.udhar,
                value: summary.udharAmount.asCurrency,
                percentage: '${summary.udharPercentage.toStringAsFixed(0)}%',
                color: AppColors.udhar,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopProductsCard(
    BuildContext context,
    List<ProductSale> products,
  ) {
    final l10n = context.l10n;

    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(l10n.noSalesData)),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (e, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: OpacityColors.primary10,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            title: Text(product.productName),
            subtitle: Text(l10n.unitsSold(product.quantitySold)),
            trailing: Text(
              product.revenue.asCurrency,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  void _shareReport(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final summary = ref.read(salesSummaryProvider);
    final period = ref.read(selectedPeriodProvider);

    summary.whenData((data) {
      final periodLabel = _getPeriodLabel(l10n, period);
      final message =
          '''
📊 *$periodLabel ${l10n.reports}*

💰 *${l10n.totalSales}:* ${data.totalSales.asCurrency}
📝 *${l10n.billing}:* ${data.billCount}
📈 *${l10n.averageBill}:* ${data.avgBillValue.asCurrency}

💵 ${l10n.cash}: ${data.cashAmount.asCurrency} (${data.cashPercentage.toStringAsFixed(0)}%)
📱 ${l10n.upi}: ${data.upiAmount.asCurrency} (${data.upiPercentage.toStringAsFixed(0)}%)
📕 ${l10n.udhar}: ${data.udharAmount.asCurrency} (${data.udharPercentage.toStringAsFixed(0)}%)

_Generated by LITE ${l10n.billing} App_
      ''';

      Share.share(message.trim());
    });
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? percentage;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha8(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha8(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (percentage != null) ...[
            const SizedBox(height: 2),
            Text(
              percentage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color.withAlpha8(0.7)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bill list item widget
class _BillListItem extends StatelessWidget {
  final BillModel bill;
  final VoidCallback onTap;

  const _BillListItem({required this.bill, required this.onTap});

  Color get _methodColor {
    switch (bill.paymentMethod) {
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
    final time =
        '${bill.createdAt.hour.toString().padLeft(2, '0')}:${bill.createdAt.minute.toString().padLeft(2, '0')}';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _methodColor.withValues(alpha: 0.1),
        child: Text(
          bill.paymentMethod.emoji,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Text(
        'Bill #${bill.billNumber}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${bill.itemCount} items • $time',
        style: TextStyle(color: AppColors.textSecondaryLight),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            bill.total.asCurrency,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _methodColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              bill.paymentMethod.displayName,
              style: TextStyle(
                fontSize: 10,
                color: _methodColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bill details popup dialog
class BillDetailsPopup extends ConsumerWidget {
  final BillModel bill;

  const BillDetailsPopup({super.key, required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get customer phone if available
    String? customerPhone;
    if (bill.customerId != null) {
      final customerAsync = ref.watch(customerProvider(bill.customerId!));
      customerPhone = customerAsync.valueOrNull?.phone;
    }
    final time =
        '${bill.createdAt.hour.toString().padLeft(2, '0')}:${bill.createdAt.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Bill #${bill.billNumber}'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date and time
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OpacityColors.grey10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${bill.date} at $time',
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getMethodColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(bill.paymentMethod.emoji),
                          const SizedBox(width: 4),
                          Text(
                            bill.paymentMethod.displayName,
                            style: TextStyle(
                              color: _getMethodColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Customer info if available
              if (bill.customerName != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Customer: ${bill.customerName}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Items header
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Item',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Price',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items list
              ...bill.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.price.asCurrency,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.total.asCurrency,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(),
              const SizedBox(height: 8),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    bill.total.asCurrency,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              // Received and change for cash payments
              if (bill.paymentMethod == PaymentMethod.cash &&
                  bill.receivedAmount != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Received',
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                    Text(bill.receivedAmount!.asCurrency),
                  ],
                ),
                if (bill.changeAmount != null && bill.changeAmount! > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(color: AppColors.success),
                      ),
                      Text(
                        bill.changeAmount!.asCurrency,
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        // SMS button (only on mobile)
        if (BillSharingService.isSmsAvailable && customerPhone != null)
          IconButton(
            icon: const Icon(Icons.sms, color: AppColors.primary),
            tooltip: 'Send SMS',
            onPressed: () async {
              final success = await BillSharingService.sendSMS(
                phone: customerPhone!,
                bill: bill,
              );
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open SMS'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        // WhatsApp button
        if (customerPhone != null)
          IconButton(
            icon: const Icon(Icons.chat, color: AppColors.success),
            tooltip: 'Send WhatsApp',
            onPressed: () async {
              final success = await BillSharingService.sendWhatsApp(
                phone: customerPhone!,
                bill: bill,
              );
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open WhatsApp'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Print feature coming soon!')),
            );
          },
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Print'),
        ),
      ],
    );
  }

  Color _getMethodColor() {
    switch (bill.paymentMethod) {
      case PaymentMethod.cash:
        return AppColors.cash;
      case PaymentMethod.upi:
        return AppColors.upi;
      case PaymentMethod.udhar:
        return AppColors.udhar;
    }
  }
}
