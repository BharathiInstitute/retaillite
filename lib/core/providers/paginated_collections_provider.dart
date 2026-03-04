/// Paginated providers for bills, expenses, and customers.
///
/// These providers use Firestore cursor pagination to load large collections
/// in pages of 50 items, supporting infinite scroll in list screens.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/providers/paginated_provider.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/products/providers/products_provider.dart'
    show fetchProductsPage;
import 'package:retaillite/models/bill_model.dart';
import 'package:retaillite/models/customer_model.dart';
import 'package:retaillite/models/expense_model.dart';
import 'package:retaillite/models/product_model.dart';

/// Paginated bills provider — loads 50 bills per page, sorted by createdAt desc
final paginatedBillsProvider =
    StateNotifierProvider.autoDispose<
      PaginatedNotifier<BillModel>,
      PaginatedState<BillModel>
    >((ref) {
      return PaginatedNotifier<BillModel>(
        fetcher: OfflineStorageService.fetchBillsPage,
      )..loadInitial();
    });

/// Paginated expenses provider — loads 50 expenses per page
final paginatedExpensesProvider =
    StateNotifierProvider.autoDispose<
      PaginatedNotifier<ExpenseModel>,
      PaginatedState<ExpenseModel>
    >((ref) {
      return PaginatedNotifier<ExpenseModel>(
        fetcher: OfflineStorageService.fetchExpensesPage,
      )..loadInitial();
    });

/// Paginated customers provider — loads 50 customers per page, sorted by name
final paginatedCustomersProvider =
    StateNotifierProvider.autoDispose<
      PaginatedNotifier<CustomerModel>,
      PaginatedState<CustomerModel>
    >((ref) {
      return PaginatedNotifier<CustomerModel>(
        fetcher: OfflineStorageService.fetchCustomersPage,
      )..loadInitial();
    });

/// Paginated products provider — loads 50 products per page, sorted by name
final paginatedProductsProvider =
    StateNotifierProvider.autoDispose<
      PaginatedNotifier<ProductModel>,
      PaginatedState<ProductModel>
    >((ref) {
      return PaginatedNotifier<ProductModel>(
        fetcher: fetchProductsPage,
      )..loadInitial();
    });
