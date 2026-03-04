/// Tests for ThemeSettingsProvider — ThemeSettingsModel, theme mode logic
///
/// Tests pure data class and theme mode determination.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/theme_settings_model.dart';

void main() {
  // ── ThemeSettingsModel data class ──

  group('ThemeSettingsModel', () {
    test('defaults are correct', () {
      const model = ThemeSettingsModel();
      expect(model.primaryColorHex, '#10B981');
      expect(model.fontFamily, 'Inter');
      expect(model.fontSizeScale, 1.0);
      expect(model.useDarkMode, isFalse);
      expect(model.useSystemTheme, isFalse);
    });

    test('primaryColor parses hex correctly', () {
      const model = ThemeSettingsModel(primaryColorHex: '#3B82F6');
      expect(model.primaryColor, const Color(0xFF3B82F6));
    });

    test('primaryColor handles default emerald', () {
      const model = ThemeSettingsModel();
      expect(model.primaryColor, const Color(0xFF10B981));
    });

    test('primaryColor handles invalid hex gracefully', () {
      const model = ThemeSettingsModel(primaryColorHex: 'invalid');
      // Falls back to emerald
      expect(model.primaryColor, const Color(0xFF10B981));
    });

    test('colorPresets has expected length', () {
      expect(ThemeSettingsModel.colorPresets.length, 8);
    });

    test('fontPresets has expected fonts', () {
      expect(ThemeSettingsModel.fontPresets, contains('Inter'));
      expect(ThemeSettingsModel.fontPresets, contains('Roboto'));
      expect(ThemeSettingsModel.fontPresets.length, 5);
    });
  });

  // ── copyWith ──

  group('ThemeSettingsModel.copyWith', () {
    test('preserves unchanged fields', () {
      const original = ThemeSettingsModel(
        useDarkMode: true,
        fontFamily: 'Roboto',
      );
      final copy = original.copyWith(fontSizeScale: 1.2);
      expect(copy.useDarkMode, isTrue);
      expect(copy.fontFamily, 'Roboto');
      expect(copy.fontSizeScale, 1.2);
    });

    test('overrides specified fields', () {
      const model = ThemeSettingsModel();
      final copy = model.copyWith(
        primaryColorHex: '#EF4444',
        useDarkMode: true,
        useSystemTheme: true,
      );
      expect(copy.primaryColorHex, '#EF4444');
      expect(copy.useDarkMode, isTrue);
      expect(copy.useSystemTheme, isTrue);
    });
  });

  // ── toJson/fromJson ──

  group('ThemeSettingsModel serialization', () {
    test('toJson includes all fields', () {
      const model = ThemeSettingsModel(
        primaryColorHex: '#3B82F6',
        fontFamily: 'Poppins',
        fontSizeScale: 1.2,
        useDarkMode: true,
      );
      final json = model.toJson();
      expect(json['primaryColorHex'], '#3B82F6');
      expect(json['fontFamily'], 'Poppins');
      expect(json['fontSizeScale'], 1.2);
      expect(json['useDarkMode'], isTrue);
      expect(json['useSystemTheme'], isFalse);
    });

    test('fromJson parses all fields', () {
      final model = ThemeSettingsModel.fromJson({
        'primaryColorHex': '#EC4899',
        'fontFamily': 'Lato',
        'fontSizeScale': 0.8,
        'useDarkMode': true,
        'useSystemTheme': true,
      });
      expect(model.primaryColorHex, '#EC4899');
      expect(model.fontFamily, 'Lato');
      expect(model.fontSizeScale, 0.8);
      expect(model.useDarkMode, isTrue);
      expect(model.useSystemTheme, isTrue);
    });

    test('fromJson handles missing fields with defaults', () {
      final model = ThemeSettingsModel.fromJson({});
      expect(model.primaryColorHex, '#10B981');
      expect(model.fontFamily, 'Inter');
      expect(model.fontSizeScale, 1.0);
      expect(model.useDarkMode, isFalse);
      expect(model.useSystemTheme, isFalse);
    });

    test('fromJson handles null values', () {
      final model = ThemeSettingsModel.fromJson({
        'primaryColorHex': null,
        'fontFamily': null,
        'fontSizeScale': null,
        'useDarkMode': null,
        'useSystemTheme': null,
      });
      expect(model.primaryColorHex, '#10B981');
      expect(model.fontFamily, 'Inter');
      expect(model.fontSizeScale, 1.0);
    });

    test('toJson→fromJson roundtrip preserves data', () {
      const original = ThemeSettingsModel(
        primaryColorHex: '#06B6D4',
        fontFamily: 'Open Sans',
        fontSizeScale: 1.4,
        useDarkMode: true,
      );
      final restored = ThemeSettingsModel.fromJson(original.toJson());
      expect(restored.primaryColorHex, original.primaryColorHex);
      expect(restored.fontFamily, original.fontFamily);
      expect(restored.fontSizeScale, original.fontSizeScale);
      expect(restored.useDarkMode, original.useDarkMode);
      expect(restored.useSystemTheme, original.useSystemTheme);
    });

    test('fromJson handles int fontSizeScale', () {
      final model = ThemeSettingsModel.fromJson({
        'fontSizeScale': 1, // int instead of double
      });
      expect(model.fontSizeScale, 1.0);
    });
  });

  // ── Theme mode determination (extracted from userThemeModeProvider) ──

  group('Theme mode determination', () {
    ThemeMode determineThemeMode(ThemeSettingsModel settings) {
      if (settings.useSystemTheme) return ThemeMode.system;
      return settings.useDarkMode ? ThemeMode.dark : ThemeMode.light;
    }

    test('system theme overrides dark mode setting', () {
      const settings = ThemeSettingsModel(
        useSystemTheme: true,
        useDarkMode: true,
      );
      expect(determineThemeMode(settings), ThemeMode.system);
    });

    test('dark mode when system theme disabled', () {
      const settings = ThemeSettingsModel(
        useDarkMode: true,
      );
      expect(determineThemeMode(settings), ThemeMode.dark);
    });

    test('light mode as default', () {
      const settings = ThemeSettingsModel();
      expect(determineThemeMode(settings), ThemeMode.light);
    });

    test('explicit light mode', () {
      const settings = ThemeSettingsModel(
        
      );
      expect(determineThemeMode(settings), ThemeMode.light);
    });
  });
}
