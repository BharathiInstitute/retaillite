/// Adaptive Layout Widget
/// Switches between DIFFERENT layouts per breakpoint
/// Uses LayoutBuilder for available-width detection (works in split-screen)
library;

import 'package:flutter/material.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';

/// Builds different widget trees per breakpoint
/// Key insight: mobile shows a DIFFERENT UI, not a shrunk desktop
class AdaptiveLayout extends StatelessWidget {
  /// Required: mobile layout builder
  final Widget Function(BuildContext context) mobile;

  /// Optional: tablet layout builder (falls back to mobile)
  final Widget Function(BuildContext context)? tablet;

  /// Optional: desktop layout builder (falls back to tablet → mobile)
  final Widget Function(BuildContext context)? desktop;

  /// Optional: large desktop layout builder (falls back to desktop → tablet → mobile)
  final Widget Function(BuildContext context)? desktopLarge;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.desktopLarge,
  });

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to detect AVAILABLE width (not device width)
    // This handles split-screen and window resizing correctly
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveHelper.getDeviceTypeFromWidth(
          constraints.maxWidth,
        );

        return switch (deviceType) {
          DeviceType.desktopLarge =>
            (desktopLarge ?? desktop ?? tablet ?? mobile)(context),
          DeviceType.desktop => (desktop ?? tablet ?? mobile)(context),
          DeviceType.tablet => (tablet ?? mobile)(context),
          DeviceType.mobile => mobile(context),
        };
      },
    );
  }
}

/// A simpler variant that just takes pre-built widgets instead of builders
class AdaptiveLayoutStatic extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? desktopLarge;

  const AdaptiveLayoutStatic({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.desktopLarge,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveHelper.getDeviceTypeFromWidth(
          constraints.maxWidth,
        );

        return switch (deviceType) {
          DeviceType.desktopLarge =>
            desktopLarge ?? desktop ?? tablet ?? mobile,
          DeviceType.desktop => desktop ?? tablet ?? mobile,
          DeviceType.tablet => tablet ?? mobile,
          DeviceType.mobile => mobile,
        };
      },
    );
  }
}
