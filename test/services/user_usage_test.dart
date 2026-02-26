import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/user_usage_service.dart';

void main() {
  // ── FirebasePricing ──

  group('FirebasePricing constants', () {
    test('reads pricing is set', () {
      expect(FirebasePricing.firestoreReadsPer100k, greaterThan(0));
    });

    test('writes pricing is higher than reads', () {
      expect(
        FirebasePricing.firestoreWritesPer100k,
        greaterThan(FirebasePricing.firestoreReadsPer100k),
      );
    });

    test('all pricing values are positive', () {
      expect(FirebasePricing.firestoreReadsPer100k, greaterThan(0));
      expect(FirebasePricing.firestoreWritesPer100k, greaterThan(0));
      expect(FirebasePricing.firestoreDeletesPer100k, greaterThan(0));
      expect(FirebasePricing.storagePerGB, greaterThan(0));
      expect(FirebasePricing.functionCallsPerMillion, greaterThan(0));
    });
  });

  // ── UserUsage ──

  group('UserUsage', () {
    late UserUsage usage;

    setUp(() {
      usage = UserUsage(
        odUserId: 'user_1',
        email: 'test@example.com',
        firestoreReads: 100000,
        firestoreWrites: 50000,
        firestoreDeletes: 10000,
        storageBytes: 1073741824, // 1 GB
        functionCalls: 1000000,
        lastUpdated: DateTime(2026, 2, 25),
        periodStart: DateTime(2026, 2),
      );
    });

    test('estimatedCost calculates correctly', () {
      // reads:  100k/100k * 0.06 = 0.06
      // writes: 50k/100k  * 0.18 = 0.09
      // deletes: 10k/100k * 0.02 = 0.002
      // storage: 1GB * 0.026    = 0.026
      // funcs:  1M/1M * 0.40    = 0.40
      // total: ~0.578
      expect(usage.estimatedCost, closeTo(0.578, 0.001));
    });

    test('estimatedCost is 0 when no usage', () {
      final empty = UserUsage(
        odUserId: 'user_2',
        lastUpdated: DateTime.now(),
        periodStart: DateTime.now(),
      );
      expect(empty.estimatedCost, 0.0);
    });

    test('storageMB converts bytes to MB', () {
      expect(usage.storageMB, closeTo(1024, 0.1));
    });

    test('storageMB is 0 for no storage', () {
      final empty = UserUsage(
        odUserId: 'user_2',
        lastUpdated: DateTime.now(),
        periodStart: DateTime.now(),
      );
      expect(empty.storageMB, 0.0);
    });

    test('copyWith updates specified fields', () {
      final updated = usage.copyWith(firestoreReads: 200000);
      expect(updated.firestoreReads, 200000);
      expect(updated.firestoreWrites, 50000); // unchanged
      expect(updated.odUserId, 'user_1'); // unchanged
    });

    test('copyWith preserves unspecified fields', () {
      final updated = usage.copyWith();
      expect(updated.odUserId, usage.odUserId);
      expect(updated.email, usage.email);
      expect(updated.firestoreReads, usage.firestoreReads);
      expect(updated.periodStart, usage.periodStart);
    });

    test('defaults are zero', () {
      final empty = UserUsage(
        odUserId: 'user_2',
        lastUpdated: DateTime.now(),
        periodStart: DateTime.now(),
      );
      expect(empty.firestoreReads, 0);
      expect(empty.firestoreWrites, 0);
      expect(empty.firestoreDeletes, 0);
      expect(empty.storageBytes, 0);
      expect(empty.functionCalls, 0);
      expect(empty.isAdmin, isFalse);
    });

    test('isAdmin default is false', () {
      expect(usage.isAdmin, isFalse);
    });
  });
}
