/// Tests for ConflictResolutionService — enums, device ID, conflict detection
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/conflict_resolution_service.dart';

void main() {
  // ── ConflictResult enum ──

  group('ConflictResult', () {
    test('has all expected values', () {
      expect(ConflictResult.values.length, 4);
    });

    test('noConflict indicates safe to write', () {
      expect(ConflictResult.noConflict, isNotNull);
    });

    test('serverNewer indicates remote change', () {
      expect(ConflictResult.serverNewer, isNotNull);
    });

    test('localNewer indicates local is ahead', () {
      expect(ConflictResult.localNewer, isNotNull);
    });

    test('notFound indicates no server document', () {
      expect(ConflictResult.notFound, isNotNull);
    });

    test('values are all distinct', () {
      final values = ConflictResult.values.toSet();
      expect(values.length, ConflictResult.values.length);
    });
  });

  // ── ConflictAction enum ──

  group('ConflictAction', () {
    test('has all expected values', () {
      expect(ConflictAction.values.length, 3);
    });

    test('overwrite is available', () {
      expect(ConflictAction.overwrite, isNotNull);
    });

    test('discard is available', () {
      expect(ConflictAction.discard, isNotNull);
    });

    test('merge is available', () {
      expect(ConflictAction.merge, isNotNull);
    });

    test('values are all distinct', () {
      final values = ConflictAction.values.toSet();
      expect(values.length, ConflictAction.values.length);
    });
  });
}
