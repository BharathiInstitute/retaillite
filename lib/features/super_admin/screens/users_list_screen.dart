/// Users List Screen for Super Admin
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/super_admin/screens/admin_shell_screen.dart';
import 'package:retaillite/features/super_admin/models/admin_user_model.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';
import 'package:retaillite/features/super_admin/services/admin_firestore_service.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  static const int _pageSize = 25;

  final TextEditingController _searchController = TextEditingController();

  List<AdminUser> _users = [];
  DocumentSnapshot? _lastDoc;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  // Track which filters are currently loaded
  String _loadedSearch = '';
  SubscriptionPlan? _loadedPlan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_isLoadingMore && !reset) return;

    if (reset) {
      setState(() {
        _users = [];
        _lastDoc = null;
        _hasMore = true;
        _isInitialLoading = true;
        _error = null;
      });
    }

    final searchQuery = ref.read(usersSearchQueryProvider);
    final planFilter = ref.read(usersPlanFilterProvider);
    setState(() {
      _loadedSearch = searchQuery;
      _loadedPlan = planFilter;
      if (!reset) _isLoadingMore = true;
    });

    try {
      final page = await AdminFirestoreService.getAllUsers(
        limit: _pageSize,
        startAfter: reset ? null : _lastDoc,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
        planFilter: planFilter,
      );

      // getAllUsers returns a list but doesn't expose the last doc snapshot.
      // We need to fetch that separately via a raw query — grab it from the
      // service's raw snapshot by re-querying with the same params.
      DocumentSnapshot? newLastDoc;
      if (page.isNotEmpty) {
        // Re-query to get the raw DocumentSnapshot for cursor
        Query q = FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true);
        if (planFilter != null) {
          q = q.where('subscription.plan', isEqualTo: planFilter.name);
        }
        if (_lastDoc != null && !reset) q = q.startAfterDocument(_lastDoc!);
        q = q.limit(_pageSize);
        final raw = await q.get();
        if (raw.docs.isNotEmpty) {
          newLastDoc = raw.docs.last;
        }
      }

      if (!mounted) return;
      setState(() {
        if (reset) {
          _users = page;
        } else {
          _users = [..._users, ...page];
        }
        _lastDoc = newLastDoc;
        _hasMore = page.length == _pageSize;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onFiltersChanged() {
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(usersSearchQueryProvider);
    final planFilter = ref.watch(usersPlanFilterProvider);
    final isWide = MediaQuery.of(context).size.width >= 1024;

    // Reset when filters change
    if (searchQuery != _loadedSearch || planFilter != _loadedPlan) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onFiltersChanged());
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Users (${_users.length}${_hasMore ? '+' : ''})'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    adminShellScaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: cs.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, phone...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                        .read(usersSearchQueryProvider.notifier)
                                        .state =
                                    '';
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: cs.surface,
                    ),
                    onChanged: (value) {
                      ref.read(usersSearchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<SubscriptionPlan?>(
                    value: planFilter,
                    hint: const Text('All Plans'),
                    underline: const SizedBox(),
                    dropdownColor: cs.surface,
                    items: [
                      const DropdownMenuItem(child: Text('All Plans')),
                      ...SubscriptionPlan.values.map(
                        (plan) => DropdownMenuItem(
                          value: plan,
                          child: Text(plan.name.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(usersPlanFilterProvider.notifier).state = value;
                    },
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty || planFilter != null
                              ? 'No users match your filters'
                              : 'No users found',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : isWide
                ? _buildDataTable()
                : _buildUsersList(),
          ),

          // Load More footer
          if (!_isInitialLoading && _users.isNotEmpty) _buildLoadMoreFooter(),
        ],
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    final cs = Theme.of(context).colorScheme;
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.expand_more),
            label: Text('Load More (${_users.length} loaded)'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          'All ${_users.length} users loaded',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Shop Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Plan')),
            DataColumn(label: Text('Bills')),
            DataColumn(label: Text('Last Active')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _users
              .map(
                (user) => DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getPlanColor(
                              user.subscription.plan,
                            ),
                            radius: 16,
                            child: Text(
                              user.shopName.isNotEmpty
                                  ? user.shopName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.shopName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                user.ownerName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(user.email)),
                    DataCell(_buildPlanBadge(user.subscription.plan)),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.limits.billsThisMonth}/${user.limits.billsLimit}',
                          ),
                          SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              value: user.limits.usagePercentage,
                              backgroundColor: cs.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                user.limits.isNearLimit
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        user.activity.lastActiveAgo,
                        style: TextStyle(
                          color: user.activity.isActiveToday
                              ? Colors.green
                              : cs.onSurface.withValues(alpha: 0.6),
                          fontWeight: user.activity.isActiveToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () =>
                            context.go('/super-admin/users/${user.id}'),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final cs = Theme.of(context).colorScheme;
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPlanColor(user.subscription.plan),
              child: Text(
                user.shopName.isNotEmpty ? user.shopName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.shopName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildPlanBadge(user.subscription.plan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: user.limits.usagePercentage,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${user.limits.billsThisMonth}/${user.limits.billsLimit}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: user.activity.isActiveToday
                      ? Colors.green
                      : Colors.grey,
                ),
                Text(
                  user.activity.lastActiveAgo,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            onTap: () => context.go('/super-admin/users/${user.id}'),
          ),
        );
      },
    );
  }

  Widget _buildPlanBadge(SubscriptionPlan plan) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final planColor = _getPlanColor(plan);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: planColor.withValues(alpha: isDark ? 0.25 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: planColor),
          ),
          child: Text(
            plan.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? planColor.withValues(alpha: 0.9) : planColor,
            ),
          ),
        );
      },
    );
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Colors.grey;
      case SubscriptionPlan.pro:
        return Colors.blue;
      case SubscriptionPlan.business:
        return Colors.purple;
    }
  }
}
