import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('returns error for null input', () {
      expect(Validators.phone(null), isNotNull);
    });

    test('returns error for empty input', () {
      expect(Validators.phone(''), isNotNull);
    });

    test('accepts valid Indian mobile number', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('6000000000'), isNull);
      expect(Validators.phone('7999999999'), isNull);
      expect(Validators.phone('8123456789'), isNull);
    });

    test('rejects numbers not starting with 6-9', () {
      expect(Validators.phone('5876543210'), isNotNull);
      expect(Validators.phone('0876543210'), isNotNull);
      expect(Validators.phone('1234567890'), isNotNull);
    });

    test('rejects wrong length', () {
      expect(Validators.phone('98765'), isNotNull);
      expect(Validators.phone('987654321012'), isNotNull);
    });

    test('strips non-digit characters before validating', () {
      expect(
        Validators.phone('+91 98765 43210'),
        isNotNull,
      ); // 12 digits with 91
    });
  });

  group('Validators.email', () {
    test('returns error for null or empty', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
    });

    test('accepts valid emails', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user.name+tag@domain.co.in'), isNull);
      expect(Validators.email('test123@gmail.com'), isNull);
    });

    test('rejects invalid emails', () {
      expect(Validators.email('user'), isNotNull);
      expect(Validators.email('user@'), isNotNull);
      expect(Validators.email('@domain.com'), isNotNull);
      expect(Validators.email('user@domain'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('returns error for null or empty', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('rejects passwords shorter than 8 characters', () {
      expect(Validators.password('abc12'), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
    });

    test('requires at least one letter', () {
      expect(Validators.password('12345678'), isNotNull);
    });

    test('requires at least one number', () {
      expect(Validators.password('abcdefgh'), isNotNull);
    });

    test('accepts valid passwords', () {
      expect(Validators.password('password1'), isNull);
      expect(Validators.password('MyP4ssw0rd'), isNull);
    });
  });

  group('Validators.required', () {
    test('returns error for null or empty', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('accepts non-empty value', () {
      expect(Validators.required('hello'), isNull);
    });

    test('uses custom field name in error message', () {
      final result = Validators.required('', 'Shop Name');
      expect(result, contains('Shop Name'));
    });
  });

  group('Validators.name', () {
    test('returns error for empty', () {
      expect(Validators.name(null), isNotNull);
      expect(Validators.name(''), isNotNull);
    });

    test('requires at least 2 characters', () {
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('AB'), isNull);
    });
  });

  group('Validators.price', () {
    test('returns error for empty', () {
      expect(Validators.price(null), isNotNull);
      expect(Validators.price(''), isNotNull);
    });

    test('rejects non-numeric', () {
      expect(Validators.price('abc'), isNotNull);
      expect(Validators.price('12.3.4'), isNotNull);
    });

    test('rejects zero and negative', () {
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('-10'), isNotNull);
    });

    test('accepts positive numbers', () {
      expect(Validators.price('10'), isNull);
      expect(Validators.price('99.99'), isNull);
      expect(Validators.price('0.01'), isNull);
    });
  });

  group('Validators.stock', () {
    test('rejects negative values', () {
      expect(Validators.stock('-1'), isNotNull);
    });

    test('accepts zero and positive', () {
      expect(Validators.stock('0'), isNull);
      expect(Validators.stock('100'), isNull);
    });

    test('rejects non-numeric', () {
      expect(Validators.stock('abc'), isNotNull);
    });
  });

  group('Validators.gstNumber', () {
    test('allows empty (optional field)', () {
      expect(Validators.gstNumber(null), isNull);
      expect(Validators.gstNumber(''), isNull);
    });

    test('accepts valid GST format', () {
      // Standard GST format: 2 digits + 5 uppercase + 4 digits + 1 alpha + 1 alphanum + Z + 1 alphanum
      expect(Validators.gstNumber('29ABCDE1234F1Z5'), isNull);
    });

    test('rejects invalid GST', () {
      expect(Validators.gstNumber('INVALID'), isNotNull);
      expect(Validators.gstNumber('123'), isNotNull);
    });
  });

  group('Validators.barcode', () {
    test('allows empty (optional field)', () {
      expect(Validators.barcode(null), isNull);
      expect(Validators.barcode(''), isNull);
    });

    test('accepts valid barcode lengths (8-14 chars)', () {
      expect(Validators.barcode('12345678'), isNull);
      expect(Validators.barcode('12345678901234'), isNull);
    });

    test('rejects too short or too long', () {
      expect(Validators.barcode('1234567'), isNotNull);
      expect(Validators.barcode('123456789012345'), isNotNull);
    });
  });

  group('Validators.amount', () {
    test('rejects zero and negative', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
    });

    test('respects max cap', () {
      expect(Validators.amount('1000', max: 500), isNotNull);
      expect(Validators.amount('500', max: 500), isNull);
    });
  });

  group('Validators.sanitize', () {
    test('strips HTML tags', () {
      expect(Validators.sanitize('<b>bold</b>'), 'bold');
      expect(Validators.sanitize('hello <img src="x"> world'), 'hello  world');
    });

    test('strips script tags', () {
      expect(
        Validators.sanitize('hello<script>alert("xss")</script>world'),
        'helloworld',
      );
    });

    test('trims whitespace', () {
      expect(Validators.sanitize('  hello  '), 'hello');
    });

    test('preserves normal text', () {
      expect(Validators.sanitize('Normal text 123'), 'Normal text 123');
    });
  });

  group('Validators.containsSuspiciousInput', () {
    test('detects SQL injection patterns', () {
      expect(
        Validators.containsSuspiciousInput("'; DROP TABLE users;--"),
        isTrue,
      );
      expect(Validators.containsSuspiciousInput('1 OR 1=1'), isTrue);
    });

    test('allows normal text', () {
      expect(Validators.containsSuspiciousInput('John Doe'), isFalse);
      expect(Validators.containsSuspiciousInput('Product 123'), isFalse);
    });

    test('detects script tags', () {
      expect(
        Validators.containsSuspiciousInput('<script>alert("xss")</script>'),
        isTrue,
      );
    });
  });

  group('Validators.otp', () {
    test('rejects wrong length', () {
      expect(Validators.otp('123'), isNotNull);
      expect(Validators.otp('12345'), isNotNull);
    });

    test('rejects non-numeric', () {
      expect(Validators.otp('abcd'), isNotNull);
    });

    test('accepts 4-digit numeric', () {
      expect(Validators.otp('1234'), isNull);
      expect(Validators.otp('0000'), isNull);
    });
  });
}
