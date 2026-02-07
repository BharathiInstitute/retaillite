/// Super Admin providers for state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/super_admin/services/admin_firestore_service.dart';

/// Super admin email whitelist
const List<String> superAdminEmails = [
  'kehsaram001@gmail.com',
  'admin@retaillite.com',
  'bharathiinstitute1@gmail.com',
  'bharahiinstitute1@gmail.com',
];

/// Check if current user is a super admin
final isSuperAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;

  if (user == null || user.email == null) return false;

  return superAdminEmails.contains(user.email!.toLowerCase().trim());
});

/// Dashboard statistics provider
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  return AdminFirestoreService.getAdminStats();
});

/// All users provider with pagination
final allUsersProvider =
    FutureProvider.family<List<AdminUser>, UsersQueryParams>((
      ref,
      params,
    ) async {
      return AdminFirestoreService.getAllUsers(
        limit: params.limit,
        searchQuery: params.searchQuery,
        planFilter: params.planFilter,
      );
    });

/// Simple all users provider (for initial load)
final usersListProvider = FutureProvider<List<AdminUser>>((ref) async {
  return AdminFirestoreService.getAllUsers(limit: 100);
});

/// Recent users for dashboard
final recentUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  return AdminFirestoreService.getRecentUsers(limit: 5);
});

/// Single user detail provider
final userDetailProvider = FutureProvider.family<AdminUser?, String>((
  ref,
  userId,
) async {
  return AdminFirestoreService.getUser(userId);
});

/// Expiring subscriptions provider
final expiringSubscriptionsProvider = FutureProvider<List<AdminUser>>((
  ref,
) async {
  return AdminFirestoreService.getExpiringSubscriptions(daysAhead: 7);
});

/// Query parameters for users list
class UsersQueryParams {
  final int limit;
  final String? searchQuery;
  final SubscriptionPlan? planFilter;

  const UsersQueryParams({this.limit = 100, this.searchQuery, this.planFilter});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsersQueryParams &&
        other.limit == limit &&
        other.searchQuery == searchQuery &&
        other.planFilter == planFilter;
  }

  @override
  int get hashCode => Object.hash(limit, searchQuery, planFilter);
}

/// Search query state
final usersSearchQueryProvider = StateProvider<String>((ref) => '');

/// Plan filter state
final usersPlanFilterProvider = StateProvider<SubscriptionPlan?>((ref) => null);

/// Filtered users provider (combines search and filter)
final filteredUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  final searchQuery = ref.watch(usersSearchQueryProvider);
  final planFilter = ref.watch(usersPlanFilterProvider);

  return AdminFirestoreService.getAllUsers(
    limit: 100,
    searchQuery: searchQuery.isEmpty ? null : searchQuery,
    planFilter: planFilter,
  );
});

/// Platform distribution stats provider
final platformStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return AdminFirestoreService.getPlatformStats();
});

/// Feature usage stats provider
final featureUsageProvider = FutureProvider<Map<String, double>>((ref) async {
  return AdminFirestoreService.getFeatureUsageStats();
});
