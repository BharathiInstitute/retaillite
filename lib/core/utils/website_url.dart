/// Centralized website URL helper.
///
/// Production (Firebase hosting):
///   App at /app/, website at / — same domain, always works.
///
/// Local dev (flutter run):
///   - Preview mode (preview.ps1 on port 9000): / works directly
///   - Dev mode (flutter run + http-server): website at localhost:8080
///
/// On native (Android / Windows) this should never be called,
/// but returns an empty string as a safety net.
library;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// Whether the current platform should show website navigation links.
/// Only web builds show the website link.
bool get showWebsiteLink => kIsWeb;

/// The URL that takes the user from the Flutter app to the marketing website.
///
/// In production: / (same domain root)
/// In debug: / first (works in preview.ps1 mode), falls back to localhost:8080
String get websiteUrl {
  if (!kDebugMode) return '/';
  // In debug, we might be on preview.ps1 (port 9000) where / is the website,
  // or on flutter run (port 5050) where website is on 8080.
  // Use / which works in preview mode. The JS on the website handles the
  // reverse direction. For flutter run mode, 8080 is the fallback.
  return 'http://localhost:8080';
}

/// The URL that takes the user from the marketing website to the Flutter app.
/// (Primarily used in the static website HTML, listed here for reference.)
String get appUrl => '/app/';
