import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/features/settings/providers/theme_settings_provider.dart';
import 'package:retaillite/models/theme_settings_model.dart';
import 'package:retaillite/core/services/sync_settings_service.dart';
import 'package:retaillite/core/services/image_service.dart';
import 'package:retaillite/core/design/design_system.dart';
import 'package:retaillite/router/app_router.dart';
import 'package:retaillite/shared/widgets/shop_logo_widget.dart';

/// Settings tab enum
enum SettingsTab { general, account, hardware, billing }

class SettingsWebScreen extends ConsumerStatefulWidget {
  final String initialTab;

  const SettingsWebScreen({super.key, this.initialTab = 'general'});

  @override
  ConsumerState<SettingsWebScreen> createState() => _SettingsWebScreenState();
}

class _SettingsWebScreenState extends ConsumerState<SettingsWebScreen> {
  SettingsTab get _selectedTab {
    switch (widget.initialTab) {
      case 'account':
        return SettingsTab.account;
      case 'hardware':
        return SettingsTab.hardware;
      case 'billing':
        return SettingsTab.billing;
      default:
        return SettingsTab.general;
    }
  }

  void _navigateToTab(SettingsTab tab) {
    context.go('/settings/${tab.name}');
  }

  bool _isSyncing = false;
  bool _isUploadingLogo = false;

  bool get _isMobileView =>
      ResponsiveHelper.isMobile(context) || ResponsiveHelper.isTablet(context);

  Future<void> _pickShopLogo() async {
    setState(() => _isUploadingLogo = true);
    try {
      final downloadUrl = await ImageService.pickAndUploadLogo();
      if (downloadUrl != null && mounted) {
        final success = await ref
            .read(authNotifierProvider.notifier)
            .updateShopLogo(downloadUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Shop logo updated!' : 'Failed to update logo',
              ),
              backgroundColor: success ? AppColors.primary : AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _removeShopLogo() async {
    setState(() => _isUploadingLogo = true);
    try {
      await ImageService.deleteLogoFromStorage();
      final success = await ref
          .read(authNotifierProvider.notifier)
          .updateShopLogo('');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Logo removed' : 'Failed to remove logo'),
            backgroundColor: success ? AppColors.primary : AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Widget _buildLogoPreview(String? logoPath) {
    if (_isUploadingLogo) {
      return const SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (logoPath != null && logoPath.isNotEmpty) {
      // If it's a URL (Firebase Storage), use Image.network
      if (logoPath.startsWith('http')) {
        // Add cache-buster to force reload after upload
        final separator = logoPath.contains('?') ? '&' : '?';
        final cacheBustedUrl =
            '$logoPath${separator}t=${DateTime.now().millisecondsSinceEpoch}';
        return Image.network(
          cacheBustedUrl,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, error, _) {
            debugPrint('Logo load error: $error');
            return const Icon(Icons.store, size: 28, color: Colors.grey);
          },
        );
      }
      // If it's a local file path (non-web)
      if (!kIsWeb) {
        final file = File(logoPath);
        if (file.existsSync()) {
          return Image.file(file, width: 64, height: 64, fit: BoxFit.cover);
        }
      }
    }
    return const Icon(Icons.store, size: 28, color: Colors.grey);
  }

  /// Two columns on desktop, stacked on mobile
  Widget _responsiveColumns(
    List<Widget> leftChildren,
    List<Widget> rightChildren, {
    double spacing = 24,
  }) {
    if (_isMobileView) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...leftChildren,
          SizedBox(height: spacing),
          ...rightChildren,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftChildren)),
        SizedBox(width: spacing),
        Expanded(child: Column(children: rightChildren)),
      ],
    );
  }

  /// Side-by-side fields on desktop, stacked on mobile
  Widget _responsiveFields(List<Widget> children, {double spacing = 16}) {
    if (_isMobileView) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children.expand((w) => [w, SizedBox(height: spacing)]).toList()
              ..removeLast(),
      );
    }
    return Row(
      children:
          children
              .expand((w) => [Expanded(child: w), SizedBox(width: spacing)])
              .toList()
            ..removeLast(),
    );
  }

  // Tab metadata
  static const _tabData = {
    SettingsTab.general: (
      icon: Icons.settings,
      label: 'General',
      title: 'General Settings',
      subtitle:
          'Manage your shop profile, business details, and customize your app branding.',
    ),
    SettingsTab.account: (
      icon: Icons.person,
      label: 'Account',
      title: 'Account Settings',
      subtitle:
          'Manage your personal profile, security preferences, and subscription plan.',
    ),
    SettingsTab.hardware: (
      icon: Icons.print,
      label: 'Hardware',
      title: 'System Settings',
      subtitle:
          'Configure your shop\'s hardware, cloud synchronization, and localized app preferences.',
    ),
    SettingsTab.billing: (
      icon: Icons.receipt_long,
      label: 'Billing',
      title: 'Invoice & Billing Settings',
      subtitle:
          'Customize your invoice appearance, tax rules, and digital payment integrations.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final tabInfo = _tabData[_selectedTab]!;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    if (isMobile || isTablet) {
      return _buildMobileLayout(tabInfo);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Top bar — mirrors the main app header
          _buildTopBar(),

          Expanded(
            child: Row(
              children: [
                // Side Navigation
                _buildSideNav(),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Header with breadcrumb
                      _buildHeader(tabInfo),

                      // Tab Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(
                            ResponsiveHelper.isTablet(context) ? 20 : 24,
                          ),
                          child: _buildTabContent(),
                        ),
                      ),
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

  /// Top bar with app branding + back arrow — consistent with main shell look
  Widget _buildTopBar() {
    final user = ref.watch(currentUserProvider);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back arrow
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => context.go(AppRoutes.billing),
            tooltip: 'Back to app',
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          // App icon / Store logo
          ShopLogoWidget(
            logoPath: user?.shopLogoPath,
            size: 30,
            borderRadius: 6,
            iconSize: 16,
          ),
          const SizedBox(width: 10),
          Text(
            user?.shopName ?? 'Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/ Settings',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const Spacer(),
          // Notification icon (for consistency)
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {},
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile layout with AppBar and drawer navigation
  Widget _buildMobileLayout(
    ({IconData icon, String label, String title, String subtitle}) tabInfo,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tabInfo.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
      ),
      body: Column(
        children: [
          // Tab selector chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SettingsTab.values.map((tab) {
                  final isSelected = tab == _selectedTab;
                  final data = _tabData[tab]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(data.label),
                      avatar: Icon(data.icon, size: 18),
                      selected: isSelected,
                      onSelected: (_) => _navigateToTab(tab),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 200,
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 4),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.outline,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...SettingsTab.values.map((tab) => _buildNavItem(tab)),
          const Spacer(),
          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () {
                ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Log Out'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(SettingsTab tab) {
    final isSelected = _selectedTab == tab;
    final data = _tabData[tab]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _navigateToTab(tab),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  data.icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  data.label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ({IconData icon, String label, String title, String subtitle}) tabInfo,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                Row(
                  children: [
                    Text(
                      'Home',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 13,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 13,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      tabInfo.label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  tabInfo.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tabInfo.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Save button
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Settings saved')));
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case SettingsTab.general:
        return _buildGeneralTab();
      case SettingsTab.account:
        return _buildAccountTab();
      case SettingsTab.hardware:
        return _buildHardwareTab();
      case SettingsTab.billing:
        return _buildBillingTab();
    }
  }

  // ============ GENERAL TAB ============
  Widget _buildGeneralTab() {
    final user = ref.watch(currentUserProvider);

    return _responsiveColumns(
      [
        // Shop Profile
        _SectionCard(
          icon: Icons.store,
          iconColor: AppColors.info,
          title: 'Shop Profile',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Logo
              _buildFieldLabel('Shop Logo'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.small,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildLogoPreview(user?.shopLogoPath),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isUploadingLogo
                                  ? null
                                  : () => _pickShopLogo(),
                              icon: _isUploadingLogo
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.upload, size: 16),
                              label: Text(
                                _isUploadingLogo ? 'Uploading...' : 'Upload',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _isUploadingLogo
                                  ? null
                                  : () => _removeShopLogo(),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '500×500px. JPG, PNG or SVG',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFieldLabel('Shop Name', required: true),
              _buildTextField(value: user?.shopName ?? ''),
              const SizedBox(height: 16),
              _responsiveFields([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Owner Name'),
                    _buildTextField(value: user?.ownerName ?? ''),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Contact Number'),
                    _buildTextField(value: user?.phone ?? ''),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              _buildFieldLabel('Shop Address'),
              _buildTextField(value: user?.address ?? '', maxLines: 2),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Business Details
        _SectionCard(
          icon: Icons.business,
          iconColor: AppColors.warning,
          title: 'Business Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('GST Number'),
              _buildTextField(
                value: user?.gstNumber ?? '',
                hint: '22AAAAA0000A1Z5',
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter GSTIN to enable tax invoicing.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              _responsiveFields([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Currency'),
                    _buildDropdown('Indian Rupee (₹)', [
                      'Indian Rupee (₹)',
                      'US Dollar (\$)',
                    ]),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Timezone'),
                    _buildDropdown('Asia/Kolkata (GMT+5:30)', [
                      'Asia/Kolkata (GMT+5:30)',
                    ]),
                  ],
                ),
              ]),
            ],
          ),
        ),
      ],
      [
        // App Branding & Theme
        _SectionCard(
          icon: Icons.palette,
          iconColor: const Color(0xFFEC4899),
          title: 'App Branding & Theme',
          child: Builder(
            builder: (context) {
              final themeSettings = ref.watch(themeSettingsProvider);
              final themeNotifier = ref.read(themeSettingsProvider.notifier);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Accent Color (connected to provider)
                  _buildFieldLabel('Brand Accent Color'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: ThemeSettingsModel.colorPresets.map((hex) {
                      final isSelected = hex == themeSettings.primaryColorHex;
                      final color = Color(
                        int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                      );
                      return GestureDetector(
                        onTap: () => themeNotifier.setPrimaryColor(hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Font Family
                  _buildFieldLabel('Font Family'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ThemeSettingsModel.fontPresets.map((font) {
                      final isSelected = font == themeSettings.fontFamily;
                      return ChoiceChip(
                        label: Text(font),
                        selected: isSelected,
                        onSelected: (_) => themeNotifier.setFontFamily(font),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Font Size
                  _buildFieldLabel('Font Size'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Aa', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: themeSettings.fontSizeScale,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          label: _getFontSizeLabel(themeSettings.fontSizeScale),
                          onChanged: (v) => themeNotifier.setFontSizeScale(v),
                        ),
                      ),
                      const Text('Aa', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  Text(
                    _getFontSizeLabel(themeSettings.fontSizeScale),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Theme Mode
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use System Theme',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Match your device settings',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: themeSettings.useSystemTheme,
                        onChanged: (v) => themeNotifier.setUseSystemTheme(v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (!themeSettings.useSystemTheme) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Enable dark appearance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: themeSettings.useDarkMode,
                          onChanged: (v) => themeNotifier.setDarkMode(v),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Quick Actions & Support
        _SectionCard(
          icon: Icons.flash_on,
          iconColor: const Color(0xFFF97316),
          title: 'Quick Actions & Support',
          child: Column(
            children: [
              _buildActionRow(
                'Backup Data',
                'Download a local copy of your shop data',
                Icons.download,
              ),
              const Divider(height: 24),
              _buildActionRow(
                'Reset Settings',
                'Restore default configuration',
                Icons.refresh,
              ),
              const Divider(height: 24),
              _buildClickableActionRow(
                'Help Center',
                'Get support and contact us',
                Icons.help_outline,
                () => _showHelpDialog(context),
              ),
              const Divider(height: 24),
              _buildClickableActionRow(
                'About',
                'Version 1.0.0',
                Icons.info_outline,
                () => _showAboutDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ ACCOUNT TAB ============
  Widget _buildAccountTab() {
    final user = ref.watch(currentUserProvider);

    final leftChildren = <Widget>[
      // User Profile
      _SectionCard(
        icon: Icons.person,
        iconColor: AppColors.info,
        title: 'User Profile',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).dividerColor,
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.ownerName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Owner',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _responsiveFields([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Full Name'),
                  _buildTextField(value: user?.ownerName ?? ''),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Email Address'),
                  _buildTextField(value: user?.email ?? ''),
                ],
              ),
            ]),
            const SizedBox(height: 24),
            const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _responsiveFields([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('New Password'),
                  _buildTextField(value: '••••••••', obscure: true),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Confirm Password'),
                  _buildTextField(value: '••••••••', obscure: true),
                ],
              ),
            ]),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Security
      _SectionCard(
        icon: Icons.security,
        iconColor: const Color(0xFFA855F7),
        title: 'Security',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication (2FA)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add an extra layer of security to your account by requiring a code from your phone in addition to your password.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: false,
                  onChanged: (v) => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Two-factor authentication requires additional setup through your account security settings',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Login History',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Login history feature - check your email for detailed security logs',
                      ),
                    ),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isMobileView)
              const Text(
                'Login history available on desktop view.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            else
              _buildLoginHistoryTable(),
          ],
        ),
      ),
    ];

    final rightChildren = <Widget>[
      _SectionCard(
        icon: Icons.star,
        iconColor: const Color(0xFFFBBF24),
        title: 'Subscription Plan',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CURRENT PLAN',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Standard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text('₹499 / month', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '22 Days remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Subscription renewal - please contact support or upgrade through settings',
                      ),
                    ),
                  ),
                  child: const Text(
                    'Renew now',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Plan Features',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildFeatureRow('Unlimited Invoices', true),
            _buildFeatureRow('Inventory Management', true),
            _buildFeatureRow('GST Reports', true),
            _buildFeatureRow('Multi-store Support', false),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Premium upgrade coming soon! Contact support for early access.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.rocket_launch, size: 18),
                label: const Text('Upgrade to Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Start your 14-day free trial of Premium',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    ];

    if (_isMobileView) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...leftChildren,
          const SizedBox(height: 24),
          ...rightChildren,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftChildren)),
        const SizedBox(width: 24),
        SizedBox(width: 320, child: Column(children: rightChildren)),
      ],
    );
  }

  // ============ HARDWARE TAB ============
  Widget _buildHardwareTab() {
    final printerState = ref.watch(printerProvider);

    return _responsiveColumns(
      [
        // Printer Settings
        _SectionCard(
          icon: Icons.print,
          iconColor: AppColors.info,
          title: 'Printer Settings',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Connected',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Select Printer'),
              _buildDropdown(
                printerState.printerName ?? 'Epson TM-T82 (Bluetooth)',
                ['Epson TM-T82 (Bluetooth)', 'None'],
              ),
              const SizedBox(height: 20),
              _responsiveFields([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Paper Width'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildToggleChip('58mm', false),
                        const SizedBox(width: 8),
                        _buildToggleChip('80mm', true),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Density'),
                    const SizedBox(height: 8),
                    Slider(
                      value: 0.7,
                      onChanged: (v) {},
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Test Print'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Barcode Scanner
        _SectionCard(
          icon: Icons.qr_code_scanner,
          iconColor: AppColors.warning,
          title: 'Barcode Scanner',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _responsiveFields([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Prefix'),
                    _buildTextField(value: 'None'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Suffix'),
                    _buildTextField(value: 'Enter (Return)'),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              const Text(
                'TEST CONFIGURATION',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Scan an item here to test...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scan test reset - ready for new scan'),
                        duration: Duration(seconds: 2),
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ],
          ),
        ),
      ],
      [
        // Cloud Synchronization
        _SectionCard(
          icon: Icons.cloud_sync,
          iconColor: AppColors.success,
          title: 'Cloud Synchronization',
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          'Up to date',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Last synced: Just now',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSyncing
                      ? null
                      : () async {
                          setState(() => _isSyncing = true);
                          await SyncSettingsService.syncNow();
                          if (mounted) setState(() => _isSyncing = false);
                        },
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: const Text('Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Sync Interval Selector
              _isMobileView
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sync Interval',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'How often to auto-sync data',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: AppShadows.small,
                          ),
                          child: DropdownButtonFormField<SyncInterval>(
                            isExpanded: true,
                            initialValue: SyncSettingsService.getSyncInterval(),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                            ),
                            items: SyncInterval.values.map((interval) {
                              return DropdownMenuItem(
                                value: interval,
                                child: Text(interval.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                SyncSettingsService.setSyncInterval(value);
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sync Interval',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'How often to auto-sync data',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 150),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: AppShadows.small,
                            ),
                            child: DropdownButtonFormField<SyncInterval>(
                              isExpanded: true,
                              initialValue:
                                  SyncSettingsService.getSyncInterval(),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: InputBorder.none,
                              ),
                              items: SyncInterval.values.map((interval) {
                                return DropdownMenuItem(
                                  value: interval,
                                  child: Text(interval.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  SyncSettingsService.setSyncInterval(value);
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // App Preferences
        _SectionCard(
          icon: Icons.tune,
          iconColor: AppColors.upi,
          title: 'App Preferences',
          child: Builder(
            builder: (context) {
              final appSettings = ref.watch(settingsProvider);
              final appSettingsNotifier = ref.read(settingsProvider.notifier);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Selector
                  _buildFieldLabel('Language'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppShadows.small,
                    ),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: appSettings.languageCode,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: InputBorder.none,
                      ),
                      items: AppLanguage.values.map((lang) {
                        return DropdownMenuItem(
                          value: lang.code,
                          child: Text(lang.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          appSettingsNotifier.setLanguage(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data Retention
                  _buildFieldLabel('Data Retention'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppShadows.small,
                    ),
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: appSettings.retentionDays,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: InputBorder.none,
                      ),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 days')),
                        DropdownMenuItem(value: 60, child: Text('60 days')),
                        DropdownMenuItem(value: 90, child: Text('90 days')),
                        DropdownMenuItem(value: 180, child: Text('180 days')),
                        DropdownMenuItem(value: 365, child: Text('1 year')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          appSettingsNotifier.setRetentionDays(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Existing toggles
                  _buildPreferenceToggle(
                    'Offline Mode',
                    'Continue billing even when the internet connection is lost. Data will sync automatically when back online.',
                    true,
                  ),
                  const SizedBox(height: 20),
                  _buildPreferenceToggle(
                    'Voice Input',
                    'Enable product search using voice commands. Supports English and Hindi (Hinglish).',
                    false,
                    badge: 'BETA',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Help?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "If your hardware isn't connecting, try restarting the RetailLite app or re-pairing your Bluetooth device.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ============ BILLING TAB ============
  Widget _buildBillingTab() {
    final user = ref.watch(currentUserProvider);

    return _responsiveColumns(
      [
        // Invoice Header
        _SectionCard(
          icon: Icons.receipt,
          iconColor: AppColors.info,
          title: 'Invoice Header',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppShadows.small,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 24, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          'Logo',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Shop Name'),
                        _buildTextField(
                          value: user?.shopName ?? 'Your Shop Name',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFieldLabel('Invoice Title'),
              _buildTextField(value: 'Tax Invoice'),
              const SizedBox(height: 16),
              _responsiveFields([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Address Line 1'),
                    _buildTextField(value: user?.address ?? 'Shop Address'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Contact Number'),
                    _buildTextField(value: user?.phone ?? ''),
                  ],
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tax Settings
        _SectionCard(
          icon: Icons.percent,
          iconColor: AppColors.warning,
          title: 'Tax Settings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable GST Billing',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Automatically calculate CGST/SGST based on rates.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: user?.settings.gstEnabled ?? true,
                      onChanged: (v) {
                        // TODO: Save to user settings
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _responsiveFields([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('GSTIN'),
                    _buildTextField(
                      value: user?.gstNumber ?? '',
                      hint: '22AAAAA0000A1Z5',
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Default Tax Rate'),
                    _buildDropdown(
                      '${(user?.settings.taxRate ?? 5.0).toStringAsFixed(0)}%',
                      ['5%', '12%', '18%', '28%'],
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(value: false, onChanged: (v) {}),
                  const Text('Prices are inclusive of tax'),
                ],
              ),
            ],
          ),
        ),
      ],
      [
        _SectionCard(
          icon: Icons.description,
          iconColor: AppColors.error,
          title: 'Terms & Conditions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Footer Text'),
              const SizedBox(height: 8),
              TextField(
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter terms and conditions...',
                  filled: true,
                ),
                controller: TextEditingController(
                  text:
                      '1. Goods once sold will not be taken back.\n2. Subject to local jurisdiction.\n3. Warranty as per manufacturer terms.',
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'This text will appear at the bottom of every printed invoice.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Digital Payment Setup
        _SectionCard(
          icon: Icons.payment,
          iconColor: AppColors.success,
          title: 'Digital Payment Setup',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'UPI QR Code',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppShadows.small,
                    ),
                    child: const Icon(Icons.qr_code_2, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(value: 'retailstore@upi'),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Generate New QR',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Razorpay Integration',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Switch(value: false, onChanged: (v) {}),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                value: '',
                hint: 'Key ID (rzp_live_...)',
                enabled: false,
              ),
              const SizedBox(height: 8),
              _buildTextField(value: '', hint: 'Key Secret', enabled: false),
              const SizedBox(height: 8),
              const Text(
                'Enable to send payment links via SMS/Email.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ HELPER WIDGETS ============

  /// Get font size label from scale value
  String _getFontSizeLabel(double scale) {
    if (scale <= 0.85) return 'Small';
    if (scale <= 0.95) return 'Compact';
    if (scale <= 1.05) return 'Normal';
    if (scale <= 1.15) return 'Large';
    if (scale <= 1.25) return 'Larger';
    return 'Extra Large';
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (required) const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String value,
    String? hint,
    bool obscure = false,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      obscureText: obscure,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items) {
    // Ensure value is in items list to prevent assertion error
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.small,
      ),
      child: DropdownButton<String>(
        value: safeValue,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {},
      ),
    );
  }

  Widget _buildActionRow(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(icon, color: AppColors.textSecondary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildClickableActionRow(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help Center'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: support@retaillite.com'),
            SizedBox(height: 8),
            Text('📞 Phone: +91 9876543210'),
            SizedBox(height: 8),
            Text('🕐 Mon-Sat: 9am - 6pm IST'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About RetailLite'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tulasi Shop Lite',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text('Simple POS for Small Retailers'),
            SizedBox(height: 16),
            Text('© 2026 RetailLite', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHistoryTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(),
      },
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Device',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Location',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Time',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        _buildLoginRow('Chrome on Windows', 'Mumbai, India', 'Just now', true),
        _buildLoginRow(
          'RetailLite Mobile App',
          'Mumbai, India',
          'Yesterday',
          false,
        ),
      ],
    );
  }

  TableRow _buildLoginRow(
    String device,
    String location,
    String time,
    bool isCurrent,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                device.contains('Mobile') ? Icons.phone_android : Icons.laptop,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(device, style: const TextStyle(fontSize: 13)),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(location, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            time,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(String feature, bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: included ? AppColors.success : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              decoration: included ? null : TextDecoration.lineThrough,
              color: included ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: AppColors.primary) : null,
        boxShadow: isSelected ? null : AppShadows.small,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPreferenceToggle(
    String title,
    String description,
    bool value, {
    String? badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (v) {},
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}

/// Section card widget
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
