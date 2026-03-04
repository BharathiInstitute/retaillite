/// Privacy consent management service.
///
/// Tracks user consent for data processing, analytics, and terms acceptance.
/// Implements DPDP Act (India) requirements:
///   - Informed consent before data processing
///   - Consent versioning (re-consent on policy updates)
///   - Right to withdraw consent
///   - Right to data portability (export)
///   - Right to erasure (account deletion — see auth_provider.dart)
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:retaillite/core/services/analytics_service.dart';
import 'package:retaillite/core/services/offline_storage_service.dart';

/// Current versions of legal documents.
/// Bump these when the policy/terms change to trigger re-consent.
class LegalDocVersions {
  static const String privacyPolicy = '1.0.0';
  static const String termsOfService = '1.0.0';

  /// URLs for full legal documents
  static const String privacyPolicyUrl = 'https://retaillite.com/privacy';
  static const String termsOfServiceUrl = 'https://retaillite.com/terms';
}

/// Consent record stored in Firestore
class ConsentRecord {
  final String privacyPolicyVersion;
  final String termsOfServiceVersion;
  final DateTime acceptedAt;
  final bool analyticsConsent;
  final bool crashlyticsConsent;

  const ConsentRecord({
    required this.privacyPolicyVersion,
    required this.termsOfServiceVersion,
    required this.acceptedAt,
    this.analyticsConsent = true,
    this.crashlyticsConsent = true,
  });

  Map<String, dynamic> toMap() => {
    'privacyPolicyVersion': privacyPolicyVersion,
    'termsOfServiceVersion': termsOfServiceVersion,
    'acceptedAt': Timestamp.fromDate(acceptedAt),
    'analyticsConsent': analyticsConsent,
    'crashlyticsConsent': crashlyticsConsent,
  };

  factory ConsentRecord.fromMap(Map<String, dynamic> map) {
    return ConsentRecord(
      privacyPolicyVersion: map['privacyPolicyVersion'] as String? ?? '',
      termsOfServiceVersion: map['termsOfServiceVersion'] as String? ?? '',
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      analyticsConsent: map['analyticsConsent'] as bool? ?? true,
      crashlyticsConsent: map['crashlyticsConsent'] as bool? ?? true,
    );
  }

  /// Whether consent is up-to-date with current legal document versions
  bool get isCurrentVersion =>
      privacyPolicyVersion == LegalDocVersions.privacyPolicy &&
      termsOfServiceVersion == LegalDocVersions.termsOfService;
}

/// Service for managing privacy consent and DPDP compliance
class PrivacyConsentService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Get the current user's consent record
  static Future<ConsentRecord?> getConsent() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('consent')
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return ConsentRecord.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('⚠️ Failed to read consent: $e');
      return null;
    }
  }

  /// Record user consent (on registration or re-consent)
  static Future<bool> recordConsent({
    bool analyticsConsent = true,
    bool crashlyticsConsent = true,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final record = ConsentRecord(
        privacyPolicyVersion: LegalDocVersions.privacyPolicy,
        termsOfServiceVersion: LegalDocVersions.termsOfService,
        acceptedAt: DateTime.now(),
        analyticsConsent: analyticsConsent,
        crashlyticsConsent: crashlyticsConsent,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('consent')
          .set(record.toMap());

      // Apply analytics preference
      await _applyAnalyticsPreference(analyticsConsent);

      // Cache consent locally
      unawaited(
        OfflineStorageService.saveSetting(
          'consent_version',
          '${LegalDocVersions.privacyPolicy}|${LegalDocVersions.termsOfService}',
        ),
      );

      return true;
    } catch (e) {
      debugPrint('⚠️ Failed to record consent: $e');
      return false;
    }
  }

  /// Check if user needs to re-consent (policy version changed)
  static Future<bool> needsReConsent() async {
    // Quick local check first
    final cachedVersion = OfflineStorageService.getSetting<String>(
      'consent_version',
    );
    const expectedVersion =
        '${LegalDocVersions.privacyPolicy}|${LegalDocVersions.termsOfService}';

    if (cachedVersion == expectedVersion) return false;

    // Full Firestore check
    final consent = await getConsent();
    if (consent == null) return true;
    return !consent.isCurrentVersion;
  }

  /// Update analytics opt-in/out preference
  static Future<bool> updateAnalyticsConsent(bool enabled) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('consent')
          .update({'analyticsConsent': enabled});

      await _applyAnalyticsPreference(enabled);
      return true;
    } catch (e) {
      debugPrint('⚠️ Failed to update analytics consent: $e');
      return false;
    }
  }

  /// Apply analytics collection preference
  static Future<void> _applyAnalyticsPreference(bool enabled) async {
    try {
      await AnalyticsService.setAnalyticsEnabled(enabled);
    } catch (e) {
      debugPrint('⚠️ Failed to apply analytics preference: $e');
    }
  }

  /// Export all user data as JSON (DPDP right to data portability)
  ///
  /// Exports: profile, products, bills, customers, transactions, expenses,
  /// settings, attendance, and consent records.
  static Future<String> exportAllUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final userRef = _firestore.collection('users').doc(uid);
    final exportData = <String, dynamic>{};

    try {
      // 1. User profile
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        exportData['profile'] = userDoc.data();
      }

      // 2. Sub-collections
      const collections = [
        'products',
        'bills',
        'customers',
        'expenses',
        'transactions',
        'settings',
        'attendance',
        'notifications',
        'counters',
      ];

      for (final collection in collections) {
        final snapshot = await userRef
            .collection(collection)
            .limit(10000)
            .get();
        if (snapshot.docs.isNotEmpty) {
          exportData[collection] = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        }
      }

      // 3. Customer transactions (nested)
      final customers = await userRef
          .collection('customers')
          .limit(10000)
          .get();
      final customerTransactions = <String, dynamic>{};
      for (final customer in customers.docs) {
        final txns = await customer.reference
            .collection('transactions')
            .limit(5000)
            .get();
        if (txns.docs.isNotEmpty) {
          customerTransactions[customer.id] = txns.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        }
      }
      if (customerTransactions.isNotEmpty) {
        exportData['customerTransactions'] = customerTransactions;
      }

      // 4. Metadata
      exportData['exportMetadata'] = {
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': uid,
        'email': _auth.currentUser?.email,
        'appVersion': 'RetailLite',
      };

      // Convert timestamps to ISO strings for portability
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(_convertTimestamps(exportData));
    } catch (e) {
      debugPrint('⚠️ Data export failed: $e');
      rethrow;
    }
  }

  /// Recursively convert Firestore Timestamps to ISO strings
  static dynamic _convertTimestamps(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is Map) {
      return data.map((key, value) => MapEntry(key, _convertTimestamps(value)));
    } else if (data is List) {
      return data.map(_convertTimestamps).toList();
    }
    return data;
  }
}
