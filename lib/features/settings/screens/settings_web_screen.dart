import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:retaillite/core/services/thermal_printer_service.dart';
import 'package:retaillite/core/services/payment_link_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:retaillite/router/app_router.dart';
import 'package:retaillite/shared/widgets/shop_logo_widget.dart';
import 'package:retaillite/shared/widgets/logout_dialog.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';

/// Settings tab enum
enum SettingsTab { general, account, hardware, billing }

class SettingsWebScreen extends ConsumerStatefulWidget {
  final String initialTab;

  const SettingsWebScreen({super.key, this.initialTab = 'general'});

  @override
  ConsumerState<SettingsWebScreen> createState() => _SettingsWebScreenState();
}

class _SettingsWebScreenState extends ConsumerState<SettingsWebScreen> {
  // Text controllers for editable fields
  late TextEditingController _shopNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _shopAddressController;
  late TextEditingController _emailController;
  late TextEditingController _upiIdController;

  // WiFi printer state (Windows only)
  late TextEditingController _wifiIpController;
  late TextEditingController _wifiPortController;
  bool _isWifiConnecting = false;

  // USB printer state (Windows only)
  List<String> _windowsPrinters = [];
  bool _isLoadingUsbPrinters = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _shopNameController = TextEditingController(text: user?.shopName ?? '');
    _ownerNameController = TextEditingController(text: user?.ownerName ?? '');
    _contactNumberController = TextEditingController(text: user?.phone ?? '');
    _shopAddressController = TextEditingController(text: user?.address ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _upiIdController = TextEditingController(text: PaymentLinkService.upiId);
    _upiIdController.addListener(_onUpiIdChanged);

    // WiFi/USB printer controllers (Windows only)
    _wifiIpController = TextEditingController(
      text: (!kIsWeb && Platform.isWindows)
          ? WifiPrinterService.getSavedIp()
          : '',
    );
    _wifiPortController = TextEditingController(
      text: (!kIsWeb && Platform.isWindows)
          ? WifiPrinterService.getSavedPort().toString()
          : '9100',
    );

    // Load USB printers on Windows
    if (!kIsWeb && Platform.isWindows && UsbPrinterService.isAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_loadWindowsPrinters());
      });
    }
  }

  void _onUpiIdChanged() {
    final id = _upiIdController.text.trim();
    PaymentLinkService.setUpiId(id);
    setState(() {});
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _contactNumberController.dispose();
    _shopAddressController.dispose();
    _emailController.dispose();
    _upiIdController.dispose();
    _wifiIpController.dispose();
    _wifiPortController.dispose();
    super.dispose();
  }

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
  bool _isUploadingProfileImage = false;

  // ─── WiFi Printer Methods (Windows) ───

  Future<void> _connectWifiPrinter() async {
    final ip = _wifiIpController.text.trim();
    final port = int.tryParse(_wifiPortController.text.trim()) ?? 9100;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a printer IP address')),
      );
      return;
    }

    setState(() => _isWifiConnecting = true);

    final success = await WifiPrinterService.connect(ip, port);

    if (success) {
      await WifiPrinterService.saveWifiPrinter(ip, port);
      ref
          .read(printerProvider.notifier)
          .connectPrinter('WiFi Printer', '$ip:$port');
    }

    if (mounted) {
      setState(() => _isWifiConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connected to $ip:$port'
                : 'Failed to connect to $ip:$port',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _disconnectWifiPrinter() async {
    await WifiPrinterService.disconnect();
    await ref.read(printerProvider.notifier).disconnectPrinter();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WiFi printer disconnected')),
      );
    }
  }

  // ─── USB Printer Methods (Windows) ───

  Future<void> _loadWindowsPrinters() async {
    setState(() => _isLoadingUsbPrinters = true);
    final printers = await UsbPrinterService.getWindowsPrinters();
    if (mounted) {
      setState(() {
        _windowsPrinters = printers;
        _isLoadingUsbPrinters = false;
      });
    }
  }

  Future<void> _selectUsbPrinter(String name) async {
    await UsbPrinterService.saveUsbPrinter(name);
    ref.read(printerProvider.notifier).connectPrinter('USB: $name', name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected USB printer: $name'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

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

  Future<void> _pickProfileImage() async {
    setState(() => _isUploadingProfileImage = true);
    try {
      final downloadUrl = await ImageService.pickAndUploadProfileImage();
      if (downloadUrl != null && mounted) {
        final success = await ref
            .read(authNotifierProvider.notifier)
            .updateProfileImage(downloadUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Profile picture updated!'
                    : 'Failed to update profile picture',
              ),
              backgroundColor: success ? AppColors.primary : AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploadingProfileImage = false);
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

  Future<void> _saveSettings() async {
    // Save UPI ID locally (always works)
    final upiId = _upiIdController.text.trim();
    if (upiId.isNotEmpty && PaymentLinkService.isValidUpiId(upiId)) {
      PaymentLinkService.setUpiId(upiId);
    }

    // Try to save shop info to Firebase
    bool success = false;
    String? errorDetail;
    try {
      success = await ref
          .read(authNotifierProvider.notifier)
          .updateShopInfo(
            shopName: _shopNameController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            phone: _contactNumberController.text.trim(),
            address: _shopAddressController.text.trim(),
            email: _emailController.text.trim(),
            upiId: upiId.isNotEmpty ? upiId : null,
          );
      if (!success) {
        errorDetail = 'updateShopInfo returned false';
      }
    } catch (e) {
      debugPrint('❌ _saveSettings error: $e');
      errorDetail = e.toString();
      success = false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Settings saved successfully!'
                : 'Saved locally. Cloud sync failed: ${errorDetail ?? "unknown"}',
          ),
          backgroundColor: success ? AppColors.primary : AppColors.warning,
          duration: Duration(seconds: success ? 3 : 6),
        ),
      );
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

  /// Build user profile avatar (separate from shop logo)
  Widget _buildUserProfileAvatar(String? imagePath, double radius) {
    if (_isUploadingProfileImage) {
      return CircleAvatar(
        radius: radius,
        child: SizedBox(
          width: radius,
          height: radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final hasImage = imagePath != null && imagePath.isNotEmpty;

    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).dividerColor,
        child: Icon(Icons.person, size: radius, color: Colors.grey),
      );
    }

    if (imagePath.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imagePath),
        backgroundColor: Theme.of(context).dividerColor,
        onBackgroundImageError: (_, _) {},
      );
    }

    // Fallback
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).dividerColor,
      child: Icon(Icons.person, size: radius, color: Colors.grey),
    );
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
      subtitle: 'Manage your personal profile and security preferences.',
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
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
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
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
          // Super Admin button (only visible to admins)
          if (ref.watch(isSuperAdminProvider))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Material(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => context.go('/super-admin'),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 20,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Super Admin',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () {
                showLogoutDialog(context, ref);
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
            onPressed: _saveSettings,
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
              _buildTextField(controller: _shopNameController),
              const SizedBox(height: 16),
              _responsiveFields([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Owner Name'),
                    _buildTextField(controller: _ownerNameController),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Contact Number'),
                    _buildTextField(controller: _contactNumberController),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              _buildFieldLabel('Shop Address'),
              _buildTextField(controller: _shopAddressController, maxLines: 2),
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
                          min: 0.85,
                          max: 1.15,
                          divisions: 2,
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

        // Notification Preferences
        _SectionCard(
          icon: Icons.notifications_active,
          iconColor: Colors.deepPurple,
          title: 'Notification Preferences',
          child: Column(
            children: [
              _buildNotifToggleRow(
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.orange,
                title: 'Low Stock Alerts',
                subtitle:
                    'Get notified when product stock falls below threshold',
                value:
                    ref.watch(currentUserProvider)?.settings.lowStockAlerts ??
                    true,
                onChanged: (v) => _toggleNotifPref('lowStockAlerts', v),
              ),
              const Divider(height: 24),
              _buildNotifToggleRow(
                icon: Icons.credit_card,
                iconColor: Colors.blue,
                title: 'Subscription Alerts',
                subtitle: 'Reminders before your subscription expires',
                value:
                    ref
                        .watch(currentUserProvider)
                        ?.settings
                        .subscriptionAlerts ??
                    true,
                onChanged: (v) => _toggleNotifPref('subscriptionAlerts', v),
              ),
              const Divider(height: 24),
              _buildNotifToggleRow(
                icon: Icons.bar_chart,
                iconColor: Colors.green,
                title: 'Daily Sales Summary',
                subtitle: 'Receive a summary of your daily sales at 9 PM',
                value:
                    ref.watch(currentUserProvider)?.settings.dailySummary ??
                    true,
                onChanged: (v) => _toggleNotifPref('dailySummary', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
    final profileImagePath = user?.profileImagePath;

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
                InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: _isUploadingProfileImage ? null : _pickProfileImage,
                  child: Stack(
                    children: [
                      _buildUserProfileAvatar(profileImagePath, 40),
                      if (!_isUploadingProfileImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).cardColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                  _buildTextField(controller: _ownerNameController),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Email Address'),
                  _buildTextField(controller: _emailController, enabled: false),
                ],
              ),
            ]),
          ],
        ),
      ),

      // Verification Status
      _SectionCard(
        icon: Icons.verified_user,
        iconColor: AppColors.success,
        title: 'Verification Status',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Firebase UID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'UID: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      user?.id ?? '—',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Phone verification row
            _buildVerificationRow(
              icon: Icons.phone_android,
              label: 'Phone Number',
              value: user?.phone ?? '—',
              isVerified: user?.phoneVerified ?? false,
              verifiedAt: user?.phoneVerifiedAt,
            ),
            const Divider(height: 24),

            // Email verification row
            _buildVerificationRow(
              icon: Icons.email_outlined,
              label: 'Email Address',
              value: user?.email ?? '—',
              isVerified: user?.emailVerified ?? false,
            ),
          ],
        ),
      ),
    ];

    final rightChildren = <Widget>[];

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
              color:
                  (printerState.printerType.isThermal
                          ? (printerState.isConnected
                                ? AppColors.success
                                : AppColors.error)
                          : AppColors.info)
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              printerState.printerType == PrinterTypeOption.system
                  ? 'System Print Dialog'
                  : printerState.isConnected
                  ? 'Connected'
                  : 'Not Connected',
              style: TextStyle(
                color: printerState.printerType == PrinterTypeOption.system
                    ? AppColors.info
                    : printerState.isConnected
                    ? AppColors.success
                    : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Printer type info
              _buildFieldLabel('Printer Type'),
              const SizedBox(height: 8),
              if (!kIsWeb && Platform.isWindows) ...[
                // On Windows desktop: show selectable printer type options
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildToggleChip(
                      '🖥️ System',
                      printerState.printerType == PrinterTypeOption.system,
                      onTap: () => ref
                          .read(printerProvider.notifier)
                          .setPrinterType(PrinterTypeOption.system),
                    ),
                    _buildToggleChip(
                      '📶 WiFi',
                      printerState.printerType == PrinterTypeOption.wifi,
                      onTap: () => ref
                          .read(printerProvider.notifier)
                          .setPrinterType(PrinterTypeOption.wifi),
                    ),
                    _buildToggleChip(
                      '🔌 USB',
                      printerState.printerType == PrinterTypeOption.usb,
                      onTap: () => ref
                          .read(printerProvider.notifier)
                          .setPrinterType(PrinterTypeOption.usb),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  printerState.printerType.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),

                // WiFi Printer Configuration
                if (printerState.printerType == PrinterTypeOption.wifi) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        color: WifiPrinterService.isConnected
                            ? AppColors.success
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        WifiPrinterService.isConnected
                            ? 'Connected: ${WifiPrinterService.connectedAddress}'
                            : 'Enter printer IP and port',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: WifiPrinterService.isConnected
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _wifiIpController,
                          decoration: const InputDecoration(
                            labelText: 'IP Address',
                            hintText: '192.168.1.100',
                            isDense: true,
                            prefixIcon: Icon(Icons.router, size: 20),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _wifiPortController,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '9100',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isWifiConnecting
                              ? null
                              : _connectWifiPrinter,
                          icon: _isWifiConnecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.link),
                          label: Text(
                            _isWifiConnecting ? 'Connecting...' : 'Connect',
                          ),
                        ),
                      ),
                      if (WifiPrinterService.isConnected) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _disconnectWifiPrinter,
                          icon: const Icon(Icons.link_off),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // USB Printer Configuration
                if (printerState.printerType == PrinterTypeOption.usb) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.usb,
                        color:
                            UsbPrinterService.getSavedPrinterName().isNotEmpty
                            ? AppColors.success
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          UsbPrinterService.getSavedPrinterName().isNotEmpty
                              ? 'Selected: ${UsbPrinterService.getSavedPrinterName()}'
                              : 'Select a printer from the list',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                UsbPrinterService.getSavedPrinterName()
                                    .isNotEmpty
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _isLoadingUsbPrinters
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        onPressed: _isLoadingUsbPrinters
                            ? null
                            : _loadWindowsPrinters,
                        tooltip: 'Refresh printer list',
                      ),
                    ],
                  ),
                  if (_windowsPrinters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._windowsPrinters.map((name) {
                      final savedName = UsbPrinterService.getSavedPrinterName();
                      return ListTile(
                        leading: Icon(
                          Icons.print,
                          color: name == savedName ? AppColors.success : null,
                        ),
                        title: Text(name, style: const TextStyle(fontSize: 13)),
                        trailing: name == savedName
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              )
                            : TextButton(
                                onPressed: () => _selectUsbPrinter(name),
                                child: const Text('Select'),
                              ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                  ] else if (!_isLoadingUsbPrinters) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'No printers found. Click refresh to scan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ] else ...[
                // On web: show read-only printer type
                Text(
                  printerState.printerType.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  printerState.printerType.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Change printer type on the mobile app or desktop. Web uses the browser print dialog.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.info.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _responsiveFields([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Paper Width'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildToggleChip(
                          '58mm',
                          printerState.paperSizeIndex == 0,
                          onTap: () => ref
                              .read(printerProvider.notifier)
                              .setPaperSize(0),
                        ),
                        const SizedBox(width: 8),
                        _buildToggleChip(
                          '80mm',
                          printerState.paperSizeIndex == 1,
                          onTap: () => ref
                              .read(printerProvider.notifier)
                              .setPaperSize(1),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Font Size'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...PrinterFontSize.values.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildToggleChip(
                              f.label,
                              printerState.fontSizeIndex == f.value,
                              onTap: () => ref
                                  .read(printerProvider.notifier)
                                  .setFontSize(f.value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),

              // Auto-print toggle
              _buildPreferenceToggle(
                'Auto-Print Receipts',
                'Automatically print receipt after completing a bill.',
                printerState.autoPrint,
                onChanged: (v) =>
                    ref.read(printerProvider.notifier).setAutoPrint(v),
              ),
              const SizedBox(height: 16),

              // Receipt Footer
              _buildFieldLabel('Receipt Footer'),
              const SizedBox(height: 8),
              _buildTextField(
                value: printerState.receiptFooter.isEmpty
                    ? 'Thank you for shopping!'
                    : printerState.receiptFooter,
                onChanged: (v) =>
                    ref.read(printerProvider.notifier).setReceiptFooter(v),
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
                                "If your hardware isn't connecting, try restarting the Tulasi Stores app or re-pairing your Bluetooth device.",
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
                        // Save to user settings (not yet implemented)
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

        // UPI Payment Setup
        _SectionCard(
          icon: Icons.account_balance_wallet,
          iconColor: AppColors.success,
          title: 'UPI Payment Setup',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Business UPI ID',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (PaymentLinkService.isValidUpiId(
                    _upiIdController.text.trim(),
                  ))
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
              _buildTextField(
                controller: _upiIdController,
                hint: 'e.g. myshop@ybl',
              ),
              const SizedBox(height: 8),

              // Validation feedback
              if (_upiIdController.text.trim().isNotEmpty &&
                  !PaymentLinkService.isValidUpiId(
                    _upiIdController.text.trim(),
                  ))
                const Row(
                  children: [
                    Icon(Icons.error_outline, size: 14, color: AppColors.error),
                    SizedBox(width: 4),
                    Text(
                      'Invalid format. Use: name@provider',
                      style: TextStyle(fontSize: 11, color: AppColors.error),
                    ),
                  ],
                ),

              // Setup guide
              InkWell(
                onTap: () => _showUpiGuideDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'How to get a Business UPI ID (free)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Auto-generated QR Code
              if (PaymentLinkService.isValidUpiId(
                _upiIdController.text.trim(),
              )) ...[
                const Text(
                  'Auto-Generated QR Code',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Print this or show on screen for customers to scan',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppShadows.small,
                      ),
                      child: QrImageView(
                        data: PaymentLinkService.generateUpiQrData(
                          upiId: _upiIdController.text.trim(),
                          payeeName: user?.shopName,
                        ),
                        size: 120,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _upiIdController.text.trim(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.shopName ?? 'Your Shop',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '₹0 per transaction — forever free',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (!PaymentLinkService.isValidUpiId(
                _upiIdController.text.trim(),
              )) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter your Business UPI ID above to auto-generate a QR code for invoices.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============ HELPER WIDGETS ============

  void _showUpiGuideDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Get Business UPI')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Business UPI gives you unlimited free transactions per day.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                '🥇 PhonePe Business (Recommended)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Download from Play Store / App Store'),
              const Text('• Enter PAN + link bank account'),
              const Text('• Setup time: ~5 minutes'),
              const Text('• Cost: ₹0 forever'),
              const SizedBox(height: 12),
              const Text(
                '🥈 Google Pay for Business',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Download from Play Store'),
              const Text('• Links to existing Google account'),
              const Text('• Setup time: ~10 minutes'),
              const Text('• Cost: ₹0 forever'),
              const SizedBox(height: 12),
              const Text(
                '🥉 BharatPe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Download from Play Store'),
              const Text('• Free QR stand delivered to shop'),
              const Text('• Setup time: ~15 minutes'),
              const Text('• Cost: ₹0 forever'),
              const SizedBox(height: 16),
              Text(
                'After setup, copy your Business UPI ID and paste it in settings.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Get font size label from scale value
  String _getFontSizeLabel(double scale) {
    if (scale <= 0.90) return 'Small';
    if (scale <= 1.05) return 'Compact';
    return 'Large';
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
    String? value,
    TextEditingController? controller,
    String? hint,
    bool obscure = false,
    int maxLines = 1,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller ?? TextEditingController(text: value ?? ''),
      obscureText: obscure,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
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
        title: const Text('About Tulasi Stores'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tulasi Stores',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text('Simple POS for Small Retailers'),
            SizedBox(height: 16),
            Text('© 2026 Tulasi Stores', style: TextStyle(color: Colors.grey)),
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

  Widget _buildVerificationRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isVerified,
    DateTime? verifiedAt,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isVerified
                ? AppColors.success.withAlpha(25)
                : AppColors.error.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isVerified
                  ? AppColors.success.withAlpha(80)
                  : AppColors.error.withAlpha(80),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVerified ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: isVerified ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                isVerified ? 'Verified' : 'Not Verified',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isVerified ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleChip(
    String label,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  Widget _buildPreferenceToggle(
    String title,
    String description,
    bool value, {
    String? badge,
    ValueChanged<bool>? onChanged,
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
          onChanged: onChanged ?? (v) {},
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildNotifToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
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
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Future<void> _toggleNotifPref(String key, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'settings.$key': value,
      });

      // Update local state
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final newSettings = switch (key) {
          'lowStockAlerts' => currentUser.settings.copyWith(
            lowStockAlerts: value,
          ),
          'subscriptionAlerts' => currentUser.settings.copyWith(
            subscriptionAlerts: value,
          ),
          'dailySummary' => currentUser.settings.copyWith(dailySummary: value),
          _ => currentUser.settings,
        };
        authNotifier.updateLocalUserSettings(newSettings);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
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
