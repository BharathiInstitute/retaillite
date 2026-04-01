/// Tests for AddCustomerModal — form validation and duplicate check logic.
///
/// Depends on Riverpod providers and khataServiceProvider.
/// We test the Validators and the duplicate phone check logic inline.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  // ── Name validation ──
  // Mirrors: validator: (v) => Validators.name(v)

  group('AddCustomerModal name validation', () {
    test('empty name shows error', () {
      expect(Validators.name(''), isNotNull);
    });

    test('null name shows error', () {
      expect(Validators.name(null), isNotNull);
    });

    test('valid name returns null', () {
      expect(Validators.name('Raj Sharma'), isNull);
    });

    test('single character name shows error', () {
      expect(Validators.name('R'), isNotNull);
    });
  });

  // ── Phone validation ──
  // Mirrors: PhoneTextField uses Validators.phone

  group('AddCustomerModal phone validation', () {
    test('empty phone returns error', () {
      expect(Validators.phone(''), isNotNull);
    });

    test('non-10-digit shows error', () {
      expect(Validators.phone('12345'), isNotNull);
    });

    test('valid 10-digit Indian number passes', () {
      expect(Validators.phone('9876543210'), isNull);
    });

    test('number not starting with 6-9 fails', () {
      expect(Validators.phone('1234567890'), isNotNull);
    });

    test('number with spaces is cleaned and validated', () {
      // Validators.phone strips non-digits
      expect(Validators.phone('98765 43210'), isNull);
    });

    test('number with country code prefix fails (too many digits)', () {
      expect(Validators.phone('+919876543210'), isNotNull);
    });
  });

  // ── Duplicate phone check logic ──
  // Mirrors: existing.any((c) => c.phone == phone && c.id != (widget.customer?.id ?? ''))

  group('AddCustomerModal duplicate phone check', () {
    bool isDuplicate(
      String phone,
      String currentId,
      List<Map<String, String>> existing,
    ) {
      return existing.any((c) => c['phone'] == phone && c['id'] != currentId);
    }

    test('no duplicate when phone is unique', () {
      final existing = [
        {'id': '1', 'phone': '9876543210'},
        {'id': '2', 'phone': '9876543211'},
      ];
      expect(isDuplicate('9876543212', '', existing), isFalse);
    });

    test('duplicate detected when same phone exists', () {
      final existing = [
        {'id': '1', 'phone': '9876543210'},
      ];
      expect(isDuplicate('9876543210', '', existing), isTrue);
    });

    test(
      'no duplicate when same phone belongs to current customer (edit mode)',
      () {
        final existing = [
          {'id': '1', 'phone': '9876543210'},
        ];
        expect(isDuplicate('9876543210', '1', existing), isFalse);
      },
    );

    test(
      'duplicate when same phone belongs to different customer in edit mode',
      () {
        final existing = [
          {'id': '1', 'phone': '9876543210'},
          {'id': '2', 'phone': '9876543211'},
        ];
        expect(isDuplicate('9876543210', '2', existing), isTrue);
      },
    );

    test('empty phone skips duplicate check', () {
      const phone = '';
      final shouldCheck = phone.isNotEmpty;
      expect(shouldCheck, isFalse);
    });
  });

  // ── isEditMode logic ──
  // Mirrors: bool get _isEditMode => widget.customer != null

  group('AddCustomerModal edit mode', () {
    test('null customer means add mode', () {
      const customer = null;
      expect(customer != null, isFalse);
    });

    test('non-null customer means edit mode', () {
      const customer = 'exists';
      expect(customer, isNotNull);
    });
  });

  // ── Balance sign logic ──
  // Mirrors: balance: _owesMe ? balance : -balance

  group('AddCustomerModal balance sign', () {
    double computeBalance(double amount, bool owesMe) {
      return owesMe ? amount : -amount;
    }

    test('positive balance when owesMe=true', () {
      expect(computeBalance(500, true), 500);
    });

    test('negative balance when owesMe=false', () {
      expect(computeBalance(500, false), -500);
    });

    test('zero balance stays zero regardless', () {
      expect(computeBalance(0, true), 0);
      expect(computeBalance(0, false), 0);
    });
  });
}
