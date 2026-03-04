/// Tests for ThrottleService — rate limiting and burst detection
///
/// Pure logic, no external dependencies.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/throttle_service.dart';

void main() {
  setUp(() {
    ThrottleService.reset();
  });

  group('canWrite', () {
    test('first call is always allowed', () {
      expect(ThrottleService.canWrite('test_op'), isTrue);
    });

    test('second call within cooldown is blocked', () {
      ThrottleService.recordWrite('test_op');
      expect(ThrottleService.canWrite('test_op'), isFalse);
    });

    test('call after cooldown is allowed', () async {
      ThrottleService.recordWrite('test_op');
      await Future.delayed(const Duration(milliseconds: 2100));
      expect(ThrottleService.canWrite('test_op'), isTrue);
    });

    test('different operations are independent', () {
      ThrottleService.recordWrite('op_a');
      expect(ThrottleService.canWrite('op_b'), isTrue);
    });

    test('custom cooldown is respected', () {
      ThrottleService.recordWrite('test_op');
      expect(
        ThrottleService.canWrite(
          'test_op',
          cooldown: const Duration(milliseconds: 50),
        ),
        isFalse,
      );
    });
  });

  group('recordWrite', () {
    test('registers a write so canWrite returns false', () {
      ThrottleService.recordWrite('test_op');
      expect(ThrottleService.canWrite('test_op'), isFalse);
    });

    test('tracks multiple separate operations', () {
      ThrottleService.recordWrite('op_a');
      ThrottleService.recordWrite('op_b');
      expect(ThrottleService.canWrite('op_a'), isFalse);
      expect(ThrottleService.canWrite('op_b'), isFalse);
    });
  });

  group('remainingCooldown', () {
    test('returns zero for unknown operation', () {
      expect(ThrottleService.remainingCooldown('unknown'), Duration.zero);
    });

    test('returns positive duration within cooldown', () {
      ThrottleService.recordWrite('test_op');
      final remaining = ThrottleService.remainingCooldown('test_op');
      expect(remaining.inMilliseconds, greaterThan(0));
    });

    test('returns zero after cooldown expires', () async {
      ThrottleService.recordWrite('test_op');
      await Future.delayed(const Duration(milliseconds: 2100));
      expect(ThrottleService.remainingCooldown('test_op'), Duration.zero);
    });
  });

  group('writesInLastMinute', () {
    test('returns 0 for unknown operation', () {
      expect(ThrottleService.writesInLastMinute('unknown'), 0);
    });

    test('counts single write', () {
      ThrottleService.recordWrite('test_op');
      expect(ThrottleService.writesInLastMinute('test_op'), 1);
    });

    test('counts multiple writes', () {
      for (int i = 0; i < 5; i++) {
        ThrottleService.recordWrite('test_op');
      }
      expect(ThrottleService.writesInLastMinute('test_op'), 5);
    });
  });

  group('reset', () {
    test('clears all tracked operations', () {
      ThrottleService.recordWrite('op_a');
      ThrottleService.recordWrite('op_b');
      ThrottleService.reset();
      expect(ThrottleService.canWrite('op_a'), isTrue);
      expect(ThrottleService.canWrite('op_b'), isTrue);
    });

    test('clears write counts', () {
      ThrottleService.recordWrite('test_op');
      ThrottleService.reset();
      expect(ThrottleService.writesInLastMinute('test_op'), 0);
    });
  });

  group('burst detection', () {
    test('many rapid writes are tracked', () {
      for (int i = 0; i < 10; i++) {
        ThrottleService.recordWrite('flood');
      }
      expect(ThrottleService.writesInLastMinute('flood'), 10);
    });

    test('canWrite returns false during burst', () {
      ThrottleService.recordWrite('flood');
      expect(ThrottleService.canWrite('flood'), isFalse);
    });
  });
}
