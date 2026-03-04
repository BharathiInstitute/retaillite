/// Design system tests — AppColors.updatePrimary, semantic colors, AppSizes
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/core/design/app_sizes.dart';

void main() {
  // ── AppColors.updatePrimary ──

  group('AppColors.updatePrimary', () {
    // Save originals to restore after each test
    late Color origPrimary;

    setUp(() {
      origPrimary = AppColors.primary;
    });

    tearDown(() {
      // Restore default
      AppColors.updatePrimary(origPrimary);
    });

    test('updates primary color', () {
      const blue = Color(0xFF3B82F6);
      AppColors.updatePrimary(blue);
      expect(AppColors.primary, blue);
    });

    test('generates darker shade', () {
      const base = Color(0xFF10B981);
      AppColors.updatePrimary(base);
      final primaryHSL = HSLColor.fromColor(AppColors.primary);
      final darkHSL = HSLColor.fromColor(AppColors.primaryDark);
      expect(darkHSL.lightness, lessThanOrEqualTo(primaryHSL.lightness));
    });

    test('generates lighter shade', () {
      const base = Color(0xFF10B981);
      AppColors.updatePrimary(base);
      final primaryHSL = HSLColor.fromColor(AppColors.primary);
      final lightHSL = HSLColor.fromColor(AppColors.primaryLight);
      expect(lightHSL.lightness, greaterThanOrEqualTo(primaryHSL.lightness));
    });

    test('syncs secondary with primary', () {
      const red = Color(0xFFEF4444);
      AppColors.updatePrimary(red);
      expect(AppColors.secondary, red);
      expect(AppColors.secondaryLight, AppColors.primaryLight);
      expect(AppColors.secondaryDark, AppColors.primaryDark);
    });

    test('handles very dark color (lightness near 0)', () {
      const nearBlack = Color(0xFF0A0A0A);
      AppColors.updatePrimary(nearBlack);
      // Should not crash, lightness clamps to 0
      expect(AppColors.primaryDark, isNotNull);
    });

    test('handles very light color (lightness near 1)', () {
      const nearWhite = Color(0xFFFAFAFA);
      AppColors.updatePrimary(nearWhite);
      // Should not crash, lightness clamps to 1
      expect(AppColors.primaryLight, isNotNull);
    });
  });

  // ── Semantic colors are non-null ──

  group('AppColors semantic colors', () {
    test('success color is green', () {
      expect(AppColors.success, const Color(0xFF22C55E));
    });

    test('error color is red', () {
      expect(AppColors.error, const Color(0xFFEF4444));
    });

    test('warning color is amber', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });

    test('info color is blue', () {
      expect(AppColors.info, const Color(0xFF3B82F6));
    });

    test('all background variants are non-null', () {
      expect(AppColors.successBg, isNotNull);
      expect(AppColors.errorBg, isNotNull);
      expect(AppColors.warningBg, isNotNull);
      expect(AppColors.infoBg, isNotNull);
    });
  });

  // ── AppSizes ──

  group('AppSizes', () {
    test('border radius values are positive', () {
      expect(AppSizes.radiusXs, greaterThan(0));
      expect(AppSizes.radiusSm, greaterThan(0));
      expect(AppSizes.radiusMd, greaterThan(0));
      expect(AppSizes.radiusLg, greaterThan(0));
    });

    test('spacing values are non-negative', () {
      expect(AppSizes.xs, greaterThanOrEqualTo(0));
      expect(AppSizes.sm, greaterThanOrEqualTo(0));
      expect(AppSizes.md, greaterThanOrEqualTo(0));
      expect(AppSizes.lg, greaterThanOrEqualTo(0));
    });

    test('spacing values increase', () {
      expect(AppSizes.xs, lessThan(AppSizes.sm));
      expect(AppSizes.sm, lessThan(AppSizes.md));
      expect(AppSizes.md, lessThan(AppSizes.lg));
    });
  });
}
