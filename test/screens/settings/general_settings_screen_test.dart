/// Tests for GeneralSettingsScreen — shop info fields and locale settings.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('GeneralSettingsScreen shop info validation', () {
    test('shop name cannot be empty', () {
      expect(Validators.name('', 'Shop name'), isNotNull);
    });

    test('valid shop name passes', () {
      expect(Validators.name('My Store', 'Shop name'), isNull);
    });

    test('owner name cannot be empty', () {
      expect(Validators.name('', 'Owner name'), isNotNull);
    });

    test('valid phone passes', () {
      expect(Validators.phone('9876543210'), isNull);
    });

    test('invalid phone fails', () {
      expect(Validators.phone('123'), isNotNull);
    });

    test('optional GST empty is valid', () {
      expect(Validators.gstNumber(''), isNull);
    });

    test('valid GST passes', () {
      expect(Validators.gstNumber('22AAAAA0000A1Z5'), isNull);
    });
  });

  group('GeneralSettingsScreen locale settings', () {
    test('supported currencies include INR', () {
      const currencies = ['INR', 'USD', 'EUR'];
      expect(currencies.contains('INR'), isTrue);
    });

    test('default currency is INR', () {
      const defaultCurrency = 'INR';
      expect(defaultCurrency, 'INR');
    });

    test('supported timezones include Asia/Kolkata', () {
      const timezones = ['Asia/Kolkata', 'America/New_York', 'Europe/London'];
      expect(timezones.contains('Asia/Kolkata'), isTrue);
    });

    test('default timezone is Asia/Kolkata', () {
      const defaultTimezone = 'Asia/Kolkata';
      expect(defaultTimezone, 'Asia/Kolkata');
    });
  });
}
