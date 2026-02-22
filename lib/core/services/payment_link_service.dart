/// Payment Link Service for creating shareable payment links
///
/// Uses Firebase Cloud Functions to create Razorpay payment links
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of creating a payment link
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
  }) {
    return PaymentLinkResult(
      success: true,
      paymentLink: paymentLink,
      paymentLinkId: paymentLinkId,
    );
  }

  factory PaymentLinkResult.failure(String error) {
    return PaymentLinkResult(success: false, error: error);
  }
}

/// Service for creating and sharing payment links
class PaymentLinkService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // UPI ID loaded from Remote Config or Cloud Function — never hardcoded
  // Set via Firebase Remote Config key: 'merchant_upi_id'
  static String _upiId = '';

  /// Initialize with UPI ID from Remote Config
  static void setUpiId(String upiId) {
    _upiId = upiId;
  }

  /// Get the current UPI ID (empty if not configured)
  static String get upiId => _upiId;

  /// Validate UPI ID format (e.g. shopname@ybl, store@oksbi)
  static bool isValidUpiId(String id) {
    if (id.isEmpty) return false;
    // UPI ID format: handle@provider
    final regex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$');
    return regex.hasMatch(id);
  }

  /// Generate a free UPI deep link for payment
  ///
  /// This creates a `upi://pay?...` URL that opens the customer's UPI app
  /// directly with amount pre-filled. Zero cost — no Razorpay needed.
  static String generateUpiDeepLink({
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

  /// Generate the UPI QR code data string (same as deep link, for QR rendering)
  static String generateUpiQrData({required String upiId, String? payeeName}) {
    return generateUpiDeepLink(
      upiId: upiId,
      amount: 0, // No fixed amount — customer enters at scan time
      payeeName: payeeName,
    );
  }

  /// Launch a ₹1 test payment to verify UPI ID is working
  static Future<bool> launchTestPayment({
    required String upiId,
    String? shopName,
  }) async {
    try {
      final deepLink = generateUpiDeepLink(
        upiId: upiId,
        amount: 1,
        payeeName: shopName ?? 'Test Payment',
        transactionNote: 'UPI ID verification - Rs 1 test',
      );

      final uri = Uri.parse(deepLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error launching test payment: $e');
      return false;
    }
  }

  /// Create a payment link — uses free UPI deep link when configured,
  /// falls back to Razorpay Cloud Function otherwise.
  static Future<PaymentLinkResult> createPaymentLink({
    required double amount,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? description,
    String? billId,
    String? shopName,
  }) async {
    debugPrint('========================================');
    debugPrint('PaymentLinkService.createPaymentLink()');
    debugPrint('Amount: $amount, Customer: $customerName');
    debugPrint('UPI ID: $_upiId');
    debugPrint('========================================');

    // If UPI ID is configured, generate a free UPI deep link directly
    if (_upiId.isNotEmpty && isValidUpiId(_upiId)) {
      final deepLink = generateUpiDeepLink(
        upiId: _upiId,
        amount: amount,
        payeeName: shopName,
        transactionNote: description ?? 'Payment to ${shopName ?? "store"}',
      );
      debugPrint('>>> ✅ UPI deep link generated: $deepLink');
      return PaymentLinkResult.success(paymentLink: deepLink);
    }

    // No UPI ID — try Razorpay Cloud Function
    try {
      debugPrint('>>> Calling Cloud Function: createPaymentLink');
      final callable = _functions.httpsCallable(
        'createPaymentLink',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final params = {
        'amount': amount,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'description': description ?? 'Bill payment',
        'billId': billId,
        'shopName': shopName,
      };
      debugPrint('>>> Params: $params');

      final result = await callable.call<Map<String, dynamic>>(params);
      final data = result.data;
      if (data['success'] == true && data['paymentLink'] != null) {
        debugPrint('>>> ✅ Razorpay link: ${data['paymentLink']}');
        return PaymentLinkResult.success(
          paymentLink: data['paymentLink'] as String,
          paymentLinkId: data['paymentLinkId'] as String?,
        );
      } else {
        return PaymentLinkResult.failure(
          data['error'] as String? ?? 'Failed to create payment link',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('>>> ❌ Firebase error: ${e.code} - ${e.message}');
      if (e.code == 'unauthenticated') {
        return PaymentLinkResult.failure(
          'Please login to create payment links',
        );
      }
      return PaymentLinkResult.failure(
        'UPI ID not configured. Go to Settings → Billing to set up.',
      );
    } catch (e) {
      debugPrint('>>> ❌ Error: $e');
      return PaymentLinkResult.failure(
        'UPI ID not configured. Go to Settings → Billing to set up.',
      );
    }
  }

  /// Share payment link via WhatsApp
  static Future<bool> shareViaWhatsApp({
    required String paymentLink,
    required double amount,
    required String customerPhone,
    String? shopName,
    String? customerName,
  }) async {
    try {
      final message = _formatPaymentMessage(
        paymentLink: paymentLink,
        amount: amount,
        shopName: shopName,
        customerName: customerName,
      );

      // Clean phone number
      String phone = customerPhone.replaceAll(RegExp(r'[^\d]'), '');
      if (!phone.startsWith('91') && phone.length == 10) {
        phone = '91$phone';
      }

      // Use Uri.https for proper encoding on all platforms
      final whatsappUrl = Uri.https('wa.me', '/$phone', {'text': message});

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing via WhatsApp: $e');
      return false;
    }
  }

  /// Share payment link via SMS
  static Future<bool> shareViaSMS({
    required String paymentLink,
    required double amount,
    required String customerPhone,
    String? shopName,
  }) async {
    try {
      final message = _formatPaymentMessage(
        paymentLink: paymentLink,
        amount: amount,
        shopName: shopName,
        isShort: true,
      );

      final smsUrl = Uri.parse(
        'sms:$customerPhone?body=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing via SMS: $e');
      return false;
    }
  }

  /// Share payment link via system share sheet
  static Future<void> shareGeneric({
    required String paymentLink,
    required double amount,
    String? shopName,
    String? customerName,
  }) async {
    final message = _formatPaymentMessage(
      paymentLink: paymentLink,
      amount: amount,
      shopName: shopName,
      customerName: customerName,
    );

    await Share.share(message, subject: 'Payment Request');
  }

  /// Format payment message for sharing
  static String _formatPaymentMessage({
    required String paymentLink,
    required double amount,
    String? shopName,
    String? customerName,
    bool isShort = false,
  }) {
    final amountStr = '₹${amount.toStringAsFixed(0)}';
    final shop = shopName ?? 'Store';

    // Check if this is a Razorpay link
    final isRazorpayLink =
        paymentLink.startsWith('https://rzp.io') ||
        paymentLink.startsWith('https://pages.razorpay.com');

    if (isShort) {
      if (isRazorpayLink) {
        return 'Pay $amountStr to $shop: $paymentLink';
      }
      return 'Pay $amountStr to $shop. UPI ID: $_upiId';
    }

    final greeting = customerName != null ? 'Dear $customerName,\n\n' : '';

    if (isRazorpayLink) {
      return '''${greeting}Please pay $amountStr for your purchase at $shop.

🔗 *Click to pay securely:*
$paymentLink

Supports: UPI, Cards, Net Banking

Thank you! 🙏''';
    }

    // UPI payment message (works for both upi:// links and fallback)
    return '''${greeting}Please pay $amountStr for your purchase at $shop.

💳 *UPI Payment Details:*
━━━━━━━━━━━━━━━━━
📱 UPI ID: *$_upiId*
💰 Amount: *$amountStr*
━━━━━━━━━━━━━━━━━

👉 Open GPay/PhonePe/Paytm → Send Money → Enter UPI ID above

Thank you! 🙏''';
  }
}
