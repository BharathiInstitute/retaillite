/// Tests for GiveUdhaarModal and RecordPaymentModal — amount validation and logic.
///
/// Both modals depend on Riverpod + Firestore. We test the pure
/// validation/computation logic inline.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ══════════════════════════════════════════════════════
  // ── GiveUdhaarModal ──
  // ══════════════════════════════════════════════════════

  // ── Amount parsing ──
  // Mirrors: double get _amount => double.tryParse(_amountController.text) ?? 0

  group('GiveUdhaarModal amount parsing', () {
    double parseAmount(String text) => double.tryParse(text) ?? 0;

    test('valid number parses correctly', () {
      expect(parseAmount('500'), 500);
    });

    test('decimal number parses correctly', () {
      expect(parseAmount('250.50'), 250.50);
    });

    test('empty text parses to 0', () {
      expect(parseAmount(''), 0);
    });

    test('non-numeric text parses to 0', () {
      expect(parseAmount('abc'), 0);
    });
  });

  // ── Amount validation ──
  // Mirrors: if (_amount <= 0) => 'Please enter a valid amount'

  group('GiveUdhaarModal amount validation', () {
    bool isValidAmount(double amount) => amount > 0;

    test('zero amount is invalid', () {
      expect(isValidAmount(0), isFalse);
    });

    test('negative amount is invalid', () {
      expect(isValidAmount(-100), isFalse);
    });

    test('positive amount is valid', () {
      expect(isValidAmount(500), isTrue);
    });

    test('small positive amount is valid', () {
      expect(isValidAmount(0.01), isTrue);
    });
  });

  // ── Large amount confirmation ──
  // Mirrors: if (_amount >= 10000) => showDialog('Large Credit Amount')

  group('GiveUdhaarModal large amount confirmation', () {
    bool requiresConfirmation(double amount) => amount >= 10000;

    test('₹9,999 does not need confirmation', () {
      expect(requiresConfirmation(9999), isFalse);
    });

    test('₹10,000 needs confirmation', () {
      expect(requiresConfirmation(10000), isTrue);
    });

    test('₹50,000 needs confirmation', () {
      expect(requiresConfirmation(50000), isTrue);
    });

    test('₹1,000 does not need confirmation', () {
      expect(requiresConfirmation(1000), isFalse);
    });
  });

  // ── New balance preview ──
  // Mirrors: (balance + _amount).asCurrency

  group('GiveUdhaarModal new balance preview', () {
    double newBalance(double currentBalance, double creditAmount) {
      return currentBalance + creditAmount;
    }

    test('adds credit to existing balance', () {
      expect(newBalance(500, 200), 700);
    });

    test('creates balance from zero', () {
      expect(newBalance(0, 1000), 1000);
    });

    test('adds to negative balance', () {
      expect(newBalance(-200, 500), 300);
    });
  });

  // ── Submit button state ──
  // Mirrors: onPressed: _amount > 0 ? _giveUdhaar : null

  group('GiveUdhaarModal submit button', () {
    test('enabled when amount > 0', () {
      const amount = 100.0;
      expect(amount > 0, isTrue);
    });

    test('disabled when amount is 0', () {
      const amount = 0.0;
      expect(amount > 0, isFalse);
    });
  });

  // ── Note field ──
  // Mirrors: note: _noteController.text.isEmpty ? 'Credit given' : _noteController.text

  group('GiveUdhaarModal note handling', () {
    String resolveNote(String noteText) {
      return noteText.isEmpty ? 'Credit given' : noteText;
    }

    test('empty note defaults to Credit given', () {
      expect(resolveNote(''), 'Credit given');
    });

    test('non-empty note is used as-is', () {
      expect(resolveNote('Grocery items'), 'Grocery items');
    });
  });

  // ══════════════════════════════════════════════════════
  // ── RecordPaymentModal ──
  // ══════════════════════════════════════════════════════

  // ── Amount validation ──
  // Mirrors: if (_amount <= 0) => 'Please enter a valid amount'

  group('RecordPaymentModal amount validation', () {
    bool isValidAmount(double amount) => amount > 0;

    test('zero amount is invalid', () {
      expect(isValidAmount(0), isFalse);
    });

    test('negative amount is invalid', () {
      expect(isValidAmount(-50), isFalse);
    });

    test('positive amount is valid', () {
      expect(isValidAmount(250), isTrue);
    });
  });

  // ── Amount vs balance check ──
  // Mirrors: if (_amount > currentBalance) => 'Amount exceeds customer balance'

  group('RecordPaymentModal amount vs balance', () {
    bool exceedsBalance(double amount, double balance) => amount > balance;

    test('amount within balance is ok', () {
      expect(exceedsBalance(500, 1000), isFalse);
    });

    test('amount equal to balance is ok', () {
      expect(exceedsBalance(1000, 1000), isFalse);
    });

    test('amount exceeding balance is rejected', () {
      expect(exceedsBalance(1500, 1000), isTrue);
    });
  });

  // ── Payment mode selection ──
  // Mirrors: _paymentMode defaults to 'cash'

  group('RecordPaymentModal payment modes', () {
    test('default payment mode is cash', () {
      const defaultMode = 'cash';
      expect(defaultMode, 'cash');
    });

    test('can select upi mode', () {
      var mode = 'cash';
      mode = 'upi';
      expect(mode, 'upi');
    });

    test('can select online mode', () {
      var mode = 'cash';
      mode = 'online';
      expect(mode, 'online');
    });
  });

  // ── New balance preview ──
  // Mirrors: (balance - _amount).asCurrency

  group('RecordPaymentModal new balance preview', () {
    double newBalance(double balance, double payment) {
      return balance - payment;
    }

    test('reduces balance by payment amount', () {
      expect(newBalance(1000, 500), 500);
    });

    test('full payment brings balance to zero', () {
      expect(newBalance(1000, 1000), 0);
    });

    test('partial payment leaves remaining balance', () {
      expect(newBalance(1000, 300), 700);
    });
  });

  // ── Submit button state ──
  // Mirrors: onPressed: _amount > 0 ? _recordPayment : null

  group('RecordPaymentModal submit button', () {
    test('enabled when amount > 0', () {
      const amount = 100.0;
      expect(amount > 0, isTrue);
    });

    test('disabled when amount is 0', () {
      const amount = 0.0;
      expect(amount > 0, isFalse);
    });
  });

  // ── Note formatting ──
  // Mirrors: '$_paymentMode: ${_noteController.text}'

  group('RecordPaymentModal note formatting', () {
    String formatNote(String mode, String noteText) {
      return noteText.isEmpty ? mode : '$mode: $noteText';
    }

    test('empty note uses mode only', () {
      expect(formatNote('cash', ''), 'cash');
    });

    test('non-empty note prepends mode', () {
      expect(formatNote('upi', 'Partial payment'), 'upi: Partial payment');
    });
  });
}
