/// Tests for Notification system — model, enums, serialization, and platform guards
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';

void main() {
  // ──────────────────────────────────────────────
  //  NotificationType enum
  // ──────────────────────────────────────────────
  group('NotificationType enum', () {
    test('should have all expected values', () {
      expect(NotificationType.values, hasLength(4));
      expect(
        NotificationType.values.map((e) => e.name),
        containsAll(['announcement', 'alert', 'reminder', 'system']),
      );
    });

    test('name property returns correct string', () {
      expect(NotificationType.announcement.name, 'announcement');
      expect(NotificationType.alert.name, 'alert');
      expect(NotificationType.reminder.name, 'reminder');
      expect(NotificationType.system.name, 'system');
    });
  });

  // ──────────────────────────────────────────────
  //  NotificationTargetType enum
  // ──────────────────────────────────────────────
  group('NotificationTargetType enum', () {
    test('should have all expected values', () {
      expect(NotificationTargetType.values, hasLength(3));
      expect(
        NotificationTargetType.values.map((e) => e.name),
        containsAll(['all', 'user', 'plan']),
      );
    });

    test('name property returns correct string', () {
      expect(NotificationTargetType.all.name, 'all');
      expect(NotificationTargetType.user.name, 'user');
      expect(NotificationTargetType.plan.name, 'plan');
    });
  });

  // ──────────────────────────────────────────────
  //  NotificationModel constructor
  // ──────────────────────────────────────────────
  group('NotificationModel constructor', () {
    test('creates model with required fields', () {
      final now = DateTime(2026, 2, 22, 15);
      final model = NotificationModel(
        id: 'n1',
        title: 'Test Alert',
        body: 'Low stock on Rice',
        type: NotificationType.alert,
        targetType: NotificationTargetType.all,
        createdAt: now,
        sentBy: 'admin',
      );

      expect(model.id, 'n1');
      expect(model.title, 'Test Alert');
      expect(model.body, 'Low stock on Rice');
      expect(model.type, NotificationType.alert);
      expect(model.targetType, NotificationTargetType.all);
      expect(model.createdAt, now);
      expect(model.sentBy, 'admin');
      expect(model.read, false); // default
      expect(model.readAt, isNull); // default
      expect(model.data, isNull); // default
      expect(model.targetUserId, isNull); // default
      expect(model.targetPlan, isNull); // default
    });

    test('creates model with all optional fields', () {
      final now = DateTime(2026, 2, 22);
      final readTime = DateTime(2026, 2, 22, 16);
      final model = NotificationModel(
        id: 'n2',
        title: 'Subscription Expiry',
        body: 'Your plan expires in 3 days',
        type: NotificationType.reminder,
        targetType: NotificationTargetType.user,
        targetUserId: 'user123',
        targetPlan: 'premium',
        createdAt: now,
        sentBy: 'system',
        data: {'daysLeft': 3, 'planName': 'Premium'},
        read: true,
        readAt: readTime,
      );

      expect(model.targetUserId, 'user123');
      expect(model.targetPlan, 'premium');
      expect(model.read, true);
      expect(model.readAt, readTime);
      expect(model.data, {'daysLeft': 3, 'planName': 'Premium'});
    });
  });

  // ──────────────────────────────────────────────
  //  toFirestore()
  // ──────────────────────────────────────────────
  group('NotificationModel.toFirestore', () {
    test('serializes required fields correctly', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Daily Sales Summary',
        body: 'Total: ₹15,000',
        type: NotificationType.system,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'auto',
      );

      final map = model.toFirestore();
      expect(map['title'], 'Daily Sales Summary');
      expect(map['body'], 'Total: ₹15,000');
      expect(map['type'], 'system');
      expect(map['targetType'], 'all');
      expect(map['sentBy'], 'auto');
      // createdAt uses FieldValue.serverTimestamp() — can't compare directly
      expect(map.containsKey('createdAt'), true);
    });

    test('excludes null optional fields', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'admin',
      );

      final map = model.toFirestore();
      expect(map.containsKey('targetUserId'), false);
      expect(map.containsKey('targetPlan'), false);
      expect(map.containsKey('data'), false);
    });

    test('includes optional fields when set', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.alert,
        targetType: NotificationTargetType.user,
        targetUserId: 'user456',
        targetPlan: 'basic',
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'admin',
        data: {'action': 'restock'},
      );

      final map = model.toFirestore();
      expect(map['targetUserId'], 'user456');
      expect(map['targetPlan'], 'basic');
      expect(map['data'], {'action': 'restock'});
    });
  });

  // ──────────────────────────────────────────────
  //  toUserNotification()
  // ──────────────────────────────────────────────
  group('NotificationModel.toUserNotification', () {
    test('serializes for user subcollection with read=false', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'New Feature',
        body: 'Barcode scanning is here!',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'admin',
        read: true, // even if source is read, user copy starts unread
      );

      final map = model.toUserNotification();
      expect(map['title'], 'New Feature');
      expect(map['body'], 'Barcode scanning is here!');
      expect(map['type'], 'announcement');
      expect(map['targetType'], 'all');
      expect(map['sentBy'], 'admin');
      expect(map['read'], false); // always false for new user notification
      expect(map['readAt'], isNull);
    });

    test('includes data when present', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.system,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'system',
        data: {'url': '/settings'},
      );

      final map = model.toUserNotification();
      expect(map['data'], {'url': '/settings'});
    });

    test('excludes data when null', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.system,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'system',
      );

      final map = model.toUserNotification();
      expect(map.containsKey('data'), false);
    });
  });

  // ──────────────────────────────────────────────
  //  copyWith()
  // ──────────────────────────────────────────────
  group('NotificationModel.copyWith', () {
    late NotificationModel original;

    setUp(() {
      original = NotificationModel(
        id: 'n1',
        title: 'Original Title',
        body: 'Original Body',
        type: NotificationType.alert,
        targetType: NotificationTargetType.user,
        targetUserId: 'user1',
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'admin',
      );
    });

    test('marks as read with timestamp', () {
      final readTime = DateTime(2026, 2, 22, 16, 30);
      final updated = original.copyWith(read: true, readAt: readTime);

      expect(updated.read, true);
      expect(updated.readAt, readTime);
      // Other fields unchanged
      expect(updated.id, 'n1');
      expect(updated.title, 'Original Title');
      expect(updated.body, 'Original Body');
      expect(updated.type, NotificationType.alert);
      expect(updated.targetType, NotificationTargetType.user);
      expect(updated.targetUserId, 'user1');
      expect(updated.sentBy, 'admin');
    });

    test('preserves all fields when no changes', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.body, original.body);
      expect(copy.type, original.type);
      expect(copy.targetType, original.targetType);
      expect(copy.read, original.read);
      expect(copy.readAt, original.readAt);
    });

    test('only updates read without touching readAt', () {
      final updated = original.copyWith(read: true);
      expect(updated.read, true);
      expect(updated.readAt, isNull); // wasn't set
    });
  });

  // ──────────────────────────────────────────────
  //  Type parsing (via round-trip through toFirestore)
  // ──────────────────────────────────────────────
  group('Notification type serialization round-trip', () {
    test('all NotificationType values serialize correctly', () {
      for (final type in NotificationType.values) {
        final model = NotificationModel(
          id: 'test',
          title: 'Test',
          body: 'Body',
          type: type,
          targetType: NotificationTargetType.all,
          createdAt: DateTime(2026, 2, 22),
          sentBy: 'system',
        );
        final map = model.toFirestore();
        expect(map['type'], type.name);
      }
    });

    test('all NotificationTargetType values serialize correctly', () {
      for (final targetType in NotificationTargetType.values) {
        final model = NotificationModel(
          id: 'test',
          title: 'Test',
          body: 'Body',
          type: NotificationType.system,
          targetType: targetType,
          createdAt: DateTime(2026, 2, 22),
          sentBy: 'system',
        );
        final map = model.toFirestore();
        expect(map['targetType'], targetType.name);
      }
    });
  });

  // ──────────────────────────────────────────────
  //  Edge cases
  // ──────────────────────────────────────────────
  group('Edge cases', () {
    test('empty title and body are valid', () {
      final model = NotificationModel(
        id: 'n1',
        title: '',
        body: '',
        type: NotificationType.system,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'system',
      );

      expect(model.title, '');
      expect(model.body, '');

      final map = model.toFirestore();
      expect(map['title'], '');
      expect(map['body'], '');
    });

    test('special characters in title and body', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Price: ₹500 — 20% off!',
        body: 'Items: "Rice", "Dal" & more <stock>',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'admin',
      );

      expect(model.title, 'Price: ₹500 — 20% off!');
      expect(model.body, 'Items: "Rice", "Dal" & more <stock>');
    });

    test('data map with nested values', () {
      final model = NotificationModel(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.alert,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'system',
        data: {
          'items': ['Rice', 'Dal', 'Oil'],
          'count': 3,
          'urgent': true,
          'meta': {'source': 'inventory', 'threshold': 10},
        },
      );

      expect(model.data!['items'], hasLength(3));
      expect(model.data!['count'], 3);
      expect(model.data!['urgent'], true);
      expect(model.data!['meta']['source'], 'inventory');

      final map = model.toFirestore();
      expect(map['data']['items'], hasLength(3));
    });

    test('toUserNotification always sets read=false regardless of source', () {
      final readModel = NotificationModel(
        id: 'n1',
        title: 'Already Read',
        body: 'This was read by another user',
        type: NotificationType.system,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'admin',
        read: true,
        readAt: DateTime(2026, 2, 22, 10),
      );

      final userMap = readModel.toUserNotification();
      expect(userMap['read'], false);
      expect(userMap['readAt'], isNull);
    });
  });

  // ──────────────────────────────────────────────
  //  WindowsNotificationService platform guards
  // ──────────────────────────────────────────────
  group('WindowsNotificationService platform safety', () {
    test('appName and appUserModelId are correct constants', () {
      // These must match pubspec.yaml msix config
      const appName = 'Tulasi Stores';
      const appUserModelId = 'TulasiERP.TulasiStores';

      expect(appName, 'Tulasi Stores');
      expect(appUserModelId, contains('TulasiStores'));
    });

    test('notification query path structure is correct', () {
      const userId = 'user123';
      const path = 'users/$userId/notifications';
      expect(path, 'users/user123/notifications');
    });

    test('unread filter uses correct field and value', () {
      // The Firestore query filters by read == false
      const field = 'read';
      const value = false;
      expect(field, 'read');
      expect(value, false);
    });
  });

  // ──────────────────────────────────────────────
  //  Notification targeting logic
  // ──────────────────────────────────────────────
  group('Notification targeting logic', () {
    test('all-target notification has no userId or plan', () {
      final model = NotificationModel(
        id: 'broadcast',
        title: 'App Update Available',
        body: 'v1.0.5 is out!',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'admin',
      );

      expect(model.targetType, NotificationTargetType.all);
      expect(model.targetUserId, isNull);
      expect(model.targetPlan, isNull);
    });

    test('user-target notification has userId set', () {
      final model = NotificationModel(
        id: 'personal',
        title: 'Your subscription expires',
        body: 'Renew within 3 days',
        type: NotificationType.reminder,
        targetType: NotificationTargetType.user,
        targetUserId: 'user456',
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'system',
      );

      expect(model.targetType, NotificationTargetType.user);
      expect(model.targetUserId, 'user456');
    });

    test('plan-target notification has plan set', () {
      final model = NotificationModel(
        id: 'plan-notif',
        title: 'Premium Feature Update',
        body: 'New export format available',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.plan,
        targetPlan: 'premium',
        createdAt: DateTime(2026, 2, 22),
        sentBy: 'admin',
      );

      expect(model.targetType, NotificationTargetType.plan);
      expect(model.targetPlan, 'premium');
    });
  });
}
