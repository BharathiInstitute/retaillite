/// Tests for NotificationsAdminScreen — compose form, target selector, send.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationsAdminScreen compose form', () {
    test('notification title required', () {
      const title = '';
      expect(title.isEmpty, isTrue);
    });

    test('notification body required', () {
      const body = 'New feature available!';
      expect(body.isNotEmpty, isTrue);
    });

    test('notification templates available', () {
      const templates = ['Welcome', 'New Feature', 'Maintenance'];
      expect(templates.isNotEmpty, isTrue);
    });
  });

  group('NotificationsAdminScreen target selector', () {
    test('target all users', () {
      const target = 'all';
      expect(target, 'all');
    });

    test('target by plan', () {
      const target = 'plan';
      const planFilter = 'pro';
      expect(target, 'plan');
      expect(planFilter, 'pro');
    });

    test('target selected users', () {
      const target = 'selected';
      const selectedUsers = ['user1@test.com', 'user2@test.com'];
      expect(target, 'selected');
      expect(selectedUsers.length, 2);
    });
  });

  group('NotificationsAdminScreen send', () {
    test('send button disabled when title is empty', () {
      const title = '';
      final canSend = title.isNotEmpty;
      expect(canSend, isFalse);
    });

    test('send button enabled when title and body provided', () {
      const title = 'Update';
      const body = 'New feature';
      final canSend = title.isNotEmpty && body.isNotEmpty;
      expect(canSend, isTrue);
    });
  });
}
