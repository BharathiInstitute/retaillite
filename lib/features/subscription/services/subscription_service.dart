/// Service for managing subscription purchases via Razorpay.
///
/// Handles the full flow:
/// 1. Create a Razorpay subscription (server-side via Cloud Function)
/// 2. Open Razorpay checkout (client-side)
/// 3. Activate the subscription (server-side verification + Firestore update)
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:retaillite/core/config/razorpay_config.dart';
import 'package:retaillite/features/subscription/services/razorpay_stub.dart'
    if (dart.library.js_interop) 'package:retaillite/features/subscription/services/razorpay_web.dart';

class SubscriptionService {
  static SubscriptionService? _instance;
  Razorpay? _razorpay;

  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  SubscriptionService._();

  static SubscriptionService get instance {
    _instance ??= SubscriptionService._();
    return _instance!;
  }

  /// Purchase a subscription plan.
  ///
  /// [plan] - "pro" or "business"
  /// [cycle] - "monthly" or "annual"
  /// [customerEmail] - User's email for Razorpay prefill
  /// [customerPhone] - User's phone for Razorpay prefill
  /// [customerName] - User's name for Razorpay prefill
  /// [onResult] - Callback with the result
  Future<void> purchaseSubscription({
    required String plan,
    required String cycle,
    String? customerEmail,
    String? customerPhone,
    String? customerName,
    required void Function(SubscriptionResult) onResult,
  }) async {
    try {
      // Step 1: Create subscription on Razorpay via Cloud Function
      final createResult = await _functions
          .httpsCallable('createSubscription')
          .call({
            'plan': plan,
            'cycle': cycle,
            'customerEmail': customerEmail ?? '',
            'customerPhone': customerPhone ?? '',
            'customerName': customerName ?? '',
          });

      final data = createResult.data as Map<String, dynamic>;
      if (data['success'] != true) {
        onResult(
          SubscriptionResult.failure(
            error:
                (data['error'] as String?) ?? 'Failed to create subscription',
          ),
        );
        return;
      }

      final subscriptionId = data['subscriptionId'] as String;

      // Step 2: Open Razorpay checkout with subscription_id
      _openSubscriptionCheckout(
        subscriptionId: subscriptionId,
        plan: plan,
        cycle: cycle,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        customerName: customerName,
        onResult: onResult,
      );
    } on FirebaseFunctionsException catch (e) {
      onResult(
        SubscriptionResult.failure(
          error: e.message ?? 'Failed to create subscription',
        ),
      );
    } catch (e) {
      onResult(SubscriptionResult.failure(error: e.toString()));
    }
  }

  void _openSubscriptionCheckout({
    required String subscriptionId,
    required String plan,
    required String cycle,
    String? customerEmail,
    String? customerPhone,
    String? customerName,
    required void Function(SubscriptionResult) onResult,
  }) {
    if (kIsWeb) {
      _openWebCheckout(
        subscriptionId: subscriptionId,
        plan: plan,
        cycle: cycle,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        customerName: customerName,
        onResult: onResult,
      );
      return;
    }

    _razorpay?.clear();
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) {
      _handlePaymentSuccess(
        response: response,
        subscriptionId: subscriptionId,
        plan: plan,
        cycle: cycle,
        onResult: onResult,
      );
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        onResult(SubscriptionResult.cancelled());
      } else {
        onResult(
          SubscriptionResult.failure(
            error: response.message ?? 'Payment failed',
          ),
        );
      }
    });

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (
      ExternalWalletResponse response,
    ) {
      debugPrint('External wallet selected: ${response.walletName}');
      onResult(
        SubscriptionResult.failure(
          error: 'External wallets are not supported. Please use UPI or card.',
        ),
      );
    });

    final options = {
      'key': RazorpayConfig.keyId,
      'subscription_id': subscriptionId,
      'name': RazorpayConfig.appName,
      'description':
          '${plan == 'pro' ? 'Pro' : 'Business'} Plan (${cycle == 'annual' ? 'Annual' : 'Monthly'})',
      'prefill': {
        'email': customerEmail ?? '',
        'contact': customerPhone ?? '',
        'name': customerName ?? '',
      },
      'theme': {
        'color': '#${RazorpayConfig.themeColor.toRadixString(16).substring(2)}',
      },
      'modal': {'confirm_close': true},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay subscription checkout: $e');
      onResult(
        SubscriptionResult.failure(error: 'Failed to open payment gateway'),
      );
    }
  }

  Future<void> _handlePaymentSuccess({
    required PaymentSuccessResponse response,
    required String subscriptionId,
    required String plan,
    required String cycle,
    required void Function(SubscriptionResult) onResult,
  }) async {
    try {
      // Step 3: Activate subscription via Cloud Function (server verifies payment)
      final activateResult = await _functions
          .httpsCallable('activateSubscription')
          .call({
            'plan': plan,
            'cycle': cycle,
            'razorpayPaymentId': response.paymentId,
            'razorpaySubscriptionId': subscriptionId,
            'razorpaySignature': response.signature,
          });

      final data = activateResult.data as Map<String, dynamic>;
      if (data['success'] == true) {
        onResult(
          SubscriptionResult.success(
            plan: plan,
            cycle: cycle,
            expiresAt: data['expiresAt'] as String?,
          ),
        );
      } else {
        onResult(
          SubscriptionResult.failure(
            error:
                'Payment succeeded but activation failed. Please contact support.',
          ),
        );
      }
    } catch (e) {
      // Payment was captured but activation failed — critical state
      debugPrint('Subscription activation error: $e');
      onResult(
        SubscriptionResult.failure(
          error:
              'Payment received. Activation in progress — this may take a moment. '
              'If your plan doesn\'t update within 5 minutes, please contact support.',
        ),
      );
    }
  }

  /// Web-specific checkout using Razorpay Checkout.js via JS interop.
  void _openWebCheckout({
    required String subscriptionId,
    required String plan,
    required String cycle,
    String? customerEmail,
    String? customerPhone,
    String? customerName,
    required void Function(SubscriptionResult) onResult,
  }) {
    final options = <String, dynamic>{
      'key': RazorpayConfig.keyId,
      'subscription_id': subscriptionId,
      'name': RazorpayConfig.appName,
      'description':
          '${plan == 'pro' ? 'Pro' : 'Business'} Plan (${cycle == 'annual' ? 'Annual' : 'Monthly'})',
      'prefill': <String, dynamic>{
        'email': customerEmail ?? '',
        'contact': customerPhone ?? '',
        'name': customerName ?? '',
      },
      'theme': <String, dynamic>{
        'color': '#${RazorpayConfig.themeColor.toRadixString(16).substring(2)}',
      },
      'modal': <String, dynamic>{'confirm_close': true},
    };

    try {
      openRazorpayWeb(
        options: options,
        onSuccess: (paymentId, subId, signature) {
          _activateWebSubscription(
            plan: plan,
            cycle: cycle,
            paymentId: paymentId,
            subscriptionId: subscriptionId,
            signature: signature,
            onResult: onResult,
          );
        },
        onError: (code, description) {
          if (code == 2) {
            // User cancelled
            onResult(SubscriptionResult.cancelled());
          } else {
            onResult(SubscriptionResult.failure(error: description));
          }
        },
        onDismiss: () {
          onResult(SubscriptionResult.cancelled());
        },
      );
    } catch (e) {
      debugPrint('Error opening Razorpay web checkout: $e');
      onResult(
        SubscriptionResult.failure(error: 'Failed to open payment gateway'),
      );
    }
  }

  Future<void> _activateWebSubscription({
    required String plan,
    required String cycle,
    required String paymentId,
    required String subscriptionId,
    required String signature,
    required void Function(SubscriptionResult) onResult,
  }) async {
    try {
      final activateResult = await _functions
          .httpsCallable('activateSubscription')
          .call({
            'plan': plan,
            'cycle': cycle,
            'razorpayPaymentId': paymentId,
            'razorpaySubscriptionId': subscriptionId,
            'razorpaySignature': signature,
          });

      final data = activateResult.data as Map<String, dynamic>;
      if (data['success'] == true) {
        onResult(
          SubscriptionResult.success(
            plan: plan,
            cycle: cycle,
            expiresAt: data['expiresAt'] as String?,
          ),
        );
      } else {
        onResult(
          SubscriptionResult.failure(
            error:
                'Payment succeeded but activation failed. Please contact support.',
          ),
        );
      }
    } catch (e) {
      debugPrint('Web subscription activation error: $e');
      onResult(
        SubscriptionResult.failure(
          error:
              'Payment received. Activation in progress — this may take a moment. '
              'If your plan doesn\'t update within 5 minutes, please contact support.',
        ),
      );
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}

/// Result of a subscription purchase attempt.
class SubscriptionResult {
  final SubscriptionResultStatus status;
  final String? plan;
  final String? cycle;
  final String? expiresAt;
  final String? error;

  const SubscriptionResult._({
    required this.status,
    this.plan,
    this.cycle,
    this.expiresAt,
    this.error,
  });

  factory SubscriptionResult.success({
    required String plan,
    required String cycle,
    String? expiresAt,
  }) {
    return SubscriptionResult._(
      status: SubscriptionResultStatus.success,
      plan: plan,
      cycle: cycle,
      expiresAt: expiresAt,
    );
  }

  factory SubscriptionResult.failure({required String error}) {
    return SubscriptionResult._(
      status: SubscriptionResultStatus.failure,
      error: error,
    );
  }

  factory SubscriptionResult.cancelled() {
    return const SubscriptionResult._(
      status: SubscriptionResultStatus.cancelled,
    );
  }

  bool get isSuccess => status == SubscriptionResultStatus.success;
  bool get isCancelled => status == SubscriptionResultStatus.cancelled;
}

enum SubscriptionResultStatus { success, failure, cancelled }
