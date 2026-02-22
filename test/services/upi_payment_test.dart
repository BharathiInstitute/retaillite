/// Tests for PaymentLinkService UPI utility functions
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/payment_link_service.dart';

void main() {
  // ───────────────────────────────────────────────
  // isValidUpiId
  // ───────────────────────────────────────────────
  group('PaymentLinkService.isValidUpiId', () {
    test('should accept valid UPI IDs', () {
      expect(PaymentLinkService.isValidUpiId('shop@ybl'), isTrue);
      expect(PaymentLinkService.isValidUpiId('mystore@oksbi'), isTrue);
      expect(PaymentLinkService.isValidUpiId('tulasi.stores@axl'), isTrue);
      expect(PaymentLinkService.isValidUpiId('user-123@paytm'), isTrue);
      expect(PaymentLinkService.isValidUpiId('a@b'), isTrue);
    });

    test('should reject empty string', () {
      expect(PaymentLinkService.isValidUpiId(''), isFalse);
    });

    test('should reject ID without @', () {
      expect(PaymentLinkService.isValidUpiId('noprovider'), isFalse);
    });

    test('should reject ID with spaces', () {
      expect(PaymentLinkService.isValidUpiId('shop @ybl'), isFalse);
    });

    test('should reject ID with special characters in handle', () {
      expect(PaymentLinkService.isValidUpiId('shop!name@ybl'), isFalse);
      expect(PaymentLinkService.isValidUpiId('shop#name@ybl'), isFalse);
    });

    test('should reject ID with multiple @', () {
      expect(PaymentLinkService.isValidUpiId('shop@name@ybl'), isFalse);
    });

    test('should reject ID with @ at start or end', () {
      expect(PaymentLinkService.isValidUpiId('@ybl'), isFalse);
      expect(PaymentLinkService.isValidUpiId('shop@'), isFalse);
    });
  });

  // ───────────────────────────────────────────────
  // generateUpiDeepLink
  // ───────────────────────────────────────────────
  group('PaymentLinkService.generateUpiDeepLink', () {
    test('should generate valid UPI deep link with amount', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 500,
      );
      expect(link, startsWith('upi://pay?'));
      expect(link, contains('pa=shop%40ybl'));
      expect(link, contains('am=500.00'));
      expect(link, contains('cu=INR'));
    });

    test('should include payee name when provided', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 100,
        payeeName: 'Tulasi Stores',
      );
      expect(link, contains('pn=Tulasi%20Stores'));
    });

    test('should include transaction note when provided', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 100,
        transactionNote: 'Bill payment',
      );
      expect(link, contains('tn=Bill%20payment'));
    });

    test('should omit amount when zero', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 0,
      );
      expect(link, isNot(contains('am=')));
    });

    test('should omit payee name when empty', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 100,
        payeeName: '',
      );
      expect(link, isNot(contains('pn=')));
    });

    test('should format fractional amounts correctly', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 99.50,
      );
      expect(link, contains('am=99.50'));
    });
  });

  // ───────────────────────────────────────────────
  // generateUpiQrData
  // ───────────────────────────────────────────────
  group('PaymentLinkService.generateUpiQrData', () {
    test('should generate UPI deep link without amount', () {
      final data = PaymentLinkService.generateUpiQrData(upiId: 'shop@ybl');
      expect(data, startsWith('upi://pay?'));
      expect(data, contains('pa=shop%40ybl'));
      expect(data, isNot(contains('am=')));
    });

    test('should include payee name', () {
      final data = PaymentLinkService.generateUpiQrData(
        upiId: 'shop@ybl',
        payeeName: 'My Shop',
      );
      expect(data, contains('pn=My%20Shop'));
    });
  });

  // ───────────────────────────────────────────────
  // setUpiId / upiId getter
  // ───────────────────────────────────────────────
  group('PaymentLinkService UPI ID management', () {
    test('should set and get UPI ID', () {
      PaymentLinkService.setUpiId('test@upi');
      expect(PaymentLinkService.upiId, equals('test@upi'));
    });

    test('should allow overwriting UPI ID', () {
      PaymentLinkService.setUpiId('old@upi');
      PaymentLinkService.setUpiId('new@upi');
      expect(PaymentLinkService.upiId, equals('new@upi'));
    });

    // Clean up
    tearDown(() {
      PaymentLinkService.setUpiId('');
    });
  });
}
