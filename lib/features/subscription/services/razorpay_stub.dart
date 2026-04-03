/// Stub for non-web platforms. Never called — guarded by kIsWeb check.
library;

void openRazorpayWeb({
  required Map<String, dynamic> options,
  required void Function(
    String paymentId,
    String subscriptionId,
    String signature,
  )
  onSuccess,
  required void Function(int code, String description) onError,
  required void Function() onDismiss,
}) {
  throw UnsupportedError('Razorpay web checkout is only available on web');
}
