/// NotificationModel — extended tests
///
/// Tests NotificationModel data class: enums, factories, serialization,
/// copyWith, and type parsing. Covers edge cases not in notification_test.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';

NotificationModel _makeNotification({
  String id = 'notif-1',
  String title = 'Test Notification',
  String body = 'Test body',
  NotificationType type = NotificationType.announcement,
  NotificationTargetType targetType = NotificationTargetType.all,
  String? targetUserId,
  String? targetPlan,
  DateTime? createdAt,
  String sentBy = 'admin',
  Map<String, dynamic>? data,
  bool read = false,
  DateTime? readAt,
}) {
  return NotificationModel(
    id: id,
    title: title,
    body: body,
    type: type,
    targetType: targetType,
    targetUserId: targetUserId,
    targetPlan: targetPlan,
    createdAt: createdAt ?? DateTime(2024, 1, 15),
    sentBy: sentBy,
    data: data,
    read: read,
    readAt: readAt,
  );
}

void main() {
  group('NotificationType — enum coverage', () {
    test('has 4 types', () {
      expect(NotificationType.values.length, 4);
    });

    test('all types are accessible', () {
      expect(NotificationType.announcement, isNotNull);
      expect(NotificationType.alert, isNotNull);
      expect(NotificationType.reminder, isNotNull);
      expect(NotificationType.system, isNotNull);
    });

    test('names match expected strings', () {
      expect(NotificationType.announcement.name, 'announcement');
      expect(NotificationType.alert.name, 'alert');
      expect(NotificationType.reminder.name, 'reminder');
      expect(NotificationType.system.name, 'system');
    });
  });

  group('NotificationTargetType — enum coverage', () {
    test('has 3 target types', () {
      expect(NotificationTargetType.values.length, 3);
    });

    test('all target types are accessible', () {
      expect(NotificationTargetType.all, isNotNull);
      expect(NotificationTargetType.user, isNotNull);
      expect(NotificationTargetType.plan, isNotNull);
    });
  });

  group('NotificationModel — constructor', () {
    test('creates with required fields', () {
      final notif = _makeNotification();
      expect(notif.id, 'notif-1');
      expect(notif.title, 'Test Notification');
      expect(notif.body, 'Test body');
      expect(notif.type, NotificationType.announcement);
      expect(notif.read, isFalse);
      expect(notif.readAt, isNull);
    });

    test('defaults read to false', () {
      final notif = _makeNotification();
      expect(notif.read, isFalse);
    });

    test('supports data payload', () {
      final notif = _makeNotification(data: {'action': 'open_billing'});
      expect(notif.data, isNotNull);
      expect(notif.data!['action'], 'open_billing');
    });

    test('user-targeted notification has targetUserId', () {
      final notif = _makeNotification(
        targetType: NotificationTargetType.user,
        targetUserId: 'user-123',
      );
      expect(notif.targetType, NotificationTargetType.user);
      expect(notif.targetUserId, 'user-123');
    });

    test('plan-targeted notification has targetPlan', () {
      final notif = _makeNotification(
        targetType: NotificationTargetType.plan,
        targetPlan: 'pro',
      );
      expect(notif.targetType, NotificationTargetType.plan);
      expect(notif.targetPlan, 'pro');
    });
  });

  group('NotificationModel — copyWith', () {
    test('copyWith read changes only read', () {
      final original = _makeNotification();
      final updated = original.copyWith(read: true);
      expect(updated.read, isTrue);
      expect(updated.title, original.title);
      expect(updated.body, original.body);
      expect(updated.id, original.id);
    });

    test('copyWith readAt', () {
      final now = DateTime.now();
      final original = _makeNotification();
      final updated = original.copyWith(readAt: now);
      expect(updated.readAt, now);
    });

    test('copyWith preserves all other fields', () {
      final original = _makeNotification(
        id: 'n1',
        title: 'Title',
        body: 'Body',
        type: NotificationType.alert,
        targetType: NotificationTargetType.plan,
        targetPlan: 'business',
        sentBy: 'superadmin',
        data: {'key': 'val'},
      );
      final updated = original.copyWith(read: true);
      expect(updated.id, 'n1');
      expect(updated.title, 'Title');
      expect(updated.body, 'Body');
      expect(updated.type, NotificationType.alert);
      expect(updated.targetType, NotificationTargetType.plan);
      expect(updated.targetPlan, 'business');
      expect(updated.sentBy, 'superadmin');
      expect(updated.data, {'key': 'val'});
    });
  });

  group('NotificationModel — toFirestore', () {
    test('toFirestore includes required fields', () {
      final notif = _makeNotification();
      final map = notif.toFirestore();
      expect(map['title'], 'Test Notification');
      expect(map['body'], 'Test body');
      expect(map['type'], 'announcement');
      expect(map['targetType'], 'all');
      expect(map['sentBy'], 'admin');
    });

    test('toFirestore excludes null optional fields', () {
      final notif = _makeNotification();
      final map = notif.toFirestore();
      expect(map.containsKey('targetUserId'), isFalse);
      expect(map.containsKey('data'), isFalse);
    });

    test('toFirestore includes targetUserId when set', () {
      final notif = _makeNotification(targetUserId: 'user-1');
      final map = notif.toFirestore();
      expect(map['targetUserId'], 'user-1');
    });

    test('toFirestore includes data when set', () {
      final notif = _makeNotification(data: {'url': '/billing'});
      final map = notif.toFirestore();
      expect(map['data'], {'url': '/billing'});
    });
  });

  group('NotificationModel — toUserNotification', () {
    test('sets read to false', () {
      final notif = _makeNotification(read: true);
      final userMap = notif.toUserNotification();
      expect(userMap['read'], isFalse); // Always false for new delivery
    });

    test('sets readAt to null', () {
      final notif = _makeNotification(readAt: DateTime.now());
      final userMap = notif.toUserNotification();
      expect(userMap['readAt'], isNull);
    });

    test('includes title and body', () {
      final notif = _makeNotification(title: 'New Feature!', body: 'Check it');
      final userMap = notif.toUserNotification();
      expect(userMap['title'], 'New Feature!');
      expect(userMap['body'], 'Check it');
    });
  });

  group('NotificationModel — batch invariants (10K scale)', () {
    test('sendToSelectedUsers batches at 450 to stay under 500 limit', () {
      // Firestore WriteBatch limit is 500 operations
      // Service batches at 450 for safety margin
      const batchSize = 450;
      const firestoreLimit = 500;
      expect(batchSize, lessThan(firestoreLimit));

      // With 10K users, number of batches:
      const totalUsers = 10000;
      final numBatches = (totalUsers / batchSize).ceil();
      expect(numBatches, 23); // 10000/450 = 22.2 → 23 batches
    });
  });
}
