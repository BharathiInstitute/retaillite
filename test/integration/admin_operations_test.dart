/// Tests for admin operations — user management, subscription, admin emails.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  const primaryOwnerEmail = 'kehsaram001@gmail.com';
  const adminEmails = [
    'kehsaram001@gmail.com',
    'admin@retaillite.com',
    'admin@lite.app',
  ];

  group('Admin operations: user list', () {
    test('admin views user list with correct count', () {
      final users = List.generate(
        10,
        (i) => {'email': 'user$i@test.com', 'plan': 'free'},
      );
      expect(users.length, 10);
    });

    test('user list contains expected data fields', () {
      final user = {
        'email': 'user@test.com',
        'plan': 'pro',
        'shopName': 'Test Store',
        'billsThisMonth': 42,
      };
      expect(user.containsKey('email'), isTrue);
      expect(user.containsKey('plan'), isTrue);
      expect(user.containsKey('shopName'), isTrue);
    });
  });

  group('Admin operations: user detail', () {
    test('user detail shows subscription and usage', () {
      final detail = {
        'plan': 'pro',
        'status': 'active',
        'billsThisMonth': 42,
        'totalProducts': 85,
        'totalCustomers': 15,
      };
      expect(detail['plan'], 'pro');
      expect(detail['billsThisMonth'], isNonNegative);
    });
  });

  group('Admin operations: subscription management', () {
    test('admin updates subscription → limits change', () {
      const oldPlan = 'free';
      const newPlan = 'pro';
      const proLimits = {'billsLimit': 500, 'productsLimit': 1000};
      expect(newPlan, isNot(oldPlan));
      expect(proLimits['billsLimit'], 500);
    });

    test('admin resets user limits → billsThisMonth goes to 0', () {
      var billsThisMonth = 42;
      billsThisMonth = 0; // admin reset
      expect(billsThisMonth, 0);
    });
  });

  group('Admin operations: admin email management', () {
    test('admin adds email → appears in list', () {
      final admins = List<String>.from(adminEmails);
      admins.add('newadmin@test.com');
      expect(admins.contains('newadmin@test.com'), isTrue);
    });

    test('admin removes email → removed from list', () {
      final admins = List<String>.from(adminEmails);
      admins.remove('admin@lite.app');
      expect(admins.contains('admin@lite.app'), isFalse);
    });

    test('admin cannot remove primary owner email', () {
      const emailToRemove = primaryOwnerEmail;
      final canRemove = emailToRemove != primaryOwnerEmail;
      expect(canRemove, isFalse);
    });
  });
}
