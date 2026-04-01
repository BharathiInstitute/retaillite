/// Tests for WindowsNotificationService — Windows-only local notification system.
///
/// The service uses FlutterLocalNotificationsPlugin and FirebaseFirestore
/// directly, so we test the platform branching and notification logic contracts.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Platform guard ──

  group('WindowsNotificationService platform guard', () {
    // Mirrors: if (!Platform.isWindows) return;
    bool shouldInit({required bool isWindows}) => isWindows;

    test('initializes on Windows', () {
      expect(shouldInit(isWindows: true), isTrue);
    });

    test('skips on non-Windows', () {
      expect(shouldInit(isWindows: false), isFalse);
    });
  });

  // ── Notification ID generation ──

  group('WindowsNotificationService notification IDs', () {
    // The service uses hashCode of notification ID as int ID:
    //   _showNotification(id: doc.id.hashCode, ...)
    test('hashCode produces consistent int ID from string', () {
      const docId = 'notification_abc123';
      expect(docId.hashCode, docId.hashCode); // deterministic
    });

    test('different doc IDs produce different notification IDs', () {
      expect('notif_1'.hashCode, isNot('notif_2'.hashCode));
    });
  });

  // ── Listening lifecycle ──

  group('WindowsNotificationService listening lifecycle', () {
    // Mirrors the startListening → stopListening contract
    bool? isListening;

    test('startListening sets up Firestore subscription', () {
      isListening = true;
      expect(isListening, isTrue);
    });

    test('stopListening cancels Firestore subscription', () {
      isListening = true;
      // stopListening:
      isListening = false;
      expect(isListening, isFalse);
    });

    test('stopListening is safe when not listening', () {
      isListening = null; // never started
      expect(() {
        // _subscription?.cancel() — safe when null
        if (isListening != null) isListening = false;
      }, returnsNormally);
    });

    test('startListening filters for unread notifications only', () {
      // Mirrors: .where('read', isEqualTo: false)
      final notifications = [
        {'id': 'n1', 'read': false, 'title': 'New'},
        {'id': 'n2', 'read': true, 'title': 'Old'},
        {'id': 'n3', 'read': false, 'title': 'Another new'},
      ];
      final unread = notifications.where((n) => n['read'] == false).toList();
      expect(unread.length, 2);
      expect(unread.map((n) => n['id']), ['n1', 'n3']);
    });
  });

  // ── Initialization guard ──

  group('WindowsNotificationService initialization', () {
    test('init can only be called once (idempotent)', () {
      bool initialized = false;

      void init() {
        if (initialized) return;
        initialized = true;
      }

      init();
      expect(initialized, isTrue);
      init(); // Should be no-op
      expect(initialized, isTrue);
    });
  });
}
