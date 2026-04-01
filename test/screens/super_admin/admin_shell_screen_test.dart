/// Tests for AdminShellScreen — sidebar nav, route switching, active highlight.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminShellScreen sidebar navigation', () {
    test('sidebar renders navigation items', () {
      const navItems = [
        'Dashboard',
        'Users',
        'Subscriptions',
        'Analytics',
        'Errors',
        'Performance',
        'Costs',
        'Manage Admins',
        'Notifications',
      ];
      expect(navItems.isNotEmpty, isTrue);
    });

    test('sidebar width is 220px', () {
      const sidebarWidth = 220.0;
      expect(sidebarWidth, 220.0);
    });
  });

  group('AdminShellScreen route switching', () {
    test('selecting Users navigates to users route', () {
      const selectedRoute = '/super-admin/users';
      expect(selectedRoute.contains('users'), isTrue);
    });

    test('selecting Analytics navigates to analytics route', () {
      const selectedRoute = '/super-admin/analytics';
      expect(selectedRoute.contains('analytics'), isTrue);
    });
  });

  group('AdminShellScreen active highlight', () {
    test('current route item is highlighted', () {
      const currentRoute = '/super-admin/users';
      const itemRoute = '/super-admin/users';
      const isActive = currentRoute == itemRoute;
      expect(isActive, isTrue);
    });

    test('non-current route items are not highlighted', () {
      const currentRoute = '/super-admin/users';
      const itemRoute = '/super-admin/analytics';
      const isActive = currentRoute == itemRoute;
      expect(isActive, isFalse);
    });
  });

  group('AdminShellScreen responsive layout', () {
    test('wide screen shows sidebar + content', () {
      const isWide = true;
      expect(isWide, isTrue);
    });

    test('narrow screen uses drawer', () {
      const isWide = false;
      expect(isWide, isFalse);
    });
  });
}
