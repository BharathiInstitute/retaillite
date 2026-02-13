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
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ Web persistence enabled (IndexedDB)');
  } catch (e) {
    debugPrint('⚠️ Web persistence setup: $e');
  }
}
