/// Global error handling utilities
library;

import 'dart:io' show Platform;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:retaillite/core/services/error_logging_service.dart';

/// Check if Crashlytics is supported (not web and not Windows)
bool get _supportsCrashlytics => !kIsWeb && !Platform.isWindows;

/// Error types for categorization
enum AppErrorType {
  network,
  authentication,
  permission,
  validation,
  server,
  unknown,
}

/// Application error model
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

  /// Create from any exception
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

/// Global error handler
class ErrorHandler {
  ErrorHandler._();

  static bool _initialized = false;

  /// Initialize global error handling
  static void initialize() {
    if (_initialized) return;

    // Handle Flutter errors (web uses different handling)
    if (_supportsCrashlytics) {
      // Mobile: Use Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterError(details);
        _logError(details.exception, details.stack);
      };
    } else {
      // Web/Windows: Use console + Firestore logging
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _logError(details.exception, details.stack);
      };
    }

    // Handle async errors (platform dispatcher)
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      return true;
    };

    _initialized = true;
    debugPrint(
      '✅ ErrorHandler initialized (${kIsWeb
          ? "Web"
          : Platform.isWindows
          ? "Windows"
          : "Native"} mode)',
    );
  }

  /// Log error with platform-specific handling
  static void _logError(dynamic error, StackTrace? stack) {
    // Debug console logging
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('ERROR: $error');
      if (stack != null) {
        debugPrint('STACK TRACE:');
        debugPrint(stack.toString());
      }
      debugPrint('═══════════════════════════════════════════');
    }

    // Platform-specific error reporting
    if (kIsWeb) {
      // Web: Log to Firestore
      ErrorLoggingService.logError(error: error, stackTrace: stack);
    } else if (_supportsCrashlytics) {
      // Mobile: Log to Crashlytics (non-fatal)
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
    // Windows: Just console logging (Crashlytics not supported)
  }

  /// Report a caught error (use this for try-catch blocks)
  static void report(dynamic error, [StackTrace? stack]) {
    _logError(error, stack);
  }

  /// Report a non-fatal error with custom message
  static void reportWithMessage(
    String message,
    dynamic error, [
    StackTrace? stack,
  ]) {
    if (kDebugMode) {
      debugPrint('⚠️ $message: $error');
    }

    if (kIsWeb) {
      ErrorLoggingService.logError(
        error: '$message: $error',
        stackTrace: stack,
        severity: ErrorSeverity.warning,
      );
    } else if (_supportsCrashlytics) {
      FirebaseCrashlytics.instance.log(message);
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
  }

  /// Set user identifier for crash reports
  static Future<void> setUser(String? userId, {String? email}) async {
    if (_supportsCrashlytics && userId != null) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      if (email != null) {
        await FirebaseCrashlytics.instance.setCustomKey('email', email);
      }
    }
  }

  /// Log a custom message/breadcrumb
  static void log(String message) {
    if (_supportsCrashlytics) {
      FirebaseCrashlytics.instance.log(message);
    }
    if (kDebugMode) {
      debugPrint('📝 $message');
    }
  }

  /// Show error to user via SnackBar
  static void showError(BuildContext context, dynamic error) {
    final appError = AppError.from(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getErrorIcon(appError.type), color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(appError.message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        // Only show error details in debug mode to prevent leaking internals
        action: kDebugMode && appError.details != null
            ? SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () => _showErrorDetails(context, appError),
              )
            : null,
      ),
    );
  }

  static IconData _getErrorIcon(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.authentication:
        return Icons.lock_outline;
      case AppErrorType.permission:
        return Icons.block;
      case AppErrorType.validation:
        return Icons.error_outline;
      case AppErrorType.server:
        return Icons.cloud_off;
      case AppErrorType.unknown:
        return Icons.warning_amber;
    }
  }

  static void _showErrorDetails(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${error.type.name}'),
              const SizedBox(height: 8),
              Text('Message: ${error.message}'),
              if (error.details != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.details!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _defaultErrorWidget();
    }

    return widget.child;
  }

  Widget _defaultErrorWidget() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error?.exceptionAsString() ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
