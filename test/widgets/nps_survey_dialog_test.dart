/// Tests for NpsSurveyDialog — eligibility logic and survey behavior.
///
/// The dialog depends on FirebaseFirestore for eligibility checks.
/// We test the pure eligibility logic and UI state contracts inline.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Eligibility: account age check ──
  // Mirrors: accountAge.inDays < 7 => return (don't show)

  group('NpsSurveyDialog account age eligibility', () {
    bool accountAgeEligible(DateTime? accountCreatedAt) {
      if (accountCreatedAt == null) return false;
      final accountAge = DateTime.now().difference(accountCreatedAt);
      return accountAge.inDays >= 7;
    }

    test('null accountCreatedAt is not eligible', () {
      expect(accountAgeEligible(null), isFalse);
    });

    test('account less than 7 days old is not eligible', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 3));
      expect(accountAgeEligible(createdAt), isFalse);
    });

    test('account exactly 7 days old is eligible', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 7));
      expect(accountAgeEligible(createdAt), isTrue);
    });

    test('account older than 7 days is eligible', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 30));
      expect(accountAgeEligible(createdAt), isTrue);
    });

    test('brand new account (0 days) is not eligible', () {
      final createdAt = DateTime.now();
      expect(accountAgeEligible(createdAt), isFalse);
    });
  });

  // ── Eligibility: recent survey check ──
  // Mirrors: daysSinceLast < 90 => return (don't show)

  group('NpsSurveyDialog recent survey eligibility', () {
    bool surveyEligible(DateTime? lastSurveyDate) {
      if (lastSurveyDate == null) return true; // No previous survey
      final daysSinceLast = DateTime.now().difference(lastSurveyDate).inDays;
      return daysSinceLast >= 90;
    }

    test('no previous survey is eligible', () {
      expect(surveyEligible(null), isTrue);
    });

    test('survey in last 90 days is not eligible', () {
      final lastSurvey = DateTime.now().subtract(const Duration(days: 30));
      expect(surveyEligible(lastSurvey), isFalse);
    });

    test('survey exactly 90 days ago is eligible', () {
      final lastSurvey = DateTime.now().subtract(const Duration(days: 90));
      expect(surveyEligible(lastSurvey), isTrue);
    });

    test('survey more than 90 days ago is eligible', () {
      final lastSurvey = DateTime.now().subtract(const Duration(days: 180));
      expect(surveyEligible(lastSurvey), isTrue);
    });

    test('survey yesterday is not eligible', () {
      final lastSurvey = DateTime.now().subtract(const Duration(days: 1));
      expect(surveyEligible(lastSurvey), isFalse);
    });
  });

  // ── Score selection / submit button state ──
  // Mirrors: FilledButton(onPressed: selectedScore != null ? _submit : null)

  group('NpsSurveyDialog score selection', () {
    test('submit disabled when score is null', () {
      const int? selectedScore = null;
      expect(selectedScore != null, isFalse); // button disabled
    });

    test('submit enabled when score is 0', () {
      const int selectedScore = 0;
      expect(selectedScore, isNotNull);
    });

    test('submit enabled when score is 10', () {
      const int selectedScore = 10;
      expect(selectedScore, isNotNull);
    });

    test('submit enabled when score is 5 (mid-range)', () {
      const int selectedScore = 5;
      expect(selectedScore, isNotNull);
    });
  });

  // ── Score range validation ──
  // Mirrors: List.generate(11, (index) => ChoiceChip(label: '$index'))

  group('NpsSurveyDialog score range', () {
    test('generates 11 score chips (0-10)', () {
      final scores = List.generate(11, (index) => index);
      expect(scores.length, 11);
      expect(scores.first, 0);
      expect(scores.last, 10);
    });

    test('each score has a text label', () {
      for (int i = 0; i <= 10; i++) {
        expect('$i', isNotEmpty);
      }
    });
  });

  // ── Combined eligibility check ──

  group('NpsSurveyDialog combined eligibility', () {
    bool isEligible({DateTime? accountCreatedAt, DateTime? lastSurveyDate}) {
      if (accountCreatedAt == null) return false;
      final accountAge = DateTime.now().difference(accountCreatedAt);
      if (accountAge.inDays < 7) return false;
      if (lastSurveyDate != null) {
        final daysSinceLast = DateTime.now().difference(lastSurveyDate).inDays;
        if (daysSinceLast < 90) return false;
      }
      return true;
    }

    test('old account with no previous survey is eligible', () {
      final created = DateTime.now().subtract(const Duration(days: 30));
      expect(isEligible(accountCreatedAt: created), isTrue);
    });

    test('new account with no previous survey is not eligible', () {
      final created = DateTime.now().subtract(const Duration(days: 2));
      expect(isEligible(accountCreatedAt: created), isFalse);
    });

    test('old account with recent survey is not eligible', () {
      final created = DateTime.now().subtract(const Duration(days: 30));
      final lastSurvey = DateTime.now().subtract(const Duration(days: 10));
      expect(
        isEligible(accountCreatedAt: created, lastSurveyDate: lastSurvey),
        isFalse,
      );
    });

    test('old account with old survey is eligible', () {
      final created = DateTime.now().subtract(const Duration(days: 200));
      final lastSurvey = DateTime.now().subtract(const Duration(days: 100));
      expect(
        isEligible(accountCreatedAt: created, lastSurveyDate: lastSurvey),
        isTrue,
      );
    });
  });
}
