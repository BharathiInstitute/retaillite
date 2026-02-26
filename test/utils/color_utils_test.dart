import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/color_utils.dart';

void main() {
  // ── ColorOpacity Extension ──

  group('ColorOpacity.withAlpha8', () {
    test('applies full opacity', () {
      final color = Colors.red.withAlpha8(1.0);
      expect(color.a, closeTo(1.0, 0.01));
    });

    test('applies zero opacity', () {
      final color = Colors.red.withAlpha8(0.0);
      expect(color.a, closeTo(0.0, 0.01));
    });

    test('applies half opacity', () {
      final color = Colors.blue.withAlpha8(0.5);
      expect(color.a, closeTo(0.5, 0.02));
    });

    test('preserves RGB components', () {
      const original = Color.fromRGBO(100, 150, 200, 1.0);
      final result = original.withAlpha8(0.5);
      // Flutter Color.r/g/b return normalized 0.0-1.0 values
      expect((result.r * 255).round(), 100);
      expect((result.g * 255).round(), 150);
      expect((result.b * 255).round(), 200);
    });
  });

  // ── OpacityColors Constants ──

  group('OpacityColors', () {
    test('black colors have correct RGB', () {
      expect((OpacityColors.black05.r * 255).round(), 0);
      expect((OpacityColors.black05.g * 255).round(), 0);
      expect((OpacityColors.black05.b * 255).round(), 0);
    });

    test('black05 has 5% opacity', () {
      expect(OpacityColors.black05.a, closeTo(0.05, 0.01));
    });

    test('black50 has 50% opacity', () {
      expect(OpacityColors.black50.a, closeTo(0.50, 0.01));
    });

    test('white colors have correct RGB', () {
      expect((OpacityColors.white10.r * 255).round(), 255);
      expect((OpacityColors.white10.g * 255).round(), 255);
      expect((OpacityColors.white10.b * 255).round(), 255);
    });

    test('primary colors have correct indigo base', () {
      expect((OpacityColors.primary10.r * 255).round(), 99);
      expect((OpacityColors.primary10.g * 255).round(), 102);
      expect((OpacityColors.primary10.b * 255).round(), 241);
    });

    test('success colors have correct green base', () {
      expect((OpacityColors.success10.r * 255).round(), 34);
      expect((OpacityColors.success10.g * 255).round(), 197);
      expect((OpacityColors.success10.b * 255).round(), 94);
    });

    test('error colors have correct red base', () {
      expect((OpacityColors.error10.r * 255).round(), 239);
      expect((OpacityColors.error10.g * 255).round(), 68);
      expect((OpacityColors.error10.b * 255).round(), 68);
    });

    test('warning colors have correct amber base', () {
      expect((OpacityColors.warning10.r * 255).round(), 245);
      expect((OpacityColors.warning10.g * 255).round(), 158);
      expect((OpacityColors.warning10.b * 255).round(), 11);
    });

    test('all opacity variants exist', () {
      expect(OpacityColors.black08, isNotNull);
      expect(OpacityColors.black10, isNotNull);
      expect(OpacityColors.black12, isNotNull);
      expect(OpacityColors.black20, isNotNull);
      expect(OpacityColors.black30, isNotNull);
      expect(OpacityColors.white20, isNotNull);
      expect(OpacityColors.white50, isNotNull);
      expect(OpacityColors.white70, isNotNull);
      expect(OpacityColors.primary20, isNotNull);
      expect(OpacityColors.primary30, isNotNull);
      expect(OpacityColors.success20, isNotNull);
      expect(OpacityColors.error20, isNotNull);
      expect(OpacityColors.error30, isNotNull);
      expect(OpacityColors.warning20, isNotNull);
      expect(OpacityColors.warning30, isNotNull);
      expect(OpacityColors.info10, isNotNull);
      expect(OpacityColors.info20, isNotNull);
      expect(OpacityColors.secondary10, isNotNull);
      expect(OpacityColors.secondary20, isNotNull);
      expect(OpacityColors.grey10, isNotNull);
      expect(OpacityColors.grey20, isNotNull);
    });
  });
}
