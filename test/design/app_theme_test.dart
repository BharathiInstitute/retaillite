/// Tests for AppTheme — verifying light/dark theme properties.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/core/design/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Pre-build themes inside a guarded zone so async google_fonts
  // font-loading errors are suppressed (fonts fall back to platform default).
  late ThemeData lightTheme;
  late ThemeData darkTheme;

  setUpAll(() async {
    await runZonedGuarded(
      () async {
        lightTheme = AppTheme.light;
        darkTheme = AppTheme.dark;
        // Let async font-loading futures settle (and fail) inside this zone.
        await Future<void>.delayed(const Duration(seconds: 1));
      },
      (error, stack) {
        // Suppress google_fonts asset-not-found errors in test environment.
      },
    );
  });

  group('AppTheme.light', () {
    test('uses Material 3', () {
      expect(lightTheme.useMaterial3, true);
    });

    test('brightness is light', () {
      expect(lightTheme.brightness, Brightness.light);
    });

    test('scaffold background is AppColors.background', () {
      expect(lightTheme.scaffoldBackgroundColor, AppColors.background);
    });

    test('card color is AppColors.card', () {
      expect(lightTheme.cardColor, AppColors.card);
    });

    test('primary color matches AppColors.primary', () {
      expect(lightTheme.colorScheme.primary, AppColors.primary);
    });

    test('error color is red', () {
      expect(lightTheme.colorScheme.error, AppColors.error);
    });

    test('appBar has no elevation', () {
      expect(lightTheme.appBarTheme.elevation, 0);
    });

    test('elevated button has primary background', () {
      final style = lightTheme.elevatedButtonTheme.style!;
      final bg = style.backgroundColor!.resolve({});
      expect(bg, AppColors.primary);
    });

    test('card theme has zero elevation and rounded corners', () {
      expect(lightTheme.cardTheme.elevation, 0);
      final shape = lightTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(10));
    });

    test('snackbar uses floating behavior', () {
      expect(lightTheme.snackBarTheme.behavior, SnackBarBehavior.floating);
    });

    test('bottom navigation has primary selected color', () {
      expect(
        lightTheme.bottomNavigationBarTheme.selectedItemColor,
        AppColors.primary,
      );
    });

    test('text theme has all standard sizes', () {
      expect(lightTheme.textTheme.headlineLarge, isNotNull);
      expect(lightTheme.textTheme.bodyLarge, isNotNull);
      expect(lightTheme.textTheme.labelSmall, isNotNull);
    });
  });

  group('AppTheme.dark', () {
    test('brightness is dark', () {
      expect(darkTheme.brightness, Brightness.dark);
    });

    test('scaffold uses dark background', () {
      expect(darkTheme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    test('card uses dark card color', () {
      expect(darkTheme.cardColor, AppColors.cardDark);
    });

    test('text theme uses light text on dark', () {
      expect(
        darkTheme.textTheme.headlineLarge!.color,
        AppColors.textPrimaryDark,
      );
    });

    test('primary color is primaryLight for better contrast', () {
      expect(darkTheme.colorScheme.primary, AppColors.primaryLight);
    });
  });
}
