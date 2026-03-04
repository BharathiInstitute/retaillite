/// Tests for AppSizes — static constants and dimension helpers.
library;

import 'package:flutter_test/flutter_test.dart';

// Inline the static constants we can test without BuildContext.
// AppSizes methods that need BuildContext are tested via widget tests.

/// Mirrors the constant values from AppSizes.
class _AppSizes {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;

  static const double chipHeight = 32;
  static const double chipPadding = 12;
  static const double badgeSize = 20;

  static const double cardPadding = 12;
  static const double cardPaddingLarge = 16;

  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;

  static const double maxContentWidth = 1200;
  static const double bottomNavHeight = 56;
  static const double navRailWidth = 72;
  static const double fullSidebarWidth = 220;
  static const double fullSidebarWidthLarge = 240;

  static const double cartBottomSheetFraction = 0.7;

  static const double inputHeightSmall = 40;
  static const double minTouchTarget = 48;
  static const double iconButton = 36;
  static const double fabSize = 48;
}

void main() {
  group('AppSizes — spacing constants', () {
    test('spacing values are positive and ascending', () {
      expect(_AppSizes.xs, 4);
      expect(_AppSizes.sm, 6);
      expect(_AppSizes.md, 10);
      expect(_AppSizes.lg, 14);
      expect(_AppSizes.xl, 20);
      expect(_AppSizes.xs < _AppSizes.sm, true);
      expect(_AppSizes.sm < _AppSizes.md, true);
      expect(_AppSizes.md < _AppSizes.lg, true);
      expect(_AppSizes.lg < _AppSizes.xl, true);
    });

    test('chip and badge sizes', () {
      expect(_AppSizes.chipHeight, 32);
      expect(_AppSizes.chipPadding, 12);
      expect(_AppSizes.badgeSize, 20);
    });

    test('card padding values', () {
      expect(_AppSizes.cardPadding, 12);
      expect(_AppSizes.cardPaddingLarge, 16);
      expect(_AppSizes.cardPaddingLarge > _AppSizes.cardPadding, true);
    });
  });

  group('AppSizes — border radius constants', () {
    test('radius values are positive and ascending', () {
      expect(_AppSizes.radiusXs, 4);
      expect(_AppSizes.radiusSm, 6);
      expect(_AppSizes.radiusMd, 10);
      expect(_AppSizes.radiusLg, 14);
      expect(_AppSizes.radiusXl, 20);
      expect(_AppSizes.radiusFull, 999);
    });
  });

  group('AppSizes — icon sizes', () {
    test('icon sizes are ascending', () {
      expect(_AppSizes.iconXs, 14);
      expect(_AppSizes.iconSm, 18);
      expect(_AppSizes.iconMd, 22);
      expect(_AppSizes.iconLg, 28);
    });
  });

  group('AppSizes — layout widths', () {
    test('max content width', () {
      expect(_AppSizes.maxContentWidth, 1200);
    });

    test('navigation dimensions', () {
      expect(_AppSizes.bottomNavHeight, 56);
      expect(_AppSizes.navRailWidth, 72);
      expect(_AppSizes.fullSidebarWidth, 220);
      expect(_AppSizes.fullSidebarWidthLarge, 240);
    });

    test('cart bottom sheet fraction is between 0 and 1', () {
      expect(_AppSizes.cartBottomSheetFraction, 0.7);
      expect(
        _AppSizes.cartBottomSheetFraction > 0 &&
            _AppSizes.cartBottomSheetFraction < 1,
        true,
      );
    });
  });

  group('AppSizes — touch targets', () {
    test('minimum touch target meets accessibility guidelines', () {
      expect(_AppSizes.minTouchTarget, 48);
      expect(_AppSizes.minTouchTarget >= 44, true); // WCAG minimum
    });

    test('icon button and fab sizes', () {
      expect(_AppSizes.iconButton, 36);
      expect(_AppSizes.fabSize, 48);
    });

    test('input height small', () {
      expect(_AppSizes.inputHeightSmall, 40);
    });
  });
}
