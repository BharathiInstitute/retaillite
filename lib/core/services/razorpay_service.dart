/// Razorpay payment service for handling online payments
library;

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:retaillite/core/config/razorpay_config.dart';

/// Result of a payment attempt
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorCode;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.errorMessage,
  });

  factory PaymentResult.success({
    required String paymentId,
    String? orderId,
    String? signature,
  }) {
    return PaymentResult(
      success: true,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  factory PaymentResult.failure({
    required String errorCode,
    required String errorMessage,
  }) {
    return PaymentResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  factory PaymentResult.cancelled() {
    return const PaymentResult(
      success: false,
      errorCode: 'CANCELLED',
      errorMessage: 'Payment was cancelled by user',
    );
  }
}

/// Service for handling Razorpay payments
class RazorpayService {
  static RazorpayService? _instance;
  Razorpay? _razorpay;

  // Callback for payment result
  void Function(PaymentResult)? _onPaymentComplete;

  RazorpayService._();

  static RazorpayService get instance {
    _instance ??= RazorpayService._();
    return _instance!;
  }

  /// Initialize Razorpay instance
  void _ensureInitialized() {
    if (_razorpay == null) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  /// Open Razorpay checkout for payment
  ///
  /// [amount] - Amount in rupees (will be converted to paise)
  /// [customerName] - Name of the customer
  /// [customerPhone] - Phone number (optional)
  /// [customerEmail] - Email (optional)
  /// [description] - Payment description
  /// [onComplete] - Callback when payment completes (success or failure)
  void openCheckout({
    required double amount,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? description,
    String? orderId,
    required void Function(PaymentResult) onComplete,
  }) {
    _ensureInitialized();
    _onPaymentComplete = onComplete;

    // Convert amount to paise (Razorpay expects amount in smallest currency unit)
    final amountInPaise = (amount * 100).round();

    final options = {
      'key': RazorpayConfig.keyId,
      'amount': amountInPaise,
      'name': RazorpayConfig.appName,
      'description': description ?? RazorpayConfig.description,
      'prefill': {
        'contact': customerPhone ?? '',
        'email': customerEmail ?? '',
        'name': customerName,
      },
      'theme': {
        'color': '#${RazorpayConfig.themeColor.toRadixString(16).substring(2)}',
      },
      'modal': {'confirm_close': true, 'animation': true},
      // UPI Only - disable all other payment methods
      'method': {
        'upi': true,
        'card': false,
        'netbanking': false,
        'wallet': false,
        'emi': false,
        'paylater': false,
      },
    };

    // Add order_id if provided (for server-side order creation)
    if (orderId != null) {
      options['order_id'] = orderId;
    }

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      _onPaymentComplete?.call(
        PaymentResult.failure(
          errorCode: 'OPEN_ERROR',
          errorMessage: 'Failed to open payment gateway: $e',
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _onPaymentComplete?.call(
      PaymentResult.success(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId,
        signature: response.signature,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    // Check if user cancelled
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      _onPaymentComplete?.call(PaymentResult.cancelled());
    } else {
      _onPaymentComplete?.call(
        PaymentResult.failure(
          errorCode: response.code?.toString() ?? 'UNKNOWN',
          errorMessage: response.message ?? 'Payment failed',
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    // External wallet selected, payment will continue
  }

  /// Clean up resources
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _instance = null;
  }
}

/// Extension to show payment dialog with Razorpay
extension RazorpayPaymentExtension on BuildContext {
  /// Show Razorpay payment checkout
  Future<PaymentResult> collectPayment({
    required double amount,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? description,
  }) async {
    final completer = _PaymentCompleter();

    RazorpayService.instance.openCheckout(
      amount: amount,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      description: description,
      onComplete: completer.complete,
    );

    return completer.future;
  }
}

/// Helper class to convert callback to Future
class _PaymentCompleter {
  PaymentResult? _result;
  void Function(PaymentResult)? _completeCallback;

  Future<PaymentResult> get future async {
    if (_result != null) return _result!;

    // Wait for callback
    while (_result == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return _result!;
  }

  void complete(PaymentResult result) {
    _result = result;
    _completeCallback?.call(result);
  }
}
