/// Schema Migration Service for Firestore documents
///
/// Handles backward-compatible schema upgrades when the app updates.
/// Each migration runs once per user and is idempotent.
///
/// Usage:
///   At app startup (after auth), call:
///     SchemaMigrationService.runMigrations(userId);
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents a single schema migration step.
class SchemaMigration {
  /// Unique identifier (e.g., "v7_1_add_customers_limit")
  final String id;

  /// Target schema version this migration brings the user to
  final int targetVersion;

  /// Human-readable description
  final String description;

  /// The migration function — receives the user's root doc ref
  final Future<void> Function(DocumentReference<Map<String, dynamic>> userRef)
  migrate;

  const SchemaMigration({
    required this.id,
    required this.targetVersion,
    required this.description,
    required this.migrate,
  });
}

/// Central registry and runner for all schema migrations.
class SchemaMigrationService {
  SchemaMigrationService._();

  /// Current schema version — bump this when adding new migrations
  static const int currentSchemaVersion = 1;

  /// All migrations in order. Each must be idempotent (safe to re-run).
  static final List<SchemaMigration> _migrations = [
    // ── Migration 1: Ensure all users have limits.customersLimit ──
    SchemaMigration(
      id: 'v1_ensure_customers_limit',
      targetVersion: 1,
      description: 'Add customersLimit to user limits if missing',
      migrate: (userRef) async {
        final doc = await userRef.get();
        if (!doc.exists) return;

        final data = doc.data();
        final limits = data?['limits'] as Map<String, dynamic>?;

        if (limits != null && !limits.containsKey('customersLimit')) {
          // Default: 10 for free, will be overwritten by subscription plan
          await userRef.update({'limits.customersLimit': 10});
        }
      },
    ),
  ];

  /// Run all pending migrations for a user.
  /// Call this once at app startup after authentication.
  static Future<void> runMigrations(String userId) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      final doc = await userRef.get();

      if (!doc.exists) return;

      final data = doc.data();
      final currentVersion = (data?['schemaVersion'] as int?) ?? 0;

      if (currentVersion >= currentSchemaVersion) {
        // Already up to date
        return;
      }

      // Run only migrations that haven't been applied
      final pendingMigrations =
          _migrations.where((m) => m.targetVersion > currentVersion).toList()
            ..sort((a, b) => a.targetVersion.compareTo(b.targetVersion));

      if (pendingMigrations.isEmpty) return;

      debugPrint(
        '[Migration] Running ${pendingMigrations.length} migration(s) '
        'for user $userId (v$currentVersion → v$currentSchemaVersion)',
      );

      for (final migration in pendingMigrations) {
        try {
          await migration.migrate(userRef);
          debugPrint('[Migration] ✅ ${migration.id}');
        } catch (e) {
          // Log but don't crash — migrations must be non-blocking
          debugPrint('[Migration] ❌ ${migration.id}: $e');
          // Don't update schemaVersion — retry next launch
          return;
        }
      }

      // Mark schema as up-to-date
      await userRef.update({
        'schemaVersion': currentSchemaVersion,
        '_lastMigrationAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[Migration] All migrations complete for user $userId');
    } catch (e) {
      // Never crash the app due to migration failure
      debugPrint('[Migration] Error running migrations: $e');
    }
  }

  /// Check if migrations are needed (lightweight — no writes)
  static Future<bool> needsMigration(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return false;

      final currentVersion = (doc.data()?['schemaVersion'] as int?) ?? 0;
      return currentVersion < currentSchemaVersion;
    } catch (_) {
      return false;
    }
  }
}
