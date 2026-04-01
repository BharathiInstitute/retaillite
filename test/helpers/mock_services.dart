/// Centralized mock classes for test infrastructure.
///
/// Uses mocktail for type-safe mocking. Import this file in any test
/// that needs to mock services, Firebase, or platform dependencies.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// ── Firebase Mocks ──

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ── Ref Mock ──

class MockRef extends Mock implements Ref {}
