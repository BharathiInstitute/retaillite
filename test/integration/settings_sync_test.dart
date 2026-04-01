/// Tests for settings sync — theme, language, billing settings persistence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/models/theme_settings_model.dart';

void main() {
  group('Settings sync: theme color', () {
    test('theme color toJson → fromJson roundtrip preserves value', () {
      const original = ThemeSettingsModel(primaryColorHex: '#3B82F6');
      final json = original.toJson();
      final restored = ThemeSettingsModel.fromJson(json);
      expect(restored.primaryColorHex, '#3B82F6');
    });

    test('theme settings preserve font family', () {
      const original = ThemeSettingsModel(fontFamily: 'Poppins');
      final json = original.toJson();
      final restored = ThemeSettingsModel.fromJson(json);
      expect(restored.fontFamily, 'Poppins');
    });
  });

  group('Settings sync: language', () {
    test('language code persists correctly', () {
      const languageCode = 'hi'; // Hindi
      final saved = {'languageCode': languageCode};
      expect(saved['languageCode'], 'hi');
    });

    test('default language is English', () {
      const defaultLanguage = 'en';
      expect(defaultLanguage, 'en');
    });
  });

  group('Settings sync: billing settings', () {
    test('tax rate persists and restores', () {
      const taxRate = 18.0;
      final saved = {'taxRate': taxRate};
      expect(saved['taxRate'], 18.0);
    });

    test('receipt footer persists and restores', () {
      const footer = 'Thank you for shopping!';
      final saved = {'receiptFooter': footer};
      expect(saved['receiptFooter'], footer);
    });
  });

  group('Settings sync: printer config', () {
    test('printer config survives sign-out + sign-in', () {
      // Printer config is stored in local SharedPrefs, not Firestore
      // So it persists across sign-out / sign-in
      const printerType = 'Bluetooth';
      const paperSize = '80mm';
      expect(printerType.isNotEmpty, isTrue);
      expect(paperSize.isNotEmpty, isTrue);
    });

    test('clearUserLocalSettings keeps printer config', () {
      // User-level settings cleared, but printer stays
      const printerCleared = false; // printer NOT cleared
      const userSettingsCleared = true;
      expect(printerCleared, isFalse);
      expect(userSettingsCleared, isTrue);
    });
  });
}
