/// General Settings Screen - Shop Profile, Business Details, Theme
/// Mirrors Web General Tab
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/features/settings/providers/theme_settings_provider.dart';
import 'package:retaillite/models/theme_settings_model.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() =>
      _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  late TextEditingController _shopNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;

  String _currency = 'INR';
  String _timezone = 'Asia/Kolkata';

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _shopNameController = TextEditingController(text: user?.shopName ?? '');
    _ownerNameController = TextEditingController(text: user?.ownerName ?? '');
    _contactController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _gstController = TextEditingController(text: user?.gstNumber ?? '');
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeSettings = ref.watch(themeSettingsProvider);
    final themeNotifier = ref.read(themeSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('General Settings'),
        actions: [
          TextButton(onPressed: _saveSettings, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shop Profile Section
          _buildSectionHeader(theme, 'Shop Profile'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField(
                    'Shop Name',
                    _shopNameController,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Owner Name', _ownerNameController),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Contact Number',
                    _contactController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Address', _addressController, maxLines: 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Business Details Section
          _buildSectionHeader(theme, 'Business Details'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    'GST Number',
                    _gstController,
                    hint: '22AAAAA0000A1Z5',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter GSTIN to enable tax invoicing',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField('Currency', _currency, [
                    'INR',
                    'USD',
                    'EUR',
                  ], (v) => setState(() => _currency = v!)),
                  const SizedBox(height: 16),
                  _buildDropdownField('Timezone', _timezone, [
                    'Asia/Kolkata',
                    'America/New_York',
                    'Europe/London',
                  ], (v) => setState(() => _timezone = v!)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Theme Customization Section
          _buildSectionHeader(theme, 'Theme Customization'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary Color
                  Text(
                    'Accent Color',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
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
                  const SizedBox(height: 20),

                  // Font Family
                  Text(
                    'Font',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                  const SizedBox(height: 20),

                  // Font Size
                  Text(
                    'Text Size',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                  const SizedBox(height: 16),

                  // Dark Mode
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use System Theme'),
                    value: themeSettings.useSystemTheme,
                    onChanged: (v) => themeNotifier.setUseSystemTheme(v),
                  ),
                  if (!themeSettings.useSystemTheme)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark Mode'),
                      value: themeSettings.useDarkMode,
                      onChanged: (v) => themeNotifier.setDarkMode(v),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Language & Region Section
          _buildSectionHeader(theme, 'Language & Region'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: Text(
                    AppLanguage.fromCode(
                      ref.watch(settingsProvider).languageCode,
                    ).displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  trailing: DropdownButton<AppLanguage>(
                    value: AppLanguage.fromCode(
                      ref.watch(settingsProvider).languageCode,
                    ),
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).setLanguage(v.code);
                      }
                    },
                    items: AppLanguage.values.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang.displayName),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Notification Preferences Section
          _buildSectionHeader(theme, 'Notification Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Low Stock Alerts'),
                  subtitle: const Text(
                    'Get notified when product stock falls below threshold',
                  ),
                  secondary: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.orange,
                  ),
                  value:
                      ref.watch(currentUserProvider)?.settings.lowStockAlerts ??
                      true,
                  onChanged: (v) => _toggleNotifPref('lowStockAlerts', v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Subscription Alerts'),
                  subtitle: const Text(
                    'Reminders before your subscription expires',
                  ),
                  secondary: const Icon(Icons.credit_card, color: Colors.blue),
                  value:
                      ref
                          .watch(currentUserProvider)
                          ?.settings
                          .subscriptionAlerts ??
                      true,
                  onChanged: (v) => _toggleNotifPref('subscriptionAlerts', v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Daily Sales Summary'),
                  subtitle: const Text(
                    'Receive a summary of your daily sales at 9 PM',
                  ),
                  secondary: const Icon(Icons.bar_chart, color: Colors.green),
                  value:
                      ref.watch(currentUserProvider)?.settings.dailySummary ??
                      true,
                  onChanged: (v) => _toggleNotifPref('dailySummary', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  String _getFontSizeLabel(double scale) {
    if (scale <= 0.90) return 'Small';
    if (scale <= 1.05) return 'Compact';
    return 'Large';
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

  void _saveSettings() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.updateShopInfo(
      shopName: _shopNameController.text,
      ownerName: _ownerNameController.text,
      phone: _contactController.text,
      address: _addressController.text,
      gstNumber: _gstController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.pop(context);
  }
}
