/// Razorpay Checkout.js interop for Flutter web.
///
/// Uses dart:js_interop to call Razorpay's JavaScript SDK directly,
/// since razorpay_flutter only supports Android/iOS.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('Razorpay')
extension type _RazorpayJS._(JSObject _) implements JSObject {
  external _RazorpayJS(JSObject options);
  external void open();
}

/// Opens Razorpay Checkout on web using Checkout.js.
///
/// [options] must include 'key', 'subscription_id', 'name', etc.
/// [onSuccess] called with paymentId, subscriptionId, signature.
/// [onError] called with error code and description.
/// [onDismiss] called when user closes the modal without paying.
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
  final jsOptions = _jsifyMap(options);

  // Set handler callback (Razorpay success)
  jsOptions['handler'] = ((JSObject response) {
    final paymentId = (response['razorpay_payment_id'] as JSString).toDart;
    final subId = (response['razorpay_subscription_id'] as JSString).toDart;
    final signature = (response['razorpay_signature'] as JSString).toDart;
    onSuccess(paymentId, subId, signature);
  }).toJS;

  // Set modal.ondismiss callback
  final modal = jsOptions['modal'] as JSObject? ?? JSObject();
  modal['ondismiss'] = (() {
    onDismiss();
  }).toJS;
  jsOptions['modal'] = modal;

  final rzp = _RazorpayJS(jsOptions);
  rzp.open();
}

/// Recursively convert a Dart Map to a JSObject.
JSObject _jsifyMap(Map<String, dynamic> map) {
  final obj = JSObject();
  for (final entry in map.entries) {
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      obj[entry.key] = _jsifyMap(value);
    } else if (value is String) {
      obj[entry.key] = value.toJS;
    } else if (value is int) {
      obj[entry.key] = value.toJS;
    } else if (value is double) {
      obj[entry.key] = value.toJS;
    } else if (value is bool) {
      obj[entry.key] = value.toJS;
    } else if (value is JSAny) {
      obj[entry.key] = value;
    }
  }
  return obj;
}
