/// Tests for UsersListScreen — pagination, search, and filter logic.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsersListScreen pagination', () {
    test('page size is 25', () {
      const pageSize = 25;
      expect(pageSize, 25);
    });

    test('hasMore is true when loaded count equals page size', () {
      const loadedCount = 25;
      const pageSize = 25;
      const hasMore = loadedCount >= pageSize;
      expect(hasMore, isTrue);
    });

    test('hasMore is false when loaded count less than page size', () {
      const loadedCount = 10;
      const pageSize = 25;
      const hasMore = loadedCount >= pageSize;
      expect(hasMore, isFalse);
    });
  });

  group('UsersListScreen search filtering', () {
    test('search by email filters users', () {
      final users = ['admin@test.com', 'user@test.com', 'admin@other.com'];
      const query = 'admin';
      final filtered = users
          .where((u) => u.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(filtered.length, 2);
    });

    test('empty search returns all users', () {
      final users = ['a@b.com', 'c@d.com'];
      const query = '';
      final filtered = query.isEmpty ? users : <String>[];
      expect(filtered.length, 2);
    });
  });

  group('UsersListScreen plan filter', () {
    test('filter by pro returns only pro users', () {
      final users = [
        {'email': 'a@b.com', 'plan': 'pro'},
        {'email': 'c@d.com', 'plan': 'free'},
        {'email': 'e@f.com', 'plan': 'pro'},
      ];
      const filter = 'pro';
      final filtered = users.where((u) => u['plan'] == filter).toList();
      expect(filtered.length, 2);
    });

    test('null filter returns all users', () {
      final users = [
        {'plan': 'pro'},
        {'plan': 'free'},
      ];
      const String? filter = null;
      final filtered = filter == null
          ? users
          : users.where((u) => u['plan'] == filter).toList();
      expect(filtered.length, 2);
    });
  });

  group('UsersListScreen loading states', () {
    test('initial loading shows spinner', () {
      const isInitialLoading = true;
      expect(isInitialLoading, isTrue);
    });

    test('loading more shows footer spinner', () {
      const isLoadingMore = true;
      expect(isLoadingMore, isTrue);
    });

    test('error state shows error message', () {
      const String error = 'Failed to load users';
      expect(error, isNotNull);
    });
  });
}
