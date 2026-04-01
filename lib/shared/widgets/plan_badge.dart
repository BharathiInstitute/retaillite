/// Reusable plan badge widget that shows the current subscription tier.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/subscription/providers/subscription_provider.dart';
import 'package:retaillite/router/app_router.dart';

class PlanBadge extends ConsumerWidget {
  /// If true, shows only the icon (for collapsed sidebars / small spaces).
  final bool compact;

  const PlanBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(subscriptionPlanProvider);

    return planAsync.when(
      data: (plan) => _buildBadge(context, plan),
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => _buildBadge(context, 'free'),
    );
  }

  Widget _buildBadge(BuildContext context, String plan) {
    final config = _planConfig(plan);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.subscription),
      child: Container(
        padding: compact
            ? const EdgeInsets.all(6)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(compact ? 8 : 20),
          border: Border.all(
            color: config.color.withValues(alpha: 0.4),
          ),
        ),
        child: compact
            ? Icon(config.icon, size: 16, color: config.color)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(config.icon, size: 14, color: config.color),
                  const SizedBox(width: 4),
                  Text(
                    config.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: config.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static _PlanDisplay _planConfig(String plan) {
    switch (plan) {
      case 'pro':
        return const _PlanDisplay(
          label: 'PRO',
          color: Colors.blue,
          icon: Icons.star_rounded,
        );
      case 'business':
        return const _PlanDisplay(
          label: 'BUSINESS',
          color: Colors.purple,
          icon: Icons.diamond_rounded,
        );
      default:
        return const _PlanDisplay(
          label: 'FREE',
          color: Colors.grey,
          icon: Icons.circle_outlined,
        );
    }
  }
}

class _PlanDisplay {
  final String label;
  final Color color;
  final IconData icon;

  const _PlanDisplay({
    required this.label,
    required this.color,
    required this.icon,
  });
}
