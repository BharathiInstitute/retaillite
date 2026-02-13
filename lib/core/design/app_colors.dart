/// App Colors - Single source of truth for all colors
/// Change here → affects entire app
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY - Dynamic, updates based on user's theme selection
  // Default: Emerald Green. Call updatePrimary() to change.
  // ═══════════════════════════════════════════════════════════════════════════
  static Color primary = const Color(0xFF10B981); // Emerald 500
  static Color primaryDark = const Color(0xFF059669); // Emerald 600
  static Color primaryLight = const Color(0xFF34D399); // Emerald 400
  static Color primaryBg = const Color(0xFFECFDF5); // Emerald 50

  // Secondary (stays synced with primary)
  static Color secondary = primary;
  static Color secondaryLight = primaryLight;
  static Color secondaryDark = primaryDark;

  /// Update all primary shades from a single color using HSL math.
  /// Called when user changes theme color in settings.
  static void updatePrimary(Color color) {
    primary = color;

    // Generate shades using HSL
    final hsl = HSLColor.fromColor(color);
    primaryDark = hsl
        .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
        .toColor();
    primaryLight = hsl
        .withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0))
        .toColor();
    // Very light tint for backgrounds
    primaryBg = Color.fromRGBO(
      color.r.toInt(),
      color.g.toInt(),
      color.b.toInt(),
      0.08,
    );

    // Keep secondary synced with primary
    secondary = primary;
    secondaryLight = primaryLight;
    secondaryDark = primaryDark;

    // Update gradients
    primaryGradient = LinearGradient(
      colors: [primary, primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    successGradient = LinearGradient(
      colors: [secondary, secondaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Accent (Amber) - Fixed, not theme-dependent
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS - Fixed, not theme-dependent
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color successBg = Color(0xFFF0FDF4); // Green 50
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningBg = Color(0xFFFFFBEB); // Amber 50
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorBg = Color(0xFFFEF2F2); // Red 50
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoBg = Color(0xFFEFF6FF); // Blue 50

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL COLORS - LIGHT MODE
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFF1F5F9); // Slate 100

  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Colors.white;

  // Backward-compatible aliases (Light mode)
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color cardLight = card;
  static const Color dividerLight = divider;
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color textTertiaryLight = textMuted;

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL COLORS - DARK MODE
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF334155); // Slate 700
  static const Color borderDark = Color(0xFF475569); // Slate 600
  static const Color dividerDark = borderDark;
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFFCBD5E1); // Slate 300
  static const Color textTertiaryDark = Color(0xFF94A3B8);

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT COLORS - Fixed, not theme-dependent
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color cash = Color(0xFF22C55E); // Green
  static const Color upi = Color(0xFF6366F1); // Indigo
  static const Color credit = Color(0xFFEF4444); // Red (Udhar)
  static const Color udhar = credit; // Alias

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS - Dynamic, updates with primary
  // ═══════════════════════════════════════════════════════════════════════════
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient successGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)], // Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// APP SPACING (backward compatible)
// ═══════════════════════════════════════════════════════════════════════════
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// APP SHADOWS (backward compatible)
// ═══════════════════════════════════════════════════════════════════════════
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get small => [
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
