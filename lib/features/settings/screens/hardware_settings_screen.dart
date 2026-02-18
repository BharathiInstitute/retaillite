/// Hardware Settings Screen - Printer, Barcode, Sync, Preferences
/// Mirrors Web Hardware Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/core/services/sync_settings_service.dart';
import 'package:retaillite/l10n/app_localizations.dart';

class HardwareSettingsScreen extends ConsumerStatefulWidget {
  const HardwareSettingsScreen({super.key});

  @override
  ConsumerState<HardwareSettingsScreen> createState() =>
      _HardwareSettingsScreenState();
}

class _HardwareSettingsScreenState
    extends ConsumerState<HardwareSettingsScreen> {
  String _paperWidth = '80mm';
  double _printDensity = 0.7;
  bool _offlineMode = true;
  bool _voiceInput = false;

  late TextEditingController _barcodePrefixController;
  late TextEditingController _barcodeSuffixController;

  bool _hasShownComingSoon = false;

  @override
  void initState() {
    super.initState();
    _barcodePrefixController = TextEditingController();
    _barcodeSuffixController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasShownComingSoon) {
        _hasShownComingSoon = true;
        _showComingSoonDialog();
      }
    });
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          icon: const Icon(
            Icons.construction,
            size: 48,
            color: AppColors.warning,
          ),
          title: const Text('Coming Soon'),
          content: const Text(
            'Hardware settings are under development. These features will be available in a future update.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barcodePrefixController.dispose();
    _barcodeSuffixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final printerState = ref.watch(printerProvider);
    final syncInterval = SyncSettingsService.getSyncInterval();

    return Scaffold(
      appBar: AppBar(title: const Text('Hardware Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Printer Section
          _buildSectionHeader(theme, l10n.printer),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Printer Status
                  Row(
                    children: [
                      const Icon(Icons.print, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              printerState.printerName ?? 'No Printer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              printerState.isConnected
                                  ? 'Connected'
                                  : 'Not connected',
                              style: TextStyle(
                                fontSize: 12,
                                color: printerState.isConnected
                                    ? AppColors.success
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: printerState.isConnected
                              ? AppColors.success
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Paper Width
                  Text('Paper Width', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildToggleChip(
                        '58mm',
                        _paperWidth == '58mm',
                        () => setState(() => _paperWidth = '58mm'),
                      ),
                      const SizedBox(width: 12),
                      _buildToggleChip(
                        '80mm',
                        _paperWidth == '80mm',
                        () => setState(() => _paperWidth = '80mm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Print Density
                  Text('Print Density', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Slider(
                    value: _printDensity,
                    min: 0.3,
                    divisions: 7,
                    label: '${(_printDensity * 100).toInt()}%',
                    onChanged: (v) => setState(() => _printDensity = v),
                  ),
                  const SizedBox(height: 16),

                  // Test Print
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test print sent')),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Test Print'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Barcode Scanner Section
          _buildSectionHeader(theme, 'Barcode Scanner'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _barcodePrefixController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode Prefix',
                      hintText: 'Optional prefix',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _barcodeSuffixController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode Suffix',
                      hintText: 'Optional suffix',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add prefix/suffix to barcode input for scanner compatibility',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sync Section
          _buildSectionHeader(theme, l10n.sync),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: Text(l10n.syncInterval),
                  trailing: DropdownButton<SyncInterval>(
                    value: syncInterval,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v != null) {
                        SyncSettingsService.setSyncInterval(v);
                        setState(() {});
                      }
                    },
                    items: SyncInterval.values.map((interval) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text(interval.displayName),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  trailing: DropdownButton<AppLanguage>(
                    value: AppLanguage.fromCode(settings.languageCode),
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_delete),
                  title: Text(l10n.dataRetention),
                  trailing: DropdownButton<int>(
                    value: settings.retentionDays,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(settingsProvider.notifier).setRetentionDays(v);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                      DropdownMenuItem(value: 60, child: Text('60 days')),
                      DropdownMenuItem(value: 90, child: Text('90 days')),
                      DropdownMenuItem(value: 180, child: Text('180 days')),
                      DropdownMenuItem(value: 365, child: Text('1 year')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Preferences Section
          _buildSectionHeader(theme, 'App Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_off),
                  title: const Text('Offline Mode'),
                  subtitle: const Text('Continue billing when offline'),
                  value: _offlineMode,
                  onChanged: (v) => setState(() => _offlineMode = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.mic),
                  title: const Text('Voice Input'),
                  subtitle: Row(
                    children: [
                      const Text('Voice search for products'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BETA',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: _voiceInput,
                  onChanged: (v) => setState(() => _voiceInput = v),
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

  Widget _buildToggleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
