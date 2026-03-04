/// Accessibility helper utilities for RetailLite.
///
/// Provides semantic wrappers and label helpers
/// for screen reader and TalkBack/VoiceOver support.
library;

import 'package:flutter/material.dart';

/// Wraps a widget with semantic annotation for screen readers.
///
/// Usage:
/// ```dart
/// A11y.label(
///   label: 'Add product to cart',
///   child: IconButton(icon: Icon(Icons.add), onPressed: ...),
/// )
/// ```
class A11y {
  /// Wrap a widget with a semantic label (for screen readers)
  static Widget label({
    required String label,
    required Widget child,
    bool button = false,
    bool header = false,
    bool image = false,
    bool enabled = true,
    String? hint,
    String? value,
  }) {
    return Semantics(
      label: label,
      button: button,
      header: header,
      image: image,
      enabled: enabled,
      hint: hint,
      value: value,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Wrap an interactive widget (button-like) with label
  static Widget button({
    required String label,
    required Widget child,
    bool enabled = true,
    String? hint,
  }) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      hint: hint,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Wrap a section header
  static Widget header({required String label, required Widget child}) {
    return Semantics(
      label: label,
      header: true,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Create a semantic label for currency amounts
  static String currency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Create a semantic label for stock status
  static String stockStatus(int stock, bool isLow, bool isOut) {
    if (isOut) return 'Out of stock';
    if (isLow) return 'Low stock: $stock remaining';
    return '$stock in stock';
  }

  /// Announce a message to screen reader (via live region)
  static Widget liveRegion({required String message, required Widget child}) {
    return Semantics(liveRegion: true, label: message, child: child);
  }
}
