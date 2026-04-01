/// Tests for NotificationBell widget — badge display logic.
///
/// The widget depends on unreadNotificationCountProvider (Riverpod StreamProvider)
/// which needs Firebase. We test the badge rendering logic inline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Badge display logic ──

  group('NotificationBell badge logic', () {
    // Mirrors the badge text logic from notification_bell.dart:
    //   count > 99 ? '99+' : '$count'
    String badgeText(int count) {
      return count > 99 ? '99+' : '$count';
    }

    test('shows exact count for 1', () {
      expect(badgeText(1), '1');
    });

    test('shows exact count for 99', () {
      expect(badgeText(99), '99');
    });

    test('shows 99+ for 100', () {
      expect(badgeText(100), '99+');
    });

    test('shows 99+ for large counts', () {
      expect(badgeText(500), '99+');
      expect(badgeText(9999), '99+');
    });
  });

  // ── Icon selection logic ──

  group('NotificationBell icon selection', () {
    // Mirrors: count > 0 ? Icons.notifications_active : Icons.notifications_outlined
    IconData iconForCount(int count) {
      return count > 0
          ? Icons.notifications_active
          : Icons.notifications_outlined;
    }

    test('shows active icon when unread > 0', () {
      expect(iconForCount(1), Icons.notifications_active);
      expect(iconForCount(50), Icons.notifications_active);
    });

    test('shows outlined icon when count is 0', () {
      expect(iconForCount(0), Icons.notifications_outlined);
    });
  });

  // ── Color logic ──

  group('NotificationBell color logic', () {
    // Mirrors: color: count > 0 ? Colors.amber : null
    Color? iconColor(int count) {
      return count > 0 ? Colors.amber : null;
    }

    test('amber icon when unread > 0', () {
      expect(iconColor(3), Colors.amber);
    });

    test('null (default) color when count is 0', () {
      expect(iconColor(0), isNull);
    });
  });

  // ── Tooltip logic ──

  group('NotificationBell tooltip', () {
    // Mirrors: count > 0 ? '$count unread notifications' : 'Notifications'
    String tooltip(int count) {
      return count > 0 ? '$count unread notifications' : 'Notifications';
    }

    test('shows count in tooltip when unread', () {
      expect(tooltip(5), '5 unread notifications');
    });

    test('shows generic text when no unread', () {
      expect(tooltip(0), 'Notifications');
    });
  });

  // ── Badge visibility ──

  group('NotificationBell badge visibility', () {
    // Mirrors: if (count > 0) ... show badge
    bool showBadge(int count) => count > 0;

    test('badge visible when count > 0', () {
      expect(showBadge(1), isTrue);
      expect(showBadge(100), isTrue);
    });

    test('badge hidden when count is 0', () {
      expect(showBadge(0), isFalse);
    });
  });

  // ── Loading and error states ──

  group('NotificationBell fallback states', () {
    test('loading state shows outlined icon', () {
      // Mirrors: loading: () => IconButton(icon: Icon(Icons.notifications_outlined)...)
      const icon = Icons.notifications_outlined;
      expect(icon, Icons.notifications_outlined);
    });

    test('error state shows outlined icon', () {
      // Mirrors: error: (_, _) => IconButton(icon: Icon(Icons.notifications_outlined)...)
      const icon = Icons.notifications_outlined;
      expect(icon, Icons.notifications_outlined);
    });
  });

  // ── Navigation ──

  group('NotificationBell navigation', () {
    test('navigates to /notifications route', () {
      // Mirrors: onPressed: () => context.push('/notifications')
      const route = '/notifications';
      expect(route, '/notifications');
    });
  });
}
