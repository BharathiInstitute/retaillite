/// Offline connectivity banner — shows when device is offline
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/connectivity_service.dart';
import 'package:retaillite/core/services/sync_status_service.dart';

/// Shows a slim banner when the device is offline.
/// Disappears automatically when connectivity returns.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) return const SizedBox.shrink();

    // Get pending count while offline
    final unsyncedCount = ref.watch(unsyncedCountProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.orange.shade800,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            unsyncedCount > 0
                ? 'You are offline — $unsyncedCount change${unsyncedCount == 1 ? '' : 's'} will sync when connected'
                : 'You are offline — changes will sync when connected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
