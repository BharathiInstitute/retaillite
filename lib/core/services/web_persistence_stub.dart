/// Stub for non-web platforms — no-op
library;

import 'package:flutter/foundation.dart';

/// No-op on non-web platforms (mobile, desktop)
Future<void> enableWebPersistence() async {
  debugPrint('ℹ️ Web persistence not needed on this platform');
}
