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

  // Fallback UPI ID for manual sharing
  static const String _upiId = '9666464460@ybl';
  // Future: static const String _payeeName = 'LITE Store';

  /// Create a payment link via Cloud Function (Razorpay)
  ///
  /// Returns a short URL that can be shared with customers
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
    debugPrint('========================================');

    try {
      // Call the Cloud Function to create Razorpay payment link
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

      debugPrint('>>> Cloud Function response received');
      debugPrint('>>> Response data: ${result.data}');

      final data = result.data;
      if (data['success'] == true && data['paymentLink'] != null) {
        debugPrint('>>> ✅ SUCCESS! Payment link: ${data['paymentLink']}');
        return PaymentLinkResult.success(
          paymentLink: data['paymentLink'] as String,
          paymentLinkId: data['paymentLinkId'] as String?,
        );
      } else {
        debugPrint('>>> ❌ FAILED: ${data['error']}');
        // Return failure - don't fallback silently
        return PaymentLinkResult.failure(
          data['error'] as String? ?? 'Failed to create payment link',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('>>> ❌ FirebaseFunctionsException!');
      debugPrint('>>> Code: ${e.code}');
      debugPrint('>>> Message: ${e.message}');
      debugPrint('>>> Details: ${e.details}');

      // For unauthenticated error, return failure
      if (e.code == 'unauthenticated') {
        return PaymentLinkResult.failure(
          'Please login to create payment links',
        );
      }

      // For other Firebase errors, fallback to manual UPI
      return _createManualUpiResult(amount, shopName);
    } catch (e, stackTrace) {
      debugPrint('>>> ❌ Unexpected Error: $e');
      debugPrint('>>> Stack: $stackTrace');
      // Fallback to manual UPI for network errors etc
      return _createManualUpiResult(amount, shopName);
    }
  }

  /// Create a manual UPI result as fallback
  static PaymentLinkResult _createManualUpiResult(
    double amount,
    String? shopName,
  ) {
    // Generate a message-based payment link (not a real URL)
    return PaymentLinkResult.success(
      paymentLink: 'MANUAL', // Signal to use manual UPI message
      paymentLinkId: null,
    );
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

      final whatsappUrl = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );

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

    // Check if this is a real Razorpay link
    final isRazorpayLink =
        paymentLink.startsWith('https://rzp.io') ||
        paymentLink.startsWith('https://pages.razorpay.com');

    if (isShort) {
      if (isRazorpayLink) {
        return 'Pay $amountStr to $shop: $paymentLink';
      }
      return 'Pay $amountStr to $shop. UPI: $_upiId';
    }

    final greeting = customerName != null ? 'Dear $customerName,\n\n' : '';

    if (isRazorpayLink) {
      return '''${greeting}Please pay $amountStr for your purchase at $shop.

🔗 *Click to pay securely:*
$paymentLink

Supports: UPI, Cards, Net Banking

Thank you! 🙏''';
    }

    // Fallback to manual UPI
    return '''${greeting}Please pay $amountStr for your purchase at $shop.

💳 *UPI Payment Details:*
━━━━━━━━━━━━━━━━━
📱 UPI ID: *$_upiId*
💰 Amount: *$amountStr*
━━━━━━━━━━━━━━━━━

Open GPay/PhonePe/Paytm → Send Money → Enter UPI ID above

Thank you! 🙏''';
  }
}
