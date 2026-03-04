/// Web-specific Firestore persistence using IndexedDB
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Enable IndexedDB persistence on web via Firestore settings.
/// Must be called BEFORE any other Firestore operations.
Future<void> enableWebPersistence() async {
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // 100 MB
    );
    debugPrint('✅ Web persistence enabled (IndexedDB, 100 MB cache)');
  } catch (e) {
    debugPrint('⚠️ Web persistence setup: $e');
  }
}
