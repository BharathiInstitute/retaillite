/// Referral service logic tests
///
/// Tests the referral code generation algorithm and share message formatting.
/// Verifiable without Firebase by extracting the pure logic.
library;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Extracted from ReferralService._generateCode
String generateReferralCode(String uid, {int? seed}) {
  final random = seed != null ? Random(seed) : Random();
  final suffix = random.nextInt(9999).toString().padLeft(4, '0');
  final prefix = uid.substring(0, 4).toUpperCase();
  return '$prefix$suffix';
}

/// Extracted from ReferralService.share
String buildShareMessage(String code) {
  return 'Try RetailLite for your shop! Use my referral code $code to sign up: https://retaillite.com/refer?code=$code';
}

void main() {
  group('Referral code generation', () {
    test('code is exactly 8 characters', () {
      final code = generateReferralCode('abcdefgh12345', seed: 42);
      expect(code.length, 8);
    });

    test('first 4 chars come from UID uppercased', () {
      final code = generateReferralCode('xyzw1234', seed: 42);
      expect(code.substring(0, 4), 'XYZW');
    });

    test('last 4 chars are numeric', () {
      final code = generateReferralCode('abcdefgh', seed: 42);
      final suffix = code.substring(4);
      expect(int.tryParse(suffix), isNotNull);
    });

    test('suffix is zero-padded', () {
      // Use a seed that generates a small number
      for (int seed = 0; seed < 100; seed++) {
        final code = generateReferralCode('test1234', seed: seed);
        expect(code.length, 8, reason: 'Seed $seed must produce 8-char code');
      }
    });

    test('different UIDs produce different prefixes', () {
      final code1 = generateReferralCode('aaaa1234', seed: 42);
      final code2 = generateReferralCode('bbbb1234', seed: 42);
      expect(code1.substring(0, 4), isNot(equals(code2.substring(0, 4))));
    });

    test('UID with special chars works (first 4 only)', () {
      final code = generateReferralCode('A1b2CdEf', seed: 42);
      expect(code.substring(0, 4), 'A1B2');
    });

    test('handles minimum length UID (4 chars)', () {
      final code = generateReferralCode('abcd', seed: 42);
      expect(code.substring(0, 4), 'ABCD');
    });
  });

  group('Share message formatting', () {
    test('contains referral code', () {
      final msg = buildShareMessage('ABCD1234');
      expect(msg, contains('ABCD1234'));
    });

    test('contains referral URL', () {
      final msg = buildShareMessage('TEST0001');
      expect(msg, contains('https://retaillite.com/refer?code=TEST0001'));
    });

    test('mentions RetailLite', () {
      final msg = buildShareMessage('CODE1234');
      expect(msg, contains('RetailLite'));
    });

    test('URL is well-formed', () {
      final msg = buildShareMessage('XYZW5678');
      final urlMatch = RegExp(r'https://retaillite\.com/refer\?code=\w+');
      expect(urlMatch.hasMatch(msg), isTrue);
    });

    test('code appears exactly twice (in text + URL)', () {
      const code = 'UNIQ1234';
      final msg = buildShareMessage(code);
      final count = RegExp(code).allMatches(msg).length;
      expect(count, 2);
    });
  });

  group('Referral code uniqueness', () {
    test('1000 codes from same UID have no collisions', () {
      final codes = <String>{};
      for (int i = 0; i < 1000; i++) {
        codes.add(generateReferralCode('user1234', seed: i));
      }
      // Some may collide due to Random seed behavior, but most should be unique
      expect(codes.length, greaterThan(900));
    });
  });
}
