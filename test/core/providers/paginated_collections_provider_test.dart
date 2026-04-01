import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/providers/paginated_provider.dart';
import 'package:retaillite/core/providers/paginated_collections_provider.dart';
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/models/product_model.dart';
import '../../helpers/test_factories.dart';

void main() {
  group('PaginatedCollectionsProvider', () {
    test('paginatedBillsProvider is autoDispose', () {
      // The provider should be auto-dispose to clean up when no longer listened
      expect(
        paginatedBillsProvider,
        isA<
          AutoDisposeStateNotifierProvider<
            PaginatedNotifier<BillModel>,
            PaginatedState<BillModel>
          >
        >(),
      );
    });

    test('paginatedExpensesProvider is autoDispose', () {
      expect(
        paginatedExpensesProvider,
        isA<
          AutoDisposeStateNotifierProvider<
            PaginatedNotifier<ExpenseModel>,
            PaginatedState<ExpenseModel>
          >
        >(),
      );
    });

    test('paginatedCustomersProvider is autoDispose', () {
      expect(
        paginatedCustomersProvider,
        isA<
          AutoDisposeStateNotifierProvider<
            PaginatedNotifier<CustomerModel>,
            PaginatedState<CustomerModel>
          >
        >(),
      );
    });

    test('paginatedProductsProvider is autoDispose', () {
      expect(
        paginatedProductsProvider,
        isA<
          AutoDisposeStateNotifierProvider<
            PaginatedNotifier<ProductModel>,
            PaginatedState<ProductModel>
          >
        >(),
      );
    });

    test('PaginatedState defaults are correct', () {
      const state = PaginatedState<ProductModel>();
      expect(state.items, isEmpty);
      expect(state.isLoading, false);
      expect(state.isLoadingMore, false);
      expect(state.hasMore, true);
      expect(state.error, isNull);
    });

    test('PaginatedState.copyWith preserves unset fields', () {
      final state = PaginatedState<ProductModel>(items: [makeProduct()]);
      final updated = state.copyWith(isLoadingMore: true);
      expect(updated.items.length, 1);
      expect(updated.isLoadingMore, true);
      expect(updated.hasMore, true);
    });
  });
}
