/// Provides pre-configured Riverpod overrides for widget and screen testing.
///
/// Groups overrides by scenario so test files can compose what they need.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base overrides sufficient to render most widgets without Firebase.
///
/// Usage:
/// ```dart
/// ProviderScope(overrides: baseOverrides(), child: ...);
/// ```
List<Override> baseOverrides({String plan = 'free'}) {
  // Intentionally minimal: add provider overrides as tests demand them.
  return [];
}
