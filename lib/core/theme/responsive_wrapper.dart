/// Responsive Wrapper Widget
/// Handles SafeArea + keyboard-aware scrolling + max-width constraints
/// Wrap any screen body with this to prevent overflow errors
library;

import 'package:flutter/material.dart';

/// A safety wrapper that prevents common overflow errors
/// - SafeArea for notches/status bars
/// - Keyboard-aware bottom padding
/// - Optional scroll wrapping
/// - Optional max-width constraint for centered content
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  /// Whether to wrap in SafeArea (default: true)
  final bool useSafeArea;

  /// Whether to make the content scrollable (default: true)
  final bool scrollable;

  /// Whether to add keyboard padding (default: true)
  final bool keyboardAware;

  /// Optional max width for centered content
  final double? maxWidth;

  /// Background color
  final Color? backgroundColor;

  /// Padding around the content
  final EdgeInsetsGeometry? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.scrollable = true,
    this.keyboardAware = true,
    this.maxWidth,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Add padding if specified
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    // Center with max width if specified
    if (maxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }

    // Make scrollable if needed
    if (scrollable) {
      content = SingleChildScrollView(
        padding: keyboardAware
            ? EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              )
            : null,
        child: content,
      );
    } else if (keyboardAware) {
      // Even if not scrollable, add keyboard padding
      content = Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: content,
      );
    }

    // SafeArea
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    // Background color
    if (backgroundColor != null) {
      content = ColoredBox(color: backgroundColor!, child: content);
    }

    return content;
  }
}

/// A scroll-safe Column that wraps in SingleChildScrollView
/// Use instead of Column when content might overflow
class ScrollableColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final EdgeInsetsGeometry? padding;
  final bool keyboardAware;

  const ScrollableColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.padding,
    this.keyboardAware = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: keyboardAware
          ? EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ).add(padding ?? EdgeInsets.zero)
          : padding,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: children,
      ),
    );
  }
}
