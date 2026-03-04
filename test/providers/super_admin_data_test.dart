/// Tests for super admin data — UsersQueryParams, superAdminEmails logic
///
/// Duplicated lightweight definitions to avoid Firebase-dependent imports.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Duplicated const (matches super_admin_provider.dart) ──

const List<String> superAdminEmails = [
  'kehsaram001@gmail.com',
  'admin@retaillite.com',
  'bharathiinstitute1@gmail.com',
  'bharahiinstitute1@gmail.com',
  'shivamsingh8556@gmail.com',
  'admin@lite.app',
  'kehsihba@gmail.com',
];

// ── Duplicated UsersQueryParams (matches super_admin_provider.dart) ──

class UsersQueryParams {
  final int limit;
  final String? searchQuery;
  final String? planFilter;

  const UsersQueryParams({this.limit = 100, this.searchQuery, this.planFilter});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsersQueryParams &&
        other.limit == limit &&
        other.searchQuery == searchQuery &&
        other.planFilter == planFilter;
  }

  @override
  int get hashCode => Object.hash(limit, searchQuery, planFilter);
}

void main() {
  // ── superAdminEmails ──

  group('superAdminEmails', () {
    test('contains expected email count', () {
      expect(superAdminEmails.length, 7);
    });

    test('all emails are lowercase', () {
      for (final email in superAdminEmails) {
        expect(email, email.toLowerCase());
      }
    });

    test('all emails have @ and domain', () {
      for (final email in superAdminEmails) {
        expect(email.contains('@'), true);
        expect(email.split('@').last.contains('.'), true);
      }
    });

    test('membership check works for known admin', () {
      expect(superAdminEmails.contains('kehsaram001@gmail.com'), true);
    });

    test('membership check is case sensitive (needs .toLowerCase)', () {
      // The provider normalizes with .toLowerCase().trim()
      expect(superAdminEmails.contains('KEHSARAM001@GMAIL.COM'), false);
      expect(
        superAdminEmails.contains('KEHSARAM001@GMAIL.COM'.toLowerCase().trim()),
        true,
      );
    });

    test('non-admin email is rejected', () {
      expect(superAdminEmails.contains('random@example.com'), false);
    });
  });

  // ── UsersQueryParams ──

  group('UsersQueryParams', () {
    test('default values', () {
      const params = UsersQueryParams();
      expect(params.limit, 100);
      expect(params.searchQuery, isNull);
      expect(params.planFilter, isNull);
    });

    test('custom values', () {
      const params = UsersQueryParams(
        limit: 50,
        searchQuery: 'test',
        planFilter: 'premium',
      );
      expect(params.limit, 50);
      expect(params.searchQuery, 'test');
      expect(params.planFilter, 'premium');
    });

    test('equality with same values', () {
      const a = UsersQueryParams(limit: 50, searchQuery: 'x');
      const b = UsersQueryParams(limit: 50, searchQuery: 'x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality with different limit', () {
      const a = UsersQueryParams(limit: 50);
      const b = UsersQueryParams();
      expect(a, isNot(b));
    });

    test('inequality with different searchQuery', () {
      const a = UsersQueryParams(searchQuery: 'x');
      const b = UsersQueryParams(searchQuery: 'y');
      expect(a, isNot(b));
    });

    test('inequality with different planFilter', () {
      const a = UsersQueryParams(planFilter: 'free');
      const b = UsersQueryParams(planFilter: 'premium');
      expect(a, isNot(b));
    });

    test('inequality with null vs value', () {
      const a = UsersQueryParams();
      const b = UsersQueryParams(searchQuery: 'x');
      expect(a, isNot(b));
    });

    test('identical returns equal', () {
      const a = UsersQueryParams();
      expect(a == a, true);
    });

    test('different type not equal', () {
      const a = UsersQueryParams();
      // ignore: unrelated_type_equality_checks
      expect(a == 'not a query params', false);
    });
  });
}
