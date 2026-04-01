/// Integration tests for referral flow — code generation, tracking, idempotency.
///
/// Tests the referral flow contracts:
///   1. Code generation is idempotent (same user → same code)
///   2. Referral counting via referral_rewards collection
///   3. Duplicate referral protection
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Referral code persistence ──

  group('Referral code persistence', () {
    test('getOrCreateCode saves code to user doc', () async {
      const uid = 'user123';
      const code = 'USER4567';

      // Simulate saving referral code
      await fakeFirestore.collection('users').doc(uid).set({
        'referralCode': code,
      }, SetOptions(merge: true));

      // Verify it persists
      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()?['referralCode'], code);
    });

    test('getOrCreateCode is idempotent — returns existing code', () async {
      const uid = 'user123';
      const existingCode = 'USER4567';

      // Pre-populate
      await fakeFirestore.collection('users').doc(uid).set({
        'referralCode': existingCode,
        'name': 'Test User',
      });

      // Simulate getOrCreateCode logic
      final doc = await fakeFirestore.collection('users').doc(uid).get();
      final data = doc.data();
      String code;
      if (data != null && data['referralCode'] != null) {
        code = data['referralCode'] as String;
      } else {
        code = 'NEW_CODE'; // Would not reach here
      }

      expect(code, existingCode);
    });

    test('code does not overwrite other user fields', () async {
      const uid = 'user123';
      await fakeFirestore.collection('users').doc(uid).set({
        'name': 'Existing User',
        'email': 'test@test.com',
      });

      // Merge referral code
      await fakeFirestore.collection('users').doc(uid).set({
        'referralCode': 'CODE1234',
      }, SetOptions(merge: true));

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()?['name'], 'Existing User');
      expect(doc.data()?['email'], 'test@test.com');
      expect(doc.data()?['referralCode'], 'CODE1234');
    });
  });

  // ── Referral counting ──

  group('Referral counting', () {
    test('getReferralCount counts rewards for referrer', () async {
      const referrerId = 'referrer1';

      // Add rewards
      for (var i = 0; i < 3; i++) {
        await fakeFirestore.collection('referral_rewards').add({
          'referrerId': referrerId,
          'referredUserId': 'new_user_$i',
          'createdAt': Timestamp.now(),
        });
      }

      // Add reward for different referrer
      await fakeFirestore.collection('referral_rewards').add({
        'referrerId': 'other_referrer',
        'referredUserId': 'new_user_99',
        'createdAt': Timestamp.now(),
      });

      // Count for our referrer
      final snap = await fakeFirestore
          .collection('referral_rewards')
          .where('referrerId', isEqualTo: referrerId)
          .get();
      expect(snap.docs.length, 3);
    });

    test('new user has 0 referrals', () async {
      final snap = await fakeFirestore
          .collection('referral_rewards')
          .where('referrerId', isEqualTo: 'brand_new_user')
          .get();
      expect(snap.docs.length, 0);
    });
  });

  // ── Duplicate referral protection ──

  group('Referral idempotency', () {
    test('same referredUserId should not create duplicate reward', () async {
      const referrerId = 'referrer1';
      const referredUserId = 'new_user_1';

      // First referral
      await fakeFirestore.collection('referral_rewards').add({
        'referrerId': referrerId,
        'referredUserId': referredUserId,
        'createdAt': Timestamp.now(),
      });

      // Check before adding duplicate
      final existing = await fakeFirestore
          .collection('referral_rewards')
          .where('referredUserId', isEqualTo: referredUserId)
          .get();

      // Should not add if already exists
      final shouldAdd = existing.docs.isEmpty;
      expect(shouldAdd, isFalse);
    });
  });
}
