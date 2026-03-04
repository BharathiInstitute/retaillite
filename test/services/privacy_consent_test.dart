/// Tests for PrivacyConsentService — LegalDocVersions and ConsentRecord
///
/// Tests pure data class logic and version checking.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/privacy_consent_service.dart';

void main() {
  // ── LegalDocVersions ──

  group('LegalDocVersions', () {
    test('privacyPolicy version is set', () {
      expect(LegalDocVersions.privacyPolicy, isNotEmpty);
    });

    test('termsOfService version is set', () {
      expect(LegalDocVersions.termsOfService, isNotEmpty);
    });

    test('privacyPolicyUrl is valid URL', () {
      expect(LegalDocVersions.privacyPolicyUrl, startsWith('https://'));
    });

    test('termsOfServiceUrl is valid URL', () {
      expect(LegalDocVersions.termsOfServiceUrl, startsWith('https://'));
    });

    test('versions follow semver format', () {
      final semverRegex = RegExp(r'^\d+\.\d+\.\d+$');
      expect(semverRegex.hasMatch(LegalDocVersions.privacyPolicy), isTrue);
      expect(semverRegex.hasMatch(LegalDocVersions.termsOfService), isTrue);
    });
  });

  // ── ConsentRecord ──

  group('ConsentRecord', () {
    test('creates with required fields', () {
      final record = ConsentRecord(
        privacyPolicyVersion: '1.0.0',
        termsOfServiceVersion: '1.0.0',
        acceptedAt: DateTime(2024, 6, 15),
      );
      expect(record.privacyPolicyVersion, '1.0.0');
      expect(record.termsOfServiceVersion, '1.0.0');
      expect(record.analyticsConsent, isTrue);
      expect(record.crashlyticsConsent, isTrue);
    });

    test('creates with explicit opt-outs', () {
      final record = ConsentRecord(
        privacyPolicyVersion: '1.0.0',
        termsOfServiceVersion: '1.0.0',
        acceptedAt: DateTime(2024, 6, 15),
        analyticsConsent: false,
        crashlyticsConsent: false,
      );
      expect(record.analyticsConsent, isFalse);
      expect(record.crashlyticsConsent, isFalse);
    });

    test('toMap serializes all fields', () {
      final record = ConsentRecord(
        privacyPolicyVersion: '1.0.0',
        termsOfServiceVersion: '1.0.0',
        acceptedAt: DateTime(2024, 6, 15),
        crashlyticsConsent: false,
      );
      final map = record.toMap();
      expect(map['privacyPolicyVersion'], '1.0.0');
      expect(map['termsOfServiceVersion'], '1.0.0');
      expect(map['analyticsConsent'], isTrue);
      expect(map['crashlyticsConsent'], isFalse);
      expect(map.containsKey('acceptedAt'), isTrue);
    });

    test('isCurrentVersion is true when matching', () {
      final record = ConsentRecord(
        privacyPolicyVersion: LegalDocVersions.privacyPolicy,
        termsOfServiceVersion: LegalDocVersions.termsOfService,
        acceptedAt: DateTime(2024, 6, 15),
      );
      expect(record.isCurrentVersion, isTrue);
    });

    test('isCurrentVersion is false when privacy outdated', () {
      final record = ConsentRecord(
        privacyPolicyVersion: '0.9.0',
        termsOfServiceVersion: LegalDocVersions.termsOfService,
        acceptedAt: DateTime(2024),
      );
      expect(record.isCurrentVersion, isFalse);
    });

    test('isCurrentVersion is false when terms outdated', () {
      final record = ConsentRecord(
        privacyPolicyVersion: LegalDocVersions.privacyPolicy,
        termsOfServiceVersion: '0.5.0',
        acceptedAt: DateTime(2024),
      );
      expect(record.isCurrentVersion, isFalse);
    });

    test('isCurrentVersion is false when both outdated', () {
      final record = ConsentRecord(
        privacyPolicyVersion: '0.1.0',
        termsOfServiceVersion: '0.1.0',
        acceptedAt: DateTime(2024),
      );
      expect(record.isCurrentVersion, isFalse);
    });
  });

  // ── ConsentRecord.fromMap ──

  group('ConsentRecord.fromMap', () {
    test('handles complete map', () {
      final map = {
        'privacyPolicyVersion': '1.0.0',
        'termsOfServiceVersion': '1.0.0',
        'analyticsConsent': true,
        'crashlyticsConsent': false,
      };
      final record = ConsentRecord.fromMap(map);
      expect(record.privacyPolicyVersion, '1.0.0');
      expect(record.analyticsConsent, isTrue);
      expect(record.crashlyticsConsent, isFalse);
    });

    test('handles missing fields with defaults', () {
      final map = <String, dynamic>{};
      final record = ConsentRecord.fromMap(map);
      expect(record.privacyPolicyVersion, '');
      expect(record.termsOfServiceVersion, '');
      expect(record.analyticsConsent, isTrue);
      expect(record.crashlyticsConsent, isTrue);
    });

    test('handles null analytics consent', () {
      final map = {
        'privacyPolicyVersion': '1.0.0',
        'termsOfServiceVersion': '1.0.0',
        'analyticsConsent': null,
        'crashlyticsConsent': null,
      };
      final record = ConsentRecord.fromMap(map);
      expect(record.analyticsConsent, isTrue);
      expect(record.crashlyticsConsent, isTrue);
    });
  });
}
