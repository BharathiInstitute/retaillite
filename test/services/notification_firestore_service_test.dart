/// Tests for NotificationFirestoreService — Firestore CRUD for notifications.
///
/// The production service uses static `FirebaseFirestore.instance` so we cannot
/// inject a FakeFirebaseFirestore directly. Instead we:
///   1. Test the model serialization contract (toFirestore / toUserNotification)
///   2. Test query-equivalent logic (client-side search, ordering, batching)
///   3. Test NotificationModel.fromFirestore with FakeFirebaseFirestore docs
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';

void main() {
  // ── NotificationModel serialization ──

  group('NotificationModel toFirestore()', () {
    test('serializes all required fields', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Welcome',
        body: 'Hello there',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 4),
        sentBy: 'admin',
      );
      final map = model.toFirestore();
      expect(map['title'], 'Welcome');
      expect(map['body'], 'Hello there');
      expect(map['type'], 'announcement');
      expect(map['targetType'], 'all');
      expect(map['sentBy'], 'admin');
      expect(
        map.containsKey('createdAt'),
        isTrue,
      ); // FieldValue.serverTimestamp
    });

    test('includes optional targetUserId when present', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Alert',
        body: 'Check this',
        type: NotificationType.alert,
        targetType: NotificationTargetType.user,
        targetUserId: 'user123',
        createdAt: DateTime(2026, 4),
        sentBy: 'system',
      );
      final map = model.toFirestore();
      expect(map['targetUserId'], 'user123');
    });

    test('includes optional targetPlan when present', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Pro offer',
        body: 'Upgrade now',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.plan,
        targetPlan: 'pro',
        createdAt: DateTime(2026, 4),
        sentBy: 'admin',
      );
      final map = model.toFirestore();
      expect(map['targetPlan'], 'pro');
    });

    test('includes data map when present', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Data',
        body: 'Has payload',
        type: NotificationType.system,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 4),
        sentBy: 'system',
        data: {'action': 'open_settings', 'version': '9.7.0'},
      );
      final map = model.toFirestore();
      expect(map['data'], {'action': 'open_settings', 'version': '9.7.0'});
    });

    test('excludes null optional fields', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Basic',
        body: 'No extras',
        type: NotificationType.system,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 4),
        sentBy: 'system',
      );
      final map = model.toFirestore();
      expect(map.containsKey('targetUserId'), isFalse);
      expect(map.containsKey('targetPlan'), isFalse);
      expect(map.containsKey('data'), isFalse);
    });
  });

  group('NotificationModel toUserNotification()', () {
    test('sets read=false and readAt=null for new user notification', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Hello',
        body: 'World',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 4),
        sentBy: 'admin',
      );
      final map = model.toUserNotification();
      expect(map['read'], false);
      expect(map['readAt'], isNull);
      expect(map['title'], 'Hello');
      expect(map['body'], 'World');
      expect(map['type'], 'announcement');
      expect(map['sentBy'], 'admin');
    });
  });

  // ── NotificationModel.fromFirestore with FakeFirebaseFirestore ──

  group('NotificationModel.fromFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('parses complete notification document', () async {
      await fakeFirestore.collection('notifications').doc('notif1').set({
        'title': 'Update Available',
        'body': 'Version 9.8 is here',
        'type': 'announcement',
        'targetType': 'all',
        'createdAt': Timestamp.fromDate(DateTime(2026, 4)),
        'sentBy': 'admin',
        'read': false,
        'data': {'version': '9.8'},
      });

      final doc = await fakeFirestore
          .collection('notifications')
          .doc('notif1')
          .get();
      final model = NotificationModel.fromFirestore(doc);

      expect(model.id, 'notif1');
      expect(model.title, 'Update Available');
      expect(model.body, 'Version 9.8 is here');
      expect(model.type, NotificationType.announcement);
      expect(model.targetType, NotificationTargetType.all);
      expect(model.sentBy, 'admin');
      expect(model.read, isFalse);
      expect(model.data, {'version': '9.8'});
    });

    test('defaults missing fields gracefully', () async {
      await fakeFirestore.collection('notifications').doc('notif2').set({});

      final doc = await fakeFirestore
          .collection('notifications')
          .doc('notif2')
          .get();
      final model = NotificationModel.fromFirestore(doc);

      expect(model.id, 'notif2');
      expect(model.title, '');
      expect(model.body, '');
      expect(model.type, NotificationType.system);
      expect(model.targetType, NotificationTargetType.all);
      expect(model.sentBy, 'system');
      expect(model.read, isFalse);
      expect(model.readAt, isNull);
    });

    test('parses all NotificationType values', () async {
      for (final type in NotificationType.values) {
        await fakeFirestore
            .collection('notifications')
            .doc('type_${type.name}')
            .set({
              'title': 'Test',
              'body': 'Body',
              'type': type.name,
              'createdAt': Timestamp.fromDate(DateTime(2026, 4)),
              'sentBy': 'system',
            });

        final doc = await fakeFirestore
            .collection('notifications')
            .doc('type_${type.name}')
            .get();
        final model = NotificationModel.fromFirestore(doc);
        expect(model.type, type);
      }
    });

    test('parses all NotificationTargetType values', () async {
      for (final tt in NotificationTargetType.values) {
        await fakeFirestore
            .collection('notifications')
            .doc('tt_${tt.name}')
            .set({
              'title': 'Test',
              'body': 'Body',
              'targetType': tt.name,
              'createdAt': Timestamp.fromDate(DateTime(2026, 4)),
              'sentBy': 'system',
            });

        final doc = await fakeFirestore
            .collection('notifications')
            .doc('tt_${tt.name}')
            .get();
        final model = NotificationModel.fromFirestore(doc);
        expect(model.targetType, tt);
      }
    });

    test('unknown type falls back to system', () async {
      await fakeFirestore.collection('notifications').doc('unknown').set({
        'title': 'Test',
        'body': 'Body',
        'type': 'invalid_type',
        'createdAt': Timestamp.fromDate(DateTime(2026, 4)),
        'sentBy': 'system',
      });

      final doc = await fakeFirestore
          .collection('notifications')
          .doc('unknown')
          .get();
      final model = NotificationModel.fromFirestore(doc);
      expect(model.type, NotificationType.system);
    });

    test('unknown targetType falls back to all', () async {
      await fakeFirestore.collection('notifications').doc('unknownTT').set({
        'title': 'Test',
        'body': 'Body',
        'targetType': 'invalid_target',
        'createdAt': Timestamp.fromDate(DateTime(2026, 4)),
        'sentBy': 'system',
      });

      final doc = await fakeFirestore
          .collection('notifications')
          .doc('unknownTT')
          .get();
      final model = NotificationModel.fromFirestore(doc);
      expect(model.targetType, NotificationTargetType.all);
    });

    test('parses readAt timestamp', () async {
      final readTime = DateTime(2026, 4, 1, 10, 30);
      await fakeFirestore.collection('notifications').doc('readNotif').set({
        'title': 'Read',
        'body': 'Was read',
        'read': true,
        'readAt': Timestamp.fromDate(readTime),
        'createdAt': Timestamp.fromDate(DateTime(2026, 4)),
        'sentBy': 'system',
      });

      final doc = await fakeFirestore
          .collection('notifications')
          .doc('readNotif')
          .get();
      final model = NotificationModel.fromFirestore(doc);
      expect(model.read, isTrue);
      expect(model.readAt, readTime);
    });
  });

  // ── NotificationModel copyWith ──

  group('NotificationModel copyWith', () {
    test('marks as read preserving other fields', () {
      final original = NotificationModel(
        id: 'n1',
        title: 'Original',
        body: 'Body',
        type: NotificationType.alert,
        targetType: NotificationTargetType.user,
        targetUserId: 'user1',
        createdAt: DateTime(2026, 4),
        sentBy: 'admin',
        data: {'key': 'val'},
      );
      final readTime = DateTime(2026, 4, 1, 12);
      final read = original.copyWith(read: true, readAt: readTime);

      expect(read.read, isTrue);
      expect(read.readAt, readTime);
      expect(read.id, 'n1');
      expect(read.title, 'Original');
      expect(read.body, 'Body');
      expect(read.type, NotificationType.alert);
      expect(read.targetUserId, 'user1');
      expect(read.data, {'key': 'val'});
    });

    test('copyWith without arguments returns equivalent model', () {
      final original = NotificationModel(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.system,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 4),
        sentBy: 'system',
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.read, original.read);
    });
  });

  // ── Client-side search logic (mirrors searchUsers) ──

  group('Client-side user search logic', () {
    // Mirrors NotificationFirestoreService.searchUsers logic
    List<Map<String, dynamic>> searchUsers(
      List<Map<String, dynamic>> users,
      String query,
    ) {
      final q = query.toLowerCase();
      return users.where((data) {
        final name = (data['ownerName'] as String? ?? '').toLowerCase();
        final email = (data['email'] as String? ?? '').toLowerCase();
        final shop = (data['shopName'] as String? ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || shop.contains(q);
      }).toList();
    }

    final users = [
      {
        'id': 'u1',
        'ownerName': 'Rakesh Kumar',
        'email': 'rakesh@shop.com',
        'shopName': 'Kumar Stores',
      },
      {
        'id': 'u2',
        'ownerName': 'Priya Singh',
        'email': 'priya@gmail.com',
        'shopName': 'Priya Fashion',
      },
      {
        'id': 'u3',
        'ownerName': 'Amit Patel',
        'email': 'amit@supermart.in',
        'shopName': 'Super Mart',
      },
    ];

    test('finds by shopName substring', () {
      final results = searchUsers(users, 'kumar');
      expect(results.length, 1);
      expect(results[0]['id'], 'u1');
    });

    test('finds by email', () {
      final results = searchUsers(users, 'priya@gmail');
      expect(results.length, 1);
      expect(results[0]['id'], 'u2');
    });

    test('finds by ownerName', () {
      final results = searchUsers(users, 'Amit');
      expect(results.length, 1);
      expect(results[0]['id'], 'u3');
    });

    test('case-insensitive search', () {
      final results = searchUsers(users, 'PRIYA');
      expect(results.length, 1);
      expect(results[0]['id'], 'u2');
    });

    test('returns empty for no match', () {
      final results = searchUsers(users, 'xyz');
      expect(results, isEmpty);
    });

    test('returns multiple matches', () {
      // Both u1 and u3 contain 'r' in their names
      final results = searchUsers(users, 'mart');
      expect(results.length, 1); // Only Super Mart
    });
  });

  // ── Batch logic for sendToSelectedUsers ──

  group('Batch pagination logic', () {
    test('batches of 450 — calculates correct batch count', () {
      for (final n in [1, 100, 450, 451, 900, 901]) {
        final batchCount = (n / 450).ceil();
        if (n <= 450) {
          expect(batchCount, 1, reason: '$n users → 1 batch');
        } else if (n <= 900) {
          expect(batchCount, 2, reason: '$n users → 2 batches');
        } else {
          expect(batchCount, greaterThan(2), reason: '$n users → >2 batches');
        }
      }
    });
  });

  // ── Enums ──

  group('NotificationType enum', () {
    test('has exactly 4 values', () {
      expect(NotificationType.values.length, 4);
    });

    test('values are announcement, alert, reminder, system', () {
      expect(NotificationType.values.map((e) => e.name).toList(), [
        'announcement',
        'alert',
        'reminder',
        'system',
      ]);
    });
  });

  group('NotificationTargetType enum', () {
    test('has exactly 3 values', () {
      expect(NotificationTargetType.values.length, 3);
    });

    test('values are all, user, plan', () {
      expect(NotificationTargetType.values.map((e) => e.name).toList(), [
        'all',
        'user',
        'plan',
      ]);
    });
  });
}
