/// Connectivity service for monitoring network status
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status enum
enum ConnectivityStatus { online, offline }

/// Provider for connectivity status
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ConnectivityService.statusStream;
});

/// Provider for simple online check
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (status) => status == ConnectivityStatus.online,
    loading: () => true, // Assume online during loading
    error: (e, _) => false,
  );
});

/// Service for monitoring network connectivity
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _subscription;
  static final _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  /// Stream of connectivity status changes
  static Stream<ConnectivityStatus> get statusStream =>
      _statusController.stream;

  /// Current connectivity status
  static ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  static ConnectivityStatus get currentStatus => _currentStatus;

  /// Initialize connectivity monitoring
  static Future<void> initialize() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  /// Check if currently online
  static bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Check if currently offline
  static bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Update status based on connectivity result
  static void _updateStatus(ConnectivityResult result) {
    final wasOnline = _currentStatus == ConnectivityStatus.online;

    // Consider online if connection type is not none
    final hasConnection = result != ConnectivityResult.none;
    _currentStatus = hasConnection
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;

    // Notify listeners
    _statusController.add(_currentStatus);

    // Log status change for debugging
    if (wasOnline != isOnline) {
      // Status changed - could trigger sync here
    }
  }

  /// Dispose resources
  static void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
