import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/connectivity_service.dart';
import 'package:retaillite/core/services/sync_status_service.dart';
import 'package:retaillite/shared/widgets/offline_banner.dart';

void main() {
  Widget buildBanner({required bool isOnline, int unsyncedCount = 0}) {
    return ProviderScope(
      overrides: [
        isOnlineProvider.overrideWithValue(isOnline),
        unsyncedCountProvider.overrideWithValue(unsyncedCount),
      ],
      child: const MaterialApp(
        home: Scaffold(body: OfflineBanner()),
      ),
    );
  }

  group('OfflineBanner', () {
    testWidgets('hidden when online', (tester) async {
      await tester.pumpWidget(buildBanner(isOnline: true));
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('shows cloud_off icon when offline', (tester) async {
      await tester.pumpWidget(buildBanner(isOnline: false));
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows generic message when no unsynced changes',
        (tester) async {
      await tester.pumpWidget(buildBanner(isOnline: false));
      expect(
        find.text('You are offline — changes will sync when connected'),
        findsOneWidget,
      );
    });

    testWidgets('shows singular unsynced message for 1 change',
        (tester) async {
      await tester.pumpWidget(buildBanner(isOnline: false, unsyncedCount: 1));
      expect(
        find.text(
            'You are offline — 1 change will sync when connected'),
        findsOneWidget,
      );
    });

    testWidgets('shows plural unsynced message for multiple changes',
        (tester) async {
      await tester.pumpWidget(buildBanner(isOnline: false, unsyncedCount: 5));
      expect(
        find.text(
            'You are offline — 5 changes will sync when connected'),
        findsOneWidget,
      );
    });
  });
}
