import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/payment_link_service.dart';

void main() {
  // ── UPI ID Validation ──

  group('PaymentLinkService.isValidUpiId', () {
    test('valid UPI ID with @ybl', () {
      expect(PaymentLinkService.isValidUpiId('shop@ybl'), isTrue);
    });

    test('valid UPI ID with @oksbi', () {
      expect(PaymentLinkService.isValidUpiId('mystore@oksbi'), isTrue);
    });

    test('valid UPI ID with @paytm', () {
      expect(PaymentLinkService.isValidUpiId('user@paytm'), isTrue);
    });

    test('valid UPI ID with dots', () {
      expect(PaymentLinkService.isValidUpiId('my.shop@upi'), isTrue);
    });

    test('invalid - missing @', () {
      expect(PaymentLinkService.isValidUpiId('shopnameonly'), isFalse);
    });

    test('invalid - empty string', () {
      expect(PaymentLinkService.isValidUpiId(''), isFalse);
    });

    test('invalid - only @', () {
      expect(PaymentLinkService.isValidUpiId('@'), isFalse);
    });

    test('invalid - no handle after @', () {
      expect(PaymentLinkService.isValidUpiId('shop@'), isFalse);
    });

    test('invalid - no name before @', () {
      expect(PaymentLinkService.isValidUpiId('@ybl'), isFalse);
    });
  });

  // ── UPI Deep Link Generation ──

  group('PaymentLinkService.generateUpiDeepLink', () {
    test('generates valid upi:// URL', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 500,
      );
      expect(link, startsWith('upi://pay?'));
      expect(link, contains('pa=shop%40ybl'));
      expect(link, contains('am=500.00'));
    });

    test('includes payee name when provided', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 100,
        payeeName: 'Tulasi Stores',
      );
      expect(link, contains('pn='));
    });

    test('includes transaction note when provided', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 100,
        transactionNote: 'Bill payment',
      );
      expect(link, contains('tn='));
    });

    test('handles decimal amount', () {
      final link = PaymentLinkService.generateUpiDeepLink(
        upiId: 'shop@ybl',
        amount: 99.50,
      );
      expect(link, contains('am=99.50'));
    });
  });

  // ── Payment Page URL ──

  group('PaymentLinkService.generatePaymentPageUrl', () {
    test('generates HTTPS URL', () {
      final url = PaymentLinkService.generatePaymentPageUrl(
        upiId: 'shop@ybl',
        amount: 500,
      );
      expect(url, startsWith('https://'));
    });

    test('includes UPI ID and amount', () {
      final url = PaymentLinkService.generatePaymentPageUrl(
        upiId: 'shop@ybl',
        amount: 1000,
      );
      expect(url, contains('shop@ybl'));
      expect(url, contains('1000'));
    });
  });

  // ── QR Data ──

  group('PaymentLinkService.generateUpiQrData', () {
    test('generates upi:// format', () {
      final data = PaymentLinkService.generateUpiQrData(upiId: 'shop@ybl');
      expect(data, startsWith('upi://pay?'));
      expect(data, contains('pa=shop%40ybl'));
    });

    test('includes payee name', () {
      final data = PaymentLinkService.generateUpiQrData(
        upiId: 'shop@ybl',
        payeeName: 'My Shop',
      );
      expect(data, contains('pn='));
    });
  });

  // ── PaymentLinkResult ──

  group('PaymentLinkResult', () {
    test('success factory creates successful result', () {
      final result = PaymentLinkResult.success(
        paymentLink: 'https://example.com/pay',
        paymentLinkId: 'link_123',
      );
      expect(result.success, isTrue);
      expect(result.paymentLink, 'https://example.com/pay');
      expect(result.paymentLinkId, 'link_123');
      expect(result.error, isNull);
    });

    test('failure factory creates failed result', () {
      final result = PaymentLinkResult.failure('Something went wrong');
      expect(result.success, isFalse);
      expect(result.error, 'Something went wrong');
      expect(result.paymentLink, isNull);
    });

    test('constructor with required fields', () {
      const result = PaymentLinkResult(
        success: true,
        paymentLink: 'upi://pay?pa=shop@ybl',
      );
      expect(result.success, isTrue);
      expect(result.paymentLink, contains('upi://'));
    });
  });
}
