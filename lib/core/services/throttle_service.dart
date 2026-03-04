/// Client-side write throttle service.
///
/// Prevents rapid-fire writes to Firestore by enforcing a minimum
/// interval between operations. This is the primary rate-limiting
/// defense; Firestore rules provide the server-side backstop.
library;

import 'package:flutter/foundation.dart';

/// Throttles Firestore write operations to prevent abuse and reduce costs.
///
/// Usage:
/// ```dart
/// if (!ThrottleService.canWrite('createBill')) {
///   showSnackBar('Please wait before creating another bill');
///   return;
/// }
/// // proceed with write
/// ```
class ThrottleService {
  /// Minimum interval between writes of the same type
  static const Duration _defaultCooldown = Duration(seconds: 2);

  /// Track last write time per operation type
  static final Map<String, DateTime> _lastWriteTime = {};

  /// Track write counts per minute for burst detection
  static final Map<String, List<DateTime>> _writeBursts = {};

  /// Maximum writes per minute before throttling
  static const int _maxWritesPerMinute = 30;

  /// Check if a write operation is allowed
  static bool canWrite(String operation, {Duration? cooldown}) {
    final now = DateTime.now();
    final cd = cooldown ?? _defaultCooldown;

    // Check cooldown
    final lastWrite = _lastWriteTime[operation];
    if (lastWrite != null && now.difference(lastWrite) < cd) {
      debugPrint('⏳ Throttled: $operation (cooldown ${cd.inMilliseconds}ms)');
      return false;
    }

    // Check burst limit (max N writes per minute)
    _writeBursts.putIfAbsent(operation, () => []);
    final bursts = _writeBursts[operation]!;

    // Clean old entries (older than 1 minute)
    bursts.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));

    if (bursts.length >= _maxWritesPerMinute) {
      debugPrint('🚫 Rate limited: $operation ($_maxWritesPerMinute/min)');
      return false;
    }

    // Record this write
    _lastWriteTime[operation] = now;
    bursts.add(now);
    return true;
  }

  /// Record a write without checking (for tracking purposes)
  static void recordWrite(String operation) {
    final now = DateTime.now();
    _lastWriteTime[operation] = now;
    _writeBursts.putIfAbsent(operation, () => []);
    _writeBursts[operation]!.add(now);
  }

  /// Get remaining cooldown for an operation
  static Duration remainingCooldown(String operation, {Duration? cooldown}) {
    final cd = cooldown ?? _defaultCooldown;
    final lastWrite = _lastWriteTime[operation];
    if (lastWrite == null) return Duration.zero;

    final elapsed = DateTime.now().difference(lastWrite);
    if (elapsed >= cd) return Duration.zero;
    return cd - elapsed;
  }

  /// Clear all throttle state (e.g., on logout)
  static void reset() {
    _lastWriteTime.clear();
    _writeBursts.clear();
  }

  /// Get the number of writes in the last minute for an operation
  static int writesInLastMinute(String operation) {
    final now = DateTime.now();
    final bursts = _writeBursts[operation];
    if (bursts == null) return 0;
    return bursts
        .where((t) => now.difference(t) <= const Duration(minutes: 1))
        .length;
  }
}
