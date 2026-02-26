import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/usage_tracking_service.dart';
import 'package:retaillite/features/khata/providers/khata_stats_provider.dart';

void main() {
  // ── KhataStats ──

  group('KhataStats', () {
    test('construction with required fields', () {
      const stats = KhataStats(
        totalOutstanding: 5000,
        collectedToday: 2000,
        activeCustomers: 50,
        customersWithDue: 20,
      );
      expect(stats.totalOutstanding, 5000);
      expect(stats.collectedToday, 2000);
      expect(stats.activeCustomers, 50);
      expect(stats.customersWithDue, 20);
    });

    test('empty factory returns all zeros', () {
      final stats = KhataStats.empty();
      expect(stats.totalOutstanding, 0);
      expect(stats.collectedToday, 0);
      expect(stats.activeCustomers, 0);
      expect(stats.customersWithDue, 0);
    });
  });

  // ── CustomerSortOption ──

  group('CustomerSortOption', () {
    test('has all expected values', () {
      expect(CustomerSortOption.values.length, 4);
      expect(
        CustomerSortOption.values,
        contains(CustomerSortOption.highestDebt),
      );
      expect(
        CustomerSortOption.values,
        contains(CustomerSortOption.recentlyActive),
      );
      expect(
        CustomerSortOption.values,
        contains(CustomerSortOption.alphabetical),
      );
      expect(CustomerSortOption.values, contains(CustomerSortOption.oldestDue));
    });
  });

  // ── DailyUsage ──

  group('DailyUsage', () {
    test('totalOperations sums all operations', () {
      final usage = DailyUsage(
        date: '2026-02-25',
        operations: {
          OperationType.billCreated: 10,
          OperationType.productAdded: 5,
          OperationType.syncToCloud: 3,
        },
        estimatedCost: 1.5,
      );
      expect(usage.totalOperations, 18);
    });

    test('totalOperations is zero for empty operations', () {
      final usage = DailyUsage(
        date: '2026-02-25',
        operations: {},
        estimatedCost: 0,
      );
      expect(usage.totalOperations, 0);
    });

    test('toMap includes all fields', () {
      final usage = DailyUsage(
        date: '2026-02-25',
        operations: {OperationType.billCreated: 5},
        estimatedCost: 0.25,
      );
      final map = usage.toMap();
      expect(map['date'], '2026-02-25');
      expect(map['estimatedCost'], 0.25);
      expect((map['operations'] as Map)['billCreated'], 5);
    });

    test('fromMap round-trips correctly', () {
      final original = DailyUsage(
        date: '2026-02-25',
        operations: {
          OperationType.billCreated: 10,
          OperationType.productAdded: 5,
        },
        estimatedCost: 0.65,
      );
      final map = original.toMap();
      final restored = DailyUsage.fromMap(map);
      expect(restored.date, original.date);
      expect(restored.estimatedCost, original.estimatedCost);
      expect(restored.totalOperations, original.totalOperations);
    });
  });

  // ── OperationType enum ──

  group('OperationType', () {
    test('has all expected values', () {
      expect(OperationType.values.length, 11);
      expect(OperationType.values, contains(OperationType.billCreated));
      expect(OperationType.values, contains(OperationType.billUpdated));
      expect(OperationType.values, contains(OperationType.productAdded));
      expect(OperationType.values, contains(OperationType.syncToCloud));
      expect(OperationType.values, contains(OperationType.syncFromCloud));
    });
  });
}
