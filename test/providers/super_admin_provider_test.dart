import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/features/super_admin/providers/super_admin_provider.dart';

void main() {
  group('superAdminEmails', () {
    test('contains expected emails', () {
      expect(superAdminEmails, contains('kehsaram001@gmail.com'));
      expect(superAdminEmails, contains('admin@retaillite.com'));
      expect(superAdminEmails, contains('admin@lite.app'));
    });

    test('has at least 5 entries', () {
      expect(superAdminEmails.length, greaterThanOrEqualTo(5));
    });

    test('all emails are lowercase', () {
      for (final email in superAdminEmails) {
        expect(email, email.toLowerCase(),
            reason: '$email should be lowercase');
      }
    });

    test('all emails contain @ symbol', () {
      for (final email in superAdminEmails) {
        expect(email, contains('@'), reason: '$email should contain @');
      }
    });

    test('no duplicate emails', () {
      final unique = superAdminEmails.toSet();
      expect(unique.length, superAdminEmails.length);
    });
  });

  group('superAdminEmails normalization check', () {
    test('lowercased email matches list entry', () {
      const testEmail = 'KehsaRam001@Gmail.COM';
      final normalized = testEmail.toLowerCase().trim();
      expect(superAdminEmails.contains(normalized), isTrue);
    });

    test('trimmed email matches list entry', () {
      const testEmail = '  admin@retaillite.com  ';
      final normalized = testEmail.toLowerCase().trim();
      expect(superAdminEmails.contains(normalized), isTrue);
    });

    test('non-admin email does not match', () {
      const testEmail = 'random@example.com';
      final normalized = testEmail.toLowerCase().trim();
      expect(superAdminEmails.contains(normalized), isFalse);
    });
  });
}
