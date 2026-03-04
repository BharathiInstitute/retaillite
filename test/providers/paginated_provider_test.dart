/// Tests for PaginatedProvider — PaginatedState and PaginatedNotifier
///
/// Tests state management, pagination logic with mock fetchers.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/providers/paginated_provider.dart';

void main() {
  // ── PaginatedState ──

  group('PaginatedState', () {
    test('default state is correct', () {
      const state = PaginatedState<String>();
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.error, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const state = PaginatedState<int>(items: [1, 2, 3], hasMore: false);
      final copy = state.copyWith(isLoading: true);
      expect(copy.items, [1, 2, 3]);
      expect(copy.hasMore, isFalse);
      expect(copy.isLoading, isTrue);
    });

    test('copyWith clears error when not specified', () {
      final state = const PaginatedState<String>().copyWith(error: 'oops');
      expect(state.error, 'oops');

      final cleared = state.copyWith();
      expect(cleared.error, isNull);
    });

    test('copyWith overrides items', () {
      const state = PaginatedState<int>(items: [1, 2]);
      final copy = state.copyWith(items: [3, 4, 5]);
      expect(copy.items, [3, 4, 5]);
    });
  });

  // ── PaginatedNotifier ──

  group('PaginatedNotifier', () {
    late PaginatedNotifier<String> notifier;
    late List<(List<String>, DocumentSnapshot?)> fetchResults;
    int fetchCallCount = 0;

    Future<(List<String>, DocumentSnapshot?)> mockFetcher({
      int pageSize = 50,
      DocumentSnapshot? startAfter,
    }) async {
      final result = fetchResults[fetchCallCount];
      fetchCallCount++;
      return result;
    }

    setUp(() {
      fetchCallCount = 0;
      fetchResults = [];
    });

    test('initial state before loadInitial', () {
      fetchResults = [([], null)];
      notifier = PaginatedNotifier<String>(fetcher: mockFetcher, pageSize: 2);
      expect(notifier.state.items, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    test('loadInitial loads first page', () async {
      fetchResults = [
        (['a', 'b'], null),
      ];
      notifier = PaginatedNotifier<String>(fetcher: mockFetcher, pageSize: 2);
      await notifier.loadInitial();
      expect(notifier.state.items, ['a', 'b']);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.hasMore, isTrue); // items.length == pageSize
    });

    test(
      'loadInitial with fewer items than pageSize sets hasMore=false',
      () async {
        fetchResults = [
          (['only_one'], null),
        ];
        notifier = PaginatedNotifier<String>(
          fetcher: mockFetcher,
          pageSize: 10,
        );
        await notifier.loadInitial();
        expect(notifier.state.items, ['only_one']);
        expect(notifier.state.hasMore, isFalse);
      },
    );

    test('loadInitial with empty result', () async {
      fetchResults = [(<String>[], null)];
      notifier = PaginatedNotifier<String>(fetcher: mockFetcher, pageSize: 10);
      await notifier.loadInitial();
      expect(notifier.state.items, isEmpty);
      expect(notifier.state.hasMore, isFalse);
    });

    test('loadMore appends to existing items', () async {
      fetchResults = [
        (['a', 'b'], null),
        (['c', 'd'], null),
      ];
      notifier = PaginatedNotifier<String>(fetcher: mockFetcher, pageSize: 2);
      await notifier.loadInitial();
      await notifier.loadMore();
      expect(notifier.state.items, ['a', 'b', 'c', 'd']);
    });

    test('loadMore does nothing when hasMore is false', () async {
      fetchResults = [
        (['a'], null), // Only 1 item with pageSize=2 → hasMore=false
      ];
      notifier = PaginatedNotifier<String>(fetcher: mockFetcher, pageSize: 2);
      await notifier.loadInitial();
      expect(notifier.state.hasMore, isFalse);

      await notifier.loadMore(); // Should be no-op
      expect(fetchCallCount, 1); // No additional fetch
    });

    test('loadInitial handles fetcher error', () async {
      notifier = PaginatedNotifier<String>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          throw Exception('Network error');
        },
        pageSize: 10,
      );
      await notifier.loadInitial();
      expect(notifier.state.error, contains('Network error'));
      expect(notifier.state.items, isEmpty);
    });

    test('loadMore handles fetcher error', () async {
      fetchResults = [
        (['a', 'b'], null),
      ];
      int callCount = 0;
      notifier = PaginatedNotifier<String>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          callCount++;
          if (callCount == 1) return (['a', 'b'], null);
          throw Exception('Failed');
        },
        pageSize: 2,
      );
      await notifier.loadInitial();
      await notifier.loadMore();
      expect(notifier.state.error, contains('Failed'));
      expect(notifier.state.items, ['a', 'b']); // Original items preserved
      expect(notifier.state.isLoadingMore, isFalse);
    });

    test('refresh reloads from scratch', () async {
      int callCount = 0;
      notifier = PaginatedNotifier<String>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          callCount++;
          if (callCount == 1) return (['a', 'b'], null);
          return (['x', 'y'], null);
        },
        pageSize: 2,
      );
      await notifier.loadInitial();
      expect(notifier.state.items, ['a', 'b']);

      await notifier.refresh();
      expect(notifier.state.items, ['x', 'y']);
    });
  });
}
