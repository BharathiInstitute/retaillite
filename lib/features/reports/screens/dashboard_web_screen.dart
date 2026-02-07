import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/theme/web_theme.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/features/reports/providers/reports_provider.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/sales_summary_model.dart';
import 'package:retaillite/shared/widgets/loading_states.dart';
import 'package:share_plus/share_plus.dart';

// Local provider to fetch last 7 days of bills for the dashboard
final dashboardBillsProvider = FutureProvider.autoDispose<List<BillModel>>((
  ref,
) async {
  final now = DateTime.now();
  final end = now;
  final start = now.subtract(const Duration(days: 7));

  // Use existing service from reports_provider logic reference
  final bills = await OfflineStorageService.getCachedBillsInRange(start, end);
  return bills;
});

class DashboardWebScreen extends ConsumerWidget {
  const DashboardWebScreen({super.key});

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

  String _getDateRangeLabel(WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final offset = ref.watch(periodOffsetProvider);
    final customRange = ref.watch(customDateRangeProvider);

    final range = getEffectiveDateRange(period, offset, customRange);
    final dateFormat = DateFormat('dd MMM');
    final yearFormat = DateFormat('dd MMM yyyy');

    if (range.start.year != range.end.year) {
      return '${yearFormat.format(range.start)} - ${yearFormat.format(range.end)}';
    }
    if (range.start.day == range.end.day &&
        range.start.month == range.end.month) {
      return yearFormat.format(range.start);
    }
    return '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}';
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final customRange = ref.read(customDateRangeProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: customRange != null
          ? DateTimeRange(start: customRange.start, end: customRange.end)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: WebTheme.primary)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = DateRange.custom(
        picked.start,
        picked.end,
      );
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final summary = ref.read(salesSummaryProvider);

    summary.whenData((data) async {
      final period = ref.read(selectedPeriodProvider);
      final periodLabel = _getPeriodLabel(l10n, period);

      // Generate PDF using printing package
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Sales Report - $periodLabel',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _getDateRangeLabel(ref),
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 16),

                // Summary section
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                _pdfRow('Total Sales', Formatters.currency(data.totalSales)),
                _pdfRow('Total Bills', '${data.billCount}'),
                _pdfRow('Average Bill', Formatters.currency(data.avgBillValue)),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Payment Breakdown',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                _pdfRow(
                  'Cash',
                  '${Formatters.currency(data.cashAmount)} (${data.cashPercentage.toStringAsFixed(0)}%)',
                ),
                _pdfRow(
                  'UPI',
                  '${Formatters.currency(data.upiAmount)} (${data.upiPercentage.toStringAsFixed(0)}%)',
                ),
                _pdfRow(
                  'Udhar',
                  '${Formatters.currency(data.udharAmount)} (${data.udharPercentage.toStringAsFixed(0)}%)',
                ),

                pw.Spacer(),
                pw.Divider(),
                pw.Text(
                  'Generated by LITE Billing App',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) => doc.save(),
        name: 'Sales_Report_$periodLabel',
      );
    });
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _shareReport(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.read(salesSummaryProvider);
    final period = ref.read(selectedPeriodProvider);

    summary.whenData((data) {
      final periodLabel = _getPeriodLabel(l10n, period);
      final message =
          '''
📊 *$periodLabel ${l10n.reports}*

💰 *${l10n.totalSales}:* ${Formatters.currency(data.totalSales)}
📝 *${l10n.billing}:* ${data.billCount}
📈 *${l10n.averageBill}:* ${Formatters.currency(data.avgBillValue)}

💵 ${l10n.cash}: ${Formatters.currency(data.cashAmount)} (${data.cashPercentage.toStringAsFixed(0)}%)
📱 ${l10n.upi}: ${Formatters.currency(data.upiAmount)} (${data.upiPercentage.toStringAsFixed(0)}%)
📕 ${l10n.udhar}: ${Formatters.currency(data.udharAmount)} (${data.udharPercentage.toStringAsFixed(0)}%)

_Generated by LITE ${l10n.billing} App_
      ''';

      Share.share(message.trim());
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final summaryAsync = ref.watch(salesSummaryProvider);
    final billsAsync = ref.watch(dashboardBillsProvider);
    final periodBillsAsync = ref.watch(periodBillsProvider);
    final topProductsAsync = ref.watch(topProductsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with period filter and actions
            Row(
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),

                // Navigation arrows (only for non-custom periods)
                if (selectedPeriod != ReportPeriod.custom) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip:
                        'Previous ${_getPeriodLabel(l10n, selectedPeriod)}',
                    onPressed: () {
                      final offset = ref.read(periodOffsetProvider);
                      ref.read(periodOffsetProvider.notifier).state =
                          offset - 1;
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next ${_getPeriodLabel(l10n, selectedPeriod)}',
                    onPressed: () {
                      final offset = ref.read(periodOffsetProvider);
                      if (offset < 0) {
                        ref.read(periodOffsetProvider.notifier).state =
                            offset + 1;
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Period Filter Chips
                ...ReportPeriod.values.map((period) {
                  final isSelected = selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getPeriodLabel(l10n, period)),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(selectedPeriodProvider.notifier).state =
                            period;
                        ref.read(periodOffsetProvider.notifier).state = 0;
                        if (period == ReportPeriod.custom) {
                          _showDateRangePicker(context, ref);
                        }
                      },
                      selectedColor: WebTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  );
                }),

                // Date range indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getDateRangeLabel(ref),
                    style: TextStyle(
                      fontSize: 12,
                      color: WebTheme.textSecondary,
                    ),
                  ),
                ),

                const Spacer(),
                // Action Buttons
                OutlinedButton.icon(
                  onPressed: () => _exportPdf(context, ref),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(l10n.exportPdf),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _shareReport(context, ref),
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(l10n.share),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. Overview Cards Row
            summaryAsync.when(
              data: (summary) => Row(
                children: [
                  Expanded(
                    child: _OverviewCard(
                      title: l10n.totalSales,
                      value: Formatters.currency(summary.totalSales),
                      icon: Icons.attach_money,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OverviewCard(
                      title: l10n.billing,
                      value: '${summary.billCount}',
                      icon: Icons.receipt_long,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OverviewCard(
                      title: l10n.cash,
                      value: Formatters.currency(summary.cashAmount),
                      icon: Icons.payments,
                      color: AppColors.cash,
                      subtitle: '${summary.cashPercentage.toStringAsFixed(0)}%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OverviewCard(
                      title: l10n.upi,
                      value: Formatters.currency(summary.upiAmount),
                      icon: Icons.qr_code,
                      color: AppColors.upi,
                      subtitle: '${summary.upiPercentage.toStringAsFixed(0)}%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OverviewCard(
                      title: l10n.udhar,
                      value: Formatters.currency(summary.udharAmount),
                      icon: Icons.pending_actions,
                      color: AppColors.udhar,
                      subtitle:
                          '${summary.udharPercentage.toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: LoadingIndicator()),
              error: (e, _) => const Text('Error loading summary data'),
            ),

            const SizedBox(height: 24),

            // 2. Sales Trends + Top Products Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Graph (Left 65%)
                Expanded(
                  flex: 65,
                  child: Container(
                    height: 350,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sales Trends',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: billsAsync.when(
                            data: (bills) => _SimpleBarChart(bills: bills),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Top Selling Products (Right 35%)
                Expanded(
                  flex: 35,
                  child: Container(
                    height: 350,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.topSellingProducts,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: topProductsAsync.when(
                            data: (products) {
                              if (products.isEmpty) {
                                return Center(child: Text(l10n.noSalesData));
                              }
                              return ListView.separated(
                                itemCount: products.length.clamp(0, 5),
                                separatorBuilder: (e, _) => const Divider(),
                                itemBuilder: (context, index) {
                                  final p = products[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '#${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      p.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      l10n.unitsSold(p.quantitySold),
                                    ),
                                    trailing: Text(
                                      Formatters.currency(p.revenue),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () =>
                                const Center(child: LoadingIndicator()),
                            error: (e, _) => const Text('Error'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Recent Bills Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentBills,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      periodBillsAsync.when(
                        data: (bills) => Text(
                          '${bills.length} bills',
                          style: TextStyle(color: WebTheme.textSecondary),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  periodBillsAsync.when(
                    data: (bills) {
                      if (bills.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No bills yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final sortedBills = List<BillModel>.from(bills)
                        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      final displayBills = sortedBills.take(10).toList();

                      return DataTable(
                        columns: const [
                          DataColumn(label: Text('Bill #')),
                          DataColumn(label: Text('Time')),
                          DataColumn(label: Text('Items')),
                          DataColumn(label: Text('Payment')),
                          DataColumn(label: Text('Total'), numeric: true),
                        ],
                        rows: displayBills.map((bill) {
                          final time =
                              '${bill.createdAt.hour.toString().padLeft(2, '0')}:${bill.createdAt.minute.toString().padLeft(2, '0')}';
                          return DataRow(
                            cells: [
                              DataCell(Text('#${bill.billNumber}')),
                              DataCell(Text(time)),
                              DataCell(Text('${bill.itemCount} items')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPaymentColor(
                                      bill.paymentMethod,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    bill.paymentMethod.displayName,
                                    style: TextStyle(
                                      color: _getPaymentColor(
                                        bill.paymentMethod,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  Formatters.currency(bill.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Text('Error loading bills'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return AppColors.cash;
      case PaymentMethod.upi:
        return AppColors.upi;
      case PaymentMethod.udhar:
        return AppColors.udhar;
    }
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: WebTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<BillModel> bills;

  const _SimpleBarChart({required this.bills});

  @override
  Widget build(BuildContext context) {
    // 1. Group bills by date (last 7 days)
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) {
      return now.subtract(Duration(days: 6 - i));
    });

    final data = <DateTime, double>{};
    for (var date in last7Days) {
      data[date] = 0;
    }

    for (var bill in bills) {
      final date = bill.createdAt;
      // Find matching date key (ignoring time)
      for (var key in data.keys) {
        if (key.year == date.year &&
            key.month == date.month &&
            key.day == date.day) {
          data[key] = (data[key] ?? 0) + bill.total;
          break;
        }
      }
    }

    final maxVal = data.values.fold(0.0, (p, c) => c > p ? c : p);
    final displayMax = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final barWidth = width / 7 * 0.5;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.entries.map((entry) {
            final val = entry.value;
            final h = (val / displayMax) * height;
            final dayName = DateFormat('E').format(entry.key); // Mon, Tue...

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: barWidth,
                  height: h > 0 ? h : 4, // Min height
                  decoration: BoxDecoration(
                    color: WebTheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dayName,
                  style: const TextStyle(
                    color: WebTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
