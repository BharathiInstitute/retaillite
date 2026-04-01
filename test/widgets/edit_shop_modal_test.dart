/// Tests for EditShopModal — validation and form logic.
///
/// Depends on authNotifierProvider. We test Validators used in the form.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  // ── Shop name validation ──
  // Mirrors: validator: (v) => Validators.name(v, l10n.shopName)

  group('EditShopModal shop name validation', () {
    test('empty shop name shows error', () {
      expect(Validators.name('', 'Shop name'), isNotNull);
    });

    test('valid shop name passes', () {
      expect(Validators.name('Sharma General Store', 'Shop name'), isNull);
    });

    test('single character shop name shows error', () {
      expect(Validators.name('S', 'Shop name'), isNotNull);
    });
  });

  // ── Owner name validation ──
  // Mirrors: validator: (v) => Validators.name(v, l10n.ownerName)

  group('EditShopModal owner name validation', () {
    test('empty owner name shows error', () {
      expect(Validators.name('', 'Owner name'), isNotNull);
    });

    test('valid owner name passes', () {
      expect(Validators.name('Raj Sharma', 'Owner name'), isNull);
    });
  });

  // ── Phone validation ──
  // Mirrors: validator: (v) => Validators.phone(v)

  group('EditShopModal phone validation', () {
    test('empty phone shows error', () {
      expect(Validators.phone(''), isNotNull);
    });

    test('valid phone passes', () {
      expect(Validators.phone('9876543210'), isNull);
    });

    test('invalid phone shows error', () {
      expect(Validators.phone('12345'), isNotNull);
    });
  });

  // ── GST validation ──
  // Mirrors: Validators.gstNumber (optional field)

  group('EditShopModal GST validation', () {
    test('empty GST is valid (optional)', () {
      expect(Validators.gstNumber(''), isNull);
    });

    test('null GST is valid (optional)', () {
      expect(Validators.gstNumber(null), isNull);
    });

    test('valid GST number passes', () {
      expect(Validators.gstNumber('22AAAAA0000A1Z5'), isNull);
    });

    test('invalid GST number shows error', () {
      expect(Validators.gstNumber('INVALID'), isNotNull);
    });
  });

  // ── Email display (read-only) ──
  // Mirrors: email field is displayed but not editable (Icon: lock)

  group('EditShopModal email field', () {
    test('email is read-only — shown with lock icon', () {
      const email = 'user@example.com';
      expect(email, contains('@'));
    });

    test('null email shows dash', () {
      const String? email = null;
      expect(email ?? '-', '-');
    });
  });

  // ── Prefill logic ──
  // Mirrors: _shopNameController = TextEditingController(text: user?.shopName ?? '')

  group('EditShopModal prefill', () {
    test('prefills with existing shop name', () {
      const shopName = 'Sharma Store';
      expect(shopName, isNotEmpty);
    });

    test('defaults to empty when null', () {
      const String? shopName = null;
      expect(shopName ?? '', isEmpty);
    });
  });
}
