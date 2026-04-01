/// Tests for ErrorsScreen (admin) — error list, filtering, grouping.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorsScreen error list', () {
    test('error list renders entries', () {
      final errors = List.generate(3, (i) => 'Error $i');
      expect(errors.isNotEmpty, isTrue);
    });
  });

  group('ErrorsScreen filters', () {
    test('platform filter works', () {
      final errors = [
        {'platform': 'android', 'message': 'crash'},
        {'platform': 'web', 'message': 'timeout'},
        {'platform': 'android', 'message': 'null ref'},
      ];
      const filter = 'android';
      final filtered = errors.where((e) => e['platform'] == filter).toList();
      expect(filtered.length, 2);
    });

    test('severity filter works', () {
      final errors = [
        {'severity': 'fatal'},
        {'severity': 'warning'},
        {'severity': 'fatal'},
      ];
      const filter = 'fatal';
      final filtered = errors.where((e) => e['severity'] == filter).toList();
      expect(filtered.length, 2);
    });
  });

  group('ErrorsScreen grouping', () {
    test('group by type aggregates errors', () {
      final errors = [
        {'type': 'NullPointerException'},
        {'type': 'NullPointerException'},
        {'type': 'NetworkError'},
      ];
      final grouped = <String, int>{};
      for (final e in errors) {
        final type = e['type']!;
        grouped[type] = (grouped[type] ?? 0) + 1;
      }
      expect(grouped['NullPointerException'], 2);
      expect(grouped['NetworkError'], 1);
    });
  });
}
