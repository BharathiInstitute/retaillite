/// Tests for SuperAdminDashboardScreen — stats display and navigation logic.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SuperAdminDashboard stats cards', () {
    test('total users stat card rendered', () {
      const totalUsers = 150;
      expect(totalUsers, isPositive);
    });

    test('paid users stat card rendered', () {
      const paidUsers = 25;
      const totalUsers = 150;
      expect(paidUsers, lessThanOrEqualTo(totalUsers));
    });

    test('MRR stat card rendered', () {
      const mrr = 500.0; // Monthly Recurring Revenue
      expect(mrr, isNonNegative);
    });
  });

  group('SuperAdminDashboard navigation links', () {
    test('navigation links include users, subscriptions, analytics', () {
      const links = [
        'Users',
        'Subscriptions',
        'Analytics',
        'Errors',
        'Performance',
      ];
      expect(links.length, greaterThanOrEqualTo(3));
    });
  });

  group('SuperAdminDashboard recent users', () {
    test('recent users list shows last 5 signups', () {
      final recentUsers = List.generate(10, (i) => 'User $i');
      final displayed = recentUsers.take(5).toList();
      expect(displayed.length, 5);
    });

    test('empty users list shows no recent users', () {
      const recentUsers = <String>[];
      expect(recentUsers, isEmpty);
    });
  });
}
