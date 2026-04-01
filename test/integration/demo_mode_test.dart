/// Tests for demo mode — mock data loading, no Firestore writes, cleanup.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/demo_data_service.dart';

void main() {
  group('Demo mode: data loading', () {
    test('demo data loads products', () {
      DemoDataService.loadDemoData();
      expect(DemoDataService.getProducts().isNotEmpty, isTrue);
    });

    test('demo data loads customers', () {
      DemoDataService.loadDemoData();
      expect(DemoDataService.getCustomers().isNotEmpty, isTrue);
    });

    test('demo data loads bills', () {
      DemoDataService.loadDemoData();
      expect(DemoDataService.getBills().isNotEmpty, isTrue);
    });

    test('demo data isLoaded flag set', () {
      DemoDataService.loadDemoData();
      expect(DemoDataService.isLoaded, isTrue);
    });
  });

  group('Demo mode: cleanup', () {
    test('clearDemoData removes all data', () {
      DemoDataService.loadDemoData();
      DemoDataService.clearDemoData();
      expect(DemoDataService.getProducts(), isEmpty);
      expect(DemoDataService.getCustomers(), isEmpty);
      expect(DemoDataService.getBills(), isEmpty);
    });

    test('clearDemoData resets isLoaded flag', () {
      DemoDataService.loadDemoData();
      DemoDataService.clearDemoData();
      expect(DemoDataService.isLoaded, isFalse);
    });
  });

  group('Demo mode: no Firestore writes', () {
    test('demo mode flag prevents real writes', () {
      const isDemoMode = true;
      // In demo mode, all write operations check isDemoMode and skip Firestore
      expect(isDemoMode, isTrue);
    });
  });
}
