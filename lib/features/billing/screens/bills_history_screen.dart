/// Bills History Screen - Display all past bills with search, filters, and actions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/data_export_service.dart';
import 'package:retaillite/core/services/demo_data_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/utils/formatters.dart';
import 'package:retaillite/core/utils/id_generator.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/billing/services/bill_share_service.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/features/billing/providers/billing_provider.dart';
import 'package:retaillite/features/reports/providers/reports_provider.dart';

/// Bills History Screen
class BillsHistoryScreen extends ConsumerWidget {
  const BillsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(billsFilterProvider);
    final billsAsync = ref.watch(filteredBillsProvider);
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header - Desktop only (hide on mobile & tablet to prevent overflow)
          if (ResponsiveHelper.isDesktop(context))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: Row(
                children: [
                  const Spacer(),

                  // Date & Time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppShadows.small,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(now),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          DateFormat('hh:mm a').format(now),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Print Report Button
                  OutlinedButton.icon(
                    onPressed: () {
                      // Print report (not yet implemented)
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print Report'),
                  ),
                ],
              ),
            ),

          // Filters Section - Responsive
          _buildFiltersSection(context, ref, filter),

          // Records Table (Bills and/or Expenses based on filter)
          Expanded(
            child: _buildRecordsTable(
              context,
              ref,
              filter,
              billsAsync,
              expensesAsync,
            ),
          ),
        ],
      ),
    );
  }

  /// Responsive filters section - adapts to mobile/desktop
  Widget _buildFiltersSection(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (isMobile) {
      return _buildMobileFilters(context, ref, filter);
    }

    // Desktop/Tablet: Horizontal layout with scrollable filters
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Row(
        children: [
          // Scrollable filters
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Search Bar
                  SizedBox(
                    width: screenWidth < 900 ? 200 : 300,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(billsFilterProvider.notifier).state = filter
                            .copyWith(searchQuery: value, page: 1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Date Range Filter
                  _buildDateFilter(context, ref, filter),
                  const SizedBox(width: 12),

                  // Payment Method Filter
                  _buildPaymentFilter(context, ref, filter),
                  const SizedBox(width: 12),

                  // Record Type Filter
                  _buildRecordTypeFilter(context, ref, filter),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Action Buttons - always visible, pinned to right
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// Mobile-optimized filters with vertical layout
  Widget _buildMobileFilters(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar - full width
          TextField(
            decoration: InputDecoration(
              hintText: 'Search bills or expenses...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              ref.read(billsFilterProvider.notifier).state = filter.copyWith(
                searchQuery: value,
                page: 1,
              );
            },
          ),
          const SizedBox(height: 12),

          // Scrollable filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date filter chip
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    filter.dateRange != null
                        ? '${DateFormat('MMM dd').format(filter.dateRange!.start)} - ${DateFormat('MMM dd').format(filter.dateRange!.end)}'
                        : 'Date',
                  ),
                  onPressed: () async {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: filter.dateRange,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: isDark
                                ? ColorScheme.dark(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    surface: const Color(0xFF1E1E2E),
                                  )
                                : ColorScheme.light(primary: AppColors.primary),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      ref.read(billsFilterProvider.notifier).state = filter
                          .copyWith(dateRange: range, page: 1);
                    }
                  },
                ),
                const SizedBox(width: 8),

                // Payment filter chip
                ActionChip(
                  avatar: Text(filter.paymentMethod?.emoji ?? '💳'),
                  label: Text(filter.paymentMethod?.displayName ?? 'Payment'),
                  onPressed: () =>
                      _showPaymentFilterSheet(context, ref, filter),
                ),
                const SizedBox(width: 8),

                // Type filter chip
                ActionChip(
                  label: Text(
                    filter.recordType == RecordType.all
                        ? 'All'
                        : filter.recordType == RecordType.bills
                        ? 'Bills'
                        : 'Expenses',
                  ),
                  onPressed: () => _showTypeFilterSheet(context, ref, filter),
                ),
                const SizedBox(width: 8),

                // Add Expense chip
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Expense'),
                  backgroundColor: Colors.orange.withValues(alpha: 0.12),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddExpensePopup(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Date range filter widget
  Widget _buildDateFilter(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
  ) {
    return InkWell(
      onTap: () async {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: filter.dateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: const Color(0xFF1E1E2E),
                      )
                    : ColorScheme.light(primary: AppColors.primary),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          ref.read(billsFilterProvider.notifier).state = filter.copyWith(
            dateRange: range,
            page: 1,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: AppShadows.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range, size: 18),
            const SizedBox(width: 8),
            Text(
              filter.dateRange != null
                  ? '${DateFormat('MMM dd').format(filter.dateRange!.start)} - ${DateFormat('MMM dd').format(filter.dateRange!.end)}'
                  : 'Date Range',
              style: TextStyle(
                color: filter.dateRange != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (filter.dateRange != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ref.read(billsFilterProvider.notifier).state = filter
                      .copyWith(clearDateRange: true, page: 1);
                },
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Payment method dropdown
  Widget _buildPaymentFilter(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.small,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentMethod?>(
          value: filter.paymentMethod,
          hint: const Text('All Payments'),
          items: [
            const DropdownMenuItem(child: Text('All Payments')),
            ...PaymentMethod.values
                .where((m) => m != PaymentMethod.unknown)
                .map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Row(
                      children: [
                        Text(method.emoji),
                        const SizedBox(width: 8),
                        Text(method.displayName),
                      ],
                    ),
                  );
                }),
          ],
          onChanged: (value) {
            ref.read(billsFilterProvider.notifier).state = filter.copyWith(
              paymentMethod: value,
              clearPaymentMethod: value == null,
              page: 1,
            );
          },
        ),
      ),
    );
  }

  /// Record type dropdown
  Widget _buildRecordTypeFilter(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.small,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RecordType>(
          value: filter.recordType,
          items: const [
            DropdownMenuItem(value: RecordType.all, child: Text('📋 All')),
            DropdownMenuItem(value: RecordType.bills, child: Text('🧾 Bills')),
            DropdownMenuItem(
              value: RecordType.expenses,
              child: Text('💸 Expenses'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(billsFilterProvider.notifier).state = filter.copyWith(
                recordType: value,
                page: 1,
              );
            }
          },
        ),
      ),
    );
  }

  /// Action buttons (Add Expense, Export)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddExpensePopup(),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Expense'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showExportDialog(context),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  /// Show payment filter as bottom sheet on mobile
  void _showPaymentFilterSheet(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Payments'),
              onTap: () {
                ref.read(billsFilterProvider.notifier).state = filter.copyWith(
                  clearPaymentMethod: true,
                  page: 1,
                );
                Navigator.pop(context);
              },
            ),
            ...PaymentMethod.values
                .where((m) => m != PaymentMethod.unknown)
                .map(
                  (method) => ListTile(
                    leading: Text(
                      method.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(method.displayName),
                    selected: filter.paymentMethod == method,
                    onTap: () {
                      ref.read(billsFilterProvider.notifier).state = filter
                          .copyWith(paymentMethod: method, page: 1);
                      Navigator.pop(context);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  /// Show type filter as bottom sheet on mobile
  void _showTypeFilterSheet(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('📋', style: TextStyle(fontSize: 20)),
              title: const Text('All Records'),
              selected: filter.recordType == RecordType.all,
              onTap: () {
                ref.read(billsFilterProvider.notifier).state = filter.copyWith(
                  recordType: RecordType.all,
                  page: 1,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🧾', style: TextStyle(fontSize: 20)),
              title: const Text('Bills Only'),
              selected: filter.recordType == RecordType.bills,
              onTap: () {
                ref.read(billsFilterProvider.notifier).state = filter.copyWith(
                  recordType: RecordType.bills,
                  page: 1,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('💸', style: TextStyle(fontSize: 20)),
              title: const Text('Expenses Only'),
              selected: filter.recordType == RecordType.expenses,
              onTap: () {
                ref.read(billsFilterProvider.notifier).state = filter.copyWith(
                  recordType: RecordType.expenses,
                  page: 1,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsTable(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
    AsyncValue<List<BillModel>> billsAsync,
    AsyncValue<List<ExpenseModel>> expensesAsync,
  ) {
    // Handle loading state
    if (billsAsync.isLoading || expensesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (billsAsync.hasError) {
      return Center(child: Text('Error: ${billsAsync.error}'));
    }
    if (expensesAsync.hasError) {
      return Center(child: Text('Error: ${expensesAsync.error}'));
    }

    final bills = billsAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];

    // Create combined record list based on filter
    List<dynamic> records = [];
    switch (filter.recordType) {
      case RecordType.bills:
        records = bills;
        break;
      case RecordType.expenses:
        records = expenses;
        break;
      case RecordType.all:
        // Combine and sort by date
        records = [...bills, ...expenses];
        records.sort((a, b) {
          final dateA = a is BillModel
              ? a.createdAt
              : (a as ExpenseModel).createdAt;
          final dateB = b is BillModel
              ? b.createdAt
              : (b as ExpenseModel).createdAt;
          return dateB.compareTo(dateA);
        });
        break;
    }

    if (records.isEmpty) {
      final message = switch (filter.recordType) {
        RecordType.bills => 'No bills found',
        RecordType.expenses => 'No expenses found',
        RecordType.all => 'No records found',
      };
      final icon = switch (filter.recordType) {
        RecordType.bills => Icons.receipt_long_outlined,
        RecordType.expenses => Icons.money_off_outlined,
        RecordType.all => Icons.inbox_outlined,
      };
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Pagination
    final totalPages = (records.length / filter.perPage).ceil();
    final startIndex = (filter.page - 1) * filter.perPage;
    final endIndex = (startIndex + filter.perPage).clamp(0, records.length);
    final paginatedRecords = records.sublist(startIndex, endIndex);

    final width = MediaQuery.of(context).size.width;
    final useCardView = width < 900;

    return Column(
      children: [
        // Table or Cards based on screen size
        Expanded(
          child: useCardView
              ? _buildMobileCardList(context, paginatedRecords)
              : _buildDesktopTable(context, paginatedRecords),
        ),

        // Pagination Footer
        _buildPagination(
          context,
          ref,
          filter,
          startIndex,
          endIndex,
          records.length,
          totalPages,
        ),
      ],
    );
  }

  /// Mobile card list view
  Widget _buildMobileCardList(BuildContext context, List<dynamic> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        if (record is BillModel) {
          return _MobileBillCard(bill: record);
        } else if (record is ExpenseModel) {
          return _MobileExpenseCard(expense: record);
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Desktop table view
  Widget _buildDesktopTable(BuildContext context, List<dynamic> records) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final hPad = isTablet ? 12.0 : 24.0;
    final hMargin = isTablet ? 8.0 : 24.0;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: isTablet ? 10 : 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _headerCell(context, 'TYPE'),
                _headerCell(context, 'REFERENCE', flex: 2),
                _headerCell(context, 'DATE & TIME', flex: 2),
                _headerCell(context, 'DETAILS', flex: 2),
                _headerCell(context, 'AMOUNT', flex: 2),
                _headerCell(context, 'PAYMENT', flex: 2),
                _headerCell(context, 'ACTION', flex: 2),
              ],
            ),
          ),
          // Table Rows
          Expanded(
            child: ListView.separated(
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox.shrink(),
              itemBuilder: (context, index) {
                final record = records[index];
                if (record is BillModel) {
                  return _BillRow(bill: record, compact: isTablet);
                } else if (record is ExpenseModel) {
                  return _ExpenseRow(expense: record, compact: isTablet);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Pagination footer widget
  Widget _buildPagination(
    BuildContext context,
    WidgetRef ref,
    BillsFilter filter,
    int startIndex,
    int endIndex,
    int totalRecords,
    int totalPages,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);

    if (isMobile) {
      // Simplified pagination for mobile
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${startIndex + 1}-$endIndex of $totalRecords',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: filter.page > 1
                      ? () => ref.read(billsFilterProvider.notifier).state =
                            filter.copyWith(page: filter.page - 1)
                      : null,
                ),
                Text('${filter.page}/$totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: filter.page < totalPages
                      ? () => ref.read(billsFilterProvider.notifier).state =
                            filter.copyWith(page: filter.page + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Desktop pagination
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text(
            'Showing ${startIndex + 1} to $endIndex of $totalRecords results',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: filter.page > 1
                ? () => ref.read(billsFilterProvider.notifier).state = filter
                      .copyWith(page: filter.page - 1)
                : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 8),
          ...List.generate(totalPages.clamp(0, 5), (i) {
            final pageNum = i + 1;
            final isSelected = pageNum == filter.page;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: isSelected
                    ? null
                    : () => ref.read(billsFilterProvider.notifier).state =
                          filter.copyWith(page: pageNum),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected ? null : AppShadows.small,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (totalPages > 5) ...[
            const Text(' ... '),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: AppShadows.small,
              ),
              alignment: Alignment.center,
              child: Text('$totalPages'),
            ),
          ],
          const SizedBox(width: 8),
          TextButton(
            onPressed: filter.page < totalPages
                ? () => ref.read(billsFilterProvider.notifier).state = filter
                      .copyWith(page: filter.page + 1)
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Show export dialog with date range presets and format selection
  void _showExportDialog(BuildContext context) {
    ExportRange selectedRange = ExportRange.last30Days;
    ExportFormat selectedFormat = ExportFormat.csv;
    bool isExporting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.download, size: 22),
              SizedBox(width: 8),
              Text('Export Bills'),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExportRange.values.map((range) {
                    final isSelected = range == selectedRange;
                    return ChoiceChip(
                      label: Text(range.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => selectedRange = range),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(ctx).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Format',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ExportFormat.values.map((format) {
                    final isSelected = format == selectedFormat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(format.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => selectedFormat = format),
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(ctx).colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedFormat.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isExporting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isExporting
                  ? null
                  : () async {
                      setState(() => isExporting = true);
                      final service = DataExportService();
                      final ExportResult result;

                      if (selectedFormat == ExportFormat.csv) {
                        result = await service.exportBillsToCSV(
                          range: selectedRange,
                        );
                      } else {
                        result = await service.exportBillsToJSON(
                          range: selectedRange,
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (result.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Exported ${result.recordCount} bills to ${result.filePath}',
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ ${result.error}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(isExporting ? 'Exporting...' : 'Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bill table row widget
class _BillRow extends ConsumerWidget {
  final BillModel bill;
  final bool compact;

  const _BillRow({required this.bill, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: compact ? 10 : 16,
      ),
      child: Row(
        children: [
          // Type
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt, size: 14, color: AppColors.primaryDark),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Bill',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Reference (Bill No.)
          Expanded(
            flex: 2,
            child: Text(
              '#INV-${DateTime.now().year}-${bill.billNumber.toString().padLeft(4, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Date & Time
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(bill.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('hh:mm a').format(bill.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Details (Customer Name with Avatar)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _CustomerAvatar(name: bill.customerName ?? 'Walk-in'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bill.customerName ?? 'Walk-in Customer',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '+ ${Formatters.currency(bill.total)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Payment
          Expanded(flex: 2, child: _PaymentChip(method: bill.paymentMethod)),

          // Action Buttons
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    tooltip: 'View',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BillDetailsPopup(bill: bill),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Share',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _SharePopup(bill: bill),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: IconButton(
                    icon: const Icon(Icons.print_outlined, size: 20),
                    tooltip: 'Print',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      BillShareService.downloadPdf(bill, context: context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Expense table row widget
class _ExpenseRow extends StatelessWidget {
  final ExpenseModel expense;
  final bool compact;

  const _ExpenseRow({required this.expense, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: compact ? 10 : 16,
      ),
      child: Row(
        children: [
          // Type
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '💰 Expense',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Reference (Category)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(expense.category.emoji),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    expense.category.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Date & Time
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(expense.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('hh:mm a').format(expense.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Details (Description)
          Expanded(
            flex: 2,
            child: Text(
              expense.description ?? '-',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '- ${Formatters.currency(expense.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Payment
          Expanded(flex: 2, child: _PaymentChip(method: expense.paymentMethod)),

          // Action Buttons
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Edit expense (not yet implemented)
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.error,
                    ),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Delete expense (not yet implemented)
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Customer avatar with initials
class _CustomerAvatar extends StatelessWidget {
  final String name;

  const _CustomerAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();

    // Generate color from name
    final colorIndex = name.hashCode % _avatarColors.length;
    final color = _avatarColors[colorIndex.abs()];

    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        initials.isEmpty ? 'W' : initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

const _avatarColors = [
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.red,
];

/// Payment method chip
class _PaymentChip extends StatelessWidget {
  final PaymentMethod method;

  const _PaymentChip({required this.method});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (method) {
      case PaymentMethod.cash:
        color = AppColors.cash;
        icon = Icons.payments_outlined;
        break;
      case PaymentMethod.upi:
        color = Colors.purple;
        icon = Icons.qr_code;
        break;
      case PaymentMethod.udhar:
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      case PaymentMethod.unknown:
        color = Colors.grey;
        icon = Icons.help_outline;
        break;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              method.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add Expense Popup Dialog
class AddExpensePopup extends ConsumerStatefulWidget {
  const AddExpensePopup({super.key});

  @override
  ConsumerState<AddExpensePopup> createState() => _AddExpensePopupState();
}

class _AddExpensePopupState extends ConsumerState<AddExpensePopup> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final expense = ExpenseModel(
        id: generateSafeId('exp'),
        amount: amount,
        category: _selectedCategory,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        paymentMethod: _selectedPaymentMethod,
        createdAt: _selectedDate,
        date:
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      );

      final isDemoMode = ref.read(authNotifierProvider).isDemoMode;
      if (isDemoMode) {
        DemoDataService.addExpense(expense);
      } else {
        await OfflineStorageService.saveExpense(expense);
      }

      // Refresh the expenses list, dashboard, and reports
      ref.invalidate(filteredExpensesProvider);
      ref.invalidate(salesSummaryProvider);
      ref.invalidate(periodBillsProvider);
      ref.invalidate(dashboardBillsProvider);
      ref.invalidate(topProductsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense of ${Formatters.currency(amount)} added!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 500 ? screenWidth * 0.9 : 450.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(screenWidth < 500 ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Expense',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: ExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(cat.emoji),
                        const SizedBox(width: 8),
                        Text(cat.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Payment Method and Date Row
              Row(
                children: [
                  // Payment Method
                  Expanded(
                    flex: 5,
                    child: DropdownButtonFormField<PaymentMethod>(
                      initialValue: _selectedPaymentMethod,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Payment Meth...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      items: PaymentMethod.values
                          .where(
                            (m) =>
                                m != PaymentMethod.udhar &&
                                m != PaymentMethod.unknown,
                          )
                          .map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(method.emoji),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      method.displayName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPaymentMethod = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Date Picker
                  Expanded(
                    flex: 5,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(_selectedDate),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Expense'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile-optimized bill card for list view
class _MobileBillCard extends StatelessWidget {
  final BillModel bill;

  const _MobileBillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => BillDetailsPopup(bill: bill),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Bill # + Type badge + Share
              Row(
                children: [
                  Text(
                    '#${bill.billNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => _SharePopup(bill: bill),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BILL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Customer + Date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bill.customerName ?? 'Walk-in Customer',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM, HH:mm').format(bill.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Row 3: Amount + Payment method
              Row(
                children: [
                  Text(
                    bill.total.asCurrency,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(bill.paymentMethod.emoji),
                        const SizedBox(width: 4),
                        Text(
                          bill.paymentMethod.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPaymentColor(bill.paymentMethod),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPaymentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return AppColors.cash;
      case PaymentMethod.upi:
        return Colors.blue;
      case PaymentMethod.udhar:
        return Colors.orange;
      case PaymentMethod.unknown:
        return Colors.grey;
    }
  }
}

/// Mobile-optimized expense card for list view
class _MobileExpenseCard extends StatelessWidget {
  final ExpenseModel expense;

  const _MobileExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Category + Type badge
            Row(
              children: [
                Text(
                  expense.category.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EXPENSE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Description + Date
            Row(
              children: [
                Expanded(
                  child: Text(
                    expense.description ?? '-',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('dd MMM, HH:mm').format(expense.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Row 3: Amount
            Text(
              '-${expense.amount.asCurrency}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bill details popup dialog
class BillDetailsPopup extends StatelessWidget {
  final BillModel bill;

  const BillDetailsPopup({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Bill #${bill.billNumber}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info
            _buildInfoRow(
              context,
              'Customer',
              bill.customerName ?? 'Walk-in Customer',
            ),
            _buildInfoRow(
              context,
              'Date',
              DateFormat('dd MMM yyyy, HH:mm').format(bill.createdAt),
            ),
            _buildInfoRow(context, 'Payment', bill.paymentMethod.displayName),
            const Divider(height: 24),

            // Items
            const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...bill.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(item.total.asCurrency),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  bill.total.asCurrency,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

/// Share popup dialog — smart options based on customer data
class _SharePopup extends StatefulWidget {
  final BillModel bill;

  const _SharePopup({required this.bill});

  @override
  State<_SharePopup> createState() => _SharePopupState();
}

class _SharePopupState extends State<_SharePopup> {
  String? _customerPhone;
  bool _isLoading = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerPhone();
  }

  Future<void> _loadCustomerPhone() async {
    if (widget.bill.customerId != null && widget.bill.customerId!.isNotEmpty) {
      try {
        final customer = await OfflineStorageService.getCachedCustomerAsync(
          widget.bill.customerId!,
        );
        if (mounted) {
          setState(() {
            _customerPhone = customer?.phone;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _hasPhone => _customerPhone != null && _customerPhone!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      title: Row(
        children: [
          Icon(Icons.share_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Share Bill #INV-${widget.bill.billNumber}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasPhone) ...[
                  _ShareOption(
                    icon: Icons.chat,
                    iconColor: const Color(0xFF25D366),
                    label: 'WhatsApp',
                    subtitle: _customerPhone!,
                    isLoading: _isSharing,
                    onTap: () async {
                      setState(() => _isSharing = true);
                      await BillShareService.shareViaWhatsApp(
                        widget.bill,
                        _customerPhone!,
                        context: context,
                      );
                      if (context.mounted) {
                        setState(() => _isSharing = false);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _ShareOption(
                    icon: Icons.sms_outlined,
                    iconColor: Colors.blue,
                    label: 'SMS',
                    subtitle: _customerPhone!,
                    isLoading: _isSharing,
                    onTap: () async {
                      await BillShareService.shareViaSms(
                        widget.bill,
                        _customerPhone!,
                        context: context,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 1),
                ],
                _ShareOption(
                  icon: Icons.picture_as_pdf,
                  iconColor: AppColors.error,
                  label: 'Download PDF',
                  subtitle: 'Save or print invoice',
                  isLoading: _isSharing,
                  onTap: () async {
                    setState(() => _isSharing = true);
                    await BillShareService.downloadPdf(
                      widget.bill,
                      context: context,
                    );
                    if (context.mounted) {
                      setState(() => _isSharing = false);
                      Navigator.pop(context);
                    }
                  },
                ),
                const Divider(height: 1),
                _ShareOption(
                  icon: Icons.share,
                  iconColor: AppColors.primary,
                  label: 'More...',
                  subtitle: 'Share via other apps',
                  isLoading: _isSharing,
                  onTap: () async {
                    setState(() => _isSharing = true);
                    await BillShareService.shareGeneral(
                      widget.bill,
                      context: context,
                    );
                    if (context.mounted) {
                      setState(() => _isSharing = false);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Individual share option tile
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      dense: true,
      enabled: !isLoading,
      onTap: onTap,
    );
  }
}
