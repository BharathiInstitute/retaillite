/// Responsive Utilities — Edge Cases
/// Handles foldables, accessibility, split-screen, system font scaling
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';
import 'package:retaillite/core/theme/responsive_scale.dart';

class ResponsiveUtils {
  ResponsiveUtils._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SPLIT-SCREEN / MULTI-WINDOW DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Detect if app is in split-screen mode
  /// Available width is much less than typical minimum
  static bool isSplitScreen(BuildContext context) {
    final logicalWidth = MediaQuery.of(context).size.width;

    // If available width is less than 60% of a typical phone,
    // we're likely in split-screen or floating window
    return logicalWidth < 300;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LANDSCAPE PHONE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Is phone in landscape mode (wide but short)?
  static bool isLandscapePhone(BuildContext context) {
    return ResponsiveHelper.isLandscapePhone(context);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCESSIBILITY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Is the user using large/bold text?
  static bool isLargeText(BuildContext context) {
    final scaler = MediaQuery.of(context).textScaler;
    return scaler.scale(1.0) > 1.2;
  }

  /// Is reduce motion enabled?
  static bool isReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Is high contrast mode?
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Get a safe animation duration (respects reduce motion)
  static Duration safeAnimationDuration(
    BuildContext context, {
    Duration normal = const Duration(milliseconds: 300),
  }) {
    return isReduceMotion(context) ? Duration.zero : normal;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAFE TEXT STYLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ensure a TextStyle has minimum font size
  static TextStyle safeTextStyle(TextStyle style) {
    final fontSize = style.fontSize ?? 14;
    return style.copyWith(fontSize: max(fontSize, ResponsiveScale.minFontSize));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GRID HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get pre-built grid delegate based on current breakpoint
  static SliverGridDelegateWithFixedCrossAxisCount responsiveGridDelegate(
    BuildContext context, {
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 8,
    double mainAxisSpacing = 8,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: ResponsiveHelper.gridColumns(context),
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAFE IMAGE WIDGET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build an Image widget with error handling and proper fit
  static Widget safeImage({
    required ImageProvider image,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
  }) {
    return Image(
      image: image,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey.shade400,
                size: 24,
              ),
            );
      },
    );
  }

  /// Build a safe network image with loading + error states
  static Widget safeNetworkImage({
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey.shade400,
            size: 24,
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KEYBOARD HEIGHT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get keyboard height (0 when keyboard is hidden)
  static double keyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Is keyboard currently visible?
  static bool isKeyboardVisible(BuildContext context) {
    return keyboardHeight(context) > 0;
  }
}
