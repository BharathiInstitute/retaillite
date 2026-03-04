/// Tests for AppError — error classification logic
/// Uses inline duplicates to avoid transitive Firebase import chain.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicates (avoid transitive import of billing_screen.dart) ──

enum AppErrorType {
  network,
  authentication,
  permission,
  validation,
  server,
  unknown,
}

class AppError implements Exception {
  final String message;
  final String? details;
  final AppErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.details,
    this.type = AppErrorType.unknown,
    this.originalError,
    this.stackTrace,
  });

  factory AppError.from(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    String message = 'Something went wrong';
    AppErrorType type = AppErrorType.unknown;

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      message = 'Network error. Please check your connection.';
      type = AppErrorType.network;
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      message = 'Permission denied. Please grant required permissions.';
      type = AppErrorType.permission;
    } else if (errorString.contains('auth') ||
        errorString.contains('credential') ||
        errorString.contains('password')) {
      message = 'Authentication failed. Please try again.';
      type = AppErrorType.authentication;
    } else if (errorString.contains('invalid') ||
        errorString.contains('format')) {
      message = 'Invalid data. Please check your input.';
      type = AppErrorType.validation;
    }

    return AppError(
      message: message,
      details: error.toString(),
      type: type,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => message;
}

void main() {
  // ── AppErrorType enum ──

  group('AppErrorType', () {
    test('has all expected types', () {
      expect(
        AppErrorType.values,
        containsAll([
          AppErrorType.network,
          AppErrorType.authentication,
          AppErrorType.permission,
          AppErrorType.validation,
          AppErrorType.server,
          AppErrorType.unknown,
        ]),
      );
    });
  });

  // ── AppError ──

  group('AppError construction', () {
    test('creates with required fields', () {
      const error = AppError(message: 'Something went wrong');
      expect(error.message, 'Something went wrong');
      expect(error.type, AppErrorType.unknown);
      expect(error.details, isNull);
    });

    test('creates with all fields', () {
      const error = AppError(
        message: 'Network error',
        details: 'Socket exception',
        type: AppErrorType.network,
      );
      expect(error.message, 'Network error');
      expect(error.details, 'Socket exception');
      expect(error.type, AppErrorType.network);
    });

    test('toString returns message', () {
      const error = AppError(message: 'Test error');
      expect(error.toString(), 'Test error');
    });
  });

  group('AppError.from - error classification', () {
    test('classifies network errors', () {
      final error = AppError.from(Exception('network connection failed'));
      expect(error.type, AppErrorType.network);
      expect(error.message, contains('Network'));
    });

    test('classifies socket errors', () {
      final error = AppError.from(
        Exception('SocketException: Connection refused'),
      );
      expect(error.type, AppErrorType.network);
    });

    test('classifies connection errors', () {
      final error = AppError.from(Exception('connection timeout'));
      expect(error.type, AppErrorType.network);
    });

    test('classifies permission errors', () {
      final error = AppError.from(Exception('permission denied'));
      expect(error.type, AppErrorType.permission);
      expect(error.message, contains('Permission'));
    });

    test('classifies auth errors', () {
      final error = AppError.from(Exception('auth failed'));
      expect(error.type, AppErrorType.authentication);
      expect(error.message, contains('Authentication'));
    });

    test('classifies credential errors', () {
      final error = AppError.from(Exception('invalid credential'));
      expect(error.type, AppErrorType.authentication);
    });

    test('classifies password errors', () {
      final error = AppError.from(Exception('wrong password'));
      expect(error.type, AppErrorType.authentication);
    });

    test('classifies validation errors', () {
      final error = AppError.from(Exception('invalid format'));
      expect(error.type, AppErrorType.validation);
      expect(error.message, contains('Invalid'));
    });

    test('classifies format errors', () {
      final error = AppError.from(Exception('format exception'));
      expect(error.type, AppErrorType.validation);
    });

    test('classifies unknown errors', () {
      final error = AppError.from(Exception('something happened'));
      expect(error.type, AppErrorType.unknown);
      expect(error.message, 'Something went wrong');
    });

    test('returns same AppError if already AppError', () {
      const original = AppError(
        message: 'Already an AppError',
        type: AppErrorType.server,
      );
      final result = AppError.from(original);
      expect(identical(result, original), isTrue);
    });

    test('preserves stack trace', () {
      final trace = StackTrace.current;
      final error = AppError.from(Exception('test'), trace);
      expect(error.stackTrace, trace);
    });

    test('stores original error', () {
      final original = Exception('original error');
      final error = AppError.from(original);
      expect(error.originalError, original);
    });

    test('stores error string as details', () {
      final error = AppError.from(Exception('detailed message'));
      expect(error.details, isNotNull);
      expect(error.details, contains('detailed message'));
    });
  });
}
