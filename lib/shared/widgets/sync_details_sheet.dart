/// Sync details bottom sheet — shows per-collection sync breakdown
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/sync_status_service.dart';
import 'package:retaillite/core/services/connectivity_service.dart';

class SyncDetailsSheet extends ConsumerWidget {
  const SyncDetailsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(globalSyncStatusProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: isOnline ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Sync Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? Colors.green : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Collection list
          syncStatus.when(
            data: (status) {
              if (status.collections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No data loaded yet',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                );
              }
              return Column(
                children: [
                  ...status.collections.entries.map(
                    (e) => _buildCollectionRow(context, e.value),
                  ),
                  const Divider(height: 24),
                  _buildTotalRow(context, status),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCollectionRow(
    BuildContext context,
    CollectionSyncStatus status,
  ) {
    final cs = Theme.of(context).colorScheme;
    final displayName = _collectionDisplayName(status.name);
    final icon = _collectionIcon(status.name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(fontSize: 14, color: cs.onSurface),
            ),
          ),
          // Count
          Text(
            '${status.totalDocs}',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          // Sync icon
          Icon(
            status.isSynced ? Icons.cloud_done : Icons.cloud_upload,
            size: 18,
            color: status.isSynced ? Colors.green : Colors.orange.shade600,
          ),
          if (status.unsyncedDocs > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${status.unsyncedDocs}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, GlobalSyncStatus status) {
    final cs = Theme.of(context).colorScheme;
    final totalUnsynced = status.totalUnsynced;

    return Row(
      children: [
        Icon(
          totalUnsynced == 0 ? Icons.check_circle : Icons.info_outline,
          size: 20,
          color: totalUnsynced == 0 ? Colors.green : Colors.orange.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            totalUnsynced == 0
                ? 'All data synced to cloud'
                : '$totalUnsynced item${totalUnsynced == 1 ? '' : 's'} not synced',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _collectionDisplayName(String collection) {
    switch (collection) {
      case 'products':
        return 'Products';
      case 'bills':
        return 'Bills';
      case 'customers':
        return 'Customers';
      case 'expenses':
        return 'Expenses';
      case 'transactions':
        return 'Transactions';
      case 'notifications':
        return 'Notifications';
      default:
        return collection;
    }
  }

  IconData _collectionIcon(String collection) {
    switch (collection) {
      case 'products':
        return Icons.inventory_2_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'customers':
        return Icons.people_outline;
      case 'expenses':
        return Icons.account_balance_wallet_outlined;
      case 'transactions':
        return Icons.swap_horiz;
      case 'notifications':
        return Icons.notifications_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}
