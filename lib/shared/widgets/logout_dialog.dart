/// Logout confirmation dialog with data sync warning
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';

/// Shows a logout confirmation dialog.
/// If there is unsynced offline data, it warns the user first and
/// waits for pending writes before signing out.
Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
  // Check if there are pending Firestore writes
  bool hasPendingData = false;
  try {
    // Try waiting for pending writes with a very short timeout
    // If it times out, that means there ARE pending writes
    await FirebaseFirestore.instance.waitForPendingWrites().timeout(
      const Duration(milliseconds: 200),
    );
    hasPendingData = false;
  } catch (_) {
    hasPendingData = true;
  }

  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            hasPendingData ? Icons.warning_amber_rounded : Icons.logout,
            color: hasPendingData ? Colors.orange : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Sign Out'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPendingData) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_problem,
                    color: Colors.orange.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have unsynced data! Please connect to the internet and wait for sync to complete before logging out.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Signing out will clear all locally cached data from this device.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Your data is safely stored in the cloud and will be available when you sign back in.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        if (hasPendingData)
          TextButton(
            onPressed: () async {
              // Try to sync first
              Navigator.pop(ctx, false);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Syncing data... Please wait.'),
                    ],
                  ),
                  duration: Duration(seconds: 10),
                ),
              );
              try {
                await FirebaseFirestore.instance.waitForPendingWrites().timeout(
                  const Duration(seconds: 30),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Data synced! You can now safely sign out.'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sync failed. Check your internet connection.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Sync First'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ref.read(authNotifierProvider.notifier).signOut();
  }
}
