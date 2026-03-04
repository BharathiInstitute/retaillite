import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Trigger reasons for showing the upgrade prompt.
enum UpgradeTrigger { productLimit, billLimit, customerLimit, featureGated }

/// Modal that prompts users to upgrade their subscription plan.
class UpgradePromptModal {
  /// Shows the upgrade prompt modal with context about why the upgrade is needed.
  static Future<void> show(
    BuildContext context, {
    required UpgradeTrigger trigger,
  }) async {
    final triggerMessages = {
      UpgradeTrigger.productLimit: 'You\'ve reached your product limit.',
      UpgradeTrigger.billLimit: 'You\'ve reached your monthly bill limit.',
      UpgradeTrigger.customerLimit: 'You\'ve reached your customer limit.',
      UpgradeTrigger.featureGated: 'This feature requires a higher plan.',
    };

    final message =
        triggerMessages[trigger] ?? 'Upgrade to unlock more features.';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade Your Plan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            const Text(
              'Upgrade to Pro or Business to unlock higher limits and premium features.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/subscription');
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}
