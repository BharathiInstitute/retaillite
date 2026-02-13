/// App Dimensions - Single source of truth for ALL layout dimensions
/// Enhanced with per-breakpoint values for navigation, cart, grid, etc.
/// Change here → affects entire app
library;

import 'package:flutter/material.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';

class AppSizes {
  AppSizes._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTON HEIGHTS (Uses ResponsiveHelper)
  // ═══════════════════════════════════════════════════════════════════════════
  static double buttonHeight(BuildContext context) =>
      ResponsiveHelper.buttonHeight(context);

  static double buttonHeightSmall(BuildContext context) =>
      ResponsiveHelper.buttonHeight(context) - 4;

  static const double iconButton = 36;
  static const double fabSize = 48;

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT HEIGHTS
  // ═══════════════════════════════════════════════════════════════════════════
  static double inputHeight(BuildContext context) =>
      ResponsiveHelper.inputHeight(context);

  static const double inputHeightSmall = 40;

  // ═══════════════════════════════════════════════════════════════════════════
  // CHIP & BADGE SIZES
  // ═══════════════════════════════════════════════════════════════════════════
  static const double chipHeight = 32;
  static const double chipPadding = 12;
  static const double badgeSize = 20;

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING (Tight - no wasted space)
  // ═══════════════════════════════════════════════════════════════════════════
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;

  // Page padding (responsive)
  static double pagePadding(BuildContext context) =>
      ResponsiveHelper.pagePadding(context);

  static double pagePaddingLarge(BuildContext context) =>
      ResponsiveHelper.pagePadding(context) + 4;

  // Card padding
  static const double cardPadding = 12;
  static const double cardPaddingLarge = 16;

  // Modal padding (responsive)
  static double modalPadding(BuildContext context) =>
      ResponsiveHelper.modalPadding(context);

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════
  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  // ═══════════════════════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════════════════════
  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYOUT WIDTHS
  // ═══════════════════════════════════════════════════════════════════════════
  static double modalWidth(BuildContext context) =>
      ResponsiveHelper.isMobile(context)
      ? double.infinity
      : ResponsiveHelper.isTablet(context)
      ? 420
      : 480;

  static double sidebarWidth(BuildContext context) => ResponsiveHelper.value(
    context,
    mobile: 0.0,
    tablet: 72.0, // Rail - icons only
    desktop: 220.0, // Full sidebar
    desktopLarge: 240.0, // Wider full sidebar
  );

  static const double maxContentWidth = 1200;

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION DIMENSIONS (per breakpoint)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bottom navigation bar height (mobile only)
  static const double bottomNavHeight = 56;

  /// Navigation rail width (tablet)
  static const double navRailWidth = 72;

  /// Full sidebar width (desktop)
  static const double fullSidebarWidth = 220;

  /// Full sidebar width (large desktop)
  static const double fullSidebarWidthLarge = 240;

  // ═══════════════════════════════════════════════════════════════════════════
  // CART PANEL DIMENSIONS (per breakpoint)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cart panel width for desktop
  static double cartPanelWidth(BuildContext context) => ResponsiveHelper.value(
    context,
    mobile: double.infinity, // bottom sheet = full width
    tablet: 320.0, // slide-in overlay
    desktop: 350.0, // fixed right panel
    desktopLarge: 400.0, // wider fixed panel
  );

  /// Cart bottom sheet height (mobile) - fraction of screen
  static const double cartBottomSheetFraction = 0.7;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRODUCT GRID
  // ═══════════════════════════════════════════════════════════════════════════

  /// Product grid columns by breakpoint
  static int productGridColumns(BuildContext context) =>
      ResponsiveHelper.gridColumns(context);

  /// Product card aspect ratio
  static double productCardAspectRatio(BuildContext context) =>
      ResponsiveHelper.value(context, mobile: 0.75, tablet: 0.8, desktop: 0.85);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether search should always be visible or be an expandable icon
  static bool searchAlwaysVisible(BuildContext context) =>
      !ResponsiveHelper.isMobile(context);

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAV PADDING (for mobile)
  // ═══════════════════════════════════════════════════════════════════════════
  static double bottomPadding(BuildContext context) =>
      ResponsiveHelper.isMobile(context) ? 70 : 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // TOUCH TARGETS
  // ═══════════════════════════════════════════════════════════════════════════
  static const double minTouchTarget = 48;
}
