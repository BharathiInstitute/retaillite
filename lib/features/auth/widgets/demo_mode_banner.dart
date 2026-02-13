/// Demo mode banner widget
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';

/// Banner shown at the top of the app when in demo mode
class DemoModeBanner extends ConsumerWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(isDemoModeProvider);

    if (!isDemoMode) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning.withValues(alpha: 0.9), AppColors.warning],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Demo Mode - Register to save your data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showRegisterDialog(context, ref),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Register',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _exitDemoMode(context, ref),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegisterDialog(BuildContext outerContext, WidgetRef ref) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Register to Save Data'),
        content: const Text(
          'Start fresh with your own data or keep demo data for reference?',
        ),
        actions: [
          // Keep Demo Data - secondary (text button)
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await OfflineStorageService.saveSetting('keep_demo_data', true);
              if (outerContext.mounted) {
                unawaited(outerContext.push('/register'));
              }
            },
            child: const Text('Keep Demo Data'),
          ),
          // Start Fresh - primary (elevated button)
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await OfflineStorageService.saveSetting('keep_demo_data', false);
              if (outerContext.mounted) {
                unawaited(outerContext.push('/register'));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Fresh'),
          ),
        ],
      ),
    );
  }

  void _exitDemoMode(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Demo Mode?'),
        content: const Text(
          'This will clear all demo data and return to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await OfflineStorageService.clearDemoData();
              await ref.read(authNotifierProvider.notifier).exitDemoMode();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit Demo'),
          ),
        ],
      ),
    );
  }
}
