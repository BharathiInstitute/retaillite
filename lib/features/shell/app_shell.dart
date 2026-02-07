/// Main app shell with responsive navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/constants/theme_constants.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/core/utils/color_utils.dart';
import 'package:retaillite/features/auth/widgets/demo_mode_banner.dart';
import 'package:retaillite/features/shell/web_shell.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/router/app_router.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/billing')) return 0;
    if (location.startsWith('/khata')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/dashboard')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.billing);
        break;
      case 1:
        context.go(AppRoutes.khata);
        break;
      case 2:
        context.go(AppRoutes.products);
        break;
      case 3:
        context.go(AppRoutes.dashboard);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndex(context);
    final deviceType = ResponsiveHelper.getDeviceType(context);

    // Use WebShell for Desktop/Web view
    if (deviceType == DeviceType.desktop) {
      return WebShell(
        selectedIndex: selectedIndex,
        onItemTapped: (index) => _onItemTapped(context, index),
        child: child,
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Demo mode banner
          const DemoModeBanner(),

          // Main content with navigation
          Expanded(
            child: Row(
              children: [
                // Side navigation for tablet (Desktop uses WebShell now)
                if (deviceType == DeviceType.tablet)
                  _buildSideNavigation(context, selectedIndex, deviceType),

                // Main content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: deviceType == DeviceType.mobile
          ? _buildBottomNavigation(context, selectedIndex)
          : null,
    );
  }

  Widget _buildBottomNavigation(BuildContext context, int selectedIndex) {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: OpacityColors.black10,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(context, index),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: l10n.billing,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: l10n.khata,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined),
              activeIcon: const Icon(Icons.inventory_2),
              label: l10n.products,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: const Icon(Icons.bar_chart),
              label: l10n.dashboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNavigation(
    BuildContext context,
    int selectedIndex,
    DeviceType deviceType,
  ) {
    final isExpanded = deviceType == DeviceType.desktop;
    final l10n = context.l10n;

    return Container(
      width: isExpanded ? 240 : 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: OpacityColors.black05,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 8,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'L',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    l10n.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.receipt_long,
                  label: l10n.billing,
                  isSelected: selectedIndex == 0,
                  isExpanded: isExpanded,
                  onTap: () => _onItemTapped(context, 0),
                ),
                _NavItem(
                  icon: Icons.people,
                  label: l10n.khata,
                  isSelected: selectedIndex == 1,
                  isExpanded: isExpanded,
                  onTap: () => _onItemTapped(context, 1),
                ),
                _NavItem(
                  icon: Icons.inventory_2,
                  label: l10n.products,
                  isSelected: selectedIndex == 2,
                  isExpanded: isExpanded,
                  onTap: () => _onItemTapped(context, 2),
                ),
                _NavItem(
                  icon: Icons.bar_chart,
                  label: l10n.dashboard,
                  isSelected: selectedIndex == 3,
                  isExpanded: isExpanded,
                  onTap: () => _onItemTapped(context, 3),
                ),
              ],
            ),
          ),

          // Settings at bottom
          const Divider(height: 1),
          _NavItem(
            icon: Icons.settings,
            label: l10n.settings,
            isSelected: false,
            isExpanded: isExpanded,
            onTap: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 8 : 4,
        vertical: 2,
      ),
      child: Material(
        color: isSelected ? OpacityColors.primary10 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 0),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondaryLight,
                  size: 24,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimaryLight,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
