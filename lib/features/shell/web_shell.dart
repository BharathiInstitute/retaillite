import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/theme/web_theme.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/widgets/demo_mode_banner.dart';
import 'package:retaillite/router/app_router.dart';

class WebShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const WebShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current location for breadcrumbs/title
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: WebTheme.background,
      body: Column(
        children: [
          // Demo mode banner at the very top if active
          const DemoModeBanner(),

          Expanded(
            child: Row(
              children: [
                // Sidebar
                _WebSidebar(
                  selectedIndex: selectedIndex,
                  onItemTapped: onItemTapped,
                  currentPath: location,
                ),

                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      // Header (hide for billing which has its own nav)
                      if (!location.startsWith(AppRoutes.billing))
                        _WebHeader(currentPath: location),

                      // Content
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final String currentPath;

  const _WebSidebar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    // Identify if we are in settings (since it might be outside standard index)
    final isSettings = currentPath.startsWith(AppRoutes.settings);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: WebTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'RetailLite',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemTapped(3),
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemTapped(2),
                ),
                _SidebarItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Billing',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                ),
                // Khata Ledger
                _SidebarItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Khata Ledger',
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                ),

                const Divider(height: 32),
              ],
            ),
          ),

          // User Profile Card (Bottom of Sidebar) - Navigates to Settings
          GestureDetector(
            onTap: () => context.go(AppRoutes.settings),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSettings
                    ? WebTheme.primary.withValues(alpha: 0.1)
                    : WebTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: isSettings
                    ? Border.all(color: WebTheme.primary, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isSettings
                        ? WebTheme.primary
                        : Colors.grey,
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.ownerName ?? 'User',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: WebTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.shopName ?? 'Store Owner',
                          style: TextStyle(
                            fontSize: 12,
                            color: WebTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: isSettings ? WebTheme.primary : WebTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? WebTheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? WebTheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? WebTheme.primary : WebTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? WebTheme.primary
                        : WebTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebHeader extends StatelessWidget {
  final String currentPath;

  const _WebHeader({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    String title = 'Dashboard';
    String breadcrumb = 'Home';

    if (currentPath.startsWith(AppRoutes.billing)) {
      title = 'POS / Billing';
      breadcrumb = 'Billing';
    } else if (currentPath.startsWith(AppRoutes.products)) {
      title = 'Inventory Management';
      breadcrumb = 'Inventory';
    } else if (currentPath.startsWith(AppRoutes.dashboard)) {
      title = 'Dashboard';
      breadcrumb = 'Dashboard';
    } else if (currentPath.startsWith(AppRoutes.khata)) {
      title = 'Customer Ledger';
      breadcrumb = 'Khata';
    } else if (currentPath.startsWith(AppRoutes.settings)) {
      title = 'System Settings';
      breadcrumb = 'Settings';
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '/',
                        style: TextStyle(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    Text(
                      breadcrumb,
                      style: const TextStyle(
                        fontSize: 12,
                        color: WebTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Header Actions (optional)
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: WebTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
