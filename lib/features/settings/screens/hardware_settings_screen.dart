/// Hardware Settings Screen - Printer, Barcode, Sync, Preferences
/// Functional printer settings for Bluetooth thermal and system printers
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/core/services/thermal_printer_service.dart';
import 'package:retaillite/features/settings/providers/settings_provider.dart';
import 'package:retaillite/core/services/sync_settings_service.dart';
import 'package:retaillite/l10n/app_localizations.dart';
import 'package:retaillite/main.dart' show appVersion, appBuildNumber;

class HardwareSettingsScreen extends ConsumerStatefulWidget {
  const HardwareSettingsScreen({super.key});

  @override
  ConsumerState<HardwareSettingsScreen> createState() =>
      _HardwareSettingsScreenState();
}

class _HardwareSettingsScreenState
    extends ConsumerState<HardwareSettingsScreen> {
  bool _offlineMode = true;
  bool _voiceInput = false;
  bool _isScanning = false;
  List<PrinterDevice> _scannedDevices = [];

  // WiFi printer state
  late TextEditingController _wifiIpController;
  late TextEditingController _wifiPortController;
  bool _isWifiConnecting = false;

  // USB printer state (Windows)
  List<String> _windowsPrinters = [];
  bool _isLoadingUsbPrinters = false;

  late TextEditingController _barcodePrefixController;
  late TextEditingController _barcodeSuffixController;
  late TextEditingController _receiptFooterController;

  @override
  void initState() {
    super.initState();
    _barcodePrefixController = TextEditingController();
    _barcodeSuffixController = TextEditingController();
    _receiptFooterController = TextEditingController();
    _wifiIpController = TextEditingController(
      text: WifiPrinterService.getSavedIp(),
    );
    _wifiPortController = TextEditingController(
      text: WifiPrinterService.getSavedPort().toString(),
    );

    // Load receipt footer from state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final printerState = ref.read(printerProvider);
      _receiptFooterController.text = printerState.receiptFooter;

      // Load USB printers on Windows
      if (UsbPrinterService.isAvailable) {
        unawaited(_loadWindowsPrinters());
      }
    });
  }

  @override
  void dispose() {
    _barcodePrefixController.dispose();
    _barcodeSuffixController.dispose();
    _receiptFooterController.dispose();
    _wifiIpController.dispose();
    _wifiPortController.dispose();
    super.dispose();
  }

  Future<void> _scanBluetoothPrinters() async {
    setState(() {
      _isScanning = true;
      _scannedDevices = [];
    });

    try {
      final devices = await ThermalPrinterService.getPairedDevices();
      if (mounted) {
        setState(() {
          _scannedDevices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    }
  }

  Future<void> _connectToPrinter(PrinterDevice device) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Connecting to ${device.name}...')));

    final success = await ThermalPrinterService.connect(device);
    if (success) {
      await ThermalPrinterService.savePrinter(device);
      await ref
          .read(printerProvider.notifier)
          .connectPrinter(device.name, device.address);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _disconnectPrinter() async {
    await ThermalPrinterService.disconnect();
    await ref.read(printerProvider.notifier).disconnectPrinter();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Printer disconnected')));
    }
  }

  Future<void> _testPrint() async {
    final printerState = ref.read(printerProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    switch (printerState.printerType) {
      case PrinterTypeOption.bluetooth:
        final connected = await ThermalPrinterService.isConnected;
        if (!connected) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No Bluetooth printer connected')),
          );
          return;
        }
        final success = await ThermalPrinterService.printTestPage();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print sent!' : 'Print failed'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        break;

      case PrinterTypeOption.wifi:
        if (!WifiPrinterService.isConnected) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No WiFi printer connected')),
          );
          return;
        }
        final success = await WifiPrinterService.printTestPage();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print sent!' : 'Print failed'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        break;

      case PrinterTypeOption.usb:
        final usbName = UsbPrinterService.getSavedPrinterName();
        if (usbName.isEmpty) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('No USB printer selected')),
          );
          return;
        }
        final success = await UsbPrinterService.printTestPage(usbName);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print sent!' : 'Print failed'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        break;

      case PrinterTypeOption.system:
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'System printer: Use the print dialog when printing a receipt',
            ),
          ),
        );
        break;
    }
  }

  // ─── WiFi Printer Methods ───

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
    await ref.read(printerProvider.notifier).connectPrinter('USB: $name', name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected USB printer: $name'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
          _buildPrinterTypeCard(theme, printerState),
          const SizedBox(height: 16),
          if (printerState.printerType == PrinterTypeOption.bluetooth)
            _buildBluetoothSection(theme, printerState),
          if (printerState.printerType == PrinterTypeOption.wifi)
            _buildWifiSection(theme),
          if (printerState.printerType == PrinterTypeOption.usb)
            _buildUsbSection(theme),
          _buildPaperSettingsCard(theme, printerState),
          const SizedBox(height: 16),
          _buildReceiptSettingsCard(theme, printerState),
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
                      DropdownMenuItem(value: -1, child: Text('Keep forever')),
                    ],
                  ),
                ),
                if (settings.retentionDays == -1)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'High storage usage — data will never be auto-deleted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
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
          const SizedBox(height: 24),

          // App Version
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'v$appVersion+$appBuildNumber',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Printer Type Card ───
  Widget _buildPrinterTypeCard(ThemeData theme, PrinterState printerState) {
    final showBluetooth = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    const showWifi = !kIsWeb;
    final showUsb = !kIsWeb && Platform.isWindows;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Printer Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Choose how to connect your printer for direct ESC/POS printing.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),

            _buildPrinterTypeOption(
              theme,
              PrinterTypeOption.system,
              printerState.printerType,
              Icons.computer,
            ),
            if (showBluetooth) ...[
              const SizedBox(height: 8),
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.bluetooth,
                printerState.printerType,
                Icons.bluetooth,
              ),
            ],
            if (showWifi) ...[
              const SizedBox(height: 8),
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.wifi,
                printerState.printerType,
                Icons.wifi,
              ),
            ],
            if (showUsb) ...[
              const SizedBox(height: 8),
              _buildPrinterTypeOption(
                theme,
                PrinterTypeOption.usb,
                printerState.printerType,
                Icons.usb,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterTypeOption(
    ThemeData theme,
    PrinterTypeOption option,
    PrinterTypeOption selected,
    IconData icon,
  ) {
    final isSelected = option == selected;
    return InkWell(
      onTap: () {
        ref.read(printerProvider.notifier).setPrinterType(option);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // ─── Bluetooth Section ───
  Widget _buildBluetoothSection(ThemeData theme, PrinterState printerState) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection status
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth,
                      color: printerState.isConnected
                          ? AppColors.success
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            printerState.printerName ?? 'No Printer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                const SizedBox(height: 16),

                // Scan / Disconnect buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isScanning ? null : _scanBluetoothPrinters,
                        icon: _isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isScanning ? 'Scanning...' : 'Scan Printers',
                        ),
                      ),
                    ),
                    if (printerState.isConnected) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _disconnectPrinter,
                        icon: const Icon(Icons.link_off),
                        label: const Text('Disconnect'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),

                // Scanned devices list
                if (_scannedDevices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Found Devices:', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ..._scannedDevices.map(
                    (device) => ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(device.name),
                      subtitle: Text(
                        device.address,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.link, color: AppColors.success),
                        onPressed: () => _connectToPrinter(device),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── WiFi Printer Section ───
  Widget _buildWifiSection(ThemeData theme) {
    final isConnected = WifiPrinterService.isConnected;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                Row(
                  children: [
                    Icon(
                      Icons.wifi,
                      color: isConnected ? AppColors.success : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected
                                ? 'Connected: ${WifiPrinterService.connectedAddress}'
                                : 'WiFi Thermal Printer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            isConnected
                                ? 'Connected'
                                : 'Enter printer IP and port (default: 9100)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isConnected
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
                        color: isConnected ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // IP + Port input
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
                const SizedBox(height: 16),

                // Connect / Disconnect
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
                    if (isConnected) ...[
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
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── USB Printer Section (Windows) ───
  Widget _buildUsbSection(ThemeData theme) {
    final savedName = UsbPrinterService.getSavedPrinterName();

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.usb,
                      color: savedName.isNotEmpty
                          ? AppColors.success
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            savedName.isNotEmpty
                                ? 'USB: $savedName'
                                : 'USB Thermal Printer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            savedName.isNotEmpty
                                ? 'Selected'
                                : 'Select a printer from the list below',
                            style: TextStyle(
                              fontSize: 12,
                              color: savedName.isNotEmpty
                                  ? AppColors.success
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isLoadingUsbPrinters
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Available Printers:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ..._windowsPrinters.map(
                    (name) => ListTile(
                      leading: Icon(
                        Icons.print,
                        color: name == savedName ? AppColors.success : null,
                      ),
                      title: Text(name),
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
                    ),
                  ),
                ] else if (!_isLoadingUsbPrinters) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No printers found. Click refresh to scan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Paper Settings Card ───
  Widget _buildPaperSettingsCard(ThemeData theme, PrinterState printerState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paper & Font', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),

            // Paper size
            Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.straighten, size: 20),
                const SizedBox(width: 12),
                const Text('Paper Size'),
                const Spacer(),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('58mm')),
                    ButtonSegment(value: 1, label: Text('80mm')),
                  ],
                  selected: {printerState.paperSizeIndex},
                  onSelectionChanged: (set) {
                    ref.read(printerProvider.notifier).setPaperSize(set.first);
                  },
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Font size
            Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.text_fields, size: 20),
                const SizedBox(width: 12),
                const Text('Font Size'),
                const Spacer(),
                SegmentedButton<int>(
                  segments: PrinterFontSize.values
                      .map(
                        (f) =>
                            ButtonSegment(value: f.value, label: Text(f.label)),
                      )
                      .toList(),
                  selected: {printerState.fontSizeIndex},
                  onSelectionChanged: (set) {
                    ref.read(printerProvider.notifier).setFontSize(set.first);
                  },
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Test Print button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testPrint,
                icon: const Icon(Icons.print),
                label: const Text('Test Print'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Receipt Settings Card ───
  Widget _buildReceiptSettingsCard(ThemeData theme, PrinterState printerState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Settings', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),

            // Auto-print toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.autorenew),
              title: const Text('Auto-Print'),
              subtitle: const Text(
                'Print receipt automatically after bill completion',
              ),
              value: printerState.autoPrint,
              onChanged: (v) {
                ref.read(printerProvider.notifier).setAutoPrint(v);
              },
            ),
            const Divider(),

            // Receipt footer
            TextField(
              controller: _receiptFooterController,
              decoration: const InputDecoration(
                labelText: 'Receipt Footer',
                hintText: 'e.g. Thank you for shopping!',
                helperText: 'Custom text at the bottom of receipts',
              ),
              onChanged: (v) {
                ref.read(printerProvider.notifier).setReceiptFooter(v);
              },
            ),
          ],
        ),
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
}
