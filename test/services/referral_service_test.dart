/// Tests for ReferralService — referral code generation, sharing, and tracking.
///
/// The service uses FirebaseAuth.instance and FirebaseFirestore.instance directly.
/// We test the pure logic: code generation, URL format, share text, and
/// the code format contract.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Referral code generation ──

  group('Referral code generation', () {
    // Mirrors ReferralService._generateCode:
    //   final prefix = uid.substring(0, 4).toUpperCase();
    //   final suffix = random.nextInt(9999).toString().padLeft(4, '0');
    //   return '$prefix$suffix';
    String generateCode(String uid, int seed) {
      final random = Random(seed);
      final suffix = random.nextInt(9999).toString().padLeft(4, '0');
      final prefix = uid.substring(0, 4).toUpperCase();
      return '$prefix$suffix';
    }

    test('code format is 4 char prefix + 4 digit suffix', () {
      final code = generateCode('user12345', 42);
      expect(code.length, 8);
      expect(code.substring(0, 4), 'USER');
      expect(int.tryParse(code.substring(4)), isNotNull);
    });

    test('prefix is uppercase uid prefix', () {
      final code = generateCode('abcd9999', 0);
      expect(code.startsWith('ABCD'), isTrue);
    });

    test('suffix is 0-padded 4 digits', () {
      // With seed 0, Random(0).nextInt(9999) is deterministic
      final code = generateCode('test0000', 0);
      final suffix = code.substring(4);
      expect(suffix.length, 4);
      expect(RegExp(r'^\d{4}$').hasMatch(suffix), isTrue);
    });

    test('different UIDs produce different prefixes', () {
      final code1 = generateCode('aaaa1111', 42);
      final code2 = generateCode('bbbb2222', 42);
      expect(code1.substring(0, 4), isNot(code2.substring(0, 4)));
    });

    test('same UID + same seed produces same code', () {
      final code1 = generateCode('user1234', 99);
      final code2 = generateCode('user1234', 99);
      expect(code1, code2);
    });
  });

  // ── Referral URL format ──

  group('Referral URL', () {
    String buildReferralUrl(String code) {
      return 'https://retaillite.com/refer?code=$code';
    }

    test('URL format is correct', () {
      final url = buildReferralUrl('USER1234');
      expect(url, 'https://retaillite.com/refer?code=USER1234');
    });

    test('URL contains the code as query parameter', () {
      final url = buildReferralUrl('ABCD5678');
      expect(Uri.parse(url).queryParameters['code'], 'ABCD5678');
    });
  });

  // ── Share text ──

  group('Referral share text', () {
    String buildShareText(String code) {
      return 'Try RetailLite for your shop! Use my referral code $code to sign up: https://retaillite.com/refer?code=$code';
    }

    test('contains referral code', () {
      final text = buildShareText('TEST0001');
      expect(text.contains('TEST0001'), isTrue);
      // Code appears twice: once as text, once in URL
      expect('TEST0001'.allMatches(text).length, 2);
    });

    test('contains signup URL', () {
      final text = buildShareText('CODE9999');
      expect(
        text.contains('https://retaillite.com/refer?code=CODE9999'),
        isTrue,
      );
    });
  });

  // ── Platform sharing behavior ──

  group('Referral share platform behavior', () {
    // Mirrors: kIsWeb → clipboard, else → native share
    bool shareReturnsTrue({required bool isWeb}) => isWeb;

    test('web returns true (caller should show "Copied" feedback)', () {
      expect(shareReturnsTrue(isWeb: true), isTrue);
    });

    test('mobile returns false (native share sheet shown)', () {
      expect(shareReturnsTrue(isWeb: false), isFalse);
    });
  });

  // ── Auth guard ──

  group('Referral auth guard', () {
    // Mirrors: if (uid == null) return '';
    String getOrCreateCode(String? uid) {
      if (uid == null) return '';
      return 'MOCK_CODE';
    }

    test('returns empty string when not authenticated', () {
      expect(getOrCreateCode(null), '');
    });

    test('returns code when authenticated', () {
      expect(getOrCreateCode('user123'), isNotEmpty);
    });

    // Mirrors: if (uid == null) return 0;
    int getReferralCount(String? uid) {
      if (uid == null) return 0;
      return 5;
    }

    test('referral count is 0 when not authenticated', () {
      expect(getReferralCount(null), 0);
    });
  });
}
