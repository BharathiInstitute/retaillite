/// Errors & Health Screen — Enhanced with full context, copy, dedup, filters, trend
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retaillite/core/services/app_health_service.dart';
import 'package:retaillite/core/services/error_logging_service.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';

// ── Providers ──

final _groupedErrorsProvider = FutureProvider.autoDispose<List<GroupedError>>((
  ref,
) {
  return ErrorLoggingService.getGroupedErrors(hideResolved: false);
});

final _healthSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) {
    return AppHealthService.getHealthSummary();
  },
);

final _dailyTrendProvider = FutureProvider.autoDispose<Map<DateTime, int>>((
  ref,
) {
  return ErrorLoggingService.getDailyErrorCounts(days: 30);
});

// ── Screen ──

class ErrorsScreen extends ConsumerStatefulWidget {
  const ErrorsScreen({super.key});

  @override
  ConsumerState<ErrorsScreen> createState() => _ErrorsScreenState();
}

class _ErrorsScreenState extends ConsumerState<ErrorsScreen> {
  // Filters
  String? _platformFilter;
  String? _severityFilter;
  bool _hideResolved = true;

  @override
  Widget build(BuildContext context) {
    final groupedErrors = ref.watch(_groupedErrorsProvider);
    final health = ref.watch(_healthSummaryProvider);
    final trend = ref.watch(_dailyTrendProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Errors & Health'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        leading: MediaQuery.of(context).size.width >= 1024
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  adminShellScaffoldKey.currentState?.openDrawer();
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(_groupedErrorsProvider);
              ref.invalidate(_healthSummaryProvider);
              ref.invalidate(_dailyTrendProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_groupedErrorsProvider);
          ref.invalidate(_healthSummaryProvider);
          ref.invalidate(_dailyTrendProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Summary Card
              health.when(
                data: (data) => _buildHealthCard(data, cs),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _errorChip('Health: $e'),
              ),
              const SizedBox(height: 12),

              // 7-Day Trend Chart
              trend.when(
                data: (data) => data.isEmpty
                    ? const SizedBox.shrink()
                    : _buildTrendChart(data, cs),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Filter Bar
              _buildFilterBar(cs),
              const SizedBox(height: 12),

              // Error List
              groupedErrors.when(
                data: (errors) => _buildErrorList(errors, cs),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _errorChip('Errors: $e'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _cleanUpOldLogs(context),
        tooltip: 'Clean up logs > 30 days',
        child: const Icon(Icons.delete_sweep),
      ),
    );
  }

  // ─── Health Card ───

  Widget _buildHealthCard(Map<String, dynamic> data, ColorScheme cs) {
    final status = data['status'] as String? ?? 'unknown';
    final isHealthy = status == 'healthy';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isHealthy
              ? [Colors.green.shade600, Colors.green.shade800]
              : [Colors.red.shade600, Colors.red.shade800],
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.warning,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'System Healthy' : 'Issues Detected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uptime: ${data['uptimeHours'] ?? '?'}h · '
                  'Errors (24h): ${data['recentErrorCount'] ?? '?'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.invalidate(_groupedErrorsProvider);
              ref.invalidate(_healthSummaryProvider);
              ref.invalidate(_dailyTrendProvider);
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ─── 30-Day Uptime Bar Strip ───

  Widget _buildTrendChart(Map<DateTime, int> data, ColorScheme cs) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Calculate uptime: days with 0 errors / total days
    final totalDays = entries.length;
    final cleanDays = entries.where((e) => e.value == 0).length;
    final uptimePercent = totalDays > 0 ? (cleanDays / totalDays * 100) : 100.0;

    Color barColor(int errorCount) {
      if (errorCount == 0) return Colors.green.shade400;
      if (errorCount <= 5) return Colors.amber.shade600;
      return Colors.red.shade500;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with uptime %
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Uptime (30 days)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: uptimePercent >= 99
                      ? Colors.green.shade50
                      : uptimePercent >= 95
                      ? Colors.amber.shade50
                      : Colors.red.shade50,
                ),
                child: Text(
                  '${uptimePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: uptimePercent >= 99
                        ? Colors.green.shade700
                        : uptimePercent >= 95
                        ? Colors.amber.shade800
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 30-day bar strip
          SizedBox(
            height: 28,
            child: Row(
              children: entries.map((e) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.5),
                    child: Tooltip(
                      message:
                          '${DateFormat.MMMd().format(e.key)}: ${e.value} error${e.value == 1 ? '' : 's'}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: barColor(e.value),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Date labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30 days ago',
                style: TextStyle(
                  fontSize: 9,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              // Legend
              Row(
                children: [
                  _legendDot(Colors.green.shade400, '0', cs),
                  const SizedBox(width: 8),
                  _legendDot(Colors.amber.shade600, '1–5', cs),
                  const SizedBox(width: 8),
                  _legendDot(Colors.red.shade500, '6+', cs),
                ],
              ),
              Text(
                'Today',
                style: TextStyle(
                  fontSize: 9,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ─── Filter Bar ───

  Widget _buildFilterBar(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Platform filter
        _filterChip('All', _platformFilter == null, () {
          setState(() => _platformFilter = null);
        }),
        _filterChip('Android', _platformFilter == 'android', () {
          setState(() => _platformFilter = 'android');
        }),
        _filterChip('Web', _platformFilter == 'web', () {
          setState(() => _platformFilter = 'web');
        }),
        _filterChip('Windows', _platformFilter == 'windows', () {
          setState(() => _platformFilter = 'windows');
        }),

        const SizedBox(width: 8),

        // Severity filter
        _filterChip('Critical', _severityFilter == 'critical', () {
          setState(
            () => _severityFilter = _severityFilter == 'critical'
                ? null
                : 'critical',
          );
        }, color: Colors.red),
        _filterChip('Error', _severityFilter == 'error', () {
          setState(
            () => _severityFilter = _severityFilter == 'error' ? null : 'error',
          );
        }, color: Colors.orange),
        _filterChip('Warning', _severityFilter == 'warning', () {
          setState(
            () => _severityFilter = _severityFilter == 'warning'
                ? null
                : 'warning',
          );
        }, color: Colors.amber),

        const SizedBox(width: 8),

        // Resolved toggle
        FilterChip(
          label: Text(
            _hideResolved ? 'Hide Resolved' : 'Show All',
            style: const TextStyle(fontSize: 12),
          ),
          selected: _hideResolved,
          onSelected: (v) => setState(() => _hideResolved = v),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: selected ? Colors.white : null),
      ),
      onPressed: onTap,
      backgroundColor: selected ? (color ?? Colors.deepPurple) : null,
      side: selected ? BorderSide.none : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  // ─── Error List ───

  Widget _buildErrorList(List<GroupedError> errors, ColorScheme cs) {
    // Apply client-side filters
    final filtered = errors.where((g) {
      if (_platformFilter != null &&
          g.latestEntry.platform != _platformFilter) {
        return false;
      }
      if (_severityFilter != null &&
          g.latestEntry.severity.name != _severityFilter) {
        return false;
      }
      if (_hideResolved && g.latestEntry.resolved) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No errors found',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _hideResolved ? 'Try showing resolved errors' : 'All clear!',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildErrorCard(filtered[index], cs),
    );
  }

  // ─── Error Card ───

  Widget _buildErrorCard(GroupedError group, ColorScheme cs) {
    final e = group.latestEntry;
    final severityColor = e.severity == ErrorSeverity.critical
        ? Colors.red
        : e.severity == ErrorSeverity.error
        ? Colors.orange
        : Colors.amber;
    final severityIcon = e.severity == ErrorSeverity.critical
        ? Icons.error
        : e.severity == ErrorSeverity.error
        ? Icons.warning
        : Icons.info;

    final timeAgo = _formatTimeAgo(group.lastSeen);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: e.resolved
            ? BorderSide(color: Colors.green.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(severityIcon, color: severityColor, size: 22),
        title: Row(
          children: [
            Expanded(
              child: Text(
                e.message.split('\n').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: e.resolved ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (group.count > 1)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '×${group.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () => _copyError(e),
              tooltip: 'Copy error report',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            _platformIcon(e.platform),
            const SizedBox(width: 4),
            Text(
              e.platform.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (e.route != null) ...[
              Text(
                ' · ',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
              ),
              Flexible(
                child: Text(
                  e.route!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
            Text(
              ' · ',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
            ),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (group.affectedUsers > 0) ...[
              Text(
                ' · ',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
              ),
              Icon(
                Icons.person,
                size: 10,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
              Text(
                ' ${group.affectedUsers}',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
        children: [
          // Error type badge
          if (e.errorType != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  e.errorType!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
              ),
            ),

          // Dedup info
          if (group.count > 1)
            _detailRow(
              Icons.repeat,
              'Occurrences',
              '${group.count} times · First: ${DateFormat.MMMd().add_jm().format(group.firstSeen)}'
                  ' · Last: ${DateFormat.MMMd().add_jm().format(group.lastSeen)}',
              cs,
            ),

          // Context details
          if (e.route != null) _detailRow(Icons.route, 'Route', e.route!, cs),
          if (e.widgetContext != null)
            _detailRow(Icons.widgets, 'Widget', e.widgetContext!, cs),
          if (e.library != null)
            _detailRow(Icons.code, 'Library', e.library!, cs),
          if (e.screenWidth != null && e.screenHeight != null)
            _detailRow(
              Icons.aspect_ratio,
              'Screen',
              '${e.screenWidth!.toInt()}×${e.screenHeight!.toInt()}',
              cs,
            ),
          if (e.connectivity != null)
            _detailRow(Icons.wifi, 'Connectivity', e.connectivity!, cs),
          if (e.lifecycleState != null)
            _detailRow(Icons.sync, 'Lifecycle', e.lifecycleState!, cs),
          if (e.buildMode != null)
            _detailRow(Icons.build, 'Build', e.buildMode!, cs),
          if (e.sessionId != null)
            _detailRow(Icons.fingerprint, 'Session', e.sessionId!, cs),

          // Full message
          const SizedBox(height: 8),
          _detailRow(Icons.message, 'Message', e.message, cs),

          // Widget info
          if (e.widgetInfo != null && e.widgetInfo!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _monoBox('Widget Info', e.widgetInfo!, cs),
          ],

          // Stack trace
          if (e.stackTrace != null && e.stackTrace!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _monoBox('Stack Trace', e.stackTrace!, cs),
          ],

          // User info
          if (e.userEmail != null ||
              e.shopName != null ||
              e.userId != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        'User',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (e.userEmail != null)
                    Text(
                      e.userEmail!,
                      style: TextStyle(fontSize: 12, color: cs.onSurface),
                    ),
                  if (e.shopName != null)
                    Text(
                      e.shopName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  if (e.userId != null)
                    Text(
                      e.userId!,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Resolve button
          const SizedBox(height: 12),
          Row(
            children: [
              if (!e.resolved)
                TextButton.icon(
                  onPressed: () => _resolveError(group),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    group.count > 1
                        ? 'Resolve All (${group.count})'
                        : 'Mark Resolved',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                )
              else
                Chip(
                  label: const Text('Resolved', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  avatar: const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              const Spacer(),
              Text(
                DateFormat.yMMMd().add_jm().format(e.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───

  Widget _detailRow(IconData icon, String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monoBox(String title, String content, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _platformIcon(String platform) {
    switch (platform) {
      case 'android':
        return Icon(Icons.android, size: 12, color: Colors.green.shade600);
      case 'web':
        return Icon(Icons.language, size: 12, color: Colors.blue.shade600);
      case 'windows':
        return Icon(
          Icons.desktop_windows,
          size: 12,
          color: Colors.indigo.shade600,
        );
      default:
        return Icon(
          Icons.device_unknown,
          size: 12,
          color: Colors.grey.shade600,
        );
    }
  }

  Widget _errorChip(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        msg,
        style: TextStyle(color: Colors.red.shade800, fontSize: 12),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(dt);
  }

  // ─── Actions ───

  void _copyError(ErrorLogEntry e) {
    Clipboard.setData(ClipboardData(text: e.toCopyText()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Error report copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _resolveError(GroupedError group) async {
    final hash = group.latestEntry.errorHash;
    if (hash != null && group.count > 1) {
      final count = await ErrorLoggingService.markAllResolvedByHash(hash);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resolved $count errors'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (group.docId != null) {
      await ErrorLoggingService.markResolved(group.docId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as resolved'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    ref.invalidate(_groupedErrorsProvider);
  }

  Future<void> _cleanUpOldLogs(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clean Up Old Logs'),
        content: const Text('Delete all error logs older than 30 days?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final count = await ErrorLoggingService.deleteOldLogs();
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted $count old error logs'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.invalidate(_groupedErrorsProvider);
      ref.invalidate(_dailyTrendProvider);
    }
  }
}
