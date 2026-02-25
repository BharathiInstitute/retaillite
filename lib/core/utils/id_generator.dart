/// Safe ID generation utilities to prevent collisions across devices
library;

import 'dart:math';

final _random = Random.secure();

/// Generate a safe document ID with a random suffix to prevent
/// millisecond-level collisions across multiple devices.
///
/// Format: `{prefix}_{timestamp}_{random4}`
/// Example: `bill_1708904523456_a3f2`
String generateSafeId(String prefix) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final suffix = _random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
  return '${prefix}_${timestamp}_$suffix';
}

/// Generate a sequential bill number for display purposes.
///
/// Uses millisecond timestamp modulo + random offset to minimize
/// collisions. Range: 0–99999 (5 digits).
int generateBillNumber() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final randomOffset = _random.nextInt(1000);
  return (now + randomOffset) % 100000;
}
