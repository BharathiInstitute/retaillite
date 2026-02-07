/// Settings Screen - Fully Localized
/// All text uses context.l10n for translation.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/features/settings/widgets/edit_shop_modal.dart';
import 'package:retaillite/core/services/sync_settings_service.dart';
import 'package:retaillite/core/services/data_retention_service.dart';
import 'package:retaillite/core/services/image_service.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/features/settings/screens/settings_web_screen.dart';

/// Settings screen with all functional features
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;

  /// Pick and save shop logo
  Future<void> _pickShopLogo() async {
    final imagePath = await ImageService.pickAndResizeLogo();
    if (imagePath != null && mounted) {
      ref.read(authNotifierProvider.notifier).updateShopLogo(imagePath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Placeholder widget for logo
  Widget _buildLogoPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          'Logo',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final printerState = ref.watch(printerProvider);

    if (ResponsiveHelper.isDesktop(context) ||
        ResponsiveHelper.isTablet(context)) {
      return const SettingsWebScreen();
    }

    // Sync info
    final syncInterval = SyncSettingsService.getSyncInterval();
    final lastSyncDisplay = SyncSettingsService.getLastSyncDisplay();
    final pendingCount = SyncSettingsService.pendingSyncCount;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shop Info Section
          _buildSectionHeader(theme, l10n.shopInformation),
          _buildShopInfoCard(context, user, l10n),
          const Divider(height: 32),

          // App Settings Section
          _buildSectionHeader(theme, l10n.appSettings),
          _buildDarkModeToggle(context, settings.isDarkMode, l10n),
          _buildLanguageSelector(context, settings.languageCode, l10n),
          _buildRetentionSelector(context, settings, l10n),
          const Divider(height: 32),

          // Printer Section
          _buildSectionHeader(theme, l10n.printer),
          _buildPrinterStatus(context, printerState, l10n),
          const Divider(height: 32),

          // Sync Section
          _buildSectionHeader(theme, l10n.sync),
          _buildSyncIntervalSelector(context, syncInterval, l10n),
          _buildSyncStatus(context, lastSyncDisplay, pendingCount, l10n),
          _buildSyncNowButton(context, l10n),
          const Divider(height: 32),

          // Support Section
          _buildSectionHeader(theme, l10n.support),
          _buildHelpTile(context, l10n),
          _buildAboutTile(context, l10n),
          const Divider(height: 32),

          // Logout Section
          _buildLogoutTile(context, l10n),

          const SizedBox(height: 32),
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

  /// Shop info card with logo and edit button
  Widget _buildShopInfoCard(BuildContext context, user, AppLocalizations l10n) {
    final logoPath = user?.shopLogoPath;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Shop Logo
            GestureDetector(
              onTap: () => _pickShopLogo(),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: logoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(logoPath),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, stack) =>
                              _buildLogoPlaceholder(context),
                        ),
                      )
                    : _buildLogoPlaceholder(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to upload logo',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.store, l10n.shopName, user?.shopName ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, l10n.ownerName, user?.ownerName ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, l10n.email, user?.email ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, l10n.phone, user?.phone ?? '-'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showEditShopModal(context),
                icon: const Icon(Icons.edit),
                label: Text(l10n.editShopDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditShopModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditShopModal(),
    );
  }

  /// Dark mode toggle
  Widget _buildDarkModeToggle(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.dark_mode),
      title: Text(l10n.darkMode),
      subtitle: Text(isDark ? l10n.on : l10n.off),
      value: isDark,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setDarkMode(value);
      },
    );
  }

  /// Language selector
  Widget _buildLanguageSelector(
    BuildContext context,
    String languageCode,
    AppLocalizations l10n,
  ) {
    final currentLang = AppLanguage.fromCode(languageCode);

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text(currentLang.displayName),
      trailing: DropdownButton<AppLanguage>(
        value: currentLang,
        underline: const SizedBox(),
        onChanged: (lang) {
          if (lang != null) {
            ref.read(settingsProvider.notifier).setLanguage(lang.code);
          }
        },
        items: AppLanguage.values.map((lang) {
          return DropdownMenuItem(value: lang, child: Text(lang.displayName));
        }).toList(),
      ),
    );
  }

  /// Data retention selector
  Widget _buildRetentionSelector(
    BuildContext context,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    return ListTile(
      leading: const Icon(Icons.auto_delete),
      title: Text(l10n.dataRetention),
      subtitle: Text('${settings.retentionDays} ${l10n.days}'),
      trailing: DropdownButton<int>(
        value: settings.retentionDays,
        underline: const SizedBox(),
        onChanged: (days) {
          if (days != null) {
            ref
                .read(settingsProvider.notifier)
                .setRetentionPeriod(RetentionPeriod.fromDays(days));
          }
        },
        items: [
          DropdownMenuItem(value: 30, child: Text('30 ${l10n.days}')),
          DropdownMenuItem(value: 60, child: Text('60 ${l10n.days}')),
          DropdownMenuItem(value: 90, child: Text('90 ${l10n.days}')),
          DropdownMenuItem(value: 180, child: Text('180 ${l10n.days}')),
          DropdownMenuItem(value: 365, child: Text('1 year')),
        ],
      ),
    );
  }

  /// Printer status
  Widget _buildPrinterStatus(
    BuildContext context,
    PrinterState printerState,
    AppLocalizations l10n,
  ) {
    final isConnected = printerState.isConnected;
    final printerName = printerState.printerName;

    return ListTile(
      leading: Icon(
        isConnected ? Icons.print : Icons.print_disabled,
        color: isConnected ? Colors.green : Colors.grey,
      ),
      title: Text(l10n.printer),
      subtitle: Text(
        isConnected
            ? '${l10n.connected}: ${printerName ?? '-'}'
            : l10n.notConnected,
      ),
      trailing: printerState.isScanning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.settings),
      onTap: () => _showPrinterSettingsDialog(context, printerState, l10n),
    );
  }

  void _showPrinterSettingsDialog(
    BuildContext context,
    PrinterState state,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.printerSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.paperSize),
              trailing: DropdownButton<int>(
                value: state.paperSizeIndex,
                underline: const SizedBox(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(printerProvider.notifier).setPaperSize(v);
                    Navigator.pop(ctx);
                    _showPrinterSettingsDialog(
                      context,
                      state.copyWith(paperSizeIndex: v),
                      l10n,
                    );
                  }
                },
                items: const [
                  DropdownMenuItem(value: 0, child: Text('58mm')),
                  DropdownMenuItem(value: 1, child: Text('80mm')),
                ],
              ),
            ),
            ListTile(
              title: Text(l10n.fontSize),
              trailing: DropdownButton<int>(
                value: state.fontSizeIndex,
                underline: const SizedBox(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(printerProvider.notifier).setFontSize(v);
                    Navigator.pop(ctx);
                    _showPrinterSettingsDialog(
                      context,
                      state.copyWith(fontSizeIndex: v),
                      l10n,
                    );
                  }
                },
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Small')),
                  DropdownMenuItem(value: 1, child: Text('Normal')),
                  DropdownMenuItem(value: 2, child: Text('Large')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.isConnected)
              FilledButton.icon(
                onPressed: () {
                  ref.read(printerProvider.notifier).disconnectPrinter();
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('Disconnect'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// Sync interval selector
  Widget _buildSyncIntervalSelector(
    BuildContext context,
    SyncInterval current,
    AppLocalizations l10n,
  ) {
    return ListTile(
      leading: const Icon(Icons.schedule),
      title: Text(l10n.syncInterval),
      subtitle: Text(SyncSettingsService.getSyncModeDescription()),
      trailing: DropdownButton<SyncInterval>(
        value: current,
        underline: const SizedBox(),
        onChanged: (interval) async {
          if (interval != null) {
            await SyncSettingsService.setSyncInterval(interval);
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
    );
  }

  /// Sync status display
  Widget _buildSyncStatus(
    BuildContext context,
    String lastSyncDisplay,
    int pendingCount,
    AppLocalizations l10n,
  ) {
    final statusText = pendingCount > 0
        ? '$pendingCount ${l10n.pendingChanges} • $lastSyncDisplay'
        : lastSyncDisplay;

    return ListTile(
      leading: Icon(
        Icons.cloud_done,
        color: pendingCount > 0 ? Colors.orange : Colors.green,
      ),
      title: Text(l10n.syncStatus),
      subtitle: Text(statusText),
    );
  }

  /// Sync now button
  Widget _buildSyncNowButton(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      leading: _isSyncing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.cloud_upload),
      title: Text(l10n.syncNow),
      subtitle: Text(l10n.uploadPendingChanges),
      onTap: _isSyncing ? null : () => _handleSyncNow(l10n),
    );
  }

  Future<void> _handleSyncNow(AppLocalizations l10n) async {
    setState(() => _isSyncing = true);

    try {
      final success = await SyncSettingsService.syncNow();
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.syncCompleted : l10n.syncFailed),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Help & Support tile
  Widget _buildHelpTile(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.help_outline),
      title: Text(l10n.helpCenter),
      subtitle: Text(l10n.support),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showHelpDialog(context, l10n),
    );
  }

  void _showHelpDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.helpCenter),
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
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// About tile
  Widget _buildAboutTile(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(l10n.about),
      subtitle: Text('${l10n.version} 1.0.0'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showAboutDialog(context, l10n),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.about} ${l10n.appName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text('${l10n.version} 1.0.0'),
            const SizedBox(height: 16),
            Text(l10n.appTagline),
            const SizedBox(height: 16),
            const Text(
              '© 2026 RetailLite',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// Logout tile
  Widget _buildLogoutTile(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.error),
      title: Text(
        l10n.logout,
        style: TextStyle(color: theme.colorScheme.error),
      ),
      subtitle: Text(l10n.signOut),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.logout),
            content: Text(l10n.signOutConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: Text(l10n.logout),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await ref.read(authNotifierProvider.notifier).signOut();
        }
      },
    );
  }
}
