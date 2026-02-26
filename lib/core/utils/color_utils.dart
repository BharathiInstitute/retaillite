/// Color utility extensions
library;

import 'package:flutter/material.dart';

/// Extension to provide opacity helper that avoids deprecation
extension ColorOpacity on Color {
  /// Returns a color with the specified opacity (0.0 to 1.0)
  /// This is a replacement for the deprecated withOpacity method
  Color withAlpha8(double opacity) {
    return Color.fromRGBO(
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
      opacity,
    );
  }
}

/// Pre-defined opacity colors for common use cases
class OpacityColors {
  OpacityColors._();

  // Black opacities
  static const Color black05 = Color.fromRGBO(0, 0, 0, 0.05);
  static const Color black08 = Color.fromRGBO(0, 0, 0, 0.08);
  static const Color black10 = Color.fromRGBO(0, 0, 0, 0.10);
  static const Color black12 = Color.fromRGBO(0, 0, 0, 0.12);
  static const Color black20 = Color.fromRGBO(0, 0, 0, 0.20);
  static const Color black30 = Color.fromRGBO(0, 0, 0, 0.30);
  static const Color black50 = Color.fromRGBO(0, 0, 0, 0.50);

  // White opacities
  static const Color white10 = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color white20 = Color.fromRGBO(255, 255, 255, 0.20);
  static const Color white50 = Color.fromRGBO(255, 255, 255, 0.50);
  static const Color white70 = Color.fromRGBO(255, 255, 255, 0.70);

  // Primary (Indigo 6366F1) opacities
  static const Color primary10 = Color.fromRGBO(99, 102, 241, 0.10);
  static const Color primary20 = Color.fromRGBO(99, 102, 241, 0.20);
  static const Color primary30 = Color.fromRGBO(99, 102, 241, 0.30);

  // Success (Green 22C55E) opacities
  static const Color success10 = Color.fromRGBO(34, 197, 94, 0.10);
  static const Color success20 = Color.fromRGBO(34, 197, 94, 0.20);

  // Error (Red EF4444) opacities
  static const Color error10 = Color.fromRGBO(239, 68, 68, 0.10);
  static const Color error20 = Color.fromRGBO(239, 68, 68, 0.20);
  static const Color error30 = Color.fromRGBO(239, 68, 68, 0.30);

  // Warning (Amber F59E0B) opacities
  static const Color warning10 = Color.fromRGBO(245, 158, 11, 0.10);
  static const Color warning20 = Color.fromRGBO(245, 158, 11, 0.20);
  static const Color warning30 = Color.fromRGBO(245, 158, 11, 0.30);

  // Info (Blue 3B82F6) opacities
  static const Color info10 = Color.fromRGBO(59, 130, 246, 0.10);
  static const Color info20 = Color.fromRGBO(59, 130, 246, 0.20);

  // Secondary (Emerald 10B981) opacities
  static const Color secondary10 = Color.fromRGBO(16, 185, 129, 0.10);
  static const Color secondary20 = Color.fromRGBO(16, 185, 129, 0.20);

  // Grey opacities
  static const Color grey10 = Color.fromRGBO(128, 128, 128, 0.10);
  static const Color grey20 = Color.fromRGBO(128, 128, 128, 0.20);
}
