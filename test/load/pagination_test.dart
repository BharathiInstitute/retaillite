import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/providers/paginated_provider.dart';
import 'package:retaillite/models/product_model.dart';
import '../helpers/test_factories.dart';

void main() {
  group('PaginatedNotifier', () {
    late PaginatedNotifier<ProductModel> notifier;

    test('first page loads N items', () async {
      final page1 = List.generate(
        50,
        (i) => makeProduct(id: 'p-$i', name: 'Product $i'),
      );

      notifier = PaginatedNotifier<ProductModel>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          return (page1, null);
        },
      );

      await notifier.loadInitial();

      expect(notifier.state.items.length, 50);
      expect(notifier.state.hasMore, true);
      expect(notifier.state.isLoading, false);
    });

    test('second page appends without duplicates', () async {
      final page1 = List.generate(
        50,
        (i) => makeProduct(id: 'p-$i', name: 'Product $i'),
      );
      final page2 = List.generate(
        30,
        (i) => makeProduct(id: 'p-${50 + i}', name: 'Product ${50 + i}'),
      );
      var callCount = 0;

      notifier = PaginatedNotifier<ProductModel>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          callCount++;
          if (callCount == 1) return (page1, null);
          return (page2, null);
        },
      );

      await notifier.loadInitial();
      await notifier.loadMore();

      expect(notifier.state.items.length, 80);
      // Verify no duplicates (all IDs unique)
      final ids = notifier.state.items.map((p) => p.id).toSet();
      expect(ids.length, 80);
      expect(notifier.state.hasMore, false); // 30 < 50
    });

    test('rapid page requests do not cause duplication', () async {
      final page = List.generate(
        50,
        (i) => makeProduct(id: 'p-$i', name: 'Product $i'),
      );

      notifier = PaginatedNotifier<ProductModel>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return (page, null);
        },
      );

      await notifier.loadInitial();

      // Fire multiple loadMore simultaneously — only first should execute
      final futures = [
        notifier.loadMore(),
        notifier.loadMore(),
        notifier.loadMore(),
      ];
      await Future.wait(futures);

      // Should have at most 100 items (first page + one loadMore)
      expect(notifier.state.items.length, lessThanOrEqualTo(100));
    });

    test('pagination with error sets error state', () async {
      notifier = PaginatedNotifier<ProductModel>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          throw Exception('Network error');
        },
      );

      await notifier.loadInitial();

      expect(notifier.state.error, contains('Network error'));
      expect(notifier.state.items, isEmpty);
    });

    test('refresh resets state and reloads', () async {
      final page = List.generate(
        25,
        (i) => makeProduct(id: 'p-$i', name: 'Product $i'),
      );

      notifier = PaginatedNotifier<ProductModel>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          return (page, null);
        },
      );

      await notifier.loadInitial();
      expect(notifier.state.items.length, 25);

      await notifier.refresh();
      expect(notifier.state.items.length, 25);
      expect(notifier.state.hasMore, false); // 25 < 50
    });

    test('loadMore is no-op when hasMore is false', () async {
      var fetchCount = 0;
      notifier = PaginatedNotifier<ProductModel>(
        fetcher: ({int pageSize = 50, DocumentSnapshot? startAfter}) async {
          fetchCount++;
          return (<ProductModel>[], null);
        },
      );

      await notifier.loadInitial();
      expect(fetchCount, 1);
      expect(notifier.state.hasMore, false); // 0 < 50

      await notifier.loadMore();
      expect(fetchCount, 1); // No additional fetch
    });
  });
}
