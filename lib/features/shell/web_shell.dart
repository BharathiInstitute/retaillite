import 'package:flutter/material.dart';
import 'package:retaillite/features/notifications/widgets/notification_bell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/core/utils/website_url.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/auth/widgets/demo_mode_banner.dart';
import 'package:retaillite/router/app_router.dart';
import 'package:retaillite/shared/widgets/shop_logo_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// User-toggled sidebar collapse state. null = auto (follow screen width)
final sidebarCollapsedProvider = StateProvider<bool?>((ref) => null);

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
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
                      // Header (hide for screens that have their own header)
                      if (!location.startsWith(AppRoutes.billing) &&
                          !location.startsWith(AppRoutes.khata) &&
                          !location.startsWith(AppRoutes.products) &&
                          !location.startsWith(AppRoutes.bills) &&
                          !location.startsWith(AppRoutes.dashboard))
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

  /// Build profile avatar that handles both URL and local file
  Widget _buildProfileAvatar(String? logoPath, double radius, bool isSelected) {
    final hasImage = logoPath != null && logoPath.isNotEmpty;

    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: isSelected ? AppColors.primary : Colors.grey,
        child: Icon(Icons.person, size: radius, color: Colors.white),
      );
    }

    if (logoPath.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(logoPath),
        backgroundColor: isSelected ? AppColors.primary : Colors.grey,
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: isSelected ? AppColors.primary : Colors.grey,
      child: Icon(Icons.person, size: radius, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Identify if we are in settings (since it might be outside standard index)
    final isSettings = currentPath.startsWith(AppRoutes.settings);
    final userToggle = ref.watch(sidebarCollapsedProvider);
    final autoCollapsed = MediaQuery.of(context).size.width < 800;
    final isCollapsed = userToggle ?? autoCollapsed;
    final sidebarWidth = isCollapsed
        ? 72.0
        : (ResponsiveHelper.isDesktopLarge(context) ? 280.0 : 240.0);

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 24),
            alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: isCollapsed
                ? ShopLogoWidget(logoPath: user?.shopLogoPath)
                : Row(
                    children: [
                      ShopLogoWidget(logoPath: user?.shopLogoPath),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          user?.shopName ?? 'Tulasi Stores',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),

          // Collapse / Expand toggle button
          Container(
            alignment: isCollapsed ? Alignment.center : Alignment.centerRight,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 16,
              vertical: 4,
            ),
            child: InkWell(
              onTap: () {
                ref.read(sidebarCollapsedProvider.notifier).state =
                    !isCollapsed;
              },
              borderRadius: BorderRadius.circular(6),
              child: Tooltip(
                message: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
              children: [
                _SidebarItem(
                  icon: Icons.point_of_sale_outlined,
                  label: 'POS',
                  isSelected: selectedIndex == 0,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemTapped(0),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Khata Ledger',
                  isSelected: selectedIndex == 1,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemTapped(1),
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  isSelected: selectedIndex == 2,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemTapped(2),
                ),
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 3,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemTapped(3),
                ),
                _SidebarItem(
                  icon: Icons.receipt_outlined,
                  label: 'Bills',
                  isSelected: selectedIndex == 4,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemTapped(4),
                ),

                const Divider(height: 32),

                // Notification bell — real-time unread badge
                if (isCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: NotificationBell(),
                  )
                else
                  _SidebarItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    isSelected: false,
                    isCollapsed: isCollapsed,
                    onTap: () => GoRouter.of(context).push('/notifications'),
                  ),

                // "Visit Website" — web only, hidden on Android/Windows
                if (showWebsiteLink)
                  _SidebarItem(
                    icon: Icons.language_rounded,
                    label: 'Visit Website',
                    isSelected: false,
                    isCollapsed: isCollapsed,
                    onTap: () {
                      launchUrl(
                        Uri.parse(websiteUrl),
                        webOnlyWindowName: '_self',
                      );
                    },
                  ),
              ],
            ),
          ),

          // User Profile Card (Bottom of Sidebar) - Navigates to Settings
          GestureDetector(
            onTap: () => context.go('/settings/general'),
            child: isCollapsed
                ? Tooltip(
                    message: 'Settings',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSettings
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSettings
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 22,
                        color: isSettings
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSettings
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isSettings
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        _buildProfileAvatar(
                          user?.profileImagePath,
                          16,
                          isSettings,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user?.ownerName ?? 'User',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Owner',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: isSettings
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
          ),

          // App branding footer
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Powered by Tulasi Stores',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
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
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isCollapsed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
              vertical: isCollapsed ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected && !isCollapsed
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: isCollapsed
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: label, child: item);
    }
    return item;
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
    } else if (currentPath.startsWith(AppRoutes.bills)) {
      title = 'Billing History';
      breadcrumb = 'Bills';
    } else if (currentPath.startsWith(AppRoutes.settings)) {
      title = 'System Settings';
      breadcrumb = 'Settings';
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '/',
                        style: TextStyle(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    Text(
                      breadcrumb,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Header Actions — real notification bell
          const NotificationBell(),
        ],
      ),
    );
  }
}
