/// App Theme - Combines colors, typography, sizes into ThemeData
/// Single source of truth for Flutter theme
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retaillite/core/design/app_colors.dart';
import 'package:retaillite/core/design/app_sizes.dart';

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      onSecondary: AppColors.textOnPrimary,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),

    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.card,
    dividerColor: AppColors.divider,

    // Typography
    textTheme: _textTheme(AppColors.textPrimary),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),

    // Elevated Button (Primary)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // Outlined Button (Secondary)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 44),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    // Icon Button
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        minimumSize: const Size(36, 36),
        padding: const EdgeInsets.all(8),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
      labelStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryBg,
      disabledColor: AppColors.divider,
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        side: const BorderSide(color: AppColors.border),
      ),
      side: const BorderSide(color: AppColors.border),
      checkmarkColor: AppColors.primary,
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.textSecondary;
      }),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: AppColors.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryLight.withValues(alpha: 0.5);
        }
        return AppColors.border;
      }),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      dragHandleColor: AppColors.border,
      dragHandleSize: Size(40, 4),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // Icons
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),

    // Progress Indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get dark => light.copyWith(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryLight,

      secondary: AppColors.primaryLight,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.cardDark,
    dividerColor: AppColors.borderDark,
    textTheme: _textTheme(AppColors.textPrimaryDark),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static TextTheme _textTheme(Color textColor) => TextTheme(
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: textColor,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: textColor,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textColor,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: textColor,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: textColor,
    ),
  );
}
