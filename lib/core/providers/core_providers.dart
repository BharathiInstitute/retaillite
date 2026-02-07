/// Core Riverpod providers (local mode - no Firebase)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current user ID provider - returns local user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return 'local_user';
});
