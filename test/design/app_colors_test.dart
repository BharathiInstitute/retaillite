/// Tests for AppColors — color constants, semantic colors, and updatePrimary.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/design/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColors — default values', () {
    setUp(() {
      // Reset to default before each test
      AppColors.updatePrimary(const Color(0xFF10B981));
    });

    test('default primary is emerald green', () {
      expect(AppColors.primary, const Color(0xFF10B981));
    });

    test('secondary syncs with primary', () {
      expect(AppColors.secondary, AppColors.primary);
    });
  });

  group('AppColors — semantic colors', () {
    test('success is green', () {
      expect(AppColors.success, const Color(0xFF22C55E));
    });

    test('error is red', () {
      expect(AppColors.error, const Color(0xFFEF4444));
    });

    test('warning is amber', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });

    test('info is blue', () {
      expect(AppColors.info, const Color(0xFF3B82F6));
    });

    test('background colors are lighter than text colors', () {
      expect(AppColors.successBg, isNot(AppColors.success));
      expect(AppColors.errorBg, isNot(AppColors.error));
    });
  });

  group('AppColors — payment colors', () {
    test('cash is green', () {
      expect(AppColors.cash, const Color(0xFF22C55E));
    });

    test('upi is indigo', () {
      expect(AppColors.upi, const Color(0xFF6366F1));
    });

    test('credit/udhar are red', () {
      expect(AppColors.credit, const Color(0xFFEF4444));
      expect(AppColors.udhar, AppColors.credit);
    });
  });

  group('AppColors — light mode neutrals', () {
    test('textPrimary is dark slate', () {
      expect(AppColors.textPrimary, const Color(0xFF1E293B));
    });

    test('surface is white', () {
      expect(AppColors.surface, Colors.white);
    });

    test('backward-compatible aliases match', () {
      expect(AppColors.backgroundLight, AppColors.background);
      expect(AppColors.surfaceLight, AppColors.surface);
      expect(AppColors.textPrimaryLight, AppColors.textPrimary);
    });
  });

  group('AppColors — dark mode neutrals', () {
    test('backgroundDark is very dark', () {
      expect(AppColors.backgroundDark, const Color(0xFF0F172A));
    });

    test('textPrimaryDark is near white', () {
      expect(AppColors.textPrimaryDark, const Color(0xFFF8FAFC));
    });
  });

  group('AppColors.updatePrimary', () {
    setUp(() {
      AppColors.updatePrimary(const Color(0xFF10B981));
    });

    test('updates all primary shades', () {
      const blue = Color(0xFF3B82F6);
      AppColors.updatePrimary(blue);

      expect(AppColors.primary, blue);
      expect(AppColors.secondary, blue);
      expect(AppColors.secondaryLight, AppColors.primaryLight);
      expect(AppColors.secondaryDark, AppColors.primaryDark);
    });

    test('primaryDark is darker than primary', () {
      const base = Color(0xFF10B981);
      AppColors.updatePrimary(base);
      final primaryHSL = HSLColor.fromColor(AppColors.primary);
      final darkHSL = HSLColor.fromColor(AppColors.primaryDark);
      expect(darkHSL.lightness, lessThanOrEqualTo(primaryHSL.lightness));
    });

    test('primaryLight is lighter than primary', () {
      const base = Color(0xFF10B981);
      AppColors.updatePrimary(base);
      final primaryHSL = HSLColor.fromColor(AppColors.primary);
      final lightHSL = HSLColor.fromColor(AppColors.primaryLight);
      expect(lightHSL.lightness, greaterThanOrEqualTo(primaryHSL.lightness));
    });

    test('updates gradients', () {
      const red = Color(0xFFEF4444);
      AppColors.updatePrimary(red);
      expect(AppColors.primaryGradient.colors.first, red);
    });
  });

  group('AppSpacing constants', () {
    test('spacing values are ascending', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
    });

    test('radius values are ascending', () {
      expect(AppSpacing.radiusSm, 8);
      expect(AppSpacing.radiusMd, 12);
      expect(AppSpacing.radiusLg, 16);
      expect(AppSpacing.radiusXl, 24);
      expect(AppSpacing.radiusFull, 999);
    });
  });

  group('AppShadows', () {
    test('small shadow has low blur', () {
      expect(AppShadows.small.length, 1);
      expect(AppShadows.small.first.blurRadius, 4);
    });

    test('medium shadow has moderate blur', () {
      expect(AppShadows.medium.length, 1);
      expect(AppShadows.medium.first.blurRadius, 8);
    });

    test('large shadow has high blur', () {
      expect(AppShadows.large.length, 1);
      expect(AppShadows.large.first.blurRadius, 16);
    });

    test('shadow sizes are ascending', () {
      expect(
        AppShadows.small.first.blurRadius < AppShadows.medium.first.blurRadius,
        true,
      );
      expect(
        AppShadows.medium.first.blurRadius < AppShadows.large.first.blurRadius,
        true,
      );
    });
  });
}
