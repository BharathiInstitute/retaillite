/// Theme Settings Model - User-customizable theme preferences
library;

import 'package:flutter/material.dart';

/// User theme preferences stored in Firestore/Hive
class ThemeSettingsModel {
  final String primaryColorHex;
  final String fontFamily;
  final double fontSizeScale; // 0.8 = small, 1.0 = normal, 1.2 = large
  final bool useDarkMode;
  final bool useSystemTheme;

  const ThemeSettingsModel({
    this.primaryColorHex = '#10B981', // Emerald default
    this.fontFamily = 'Inter',
    this.fontSizeScale = 1.0,
    this.useDarkMode = false,
    this.useSystemTheme = false, // Default to light — user chooses explicitly
  });

  // Preset color options
  static const List<String> colorPresets = [
    '#10B981', // Emerald (default)
    '#3B82F6', // Blue
    '#8B5CF6', // Violet
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#06B6D4', // Cyan
    '#84CC16', // Lime
  ];

  // Preset font options
  static const List<String> fontPresets = [
    'Inter',
    'Roboto',
    'Poppins',
    'Open Sans',
    'Lato',
  ];

  Color get primaryColor {
    try {
      final hex = primaryColorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  ThemeSettingsModel copyWith({
    String? primaryColorHex,
    String? fontFamily,
    double? fontSizeScale,
    bool? useDarkMode,
    bool? useSystemTheme,
  }) {
    return ThemeSettingsModel(
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      useDarkMode: useDarkMode ?? this.useDarkMode,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
    );
  }

  Map<String, dynamic> toJson() => {
    'primaryColorHex': primaryColorHex,
    'fontFamily': fontFamily,
    'fontSizeScale': fontSizeScale,
    'useDarkMode': useDarkMode,
    'useSystemTheme': useSystemTheme,
  };

  factory ThemeSettingsModel.fromJson(Map<String, dynamic> json) {
    return ThemeSettingsModel(
      primaryColorHex: json['primaryColorHex'] as String? ?? '#10B981',
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      fontSizeScale: (json['fontSizeScale'] as num?)?.toDouble() ?? 1.0,
      useDarkMode: json['useDarkMode'] as bool? ?? false,
      useSystemTheme: json['useSystemTheme'] as bool? ?? true,
    );
  }
}
