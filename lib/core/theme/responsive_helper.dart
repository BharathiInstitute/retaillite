/// Responsive Breakpoints & Device Detection
/// 4 breakpoints: mobile (0-599), tablet (600-1023), desktop (1024-1919), desktopLarge (1920+)
/// Handles landscape phones, split-screen, and accessibility
library;

import 'package:flutter/material.dart';

/// Device type enumeration — 4 tiers
enum DeviceType { mobile, tablet, desktop, desktopLarge }

/// Responsive helper class for adaptive layouts
class ResponsiveHelper {
  ResponsiveHelper._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BREAKPOINTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMaxWidth = 1920;

  /// Get current device type based on AVAILABLE width (works in split-screen)
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Landscape phone: wide but short → treat as tablet
    if (width >= mobileMaxWidth && width < tabletMaxWidth && height < 500) {
      return DeviceType.tablet;
    }

    if (width < mobileMaxWidth) return DeviceType.mobile;
    if (width < tabletMaxWidth) return DeviceType.tablet;
    if (width < desktopMaxWidth) return DeviceType.desktop;
    return DeviceType.desktopLarge;
  }

  /// Get device type from constraints (for LayoutBuilder usage)
  static DeviceType getDeviceTypeFromWidth(double width) {
    if (width < mobileMaxWidth) return DeviceType.mobile;
    if (width < tabletMaxWidth) return DeviceType.tablet;
    if (width < desktopMaxWidth) return DeviceType.desktop;
    return DeviceType.desktopLarge;
  }

  /// Check device type
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) {
    final type = getDeviceType(context);
    return type == DeviceType.desktop || type == DeviceType.desktopLarge;
  }

  static bool isDesktopLarge(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktopLarge;

  /// Is phone in landscape mode (wide but short)?
  static bool isLandscapePhone(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= mobileMaxWidth &&
        size.width < tabletMaxWidth &&
        size.height < 500;
  }

  /// Get responsive value based on device type
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? desktopLarge,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.desktopLarge:
        return desktopLarge ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Get content max width for centered layouts
  static double contentMaxWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 720,
      desktop: 1200,
      desktopLarge: 1400,
    );
  }

  /// Get horizontal padding
  static double horizontalPadding(BuildContext context) {
    return value(
      context,
      mobile: 16,
      tablet: 24,
      desktop: 32,
      desktopLarge: 40,
    );
  }

  /// Get grid columns for product grid based on screen width
  static int gridColumns(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 2; // Tiny phones
    if (w < 428) return 3; // Standard phones
    if (w < 600) return 4; // Large phones
    if (w < 1024) return 3; // Tablet
    if (w < 1440) return 4; // Desktop
    if (w < 1920) return 5; // Large desktop
    return 6; // XL desktop
  }

  /// Get bottom padding for mobile navigation
  static double bottomNavPadding(BuildContext context) {
    return isMobile(context) ? 80 : 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE-FIRST SCALING FUNCTIONS (kept for backward compat)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Base design width (iPhone SE)
  static const double _baseWidth = 375;

  /// Scale value proportionally to screen width (mobile-focused)
  /// Clamped between 0.85-1.15 to prevent extremes
  static double scale(BuildContext context, double value) {
    final ratio = screenWidth(context) / _baseWidth;
    return value * ratio.clamp(0.85, 1.15);
  }

  /// Get page padding based on screen width
  static double pagePadding(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 8;
    if (w < 390) return 10;
    if (w < 428) return 12;
    if (w < 600) return 14;
    if (w < 1024) return 16;
    if (w < 1920) return 20;
    return 24;
  }

  /// Get spacing/gap based on screen width
  static double spacing(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 6;
    if (w < 428) return 8;
    if (w < 600) return 10;
    return 12;
  }

  /// Get button height based on screen width
  static double buttonHeight(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 40;
    if (w < 600) return 44;
    return 48;
  }

  /// Get input field height based on screen width
  static double inputHeight(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 40;
    if (w < 600) return 44;
    return 48;
  }

  /// Get icon size based on screen width
  static double iconSize(BuildContext context, {bool small = false}) {
    final w = screenWidth(context);
    if (small) {
      if (w < 360) return 16;
      if (w < 600) return 18;
      return 20;
    }
    if (w < 360) return 18;
    if (w < 600) return 20;
    return 22;
  }

  /// Get app bar height
  static double appBarHeight(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 44;
    if (w < 600) return 48;
    return 56;
  }

  /// Get modal padding
  static double modalPadding(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 10;
    if (w < 390) return 12;
    if (w < 600) return 14;
    return 16;
  }

  /// Get card height for product grid
  static double productCardHeight(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 85;
    if (w < 428) return 95;
    if (w < 600) return 100;
    return 110;
  }
}

/// Responsive layout builder widget — supports 4 breakpoints
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? desktopLarge;

  const ResponsiveLayout({
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
        if (constraints.maxWidth >= ResponsiveHelper.desktopMaxWidth) {
          return desktopLarge ?? desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= ResponsiveHelper.tabletMaxWidth) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= ResponsiveHelper.mobileMaxWidth) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// Responsive visibility widget
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final bool visibleOnDesktopLarge;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.visibleOnDesktopLarge = true,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final isVisible = switch (deviceType) {
      DeviceType.mobile => visibleOnMobile,
      DeviceType.tablet => visibleOnTablet,
      DeviceType.desktop => visibleOnDesktop,
      DeviceType.desktopLarge => visibleOnDesktopLarge,
    };

    return isVisible ? child : const SizedBox.shrink();
  }
}

/// Extension for responsive values
extension ResponsiveExtension on BuildContext {
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  bool get isDesktopLarge => ResponsiveHelper.isDesktopLarge(this);
  double get screenWidth => ResponsiveHelper.screenWidth(this);
  double get screenHeight => ResponsiveHelper.screenHeight(this);
}
