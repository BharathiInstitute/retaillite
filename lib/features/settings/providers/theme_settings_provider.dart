/// Theme Settings Provider - Manages user theme preferences
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/models/theme_settings_model.dart';

/// Current theme settings - rebuilds on user change
final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettingsModel>((ref) {
      // Watch auth state so theme reloads when a different user logs in
      ref.watch(authNotifierProvider.select((s) => s.firebaseUser?.uid));
      return ThemeSettingsNotifier();
    });

/// Computed ThemeData based on settings
final appThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return _buildTheme(settings, Brightness.light);
});

/// Computed dark ThemeData
final appDarkThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return _buildTheme(settings, Brightness.dark);
});

/// Theme mode based on user settings (renamed to avoid conflict)
final userThemeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  if (settings.useSystemTheme) return ThemeMode.system;
  return settings.useDarkMode ? ThemeMode.dark : ThemeMode.light;
});

class ThemeSettingsNotifier extends StateNotifier<ThemeSettingsModel> {
  ThemeSettingsNotifier() : super(const ThemeSettingsModel()) {
    // Load local cache SYNCHRONOUSLY first to avoid flash of light theme
    _loadLocalSync();
    // Then try cloud in background
    _loadFromCloud();
  }

  /// Synchronous load from SharedPreferences — no flash of wrong theme
  void _loadLocalSync() {
    try {
      // Try loading the full JSON first (new format with jsonEncode)
      final json = OfflineStorageService.getSetting<Map<String, dynamic>>(
        'theme_settings',
      );
      if (json != null) {
        state = ThemeSettingsModel.fromJson(json);
        AppColors.updatePrimary(state.primaryColor);
        debugPrint('✅ Theme settings loaded instantly from local cache (JSON)');
        return;
      }

      // Fallback 1: read standalone dark mode flags (reliable primitives)
      final isDark = OfflineStorageService.getSetting<bool>('theme_is_dark');
      final useSystem = OfflineStorageService.getSetting<bool>(
        'theme_use_system',
      );
      if (isDark != null) {
        state = ThemeSettingsModel(
          useDarkMode: isDark,
          useSystemTheme: useSystem ?? false,
        );
        debugPrint(
          '✅ Theme dark mode loaded from standalone flag (isDark=$isDark)',
        );
        return;
      }

      // Fallback 2: legacy .toString() format — parse raw string from SharedPreferences.
      // Old code stored maps as {useDarkMode: true, ...} which isn't valid JSON.
      final rawValue = OfflineStorageService.prefs?.getString('theme_settings');
      if (rawValue != null && rawValue.isNotEmpty) {
        final isDarkLegacy = rawValue.contains('useDarkMode: true');
        final useSystemLegacy = !rawValue.contains('useSystemTheme: false');
        if (isDarkLegacy || !useSystemLegacy) {
          state = ThemeSettingsModel(
            useDarkMode: isDarkLegacy,
            useSystemTheme: useSystemLegacy,
          );
          // Re-save in the correct format so future loads are instant
          _saveSettings();
          debugPrint(
            '✅ Theme loaded from legacy .toString() format (isDark=$isDarkLegacy)',
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading theme from local cache: $e');
    }
  }

  /// Async cloud fetch — updates if cloud has newer data
  Future<void> _loadFromCloud() async {
    try {
      final cloudData =
          await OfflineStorageService.getSettingFromCloud<Map<String, dynamic>>(
            'theme_settings',
          );
      if (cloudData != null) {
        final cloudSettings = ThemeSettingsModel.fromJson(cloudData);
        // Only update if different from current state
        if (cloudSettings != state) {
          state = cloudSettings;
          AppColors.updatePrimary(state.primaryColor);
          // Persist to local so next refresh is instant
          unawaited(_saveSettings());
          debugPrint('✅ Theme settings updated from cloud');
        }
      }
    } catch (e) {
      debugPrint('Error loading theme from cloud: $e');
    }
  }

  /// Reload settings (called on user switch)
  Future<void> reloadSettings() async {
    // Load local first for instant theme
    _loadLocalSync();
    // Then sync from cloud
    await _loadFromCloud();
  }

  /// Reset to default light theme (called on logout)
  void resetToDefault() {
    state = const ThemeSettingsModel();
    AppColors.updatePrimary(state.primaryColor);
  }

  Future<void> _saveSettings() async {
    try {
      // Save full theme as JSON (for all settings)
      await OfflineStorageService.saveSetting('theme_settings', state.toJson());
      // Also save standalone dark mode flags for instant loading on refresh
      await OfflineStorageService.saveSetting(
        'theme_is_dark',
        state.useDarkMode,
      );
      await OfflineStorageService.saveSetting(
        'theme_use_system',
        state.useSystemTheme,
      );
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
    }
  }

  void setPrimaryColor(String hexColor) {
    state = state.copyWith(primaryColorHex: hexColor);
    AppColors.updatePrimary(state.primaryColor);
    _saveSettings();
  }

  void setFontFamily(String font) {
    state = state.copyWith(fontFamily: font);
    _saveSettings();
  }

  void setFontSizeScale(double scale) {
    state = state.copyWith(fontSizeScale: scale.clamp(0.8, 1.4));
    _saveSettings();
  }

  void setDarkMode(bool enabled) {
    state = state.copyWith(useDarkMode: enabled, useSystemTheme: false);
    _saveSettings();
  }

  void setUseSystemTheme(bool enabled) {
    state = state.copyWith(useSystemTheme: enabled);
    _saveSettings();
  }

  void resetToDefaults() {
    state = const ThemeSettingsModel();
    AppColors.updatePrimary(state.primaryColor);
    _saveSettings();
  }
}

/// Build theme from settings
ThemeData _buildTheme(ThemeSettingsModel settings, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final primary = settings.primaryColor;

  // Text theme with custom font and scale
  TextTheme textTheme(TextTheme base) {
    final scaled = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 57 * settings.fontSizeScale,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 45 * settings.fontSizeScale,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36 * settings.fontSizeScale,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32 * settings.fontSizeScale,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28 * settings.fontSizeScale,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24 * settings.fontSizeScale,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22 * settings.fontSizeScale,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16 * settings.fontSizeScale,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14 * settings.fontSizeScale,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16 * settings.fontSizeScale,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14 * settings.fontSizeScale,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12 * settings.fontSizeScale,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14 * settings.fontSizeScale,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12 * settings.fontSizeScale,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11 * settings.fontSizeScale,
      ),
    );
    return GoogleFonts.getTextTheme(settings.fontFamily, scaled);
  }

  // Colors - using direct values for dynamic theme generation
  final background = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
  final textPrimary = isDark
      ? const Color(0xFFF8FAFC)
      : const Color(0xFF1E293B);
  final textSecondary = isDark
      ? const Color(0xFFCBD5E1)
      : const Color(0xFF64748B);
  final border = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    ),
    textTheme: textTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 2,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14 * settings.fontSizeScale,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14 * settings.fontSizeScale,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14 * settings.fontSizeScale,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF253248) : const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: textPrimary),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return textSecondary;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary.withValues(alpha: 0.4);
        }
        return border;
      }),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark
          ? const Color(0xFF334155)
          : const Color(0xFF1E293B),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
