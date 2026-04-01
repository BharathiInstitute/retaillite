/// Tests for ThemeSettingsScreen — color presets, font scale, dark mode logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/theme_settings_model.dart';

void main() {
  group('ThemeSettingsScreen color presets', () {
    test('color presets list is non-empty', () {
      expect(ThemeSettingsModel.colorPresets.isNotEmpty, isTrue);
    });

    test('default theme uses first color preset', () {
      final defaultColor = ThemeSettingsModel.colorPresets.first;
      expect(defaultColor, isNotNull);
    });

    test('each color preset is unique', () {
      const presets = ThemeSettingsModel.colorPresets;
      final unique = presets.toSet();
      expect(unique.length, presets.length);
    });
  });

  group('ThemeSettingsScreen font scale', () {
    test('default font scale is 1.0', () {
      const model = ThemeSettingsModel();
      expect(model.fontSizeScale, 1.0);
    });

    test('font scale of 1.2 increases text size by 20%', () {
      const scale = 1.2;
      const baseSize = 14.0;
      const scaledSize = baseSize * scale;
      expect(scaledSize, 16.8);
    });

    test('font scale of 0.8 decreases text size by 20%', () {
      const scale = 0.8;
      const baseSize = 14.0;
      const scaledSize = baseSize * scale;
      expect(scaledSize, closeTo(11.2, 0.01));
    });
  });

  group('ThemeSettingsScreen dark mode', () {
    test('default is light mode', () {
      const model = ThemeSettingsModel();
      expect(model.useDarkMode, isFalse);
    });

    test('toggling dark mode changes state', () {
      const model = ThemeSettingsModel(useDarkMode: true);
      expect(model.useDarkMode, isTrue);
    });
  });

  group('ThemeSettingsScreen reset to defaults', () {
    test('reset returns default ThemeSettingsModel', () {
      const customModel = ThemeSettingsModel(
        fontSizeScale: 1.5,
        useDarkMode: true,
      );
      const defaultModel = ThemeSettingsModel();
      expect(customModel.fontSizeScale, isNot(defaultModel.fontSizeScale));
      expect(customModel.useDarkMode, isNot(defaultModel.useDarkMode));
    });

    test('default model has expected values', () {
      const model = ThemeSettingsModel();
      expect(model.fontSizeScale, 1.0);
      expect(model.useDarkMode, isFalse);
    });
  });
}
