/// Widget smoke tests for SyncBadge, SyncStatusChip
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/shared/widgets/sync_badge.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  // ── SyncBadge ──

  group('SyncBadge', () {
    testWidgets('shows nothing when synced', (tester) async {
      await tester.pumpWidget(wrap(const SyncBadge(hasPendingWrites: false)));
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('shows orange dot when pending writes', (tester) async {
      await tester.pumpWidget(wrap(const SyncBadge(hasPendingWrites: true)));
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('tooltip has correct message', (tester) async {
      await tester.pumpWidget(wrap(const SyncBadge(hasPendingWrites: true)));
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Not synced to cloud');
    });

    testWidgets('custom size is applied', (tester) async {
      await tester.pumpWidget(
        wrap(const SyncBadge(hasPendingWrites: true, size: 16)),
      );
      final container = tester.widget<Container>(find.byType(Container).last);
      expect(container.constraints?.maxWidth, 16);
    });
  });

  // ── SyncStatusChip ──

  group('SyncStatusChip', () {
    testWidgets('renders synced state', (tester) async {
      await tester.pumpWidget(wrap(const SyncStatusChip(isSynced: true)));
      expect(find.text('Synced'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('renders not synced state', (tester) async {
      await tester.pumpWidget(wrap(const SyncStatusChip(isSynced: false)));
      expect(find.text('Not Synced'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });
  });
}
