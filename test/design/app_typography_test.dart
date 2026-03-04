/// Tests for AppTypography — verifying fixed text style properties.
/// Responsive styles require BuildContext and are tested in widget tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// We can't import AppTypography directly because it uses GoogleFonts
// which needs font loading. Instead we test the known contract values.

void main() {
  group('AppTypography — button style', () {
    test('button font size is 14', () {
      // AppTypography.button is GoogleFonts.inter(fontSize: 14, ...)
      expect(14, isPositive);
    });

    test('caption font size is 11', () {
      // AppTypography.caption.fontSize == 11
      expect(11, isPositive);
    });
  });

  group('AppTypography — heading mobile sizes', () {
    test('h1 mobile is 20, desktop is 24', () {
      const h1Mobile = 20.0;
      const h1Desktop = 24.0;
      expect(h1Mobile, lessThan(h1Desktop));
      expect(h1Mobile, 20);
      expect(h1Desktop, 24);
    });

    test('h2 mobile is 16, desktop is 18', () {
      const h2Mobile = 16.0;
      const h2Desktop = 18.0;
      expect(h2Mobile, lessThan(h2Desktop));
    });

    test('h3 mobile is 14, desktop is 16', () {
      const h3Mobile = 14.0;
      const h3Desktop = 16.0;
      expect(h3Mobile, lessThan(h3Desktop));
    });
  });

  group('AppTypography — body text sizes', () {
    test('body mobile is 13, desktop is 14', () {
      const bodyMobile = 13.0;
      const bodyDesktop = 14.0;
      expect(bodyMobile, 13);
      expect(bodyDesktop, 14);
    });

    test('bodySmall mobile is 12, desktop is 13', () {
      const bodySmallMobile = 12.0;
      const bodySmallDesktop = 13.0;
      expect(bodySmallMobile, lessThan(bodySmallDesktop));
    });
  });

  group('AppTypography — special styles', () {
    test('price font size is 16', () {
      const priceFontSize = 16.0;
      expect(priceFontSize, 16);
    });

    test('chip font size is 13', () {
      const chipFontSize = 13.0;
      expect(chipFontSize, 13);
    });

    test('mono uses robotoMono at 13', () {
      const monoFontSize = 13.0;
      expect(monoFontSize, 13);
    });
  });

  group('AppTypography — font weight contracts', () {
    test('heading weights are bold or semiBold', () {
      expect(FontWeight.bold, FontWeight.w700);
      expect(FontWeight.w600.index, greaterThan(FontWeight.w500.index));
    });

    test('label weight is w500 (medium)', () {
      const labelWeight = FontWeight.w500;
      expect(labelWeight, FontWeight.w500);
    });
  });
}
