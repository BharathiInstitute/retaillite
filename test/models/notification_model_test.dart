import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/notifications/models/notification_model.dart';

void main() {
  // ── NotificationModel construction & copyWith ──

  group('NotificationModel', () {
    late NotificationModel notification;

    setUp(() {
      notification = NotificationModel(
        id: 'n1',
        title: 'Test Notification',
        body: 'This is a test body',
        type: NotificationType.announcement,
        targetType: NotificationTargetType.all,
        createdAt: DateTime(2026, 1, 15),
        sentBy: 'admin',
      );
    });

    test('creation with required fields', () {
      expect(notification.id, 'n1');
      expect(notification.title, 'Test Notification');
      expect(notification.body, 'This is a test body');
      expect(notification.type, NotificationType.announcement);
      expect(notification.targetType, NotificationTargetType.all);
      expect(notification.read, isFalse);
      expect(notification.readAt, isNull);
    });

    test('copyWith marks as read', () {
      final readAt = DateTime(2026, 1, 16);
      final updated = notification.copyWith(read: true, readAt: readAt);
      expect(updated.read, isTrue);
      expect(updated.readAt, readAt);
      // Other fields unchanged
      expect(updated.id, 'n1');
      expect(updated.title, 'Test Notification');
      expect(updated.type, NotificationType.announcement);
    });

    test('copyWith with no args preserves values', () {
      final copy = notification.copyWith();
      expect(copy.id, notification.id);
      expect(copy.title, notification.title);
      expect(copy.read, notification.read);
    });

    test('data defaults to null', () {
      expect(notification.data, isNull);
    });

    test('targetUserId defaults to null', () {
      expect(notification.targetUserId, isNull);
    });

    test('creation with optional fields', () {
      final n = NotificationModel(
        id: 'n2',
        title: 'Targeted',
        body: 'For specific user',
        type: NotificationType.alert,
        targetType: NotificationTargetType.user,
        targetUserId: 'user_123',
        createdAt: DateTime(2026, 2),
        sentBy: 'system',
        data: {'key': 'value'},
        read: true,
        readAt: DateTime(2026, 2, 2),
      );
      expect(n.targetUserId, 'user_123');
      expect(n.data?['key'], 'value');
      expect(n.read, isTrue);
    });
  });

  // ── Enum values ──

  group('NotificationType', () {
    test('has all expected values', () {
      expect(
        NotificationType.values,
        containsAll([
          NotificationType.announcement,
          NotificationType.alert,
          NotificationType.reminder,
          NotificationType.system,
        ]),
      );
    });

    test('has exactly 4 values', () {
      expect(NotificationType.values.length, 4);
    });
  });

  group('NotificationTargetType', () {
    test('has all expected values', () {
      expect(
        NotificationTargetType.values,
        containsAll([
          NotificationTargetType.all,
          NotificationTargetType.user,
          NotificationTargetType.plan,
        ]),
      );
    });

    test('has exactly 3 values', () {
      expect(NotificationTargetType.values.length, 3);
    });
  });
}
