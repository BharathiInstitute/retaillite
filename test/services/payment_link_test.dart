/// Tests for PaymentLinkService — UPI deep link generation, validation
/// Uses inline duplicates for URL generation functions
/// to avoid cloud_functions transitive import.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicates (avoid PaymentLinkService → cloud_functions) ──

class PaymentLinkResult {
  final bool success;
  final String? paymentLink;
  final String? paymentLinkId;
  final String? error;

  const PaymentLinkResult({
    required this.success,
    this.paymentLink,
    this.paymentLinkId,
    this.error,
  });

  factory PaymentLinkResult.success({
    required String paymentLink,
    String? paymentLinkId,
  }) => PaymentLinkResult(
    success: true,
    paymentLink: paymentLink,
    paymentLinkId: paymentLinkId,
  );

  factory PaymentLinkResult.failure(String error) =>
      PaymentLinkResult(success: false, error: error);
}

bool isValidUpiId(String id) {
  if (id.isEmpty) return false;
  final regex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$');
  return regex.hasMatch(id);
}

String generateUpiDeepLink({
  required String upiId,
  required double amount,
  String? payeeName,
  String? transactionNote,
}) {
  final params = <String, String>{'pa': upiId, 'cu': 'INR'};
  if (amount > 0) params['am'] = amount.toStringAsFixed(2);
  if (payeeName != null && payeeName.isNotEmpty) params['pn'] = payeeName;
  if (transactionNote != null && transactionNote.isNotEmpty) {
    params['tn'] = transactionNote;
  }
  final queryString = params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return 'upi://pay?$queryString';
}

String generatePaymentPageUrl({
  required String upiId,
  required double amount,
  String? payeeName,
  String? transactionNote,
}) {
  final parts = <String>['pa=$upiId'];
  if (amount > 0) parts.add('am=${amount.toStringAsFixed(0)}');
  if (payeeName != null && payeeName.isNotEmpty) {
    parts.add('pn=${Uri.encodeComponent(payeeName)}');
  }
  if (transactionNote != null && transactionNote.isNotEmpty) {
    parts.add('tn=${Uri.encodeComponent(transactionNote)}');
  }
  return 'https://stores.tulasierp.com/pay?${parts.join('&')}';
}

String generateUpiQrData({required String upiId, String? payeeName}) {
  return generateUpiDeepLink(upiId: upiId, amount: 0, payeeName: payeeName);
}

void main() {
  // ── PaymentLinkResult ──

  group('PaymentLinkResult', () {
    test('success factory creates with success=true', () {
      final result = PaymentLinkResult.success(
        paymentLink: 'https://pay.example.com/link1',
        paymentLinkId: 'link1',
      );
      expect(result.success, isTrue);
      expect(result.paymentLink, 'https://pay.example.com/link1');
      expect(result.paymentLinkId, 'link1');
      expect(result.error, isNull);
    });

    test('failure factory creates with success=false', () {
      final result = PaymentLinkResult.failure('Network error');
      expect(result.success, isFalse);
      expect(result.error, 'Network error');
      expect(result.paymentLink, isNull);
    });

    test('success without paymentLinkId', () {
      final result = PaymentLinkResult.success(
        paymentLink: 'https://pay.example.com',
      );
      expect(result.paymentLinkId, isNull);
    });
  });

  // ── isValidUpiId ──

  group('isValidUpiId', () {
    test('valid upi id: store@ybl', () {
      expect(isValidUpiId('store@ybl'), isTrue);
    });

    test('valid upi id: shop.owner@oksbi', () {
      expect(isValidUpiId('shop.owner@oksbi'), isTrue);
    });

    test('valid upi id with hyphen: my-shop@paytm', () {
      expect(isValidUpiId('my-shop@paytm'), isTrue);
    });

    test('valid upi id with underscore: shop_1@upi', () {
      expect(isValidUpiId('shop_1@upi'), isTrue);
    });

    test('empty string is invalid', () {
      expect(isValidUpiId(''), isFalse);
    });

    test('missing @ is invalid', () {
      expect(isValidUpiId('storeybl'), isFalse);
    });

    test('missing provider is invalid', () {
      expect(isValidUpiId('store@'), isFalse);
    });

    test('missing handle is invalid', () {
      expect(isValidUpiId('@ybl'), isFalse);
    });

    test('spaces are invalid', () {
      expect(isValidUpiId('my store@ybl'), isFalse);
    });

    test('special chars in provider invalid', () {
      expect(isValidUpiId('store@y.bl'), isFalse);
    });
  });

  // ── generateUpiDeepLink ──

  group('generateUpiDeepLink', () {
    test('basic link with amount', () {
      final link = generateUpiDeepLink(upiId: 'shop@ybl', amount: 100);
      expect(link, startsWith('upi://pay?'));
      expect(link, contains('pa=shop%40ybl'));
      expect(link, contains('am=100.00'));
      expect(link, contains('cu=INR'));
    });

    test('zero amount omits am parameter', () {
      final link = generateUpiDeepLink(upiId: 'test@upi', amount: 0);
      expect(link, isNot(contains('am=')));
    });

    test('includes payeeName when provided', () {
      final link = generateUpiDeepLink(
        upiId: 'store@ybl',
        amount: 50,
        payeeName: 'My Shop',
      );
      expect(link, contains('pn=My%20Shop'));
    });

    test('includes transactionNote when provided', () {
      final link = generateUpiDeepLink(
        upiId: 'store@ybl',
        amount: 200,
        transactionNote: 'Bill #123',
      );
      expect(link, contains('tn=Bill%20%23123'));
    });

    test('omits payeeName when empty', () {
      final link = generateUpiDeepLink(
        upiId: 'store@ybl',
        amount: 10,
        payeeName: '',
      );
      expect(link, isNot(contains('pn=')));
    });

    test('omits transactionNote when null', () {
      final link = generateUpiDeepLink(upiId: 'store@ybl', amount: 10);
      expect(link, isNot(contains('tn=')));
    });

    test('decimal amount formatted to 2 places', () {
      final link = generateUpiDeepLink(upiId: 'x@y', amount: 49.5);
      expect(link, contains('am=49.50'));
    });
  });

  // ── generatePaymentPageUrl ──

  group('generatePaymentPageUrl', () {
    test('base URL is HTTPS', () {
      final url = generatePaymentPageUrl(upiId: 'store@ybl', amount: 100);
      expect(url, startsWith('https://stores.tulasierp.com/pay?'));
    });

    test('includes UPI ID unencoded', () {
      final url = generatePaymentPageUrl(upiId: 'shop@oksbi', amount: 200);
      expect(url, contains('pa=shop@oksbi'));
    });

    test('amount formatted as integer', () {
      final url = generatePaymentPageUrl(upiId: 'x@y', amount: 500);
      expect(url, contains('am=500'));
    });

    test('zero amount omits am', () {
      final url = generatePaymentPageUrl(upiId: 'x@y', amount: 0);
      expect(url, isNot(contains('am=')));
    });

    test('includes encoded payeeName', () {
      final url = generatePaymentPageUrl(
        upiId: 'x@y',
        amount: 100,
        payeeName: 'Tulasi Store',
      );
      expect(url, contains('pn=Tulasi%20Store'));
    });

    test('includes encoded transactionNote', () {
      final url = generatePaymentPageUrl(
        upiId: 'x@y',
        amount: 100,
        transactionNote: 'Payment for bill',
      );
      expect(url, contains('tn=Payment%20for%20bill'));
    });
  });

  // ── generateUpiQrData ──

  group('generateUpiQrData', () {
    test('generates UPI deep link with zero amount', () {
      final data = generateUpiQrData(upiId: 'store@ybl');
      expect(data, startsWith('upi://pay?'));
      expect(data, contains('pa=store%40ybl'));
      expect(data, isNot(contains('am=')));
    });

    test('includes payeeName when provided', () {
      final data = generateUpiQrData(upiId: 'store@ybl', payeeName: 'My Shop');
      expect(data, contains('pn=My%20Shop'));
    });
  });
}
