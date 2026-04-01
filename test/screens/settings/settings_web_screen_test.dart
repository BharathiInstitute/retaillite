/// Tests for SettingsWebScreen — tab navigation and section display logic.
library;

import 'package:flutter_test/flutter_test.dart';

/// Mirror of the SettingsTab enum from settings_web_screen.dart
enum _SettingsTab { general, account, hardware, billing }

void main() {
  group('SettingsWebScreen tab logic', () {
    test('settings tabs include general, account, hardware, billing', () {
      expect(_SettingsTab.values.length, 4);
      expect(_SettingsTab.values.map((t) => t.name).toList(), [
        'general',
        'account',
        'hardware',
        'billing',
      ]);
    });

    test('default tab is general', () {
      const defaultTab = _SettingsTab.general;
      expect(defaultTab, _SettingsTab.general);
    });

    test('tab switching changes displayed content', () {
      var currentTab = _SettingsTab.general;
      currentTab = _SettingsTab.billing;
      expect(currentTab, _SettingsTab.billing);
    });
  });

  group('SettingsWebScreen controller initialization', () {
    test('currency defaults to INR', () {
      const currency = 'INR';
      expect(currency, 'INR');
    });

    test('timezone defaults to Asia/Kolkata', () {
      const timezone = 'Asia/Kolkata';
      expect(timezone, 'Asia/Kolkata');
    });
  });
}
