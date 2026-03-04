/// Shared platform detection utility.
///
/// Single source of truth for platform string used in error logging,
/// health metrics, and performance tracking.
library;

import 'package:flutter/foundation.dart';

/// Returns the current platform as a lowercase string.
///
/// Values: `web`, `android`, `ios`, `windows`, `macos`, `linux`, `unknown`.
String get currentPlatformName {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.linux:
      return 'linux';
    default:
      return 'unknown';
  }
}
