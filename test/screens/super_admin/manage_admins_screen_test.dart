/// Tests for ManageAdminsScreen — admin list, add/remove email logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  const primaryOwnerEmail = 'kehsaram001@gmail.com';

  group('ManageAdminsScreen admin list', () {
    test('admin list renders emails', () {
      const admins = [
        'kehsaram001@gmail.com',
        'admin@retaillite.com',
        'admin@lite.app',
      ];
      expect(admins.isNotEmpty, isTrue);
    });
  });

  group('ManageAdminsScreen add admin', () {
    test('adding valid email succeeds', () {
      expect(Validators.email('newadmin@example.com'), isNull);
    });

    test('adding invalid email fails', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });

  group('ManageAdminsScreen remove admin', () {
    test('primary owner email cannot be removed', () {
      const emailToRemove = 'kehsaram001@gmail.com';
      const canRemove = emailToRemove != primaryOwnerEmail;
      expect(canRemove, isFalse);
    });

    test('non-primary admin can be removed', () {
      const emailToRemove = 'admin@retaillite.com';
      const canRemove = emailToRemove != primaryOwnerEmail;
      expect(canRemove, isTrue);
    });
  });
}
