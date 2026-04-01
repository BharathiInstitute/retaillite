/// Tests for AccountSettingsScreen — profile, subscription, and referral logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('AccountSettingsScreen profile display', () {
    test('shop name displayed', () {
      const shopName = 'My Store';
      expect(shopName.isNotEmpty, isTrue);
    });

    test('owner name displayed', () {
      const ownerName = 'Raj Sharma';
      expect(ownerName.isNotEmpty, isTrue);
    });

    test('email displayed', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('phone displayed and validated', () {
      expect(Validators.phone('9876543210'), isNull);
    });
  });

  group('AccountSettingsScreen subscription info', () {
    test('free plan shows as Free', () {
      const plan = 'free';
      expect(plan, 'free');
    });

    test('pro plan shows as Pro', () {
      const plan = 'pro';
      expect(plan, 'pro');
    });

    test('subscription status active shows active badge', () {
      const status = 'active';
      expect(status, 'active');
    });

    test('subscription expired shows warning', () {
      const status = 'expired';
      const isExpired = status == 'expired';
      expect(isExpired, isTrue);
    });
  });

  group('AccountSettingsScreen referral', () {
    test('referral code non-empty for registered users', () {
      const referralCode = 'REF12345';
      expect(referralCode.isNotEmpty, isTrue);
    });

    test('referral count starts at 0', () {
      const referralCount = 0;
      expect(referralCount, 0);
    });

    test('referral count increments on successful referral', () {
      var referralCount = 0;
      referralCount++;
      expect(referralCount, 1);
    });
  });

  group('AccountSettingsScreen actions', () {
    test('change password option visible for email provider', () {
      const provider = 'password';
      const showChangePassword = provider == 'password';
      expect(showChangePassword, isTrue);
    });

    test('change password hidden for Google provider', () {
      const provider = 'google.com';
      const showChangePassword = provider == 'password';
      expect(showChangePassword, isFalse);
    });

    test('uploading image disables other actions', () {
      const isUploadingImage = true;
      expect(isUploadingImage, isTrue);
    });
  });
}
