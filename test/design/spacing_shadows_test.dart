/// Tests for AppSpacing constants and AppShadows factory getters
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/design/app_colors.dart';

void main() {
  // ─── AppSpacing ──────────────────────────────────────────────────────

  group('AppSpacing', () {
    test('spacing values increase monotonically', () {
      final spacings = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];
      for (var i = 1; i < spacings.length; i++) {
        expect(
          spacings[i],
          greaterThan(spacings[i - 1]),
          reason: 'spacing[$i] should be > spacing[${i - 1}]',
        );
      }
    });

    test('all spacing values are positive', () {
      expect(AppSpacing.xs, greaterThan(0));
      expect(AppSpacing.sm, greaterThan(0));
      expect(AppSpacing.md, greaterThan(0));
      expect(AppSpacing.lg, greaterThan(0));
      expect(AppSpacing.xl, greaterThan(0));
      expect(AppSpacing.xxl, greaterThan(0));
    });

    test('exact spacing values', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 48.0);
    });

    test('radius values increase monotonically', () {
      final radii = [
        AppSpacing.radiusSm,
        AppSpacing.radiusMd,
        AppSpacing.radiusLg,
        AppSpacing.radiusXl,
        AppSpacing.radiusFull,
      ];
      for (var i = 1; i < radii.length; i++) {
        expect(
          radii[i],
          greaterThan(radii[i - 1]),
          reason: 'radius[$i] should be > radius[${i - 1}]',
        );
      }
    });

    test('radiusFull is 999 (effective circle)', () {
      expect(AppSpacing.radiusFull, 999.0);
    });
  });

  // ─── AppShadows ─────────────────────────────────────────────────────

  group('AppShadows', () {
    test('small returns single BoxShadow', () {
      final shadows = AppShadows.small;
      expect(shadows, hasLength(1));
      expect(shadows.first, isA<BoxShadow>());
    });

    test('medium returns single BoxShadow', () {
      final shadows = AppShadows.medium;
      expect(shadows, hasLength(1));
      expect(shadows.first, isA<BoxShadow>());
    });

    test('large returns single BoxShadow', () {
      final shadows = AppShadows.large;
      expect(shadows, hasLength(1));
      expect(shadows.first, isA<BoxShadow>());
    });

    test('blur radius increases with shadow size', () {
      final smallBlur = AppShadows.small.first.blurRadius;
      final mediumBlur = AppShadows.medium.first.blurRadius;
      final largeBlur = AppShadows.large.first.blurRadius;

      expect(mediumBlur, greaterThan(smallBlur));
      expect(largeBlur, greaterThan(mediumBlur));
    });

    test('offset.dy increases with shadow size', () {
      final smallOffset = AppShadows.small.first.offset.dy;
      final mediumOffset = AppShadows.medium.first.offset.dy;
      final largeOffset = AppShadows.large.first.offset.dy;

      expect(mediumOffset, greaterThan(smallOffset));
      expect(largeOffset, greaterThan(mediumOffset));
    });

    test('all shadows cast downward (dx=0, dy>0)', () {
      for (final shadows in [
        AppShadows.small,
        AppShadows.medium,
        AppShadows.large,
      ]) {
        final s = shadows.first;
        expect(s.offset.dx, 0);
        expect(s.offset.dy, greaterThan(0));
      }
    });

    test('opacity increases with shadow size', () {
      // Larger shadows are more opaque
      final smallOpacity = AppShadows.small.first.color.a;
      final mediumOpacity = AppShadows.medium.first.color.a;
      final largeOpacity = AppShadows.large.first.color.a;

      expect(mediumOpacity, greaterThan(smallOpacity));
      expect(largeOpacity, greaterThan(mediumOpacity));
    });
  });
}
