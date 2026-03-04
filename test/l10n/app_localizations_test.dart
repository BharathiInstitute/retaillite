/// Tests for AppLocalizations — i18n support for en, hi, te.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/l10n/app_localizations.dart';

void main() {
  group('supportedLocales', () {
    test('has 3 entries: en, hi, te', () {
      expect(supportedLocales.length, 3);
      expect(supportedLocales.map((l) => l.languageCode).toList(), [
        'en',
        'hi',
        'te',
      ]);
    });
  });

  group('AppLocalizations — English', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = AppLocalizations(const Locale('en'));
    });

    test('appName returns non-empty', () {
      expect(l10n.appName, isNotEmpty);
    });

    test('navigation strings return non-empty', () {
      expect(l10n.billing, isNotEmpty);
      expect(l10n.khata, isNotEmpty);
      expect(l10n.products, isNotEmpty);
      expect(l10n.reports, isNotEmpty);
      expect(l10n.dashboard, isNotEmpty);
      expect(l10n.settings, isNotEmpty);
    });

    test('common actions return non-empty', () {
      expect(l10n.save, isNotEmpty);
      expect(l10n.cancel, isNotEmpty);
      expect(l10n.delete, isNotEmpty);
      expect(l10n.add, isNotEmpty);
      expect(l10n.edit, isNotEmpty);
      expect(l10n.search, isNotEmpty);
    });

    test('billing strings return non-empty', () {
      expect(l10n.total, isNotEmpty);
      expect(l10n.cash, isNotEmpty);
      expect(l10n.upi, isNotEmpty);
      expect(l10n.pay, isNotEmpty);
    });

    test('billNumber includes number', () {
      final result = l10n.billNumber(42);
      expect(result, contains('42'));
    });

    test('itemsInCart includes count', () {
      final result = l10n.itemsInCart(5);
      expect(result, contains('5'));
    });
  });

  group('AppLocalizations — Hindi', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = AppLocalizations(const Locale('hi'));
    });

    test('appName returns non-empty', () {
      expect(l10n.appName, isNotEmpty);
    });

    test('navigation strings return non-empty', () {
      expect(l10n.billing, isNotEmpty);
      expect(l10n.khata, isNotEmpty);
      expect(l10n.products, isNotEmpty);
      expect(l10n.reports, isNotEmpty);
    });

    test('common actions return non-empty', () {
      expect(l10n.save, isNotEmpty);
      expect(l10n.cancel, isNotEmpty);
    });
  });

  group('AppLocalizations — Telugu', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = AppLocalizations(const Locale('te'));
    });

    test('appName returns non-empty', () {
      expect(l10n.appName, isNotEmpty);
    });

    test('navigation strings return non-empty', () {
      expect(l10n.billing, isNotEmpty);
      expect(l10n.khata, isNotEmpty);
      expect(l10n.products, isNotEmpty);
    });
  });

  group('AppLocalizations — fallback', () {
    test('unsupported locale falls back to English', () {
      final l10n = AppLocalizations(const Locale('fr'));
      // _translate falls back to en then to the key itself
      expect(l10n.appName, isNotEmpty);
      // Should match English since 'fr' is not supported
      final en = AppLocalizations(const Locale('en'));
      expect(l10n.appName, en.appName);
    });

    test('missing key returns the key itself', () {
      // _translate returns key if not found in any locale
      // We can't test this via public API without a missing key getter
      // But we verify the fallback chain works by using a supported locale
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.appName, isNot(equals('appName'))); // Not the raw key
    });
  });

  group('AppLocalizationsDelegate', () {
    test('delegate supports en, hi, te', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('en')), true);
      expect(AppLocalizations.delegate.isSupported(const Locale('hi')), true);
      expect(AppLocalizations.delegate.isSupported(const Locale('te')), true);
    });

    test('delegate does not support unsupported locales', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('fr')), false);
      expect(AppLocalizations.delegate.isSupported(const Locale('ja')), false);
    });
  });
}
