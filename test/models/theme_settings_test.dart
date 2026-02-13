import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/theme_settings_model.dart';

void main() {
  group('ThemeSettingsModel', () {
    test('should have sensible defaults', () {
      const settings = ThemeSettingsModel();

      expect(settings.primaryColorHex, '#10B981');
      expect(settings.fontFamily, 'Inter');
      expect(settings.fontSizeScale, 1.0);
      expect(settings.useDarkMode, false);
      expect(settings.useSystemTheme, false);
    });

    test('should parse primaryColor from hex', () {
      const settings = ThemeSettingsModel(primaryColorHex: '#3B82F6');
      final color = settings.primaryColor;

      expect(color, const Color(0xFF3B82F6));
    });

    test('should fallback on invalid color hex', () {
      const settings = ThemeSettingsModel(primaryColorHex: 'not-a-color');
      final color = settings.primaryColor;

      // Should return default emerald
      expect(color, const Color(0xFF10B981));
    });

    test('should have 8 color presets', () {
      expect(ThemeSettingsModel.colorPresets.length, 8);
      expect(ThemeSettingsModel.colorPresets.first, '#10B981');
    });

    test('should have 5 font presets', () {
      expect(ThemeSettingsModel.fontPresets.length, 5);
      expect(ThemeSettingsModel.fontPresets, contains('Inter'));
      expect(ThemeSettingsModel.fontPresets, contains('Roboto'));
    });

    test('should copyWith preserve unchanged fields', () {
      const original = ThemeSettingsModel(
        primaryColorHex: '#3B82F6',
        fontFamily: 'Poppins',
        fontSizeScale: 1.2,
        useDarkMode: true,
      );

      final updated = original.copyWith(fontSizeScale: 0.8);

      expect(updated.fontSizeScale, 0.8);
      expect(updated.primaryColorHex, '#3B82F6');
      expect(updated.fontFamily, 'Poppins');
      expect(updated.useDarkMode, true);
    });

    test('should serialize to JSON', () {
      const settings = ThemeSettingsModel(
        primaryColorHex: '#EF4444',
        fontFamily: 'Lato',
        fontSizeScale: 1.2,
        useDarkMode: true,
      );

      final json = settings.toJson();

      expect(json['primaryColorHex'], '#EF4444');
      expect(json['fontFamily'], 'Lato');
      expect(json['fontSizeScale'], 1.2);
      expect(json['useDarkMode'], true);
      expect(json['useSystemTheme'], false);
    });

    test('should deserialize from JSON', () {
      final settings = ThemeSettingsModel.fromJson({
        'primaryColorHex': '#8B5CF6',
        'fontFamily': 'Open Sans',
        'fontSizeScale': 0.8,
        'useDarkMode': false,
        'useSystemTheme': true,
      });

      expect(settings.primaryColorHex, '#8B5CF6');
      expect(settings.fontFamily, 'Open Sans');
      expect(settings.fontSizeScale, 0.8);
      expect(settings.useDarkMode, false);
      expect(settings.useSystemTheme, true);
    });

    test('should handle missing JSON fields with defaults', () {
      final settings = ThemeSettingsModel.fromJson({});

      expect(settings.primaryColorHex, '#10B981');
      expect(settings.fontFamily, 'Inter');
      expect(settings.fontSizeScale, 1.0);
      expect(settings.useDarkMode, false);
      expect(settings.useSystemTheme, true); // fromJson default differs
    });

    test('should round-trip through JSON correctly', () {
      const original = ThemeSettingsModel(
        primaryColorHex: '#F59E0B',
        fontFamily: 'Roboto',
        fontSizeScale: 1.1,
        useDarkMode: true,
      );

      final restored = ThemeSettingsModel.fromJson(original.toJson());

      expect(restored.primaryColorHex, original.primaryColorHex);
      expect(restored.fontFamily, original.fontFamily);
      expect(restored.fontSizeScale, original.fontSizeScale);
      expect(restored.useDarkMode, original.useDarkMode);
      expect(restored.useSystemTheme, original.useSystemTheme);
    });

    test('should handle int fontSizeScale from JSON', () {
      final settings = ThemeSettingsModel.fromJson({
        'fontSizeScale': 1, // int instead of double
      });

      expect(settings.fontSizeScale, 1.0);
    });
  });
}
