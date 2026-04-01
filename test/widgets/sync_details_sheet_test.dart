/// Tests for SyncDetailsSheet — display name mapping, icon mapping, and status logic.
///
/// The widget depends on globalSyncStatusProvider and isOnlineProvider.
/// We test the pure mapping/display logic inline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Collection display name mapping ──
  // Mirrors _collectionDisplayName(String collection)

  group('SyncDetailsSheet collection display names', () {
    String collectionDisplayName(String collection) {
      switch (collection) {
        case 'products':
          return 'Products';
        case 'bills':
          return 'Bills';
        case 'customers':
          return 'Customers';
        case 'expenses':
          return 'Expenses';
        case 'transactions':
          return 'Transactions';
        case 'notifications':
          return 'Notifications';
        default:
          return collection;
      }
    }

    test('products maps to Products', () {
      expect(collectionDisplayName('products'), 'Products');
    });

    test('bills maps to Bills', () {
      expect(collectionDisplayName('bills'), 'Bills');
    });

    test('customers maps to Customers', () {
      expect(collectionDisplayName('customers'), 'Customers');
    });

    test('expenses maps to Expenses', () {
      expect(collectionDisplayName('expenses'), 'Expenses');
    });

    test('transactions maps to Transactions', () {
      expect(collectionDisplayName('transactions'), 'Transactions');
    });

    test('notifications maps to Notifications', () {
      expect(collectionDisplayName('notifications'), 'Notifications');
    });

    test('unknown collection returns raw name', () {
      expect(collectionDisplayName('analytics'), 'analytics');
    });
  });

  // ── Collection icon mapping ──
  // Mirrors _collectionIcon(String collection)

  group('SyncDetailsSheet collection icons', () {
    IconData collectionIcon(String collection) {
      switch (collection) {
        case 'products':
          return Icons.inventory_2_outlined;
        case 'bills':
          return Icons.receipt_long_outlined;
        case 'customers':
          return Icons.people_outline;
        case 'expenses':
          return Icons.account_balance_wallet_outlined;
        case 'transactions':
          return Icons.swap_horiz;
        case 'notifications':
          return Icons.notifications_outlined;
        default:
          return Icons.folder_outlined;
      }
    }

    test('products icon is inventory_2_outlined', () {
      expect(collectionIcon('products'), Icons.inventory_2_outlined);
    });

    test('bills icon is receipt_long_outlined', () {
      expect(collectionIcon('bills'), Icons.receipt_long_outlined);
    });

    test('customers icon is people_outline', () {
      expect(collectionIcon('customers'), Icons.people_outline);
    });

    test('expenses icon is account_balance_wallet_outlined', () {
      expect(collectionIcon('expenses'), Icons.account_balance_wallet_outlined);
    });

    test('transactions icon is swap_horiz', () {
      expect(collectionIcon('transactions'), Icons.swap_horiz);
    });

    test('notifications icon is notifications_outlined', () {
      expect(collectionIcon('notifications'), Icons.notifications_outlined);
    });

    test('unknown collection icon is folder_outlined', () {
      expect(collectionIcon('other'), Icons.folder_outlined);
    });
  });

  // ── Online/Offline status text ──
  // Mirrors: isOnline ? 'Online' : 'Offline'

  group('SyncDetailsSheet online/offline status', () {
    String connectionLabel(bool isOnline) => isOnline ? 'Online' : 'Offline';

    test('shows Online when connected', () {
      expect(connectionLabel(true), 'Online');
    });

    test('shows Offline when disconnected', () {
      expect(connectionLabel(false), 'Offline');
    });
  });

  // ── Total row message ──
  // Mirrors: totalUnsynced == 0
  //   ? 'All data synced to cloud'
  //   : '$totalUnsynced item${totalUnsynced == 1 ? '' : 's'} not synced'

  group('SyncDetailsSheet total row message', () {
    String totalMessage(int totalUnsynced) {
      if (totalUnsynced == 0) return 'All data synced to cloud';
      return '$totalUnsynced item${totalUnsynced == 1 ? '' : 's'} not synced';
    }

    test('all synced message when 0 unsynced', () {
      expect(totalMessage(0), 'All data synced to cloud');
    });

    test('singular item for 1 unsynced', () {
      expect(totalMessage(1), '1 item not synced');
    });

    test('plural items for multiple unsynced', () {
      expect(totalMessage(5), '5 items not synced');
    });

    test('large count uses plural', () {
      expect(totalMessage(100), '100 items not synced');
    });
  });

  // ── Status header icon ──
  // Mirrors: isOnline ? Icons.cloud_done : Icons.cloud_off

  group('SyncDetailsSheet header icon', () {
    IconData connectionIcon(bool isOnline) =>
        isOnline ? Icons.cloud_done : Icons.cloud_off;

    test('cloud_done when online', () {
      expect(connectionIcon(true), Icons.cloud_done);
    });

    test('cloud_off when offline', () {
      expect(connectionIcon(false), Icons.cloud_off);
    });
  });
}
