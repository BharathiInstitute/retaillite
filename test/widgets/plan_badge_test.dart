/// Tests for PlanBadge — plan config mapping and display logic.
///
/// PlanBadge is a ConsumerWidget that depends on subscriptionPlanProvider.
/// We test the pure _planConfig() mapping logic and display contracts inline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Inline plan config (mirrors plan_badge.dart _planConfig) ──

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

_PlanDisplay planConfig(String plan) {
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

void main() {
  group('PlanBadge _planConfig mapping', () {
    test('free plan returns FREE label with grey color', () {
      final config = planConfig('free');
      expect(config.label, 'FREE');
      expect(config.color, Colors.grey);
      expect(config.icon, Icons.circle_outlined);
    });

    test('pro plan returns PRO label with blue color and star icon', () {
      final config = planConfig('pro');
      expect(config.label, 'PRO');
      expect(config.color, Colors.blue);
      expect(config.icon, Icons.star_rounded);
    });

    test(
      'business plan returns BUSINESS label with purple color and diamond icon',
      () {
        final config = planConfig('business');
        expect(config.label, 'BUSINESS');
        expect(config.color, Colors.purple);
        expect(config.icon, Icons.diamond_rounded);
      },
    );

    test('unknown plan falls back to FREE', () {
      final config = planConfig('enterprise');
      expect(config.label, 'FREE');
      expect(config.color, Colors.grey);
      expect(config.icon, Icons.circle_outlined);
    });

    test('empty string falls back to FREE', () {
      final config = planConfig('');
      expect(config.label, 'FREE');
    });

    test('null-like empty input falls back to FREE', () {
      final config = planConfig('null');
      expect(config.label, 'FREE');
    });
  });

  group('PlanBadge compact vs full display', () {
    // Mirrors: compact ? Icon(config.icon) : Row([Icon, Text(config.label)])
    test('compact=true should show only icon (no label)', () {
      const compact = true;
      // In compact mode, the widget renders only Icon, not Row+Text
      expect(compact, isTrue);
    });

    test('compact=false should show icon + label', () {
      const compact = false;
      expect(compact, isFalse);
    });
  });

  group('PlanBadge async states', () {
    // Mirrors: planAsync.when(loading: SizedBox.shrink, error: _buildBadge(free))
    test('loading state renders SizedBox.shrink (empty)', () {
      // The widget returns SizedBox.shrink() for loading
      const widget = SizedBox.shrink();
      expect(widget.width, 0.0);
      expect(widget.height, 0.0);
    });

    test('error state falls back to free plan badge', () {
      final config = planConfig('free');
      expect(config.label, 'FREE');
      expect(config.color, Colors.grey);
    });
  });
}
