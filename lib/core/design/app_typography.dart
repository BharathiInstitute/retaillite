/// App Typography - Single source of truth for all text styles
/// Change here → affects entire app
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retaillite/core/theme/responsive_helper.dart';

class AppTypography {
  AppTypography._();

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT FAMILY
  // ═══════════════════════════════════════════════════════════════════════════
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADINGS (Responsive)
  // ═══════════════════════════════════════════════════════════════════════════
  static TextStyle h1(BuildContext context) => GoogleFonts.inter(
    fontSize: ResponsiveHelper.isMobile(context) ? 20 : 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static TextStyle h2(BuildContext context) => GoogleFonts.inter(
    fontSize: ResponsiveHelper.isMobile(context) ? 16 : 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle h3(BuildContext context) => GoogleFonts.inter(
    fontSize: ResponsiveHelper.isMobile(context) ? 14 : 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY TEXT (Responsive)
  // ═══════════════════════════════════════════════════════════════════════════
  static TextStyle body(BuildContext context) => GoogleFonts.inter(
    fontSize: ResponsiveHelper.isMobile(context) ? 13 : 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
    fontSize: ResponsiveHelper.isMobile(context) ? 12 : 13,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LABELS & BUTTONS (Fixed)
  // ═══════════════════════════════════════════════════════════════════════════
  static TextStyle get button =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);

  static TextStyle get buttonSmall =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2);

  static TextStyle get label =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, height: 1.2);

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT TEXT
  // ═══════════════════════════════════════════════════════════════════════════
  static TextStyle get input => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static TextStyle get inputHint => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL STYLES
  // ═══════════════════════════════════════════════════════════════════════════
  static TextStyle get price =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2);

  static TextStyle get chip =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, height: 1.2);

  static TextStyle get mono =>
      GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.normal);
}
