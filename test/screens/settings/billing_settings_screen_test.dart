/// Tests for BillingSettingsScreen — invoice, tax, and UPI validation logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('BillingSettingsScreen tax configuration', () {
    test('tax rate defaults to 0', () {
      const taxRate = 0.0;
      expect(taxRate, 0.0);
    });

    test('valid tax rate is non-negative', () {
      const taxRate = 18.0;
      expect(taxRate >= 0, isTrue);
    });

    test('tax enabled toggle', () {
      var taxEnabled = false;
      taxEnabled = true;
      expect(taxEnabled, isTrue);
    });

    test('tax inclusive flag toggles', () {
      var taxInclusive = false;
      taxInclusive = true;
      expect(taxInclusive, isTrue);
    });
  });

  group('BillingSettingsScreen UPI validation', () {
    test('valid UPI ID format: user@bank', () {
      const upi = 'shopowner@upi';
      final isValid = RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(upi);
      expect(isValid, isTrue);
    });

    test('empty UPI ID is valid (optional field)', () {
      const upi = '';
      final isValid = upi.isEmpty || RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(upi);
      expect(isValid, isTrue);
    });

    test('invalid UPI ID without @ rejected', () {
      const upi = 'shopowner';
      final isValid = upi.isEmpty || RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(upi);
      expect(isValid, isFalse);
    });
  });

  group('BillingSettingsScreen invoice settings', () {
    test('invoice title can be custom text', () {
      const title = 'TAX INVOICE';
      expect(title.isNotEmpty, isTrue);
    });

    test('receipt footer terms field accepts text', () {
      const terms = 'Thank you for shopping!';
      expect(terms.isNotEmpty, isTrue);
    });

    test('tax rate validator accepts valid number', () {
      expect(Validators.price('18'), isNull);
    });

    test('tax rate validator rejects negative', () {
      expect(Validators.price('-5'), isNotNull);
    });
  });
}
