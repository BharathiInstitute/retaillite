/// Tests for core_providers — Riverpod provider definitions.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/providers/core_providers.dart';

void main() {
  group('currentUserIdProvider', () {
    test('returns local_user as default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final userId = container.read(currentUserIdProvider);
      expect(userId, 'local_user');
    });

    test('returns non-null value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final userId = container.read(currentUserIdProvider);
      expect(userId, isNotNull);
    });
  });
}
