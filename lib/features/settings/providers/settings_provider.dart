/// Settings providers for app preferences
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/core/services/data_retention_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';

/// App settings state
class AppSettings {
  final bool isDarkMode;
  final Locale locale;
  final String languageCode;
  final int retentionDays;
  final bool autoCleanupEnabled;

  const AppSettings({
    this.isDarkMode = false,
    this.locale = const Locale('en'),
    this.languageCode = 'en',
    this.retentionDays = 90,
    this.autoCleanupEnabled = true,
  });

  RetentionPeriod get retentionPeriod =>
      RetentionPeriod.fromDays(retentionDays);

  AppSettings copyWith({
    bool? isDarkMode,
    Locale? locale,
    String? languageCode,
    int? retentionDays,
    bool? autoCleanupEnabled,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      locale: locale ?? this.locale,
      languageCode: languageCode ?? this.languageCode,
      retentionDays: retentionDays ?? this.retentionDays,
      autoCleanupEnabled: autoCleanupEnabled ?? this.autoCleanupEnabled,
    );
  }
}

/// Main settings provider - rebuilds on user change
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  // Watch auth state so settings reload when a different user logs in
  ref.watch(authNotifierProvider.select((s) => s.firebaseUser?.uid));
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    // Load local cache SYNCHRONOUSLY first to avoid flash of wrong theme
    _loadLocalSync();
    // Then sync from cloud in background
    _loadFromCloud();
  }

  /// Synchronous load from SharedPreferences — instant, no flash
  void _loadLocalSync() {
    try {
      final isDark =
          OfflineStorageService.getSetting<bool>(
            SettingsKeys.isDarkMode,
            defaultValue: false,
          ) ??
          false;

      final langCode =
          OfflineStorageService.getSetting<String>(
            SettingsKeys.language,
            defaultValue: 'en',
          ) ??
          'en';

      final retDays =
          OfflineStorageService.getSetting<int>(
            SettingsKeys.retentionDays,
            defaultValue: 90,
          ) ??
          90;

      final autoCleanup =
          OfflineStorageService.getSetting<bool>(
            SettingsKeys.autoCleanupEnabled,
            defaultValue: true,
          ) ??
          true;

      state = AppSettings(
        isDarkMode: isDark,
        locale: Locale(langCode),
        languageCode: langCode,
        retentionDays: retDays,
        autoCleanupEnabled: autoCleanup,
      );
      debugPrint('✅ Settings loaded instantly from local cache');
    } catch (e) {
      debugPrint('Error loading settings from local cache: $e');
    }
  }

  /// Async cloud fetch — updates if cloud has newer data
  Future<void> _loadFromCloud() async {
    try {
      final cloudData = await OfflineStorageService.loadAllSettingsFromCloud();

      if (cloudData.isNotEmpty) {
        final cloudDark = cloudData[SettingsKeys.isDarkMode] as bool?;
        final cloudLang = cloudData[SettingsKeys.language] as String?;
        final cloudRetention = cloudData[SettingsKeys.retentionDays] as int?;
        final cloudAutoCleanup =
            cloudData[SettingsKeys.autoCleanupEnabled] as bool?;

        if (cloudDark != null || cloudLang != null || cloudRetention != null) {
          final langCode = cloudLang ?? state.languageCode;
          final newState = AppSettings(
            isDarkMode: cloudDark ?? state.isDarkMode,
            locale: Locale(langCode),
            languageCode: langCode,
            retentionDays: cloudRetention ?? state.retentionDays,
            autoCleanupEnabled: cloudAutoCleanup ?? state.autoCleanupEnabled,
          );
          // Only update if different
          if (newState.isDarkMode != state.isDarkMode ||
              newState.languageCode != state.languageCode ||
              newState.retentionDays != state.retentionDays ||
              newState.autoCleanupEnabled != state.autoCleanupEnabled) {
            state = newState;
            debugPrint('✅ Settings updated from cloud');
          }
        }
      }
    } catch (e) {
      debugPrint('Cloud settings load failed: $e');
    }
  }

  /// Reload settings (called on user switch)
  Future<void> reloadSettings() async {
    _loadLocalSync();
    await _loadFromCloud();
  }

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    OfflineStorageService.saveSetting(
      SettingsKeys.isDarkMode,
      state.isDarkMode,
    );
  }

  void setDarkMode(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
    OfflineStorageService.saveSetting(SettingsKeys.isDarkMode, isDark);
  }

  void setLanguage(String languageCode) {
    state = state.copyWith(
      languageCode: languageCode,
      locale: Locale(languageCode),
    );
    OfflineStorageService.saveSetting(SettingsKeys.language, languageCode);
  }

  void setRetentionPeriod(RetentionPeriod period) {
    state = state.copyWith(retentionDays: period.days);
    OfflineStorageService.saveSetting(SettingsKeys.retentionDays, period.days);
  }

  void setRetentionDays(int days) {
    state = state.copyWith(retentionDays: days);
    OfflineStorageService.saveSetting(SettingsKeys.retentionDays, days);
  }

  void setAutoCleanup(bool enabled) {
    state = state.copyWith(autoCleanupEnabled: enabled);
    OfflineStorageService.saveSetting(SettingsKeys.autoCleanupEnabled, enabled);
  }
}

/// Language options
enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिंदी'),
  telugu('te', 'తెలుగు');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Theme mode provider (legacy, use settingsProvider instead)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleDarkMode() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

/// Language provider (legacy, use settingsProvider instead)
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
  (ref) => LanguageNotifier(),
);

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english);

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

/// Printer font size enum
enum PrinterFontSize {
  small(0, 'Small', 'Compact - fits more text'),
  normal(1, 'Normal', 'Default size'),
  large(2, 'Large', 'Easier to read');

  final int value;
  final String label;
  final String description;

  const PrinterFontSize(this.value, this.label, this.description);

  static PrinterFontSize fromValue(int value) {
    return PrinterFontSize.values.firstWhere(
      (f) => f.value == value,
      orElse: () => PrinterFontSize.normal,
    );
  }
}

/// Printer type enum
enum PrinterTypeOption {
  system('System Printer', 'Uses system print dialog (USB, WiFi, network)'),
  bluetooth('Bluetooth', 'Direct ESC/POS via Bluetooth'),
  usb('USB', 'Direct ESC/POS via USB cable'),
  wifi('WiFi', 'Direct ESC/POS via network');

  final String label;
  final String description;
  const PrinterTypeOption(this.label, this.description);

  /// Whether this type uses direct ESC/POS thermal printing
  bool get isThermal => this != system;

  static PrinterTypeOption fromString(String value) {
    return PrinterTypeOption.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PrinterTypeOption.system,
    );
  }
}

/// Printer state
class PrinterState {
  final bool isConnected;
  final String? printerName;
  final String? printerAddress;
  final int paperSizeIndex; // 0 = 58mm, 1 = 80mm
  final int fontSizeIndex; // 0 = Small, 1 = Normal, 2 = Large
  final int customWidth; // 0 = auto, 28-52 = custom chars per line
  final bool isScanning;
  final String? error;
  final PrinterTypeOption printerType;
  final bool autoPrint;
  final String receiptFooter;

  const PrinterState({
    this.isConnected = false,
    this.printerName,
    this.printerAddress,
    this.paperSizeIndex = 1, // Default 80mm
    this.fontSizeIndex = 1, // Default Normal
    this.customWidth = 0, // Default auto
    this.isScanning = false,
    this.error,
    this.printerType = PrinterTypeOption.system,
    this.autoPrint = false,
    this.receiptFooter = '',
  });

  String get paperSizeLabel => paperSizeIndex == 0 ? '58mm' : '80mm';

  PrinterFontSize get fontSize => PrinterFontSize.fromValue(fontSizeIndex);

  /// Get effective characters per line
  int get effectiveWidth {
    if (customWidth > 0) return customWidth;
    // Default widths based on paper size
    return paperSizeIndex == 0 ? 32 : 48;
  }

  String get widthLabel {
    if (customWidth > 0) return '$customWidth chars';
    return 'Auto ($effectiveWidth chars)';
  }

  PrinterState copyWith({
    bool? isConnected,
    String? printerName,
    String? printerAddress,
    int? paperSizeIndex,
    int? fontSizeIndex,
    int? customWidth,
    bool? isScanning,
    String? error,
    PrinterTypeOption? printerType,
    bool? autoPrint,
    String? receiptFooter,
  }) {
    return PrinterState(
      isConnected: isConnected ?? this.isConnected,
      printerName: printerName ?? this.printerName,
      printerAddress: printerAddress ?? this.printerAddress,
      paperSizeIndex: paperSizeIndex ?? this.paperSizeIndex,
      fontSizeIndex: fontSizeIndex ?? this.fontSizeIndex,
      customWidth: customWidth ?? this.customWidth,
      isScanning: isScanning ?? this.isScanning,
      error: error,
      printerType: printerType ?? this.printerType,
      autoPrint: autoPrint ?? this.autoPrint,
      receiptFooter: receiptFooter ?? this.receiptFooter,
    );
  }
}

final printerProvider = StateNotifierProvider<PrinterNotifier, PrinterState>(
  (ref) => PrinterNotifier(),
);

class PrinterNotifier extends StateNotifier<PrinterState> {
  PrinterNotifier() : super(const PrinterState()) {
    _loadSavedPrinter();
  }

  /// Load saved printer from storage
  void _loadSavedPrinter() {
    final savedPrinter = PrinterStorage.getSavedPrinter();
    final paperSize = PrinterStorage.getSavedPaperSize();
    final fontSize = PrinterStorage.getSavedFontSize();
    final customWidth = PrinterStorage.getSavedCustomWidth();
    final autoPrint = PrinterStorage.getAutoPrint();
    final receiptFooter = PrinterStorage.getReceiptFooter();
    final printerType = PrinterTypeOption.fromString(
      PrinterStorage.getPrinterType(),
    );

    if (savedPrinter != null) {
      state = PrinterState(
        isConnected: true,
        printerName: savedPrinter['name'],
        printerAddress: savedPrinter['address'],
        paperSizeIndex: paperSize,
        fontSizeIndex: fontSize,
        customWidth: customWidth,
        autoPrint: autoPrint,
        receiptFooter: receiptFooter,
        printerType: printerType,
      );
    } else {
      state = PrinterState(
        paperSizeIndex: paperSize,
        fontSizeIndex: fontSize,
        customWidth: customWidth,
        autoPrint: autoPrint,
        receiptFooter: receiptFooter,
        printerType: printerType,
      );
    }
  }

  /// Set paper size
  Future<void> setPaperSize(int sizeIndex) async {
    await PrinterStorage.savePaperSize(sizeIndex);
    state = state.copyWith(paperSizeIndex: sizeIndex);
  }

  /// Set font size
  Future<void> setFontSize(int fontSizeIndex) async {
    await PrinterStorage.saveFontSize(fontSizeIndex);
    state = state.copyWith(fontSizeIndex: fontSizeIndex);
  }

  /// Set custom width (0 = auto)
  Future<void> setCustomWidth(int width) async {
    await PrinterStorage.saveCustomWidth(width);
    state = state.copyWith(customWidth: width);
  }

  /// Save and connect to printer
  Future<bool> connectPrinter(String name, String address) async {
    state = state.copyWith(isScanning: true);

    // Save to storage
    await PrinterStorage.savePrinter(name, address);

    state = state.copyWith(
      isConnected: true,
      printerName: name,
      printerAddress: address,
      isScanning: false,
    );

    return true;
  }

  /// Check current connection status
  Future<void> checkConnection() async {
    // This would be called to verify Bluetooth connection
    // For now, we just update state based on saved printer
    final savedPrinter = PrinterStorage.getSavedPrinter();
    if (savedPrinter == null) {
      state = state.copyWith(isConnected: false);
    }
  }

  /// Disconnect and clear saved printer
  Future<void> disconnectPrinter() async {
    await PrinterStorage.clearSavedPrinter();
    state = PrinterState(
      paperSizeIndex: state.paperSizeIndex,
      fontSizeIndex: state.fontSizeIndex,
      customWidth: state.customWidth,
      autoPrint: state.autoPrint,
      receiptFooter: state.receiptFooter,
      printerType: state.printerType,
    );
  }

  /// Set printer type
  Future<void> setPrinterType(PrinterTypeOption type) async {
    await PrinterStorage.savePrinterType(type.name);
    state = state.copyWith(printerType: type);
  }

  /// Set auto-print
  Future<void> setAutoPrint(bool autoPrint) async {
    await PrinterStorage.saveAutoPrint(autoPrint);
    state = state.copyWith(autoPrint: autoPrint);
  }

  /// Set receipt footer text
  Future<void> setReceiptFooter(String footer) async {
    await PrinterStorage.saveReceiptFooter(footer);
    state = state.copyWith(receiptFooter: footer);
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(error: error, isScanning: false);
  }

  /// Update connection status (e.g., after checking if USB device is still present)
  void setConnectionStatus(bool connected) {
    state = state.copyWith(isConnected: connected);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }
}

/// Settings loading state
final settingsLoadingProvider = StateProvider<bool>((ref) => false);
