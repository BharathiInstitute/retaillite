/// High-level pump functions for widget and screen testing.
///
/// Wraps widgets in ProviderScope + MaterialApp so tests can focus on
/// interaction rather than boilerplate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pump a widget wrapped in ProviderScope + MaterialApp + Scaffold.
///
/// [overrides] are passed directly to ProviderScope.
/// [screenSize] defaults to a desktop viewport (1920×1080).
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override>? overrides,
  Size screenSize = const Size(1920, 1080),
  ThemeData? theme,
}) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: screen, theme: theme ?? ThemeData.light()),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.view.resetPhysicalSize());
}

/// Pump for mobile viewport (390×844 — iPhone 14).
Future<void> pumpMobile(
  WidgetTester tester,
  Widget screen, {
  List<Override>? overrides,
}) async {
  await pumpScreen(
    tester,
    screen,
    overrides: overrides,
    screenSize: const Size(390, 844),
  );
}

/// Pump for tablet viewport (820×1180 — iPad Air).
Future<void> pumpTablet(
  WidgetTester tester,
  Widget screen, {
  List<Override>? overrides,
}) async {
  await pumpScreen(
    tester,
    screen,
    overrides: overrides,
    screenSize: const Size(820, 1180),
  );
}
