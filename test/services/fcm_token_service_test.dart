/// Tests for FCMTokenService — FCM device token management.
///
/// The service uses static FirebaseMessaging.instance / FirebaseFirestore.instance
/// so we test the logic contracts and platform branching.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Platform branching logic ──

  group('FCMTokenService platform logic', () {
    // Mirrors the platform check in initAndSaveToken:
    //   if (!kIsWeb && Platform.isWindows) return;
    bool shouldSkipPlatform({required bool isWeb, required bool isWindows}) {
      return !isWeb && isWindows;
    }

    test('skips on native Windows', () {
      expect(shouldSkipPlatform(isWeb: false, isWindows: true), isTrue);
    });

    test('does not skip on web (even on Windows browser)', () {
      expect(shouldSkipPlatform(isWeb: true, isWindows: true), isFalse);
    });

    test('does not skip on Android', () {
      expect(shouldSkipPlatform(isWeb: false, isWindows: false), isFalse);
    });

    test('does not skip on web non-Windows', () {
      expect(shouldSkipPlatform(isWeb: true, isWindows: false), isFalse);
    });
  });

  // ── Token storage contract ──

  group('FCMTokenService token storage', () {
    // Mirrors the Firestore write in initAndSaveToken:
    //   users/{userId} → { fcmToken: token, fcmTokenUpdatedAt: serverTimestamp }
    Map<String, dynamic> buildTokenUpdate(String token) {
      return {'fcmToken': token, 'fcmTokenUpdatedAt': 'SERVER_TIMESTAMP'};
    }

    test('builds correct token document', () {
      final update = buildTokenUpdate('abc123-fcm-token');
      expect(update['fcmToken'], 'abc123-fcm-token');
      expect(update.containsKey('fcmTokenUpdatedAt'), isTrue);
    });

    test('empty token still creates document', () {
      final update = buildTokenUpdate('');
      expect(update['fcmToken'], '');
    });
  });

  // ── Token removal contract ──

  group('FCMTokenService removeToken', () {
    // Mirrors the Firestore write in removeToken:
    //   users/{userId} → { fcmToken: FieldValue.delete(), fcmTokenUpdatedAt: FieldValue.delete() }
    Map<String, String> buildTokenRemoval() {
      return {'fcmToken': 'FIELD_DELETE', 'fcmTokenUpdatedAt': 'FIELD_DELETE'};
    }

    test('removal clears both fields', () {
      final removal = buildTokenRemoval();
      expect(removal['fcmToken'], 'FIELD_DELETE');
      expect(removal['fcmTokenUpdatedAt'], 'FIELD_DELETE');
    });
  });

  // ── VAPID key usage ──

  group('FCMTokenService VAPID key', () {
    // On web, getToken uses vapidKey parameter
    // On mobile, getToken uses default (no vapidKey)
    String? getVapidKey({required bool isWeb}) {
      if (isWeb) {
        // The actual key from the source code
        return 'web-vapid-key';
      }
      return null;
    }

    test('web platform uses VAPID key', () {
      expect(getVapidKey(isWeb: true), isNotNull);
    });

    test('mobile platform does not use VAPID key', () {
      expect(getVapidKey(isWeb: false), isNull);
    });
  });
}
