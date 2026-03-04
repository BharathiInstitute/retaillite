/// Tests for WriteRetryQueue — enums and QueuedWrite data class
///
/// Tests pure data class logic and serialization.
/// Uses inline duplicates to avoid transitive Firebase import chain.
library;

import 'package:flutter_test/flutter_test.dart';

// ── Inline duplicates (avoid transitive import of billing_screen.dart) ──

enum WriteOperation { set, update, delete }

class QueuedWrite {
  QueuedWrite({
    required this.collection,
    required this.docId,
    required this.operation,
    this.data,
    this.attempts = 0,
    DateTime? lastAttempt,
  }) : lastAttempt = lastAttempt ?? DateTime.now();

  final String collection;
  final String docId;
  final WriteOperation operation;
  final Map<String, dynamic>? data;
  int attempts;
  DateTime lastAttempt;

  Map<String, dynamic> toJson() => {
    'collection': collection,
    'docId': docId,
    'operation': operation.name,
    'data': data,
    'attempts': attempts,
    'lastAttempt': lastAttempt.toIso8601String(),
  };

  factory QueuedWrite.fromJson(Map<String, dynamic> json) => QueuedWrite(
    collection: json['collection'] as String,
    docId: json['docId'] as String,
    operation: WriteOperation.values.byName(json['operation'] as String),
    data: json['data'] as Map<String, dynamic>?,
    attempts: json['attempts'] as int? ?? 0,
    lastAttempt:
        DateTime.tryParse(json['lastAttempt'] as String? ?? '') ??
        DateTime.now(),
  );
}

void main() {
  // ── WriteOperation enum ──

  group('WriteOperation', () {
    test('has 3 values', () {
      expect(WriteOperation.values.length, 3);
    });

    test('set is available', () {
      expect(WriteOperation.set, isNotNull);
      expect(WriteOperation.set.name, 'set');
    });

    test('update is available', () {
      expect(WriteOperation.update, isNotNull);
      expect(WriteOperation.update.name, 'update');
    });

    test('delete is available', () {
      expect(WriteOperation.delete, isNotNull);
      expect(WriteOperation.delete.name, 'delete');
    });
  });

  // ── QueuedWrite data class ──

  group('QueuedWrite', () {
    test('creates with required fields', () {
      final write = QueuedWrite(
        collection: 'bills',
        docId: 'bill-1',
        operation: WriteOperation.set,
      );
      expect(write.collection, 'bills');
      expect(write.docId, 'bill-1');
      expect(write.operation, WriteOperation.set);
      expect(write.data, isNull);
      expect(write.attempts, 0);
      expect(write.lastAttempt, isNotNull); // defaults to DateTime.now()
    });

    test('creates with data and attempts', () {
      final now = DateTime(2024, 6, 15);
      final write = QueuedWrite(
        collection: 'products',
        docId: 'prod-1',
        operation: WriteOperation.update,
        data: {'name': 'Rice', 'price': 50.0},
        attempts: 3,
        lastAttempt: now,
      );
      expect(write.data, {'name': 'Rice', 'price': 50.0});
      expect(write.attempts, 3);
      expect(write.lastAttempt, now);
    });

    test('toJson serializes correctly', () {
      final write = QueuedWrite(
        collection: 'bills',
        docId: 'b-1',
        operation: WriteOperation.set,
        data: {'total': 100},
        attempts: 1,
        lastAttempt: DateTime(2024, 3, 1, 12),
      );
      final json = write.toJson();
      expect(json['collection'], 'bills');
      expect(json['docId'], 'b-1');
      expect(json['operation'], 'set');
      expect(json['data'], {'total': 100});
      expect(json['attempts'], 1);
      expect(json['lastAttempt'], isNotNull);
    });

    test('toJson handles null data', () {
      final write = QueuedWrite(
        collection: 'products',
        docId: 'p-1',
        operation: WriteOperation.delete,
      );
      final json = write.toJson();
      expect(json['data'], isNull);
      expect(json['lastAttempt'], isNotNull); // defaults to DateTime.now()
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'collection': 'expenses',
        'docId': 'exp-1',
        'operation': 'update',
        'data': {'amount': 500},
        'attempts': 2,
        'lastAttempt': '2024-03-01T12:00:00.000',
      };
      final write = QueuedWrite.fromJson(json);
      expect(write.collection, 'expenses');
      expect(write.docId, 'exp-1');
      expect(write.operation, WriteOperation.update);
      expect(write.data, {'amount': 500});
      expect(write.attempts, 2);
      expect(write.lastAttempt, isNotNull);
    });

    test('fromJson handles delete operation', () {
      final json = {
        'collection': 'bills',
        'docId': 'bill-1',
        'operation': 'delete',
        'data': null,
        'attempts': 0,
        'lastAttempt': null,
      };
      final write = QueuedWrite.fromJson(json);
      expect(write.operation, WriteOperation.delete);
      expect(write.data, isNull);
      expect(write.lastAttempt, isNotNull); // defaults to DateTime.now()
    });

    test('toJson→fromJson roundtrip preserves data', () {
      final original = QueuedWrite(
        collection: 'customers',
        docId: 'cust-42',
        operation: WriteOperation.set,
        data: {'name': 'Rahul', 'balance': -500.0},
        attempts: 4,
        lastAttempt: DateTime(2024, 6, 15, 10, 30),
      );
      final restored = QueuedWrite.fromJson(original.toJson());
      expect(restored.collection, original.collection);
      expect(restored.docId, original.docId);
      expect(restored.operation, original.operation);
      expect(restored.data, original.data);
      expect(restored.attempts, original.attempts);
    });

    test('fromJson throws on unknown operation', () {
      final json = {
        'collection': 'test',
        'docId': 'test-1',
        'operation': 'unknown_op',
        'data': null,
        'attempts': 0,
        'lastAttempt': null,
      };
      expect(() => QueuedWrite.fromJson(json), throwsArgumentError);
    });
  });
}
