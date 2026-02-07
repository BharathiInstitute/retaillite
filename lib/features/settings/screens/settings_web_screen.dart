import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/core/services/sync_settings_service.dart';
import 'package:retaillite/core/theme/web_theme.dart';
import 'package:retaillite/router/app_router.dart';

/// Settings tab enum
enum SettingsTab { general, account, hardware, billing }

class SettingsWebScreen extends ConsumerStatefulWidget {
  const SettingsWebScreen({super.key});

  @override
  ConsumerState<SettingsWebScreen> createState() => _SettingsWebScreenState();
}

class _SettingsWebScreenState extends ConsumerState<SettingsWebScreen> {
  SettingsTab _selectedTab = SettingsTab.general;
  bool _isSyncing = false;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
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
                    padding: const EdgeInsets.all(24),
                    child: _buildTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: TextButton.icon(
              onPressed: () => context.go(AppRoutes.dashboard),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: WebTheme.textSecondary,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
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
                foregroundColor: WebTheme.textSecondary,
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
        color: isSelected ? WebTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _selectedTab = tab),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  data.icon,
                  size: 20,
                  color: isSelected ? Colors.white : WebTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  data.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : WebTheme.textPrimary,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
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
                      style: TextStyle(color: WebTheme.textMuted, fontSize: 13),
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
                      style: TextStyle(color: WebTheme.textMuted, fontSize: 13),
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
                      style: const TextStyle(
                        color: WebTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  tabInfo.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tabInfo.subtitle,
                  style: TextStyle(fontSize: 14, color: WebTheme.textSecondary),
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
              backgroundColor: const Color(0xFF1E293B),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              // Shop Profile
              _SectionCard(
                icon: Icons.store,
                iconColor: const Color(0xFF3B82F6),
                title: 'Shop Profile',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Shop Name', required: true),
                    _buildTextField(value: user?.shopName ?? ''),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Owner Name'),
                              _buildTextField(value: user?.ownerName ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Contact Number'),
                              _buildTextField(value: user?.phone ?? ''),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                iconColor: const Color(0xFFF59E0B),
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
                    Text(
                      'Enter GSTIN to enable tax invoicing.',
                      style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Currency'),
                              _buildDropdown('Indian Rupee (₹)', [
                                'Indian Rupee (₹)',
                                'US Dollar (\$)',
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Timezone'),
                              _buildDropdown('Asia/Kolkata (GMT+5:30)', [
                                'Asia/Kolkata (GMT+5:30)',
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column
        Expanded(
          child: Column(
            children: [
              // App Branding
              _SectionCard(
                icon: Icons.palette,
                iconColor: const Color(0xFFEC4899),
                title: 'App Branding',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Shop Logo'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(
                            Icons.store,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E293B),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text('Upload New'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {},
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Recommended size: 500×500px. JPG, PNG or SVG allowed.',
                              style: TextStyle(
                                fontSize: 11,
                                color: WebTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFieldLabel('Brand Accent Color'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildColorCircle(const Color(0xFF22C55E), true),
                        _buildColorCircle(const Color(0xFF3B82F6), false),
                        _buildColorCircle(const Color(0xFFA855F7), false),
                        _buildColorCircle(const Color(0xFFEF4444), false),
                        _buildColorCircle(const Color(0xFFF97316), false),
                        _buildColorCircle(const Color(0xFF1E293B), false),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'CUSTOM HEX',
                          style: TextStyle(
                            fontSize: 11,
                            color: WebTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: WebTheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '#13ec5b',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              _SectionCard(
                icon: Icons.flash_on,
                iconColor: const Color(0xFFF97316),
                title: 'Quick Actions',
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
                  ],
                ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              // User Profile
              _SectionCard(
                icon: Icons.person,
                iconColor: const Color(0xFF3B82F6),
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
                              backgroundColor: const Color(0xFFF1F5F9),
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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
                              style: TextStyle(color: WebTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Full Name'),
                              _buildTextField(value: user?.ownerName ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Email Address'),
                              _buildTextField(value: user?.email ?? ''),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('New Password'),
                              _buildTextField(value: '••••••••', obscure: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Confirm Password'),
                              _buildTextField(value: '••••••••', obscure: true),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Two-Factor Authentication (2FA)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add an extra layer of security to your account by requiring a code from your phone in addition to your password.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: WebTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(value: false, onChanged: (v) {}),
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
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLoginHistoryTable(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column
        SizedBox(
          width: 320,
          child: _SectionCard(
            icon: Icons.star,
            iconColor: const Color(0xFFFBBF24),
            title: 'Subscription Plan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CURRENT PLAN',
                      style: TextStyle(
                        fontSize: 11,
                        color: WebTheme.textMuted,
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
                          color: Color(0xFF22C55E),
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
                const Text(
                  '₹499 / month',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '22 Days remaining',
                      style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
                    ),
                    TextButton(
                      onPressed: () {},
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
                    onPressed: () {},
                    icon: const Icon(Icons.rocket_launch, size: 18),
                    label: const Text('Upgrade to Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Start your 14-day free trial of Premium',
                    style: TextStyle(fontSize: 11, color: WebTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============ HARDWARE TAB ============
  Widget _buildHardwareTab() {
    final printerState = ref.watch(printerProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              // Printer Settings
              _SectionCard(
                icon: Icons.print,
                iconColor: const Color(0xFF3B82F6),
                title: 'Printer Settings',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Connected',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
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
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Density'),
                              const SizedBox(height: 8),
                              Slider(
                                value: 0.7,
                                onChanged: (v) {},
                                activeColor: WebTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                iconColor: const Color(0xFFF59E0B),
                title: 'Barcode Scanner',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Prefix'),
                              _buildTextField(value: 'None'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Suffix'),
                              _buildTextField(value: 'Enter (Return)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'TEST CONFIGURATION',
                      style: TextStyle(
                        fontSize: 11,
                        color: WebTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Scan an item here to test...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column
        Expanded(
          child: Column(
            children: [
              // Cloud Synchronization
              _SectionCard(
                icon: Icons.cloud_sync,
                iconColor: const Color(0xFF22C55E),
                title: 'Cloud Synchronization',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Color(0xFF22C55E),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sync Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WebTheme.textMuted,
                                ),
                              ),
                              const Text(
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
                                  color: WebTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'PENDING',
                              style: TextStyle(
                                fontSize: 10,
                                color: WebTheme.textMuted,
                              ),
                            ),
                            const Text(
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
                                color: WebTheme.textMuted,
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
                          backgroundColor: WebTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App Preferences
              _SectionCard(
                icon: Icons.tune,
                iconColor: const Color(0xFF6366F1),
                title: 'App Preferences',
                child: Column(
                  children: [
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
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
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
                                    color: WebTheme.textSecondary,
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ BILLING TAB ============
  Widget _buildBillingTab() {
    final user = ref.watch(currentUserProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              // Invoice Header
              _SectionCard(
                icon: Icons.receipt,
                iconColor: const Color(0xFF3B82F6),
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
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt,
                                size: 24,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Logo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: WebTheme.textMuted,
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Address Line 1'),
                              _buildTextField(
                                value: user?.address ?? 'Shop Address',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Contact Number'),
                              _buildTextField(value: user?.phone ?? ''),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tax Settings
              _SectionCard(
                icon: Icons.percent,
                iconColor: const Color(0xFFF59E0B),
                title: 'Tax Settings',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enable GST Billing',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Automatically calculate CGST/SGST based on rates.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: WebTheme.textSecondary,
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
                            activeThumbColor: WebTheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('GSTIN'),
                              _buildTextField(
                                value: user?.gstNumber ?? '',
                                hint: '22AAAAA0000A1Z5',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Default Tax Rate'),
                              _buildDropdown(
                                '${(user?.settings.taxRate ?? 5.0).toStringAsFixed(0)}%',
                                ['5%', '12%', '18%', '28%'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
          ),
        ),
        const SizedBox(width: 24),
        // Right column
        Expanded(
          child: Column(
            children: [
              // Terms & Conditions
              _SectionCard(
                icon: Icons.description,
                iconColor: const Color(0xFFEF4444),
                title: 'Terms & Conditions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Footer Text'),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter terms and conditions...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                      controller: TextEditingController(
                        text:
                            '1. Goods once sold will not be taken back.\n2. Subject to local jurisdiction.\n3. Warranty as per manufacturer terms.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: WebTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'This text will appear at the bottom of every printed invoice.',
                          style: TextStyle(
                            fontSize: 11,
                            color: WebTheme.textMuted,
                          ),
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
                iconColor: const Color(0xFF22C55E),
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
                              color: Color(0xFF22C55E),
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
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(8),
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
                    _buildTextField(
                      value: '',
                      hint: 'Key Secret',
                      enabled: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable to send payment links via SMS/Email.',
                      style: TextStyle(fontSize: 11, color: WebTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ HELPER WIDGETS ============
  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: WebTheme.textSecondary,
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
        fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {},
      ),
    );
  }

  Widget _buildColorCircle(Color color, bool isSelected) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: isSelected
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
            : null,
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
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
                style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(icon, color: WebTheme.textSecondary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildLoginHistoryTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Device',
                style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Location',
                style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Time',
                style: TextStyle(fontSize: 12, color: WebTheme.textMuted),
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
                color: WebTheme.textSecondary,
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
                    color: const Color(0xFF22C55E),
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
            style: TextStyle(fontSize: 13, color: WebTheme.textMuted),
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
            color: included ? const Color(0xFF22C55E) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              decoration: included ? null : TextDecoration.lineThrough,
              color: included ? WebTheme.textPrimary : WebTheme.textMuted,
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
        color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? WebTheme.primary : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? WebTheme.primary : WebTheme.textPrimary,
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
                        color: const Color(0xFF3B82F6),
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
                style: TextStyle(fontSize: 12, color: WebTheme.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (v) {},
          activeThumbColor: WebTheme.primary,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
