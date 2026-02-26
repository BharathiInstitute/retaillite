import 'package:flutter/material.dart';

/// Wraps a widget in MaterialApp for widget testing
Widget testApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    home: Scaffold(body: child),
    theme: theme ?? ThemeData.light(),
  );
}

/// Wraps a widget in MaterialApp with dark theme
Widget testAppDark(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
    theme: ThemeData.dark(),
  );
}
