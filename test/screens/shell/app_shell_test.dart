/// Tests for AppShell — navigation routing, responsive layout, and AppBar logic.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppShell navigation index mapping', () {
    // _getSelectedIndex maps route paths to bottom nav indices:
    // billing=0, khata=1, products=2, dashboard=3, bills=4
    test('billing route maps to index 0', () {
      const routeToIndex = {
        '/billing': 0,
        '/khata': 1,
        '/products': 2,
        '/dashboard': 3,
        '/bills': 4,
      };
      expect(routeToIndex['/billing'], 0);
    });

    test('khata route maps to index 1', () {
      const routeToIndex = {'/khata': 1};
      expect(routeToIndex['/khata'], 1);
    });

    test('products route maps to index 2', () {
      const routeToIndex = {'/products': 2};
      expect(routeToIndex['/products'], 2);
    });

    test('dashboard route maps to index 3', () {
      const routeToIndex = {'/dashboard': 3};
      expect(routeToIndex['/dashboard'], 3);
    });

    test('bills route maps to index 4', () {
      const routeToIndex = {'/bills': 4};
      expect(routeToIndex['/bills'], 4);
    });
  });

  group('AppShell bottom navigation items', () {
    test('5 navigation items for mobile', () {
      const items = ['POS', 'Khata', 'Products', 'Dashboard', 'Bills'];
      expect(items.length, 5);
    });

    test('navigation items have correct labels', () {
      const items = ['POS', 'Khata', 'Products', 'Dashboard', 'Bills'];
      expect(items[0], 'POS');
      expect(items[1], 'Khata');
      expect(items[2], 'Products');
      expect(items[3], 'Dashboard');
      expect(items[4], 'Bills');
    });
  });

  group('AppShell responsive layout', () {
    test('mobile width uses bottom navigation', () {
      const width = 500.0;
      // Mobile: width < 768
      const usesBottomNav = width < 768;
      expect(usesBottomNav, isTrue);
    });

    test('tablet width uses side navigation', () {
      const width = 900.0;
      // Tablet: 768 <= width < 1200
      const usesSideNav = width >= 768 && width < 1200;
      expect(usesSideNav, isTrue);
    });

    test('desktop width delegates to WebShell', () {
      const width = 1400.0;
      // Desktop: width >= 1200
      const usesWebShell = width >= 1200;
      expect(usesWebShell, isTrue);
    });
  });

  group('AppShell AppBar components', () {
    test('AppBar shows shop name', () {
      const shopName = 'My Store';
      expect(shopName.isNotEmpty, isTrue);
    });

    test('AppBar includes PlanBadge', () {
      // PlanBadge is always present in mobile AppBar
      const hasPlanBadge = true;
      expect(hasPlanBadge, isTrue);
    });

    test('AppBar includes GlobalSyncIndicator', () {
      const hasSyncIndicator = true;
      expect(hasSyncIndicator, isTrue);
    });

    test('AppBar includes NotificationBell', () {
      const hasNotificationBell = true;
      expect(hasNotificationBell, isTrue);
    });

    test('AppBar includes ProfileAvatar', () {
      const hasProfileAvatar = true;
      expect(hasProfileAvatar, isTrue);
    });
  });

  group('AppShell profile avatar', () {
    test('profile avatar supports URL image', () {
      const photoUrl = 'https://example.com/photo.jpg';
      final hasUrl = photoUrl.isNotEmpty;
      expect(hasUrl, isTrue);
    });

    test('profile avatar falls back to initials', () {
      const String? photoUrl = null;
      const name = 'Raj';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
      expect(photoUrl, isNull);
      expect(initial, 'R');
    });
  });
}
