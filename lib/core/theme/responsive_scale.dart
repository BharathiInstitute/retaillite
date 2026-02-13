/// Responsive Scaling Engine
/// Proportional scaling with safety clamps
/// Design base: 1920px desktop, font min 11px, touch min 48px
library;

import 'dart:math';
import 'package:flutter/material.dart';

class ResponsiveScale {
  ResponsiveScale._();

  /// Design base width (desktop)
  static const double designWidth = 1920.0;

  /// Scale factor limits
  static const double minScale = 0.3;
  static const double maxScale = 1.5;

  /// Minimum font size for readability
  static const double minFontSize = 11.0;

  /// Minimum touch target for accessibility
  static const double minTouchTarget = 48.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE SCALING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the current scale factor (clamped)
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / designWidth).clamp(minScale, maxScale);
  }

  /// Scale a value proportionally to screen width with clamps
  /// Use for spacing, padding, widths, heights
  static double scaled(BuildContext context, double designValue) {
    return designValue * scaleFactor(context);
  }

  /// Scale width value — same as scaled but semantically clearer
  static double scaledWidth(BuildContext context, double designValue) {
    return designValue * scaleFactor(context);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT SCALING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Scale font size — never below [minFontSize]
  static double scaledFont(BuildContext context, double designFontSize) {
    final scaled = designFontSize * scaleFactor(context);
    return max(scaled, minFontSize);
  }

  /// Clamp text scale factor to prevent huge system fonts
  /// Returns a clamped textScaler value (max 1.3x)
  static double textScaleClamp(BuildContext context) {
    final scaler = MediaQuery.of(context).textScaler;
    final scale = scaler.scale(1.0);
    return scale.clamp(0.8, 1.3);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOUCH TARGET SCALING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Scale touch target — never below [minTouchTarget] (48px)
  static double scaledTouchTarget(BuildContext context, double designSize) {
    final scaled = designSize * scaleFactor(context);
    return max(scaled, minTouchTarget);
  }

  /// Ensure a size is at least the minimum touch target
  static double ensureTouchTarget(double size) {
    return max(size, minTouchTarget);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVENIENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Scale padding/margin values
  static EdgeInsets scaledPadding(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: scaled(context, horizontal),
      vertical: scaled(context, vertical),
    );
  }

  /// Scale all-side padding
  static EdgeInsets scaledPaddingAll(BuildContext context, double value) {
    final s = scaled(context, value);
    return EdgeInsets.all(s);
  }
}
