/// Admin Shell — persistent sidebar for all super admin pages
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/shared/widgets/logout_dialog.dart';

/// Global key so child screens can open the admin drawer on mobile
final adminShellScaffoldKey = GlobalKey<ScaffoldState>();

class AdminShellScreen extends ConsumerWidget {
  final Widget child;
  const AdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = ResponsiveHelper.isDesktop(context);
    final currentPath = GoRouterState.of(context).matchedLocation;

    // Desktop: sidebar + content
    if (isWide) {
      return Row(
        children: [
          _buildSidebar(context, currentPath, ref),
          Expanded(child: child),
        ],
      );
    }

    // Mobile: drawer-based navigation
    return Scaffold(
      key: adminShellScaffoldKey,
      drawer: _buildDrawer(context, currentPath, ref),
      body: child,
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    String currentPath,
    WidgetRef ref,
  ) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Material(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // Admin branding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Super Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Full Access',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ..._navItems.map(
              (item) => _buildNavItem(
                context,
                item['icon'] as IconData,
                item['label'] as String,
                item['route'] as String,
                currentPath == item['route'],
              ),
            ),
            const Spacer(),
            // Back to store
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => context.go('/billing'),
                  icon: const Icon(Icons.store, size: 18),
                  label: const Text('Back to Store'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String currentPath, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          // Same branding header as sidebar
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  'Super Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Full Access',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _navItems.map((item) {
                final route = item['route'] as String;
                final isActive = currentPath == route;
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isActive ? Colors.deepPurple : Colors.grey.shade600,
                    size: 22,
                  ),
                  title: Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isActive
                          ? Colors.deepPurple
                          : Colors.grey.shade800,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isActive,
                  selectedTileColor: Colors.deepPurple.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // close drawer
                    context.go(route);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Back to store
          ListTile(
            leading: Icon(Icons.store, color: Colors.grey.shade700),
            title: const Text('Back to Store'),
            onTap: () {
              Navigator.of(context).pop();
              context.go('/billing');
            },
          ),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              showLogoutDialog(context, ref);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? Colors.deepPurple : Colors.grey.shade600,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.deepPurple : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        selected: isActive,
        selectedTileColor: Colors.deepPurple.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => context.go(route),
      ),
    );
  }

  static final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard', 'route': '/super-admin'},
    {'icon': Icons.people, 'label': 'Users', 'route': '/super-admin/users'},
    {
      'icon': Icons.credit_card,
      'label': 'Subscriptions',
      'route': '/super-admin/subscriptions',
    },
    {
      'icon': Icons.analytics,
      'label': 'Analytics',
      'route': '/super-admin/analytics',
    },
    {
      'icon': Icons.bug_report,
      'label': 'Errors',
      'route': '/super-admin/errors',
    },
    {
      'icon': Icons.speed,
      'label': 'Performance',
      'route': '/super-admin/performance',
    },
    {
      'icon': Icons.monetization_on,
      'label': 'User Costs',
      'route': '/super-admin/user-costs',
    },
    {
      'icon': Icons.admin_panel_settings,
      'label': 'Manage Admins',
      'route': '/super-admin/manage-admins',
    },
    {
      'icon': Icons.notifications,
      'label': 'Notifications',
      'route': '/super-admin/notifications',
    },
  ];
}
