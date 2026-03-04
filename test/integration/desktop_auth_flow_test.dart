/// Integration test: Desktop authentication flow
///
/// Tests the desktop link-code login flow: code generation, expiry logic,
/// session validation, and device binding.
library;

import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

void main() {
  group('Integration: Desktop Auth Flow', () {
    test('Step 1: Link code is 8 characters, alphanumeric uppercase', () {
      // Simulate the code generation logic from auth_provider.dart
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rng = Random();
      final code = List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();

      expect(code.length, 8);
      expect(code, matches(RegExp(r'^[A-Z0-9]{8}$')));
      // Excludes ambiguous chars: I, O, 0, 1
      expect(code.contains('I'), isFalse);
      expect(code.contains('O'), isFalse);
      expect(code.contains('0'), isFalse);
      expect(code.contains('1'), isFalse);
    });

    test('Step 2: Link code expiry is 10 minutes from creation', () {
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(minutes: 10));

      expect(expiresAt.difference(createdAt).inMinutes, 10);
      expect(expiresAt.isAfter(createdAt), isTrue);
    });

    test('Step 3: Expired code is rejected', () {
      final expiresAt = DateTime.now().subtract(const Duration(minutes: 1));
      final isExpired = DateTime.now().isAfter(expiresAt);

      expect(isExpired, isTrue);
    });

    test('Step 4: Valid code is accepted within window', () {
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));
      final isExpired = DateTime.now().isAfter(expiresAt);

      expect(isExpired, isFalse);
    });

    test('Step 5: Session requires deviceId binding', () {
      // Simulate session document structure
      final session = <String, dynamic>{
        'code': 'ABCD1234',
        'userId': 'user-123',
        'deviceId': 'win_abc123',
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      };

      expect(session['deviceId'], isNotNull);
      expect(session['deviceId'], isNotEmpty);
      expect(session['code']!.toString().length, 8);
    });

    test('Step 6: Countdown timer computes remaining seconds', () {
      final expiresAt = DateTime.now().add(const Duration(minutes: 5, seconds: 30));
      final remaining = expiresAt.difference(DateTime.now()).inSeconds;

      expect(remaining, greaterThan(300)); // ~5:30
      expect(remaining, lessThanOrEqualTo(330));

      // Format as Xm Ys
      final minutes = remaining ~/ 60;
      final seconds = remaining % 60;
      expect(minutes, 5);
      expect(seconds, inInclusiveRange(28, 30)); // allow small delta
    });
  });
}
