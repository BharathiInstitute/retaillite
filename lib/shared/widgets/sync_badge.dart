/// Sync badge — small dot/icon shown on list items that are not synced
library;

import 'package:flutter/material.dart';

class SyncBadge extends StatelessWidget {
  /// Whether this item has pending writes (not synced)
  final bool hasPendingWrites;

  /// Size of the indicator
  final double size;

  const SyncBadge({super.key, required this.hasPendingWrites, this.size = 8});

  @override
  Widget build(BuildContext context) {
    // Show nothing when synced — keeps UI clean
    if (!hasPendingWrites) return const SizedBox.shrink();

    return Tooltip(
      message: 'Not synced to cloud',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Larger sync status chip — for detail screens
class SyncStatusChip extends StatelessWidget {
  final bool isSynced;

  const SyncStatusChip({super.key, required this.isSynced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSynced
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSynced
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done : Icons.cloud_upload,
            size: 14,
            color: isSynced ? Colors.green : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isSynced ? 'Synced' : 'Not Synced',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSynced ? Colors.green : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
