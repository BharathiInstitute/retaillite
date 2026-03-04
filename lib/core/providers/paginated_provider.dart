/// Generic cursor-paginated provider infrastructure for Firestore collections.
///
/// Provides a reusable [PaginatedNotifier] that can load pages of any model
/// type using Firestore cursor pagination (startAfterDocument).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for a paginated list
@immutable
class PaginatedState<T> {
  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Signature for a paginated fetch function.
/// Returns a tuple of (items, lastDocument for next cursor).
typedef PaginatedFetcher<T> =
    Future<(List<T>, DocumentSnapshot?)> Function({
      int pageSize,
      DocumentSnapshot? startAfter,
    });

/// Generic paginated state notifier.
///
/// Usage:
/// ```dart
/// final provider = StateNotifierProvider<PaginatedNotifier<BillModel>, PaginatedState<BillModel>>(
///   (ref) => PaginatedNotifier(
///     fetcher: OfflineStorageService.fetchBillsPage,
///     pageSize: 50,
///   )..loadInitial(),
/// );
/// ```
class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginatedNotifier({required PaginatedFetcher<T> fetcher, this.pageSize = 50})
    : _fetcher = fetcher,
      super(const PaginatedState());

  final PaginatedFetcher<T> _fetcher;
  final int pageSize;
  DocumentSnapshot? _lastDocument;

  /// Load the first page (resets state)
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = PaginatedState<T>(isLoading: true);
    _lastDocument = null;

    try {
      final (items, lastDoc) = await _fetcher(
        pageSize: pageSize,
        startAfter: null,
      );
      _lastDocument = lastDoc;
      state = PaginatedState<T>(
        items: items,
        hasMore: items.length >= pageSize,
      );
    } catch (e) {
      state = PaginatedState<T>(error: e.toString());
    }
  }

  /// Load the next page (appends to existing items)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final (items, lastDoc) = await _fetcher(
        pageSize: pageSize,
        startAfter: _lastDocument,
      );
      _lastDocument = lastDoc;
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length >= pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Refresh (reload from scratch)
  Future<void> refresh() => loadInitial();
}
