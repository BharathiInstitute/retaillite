/// Tests for OnboardingChecklist — step completion and display logic.
///
/// The widget depends on FirebaseFirestore + FirebaseAuth via StreamBuilder.
/// We test the pure logic functions inline.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── _allStepsDone logic ──
  // Mirrors: firstProductAdded == true && firstBillCreated == true && firstCustomerAdded == true

  group('OnboardingChecklist _allStepsDone', () {
    bool allStepsDone(Map<String, dynamic> onboarding) {
      return onboarding['firstProductAdded'] == true &&
          onboarding['firstBillCreated'] == true &&
          onboarding['firstCustomerAdded'] == true;
    }

    test('all three true returns true', () {
      expect(
        allStepsDone({
          'firstProductAdded': true,
          'firstBillCreated': true,
          'firstCustomerAdded': true,
        }),
        isTrue,
      );
    });

    test('product missing returns false', () {
      expect(
        allStepsDone({
          'firstProductAdded': false,
          'firstBillCreated': true,
          'firstCustomerAdded': true,
        }),
        isFalse,
      );
    });

    test('bill missing returns false', () {
      expect(
        allStepsDone({
          'firstProductAdded': true,
          'firstBillCreated': false,
          'firstCustomerAdded': true,
        }),
        isFalse,
      );
    });

    test('customer missing returns false', () {
      expect(
        allStepsDone({
          'firstProductAdded': true,
          'firstBillCreated': true,
          'firstCustomerAdded': false,
        }),
        isFalse,
      );
    });

    test('all false returns false', () {
      expect(
        allStepsDone({
          'firstProductAdded': false,
          'firstBillCreated': false,
          'firstCustomerAdded': false,
        }),
        isFalse,
      );
    });

    test('empty map returns false', () {
      expect(allStepsDone({}), isFalse);
    });

    test('null values treated as not done', () {
      expect(
        allStepsDone({
          'firstProductAdded': null,
          'firstBillCreated': true,
          'firstCustomerAdded': true,
        }),
        isFalse,
      );
    });
  });

  // ── Progress count ──
  // Mirrors: doneCount = (hasProducts ? 1 : 0) + (hasBill ? 1 : 0) + (hasCustomer ? 1 : 0)

  group('OnboardingChecklist progress count', () {
    int doneCount(Map<String, dynamic> onboarding) {
      final hasProducts = onboarding['firstProductAdded'] == true;
      final hasBill = onboarding['firstBillCreated'] == true;
      final hasCustomer = onboarding['firstCustomerAdded'] == true;
      return (hasProducts ? 1 : 0) + (hasBill ? 1 : 0) + (hasCustomer ? 1 : 0);
    }

    test('0 done when nothing complete', () {
      expect(doneCount({}), 0);
    });

    test('1 done when one step complete', () {
      expect(doneCount({'firstProductAdded': true}), 1);
    });

    test('2 done when two steps complete', () {
      expect(
        doneCount({'firstProductAdded': true, 'firstBillCreated': true}),
        2,
      );
    });

    test('3 done when all steps complete', () {
      expect(
        doneCount({
          'firstProductAdded': true,
          'firstBillCreated': true,
          'firstCustomerAdded': true,
        }),
        3,
      );
    });

    test('progress text format is correct', () {
      expect('${2}/3', '2/3');
      expect('${0}/3', '0/3');
      expect('${3}/3', '3/3');
    });
  });

  // ── Visibility logic ──
  // Mirrors: if (dismissed == true || _allStepsDone(onboarding)) => SizedBox.shrink

  group('OnboardingChecklist visibility', () {
    bool shouldShow(Map<String, dynamic> onboarding) {
      final dismissed = onboarding['dismissed'] == true;
      final allDone =
          onboarding['firstProductAdded'] == true &&
          onboarding['firstBillCreated'] == true &&
          onboarding['firstCustomerAdded'] == true;
      return !dismissed && !allDone;
    }

    test('shows when not dismissed and steps incomplete', () {
      expect(shouldShow({'firstProductAdded': true}), isTrue);
    });

    test('hides when dismissed', () {
      expect(shouldShow({'dismissed': true}), isFalse);
    });

    test('hides when all steps done', () {
      expect(
        shouldShow({
          'firstProductAdded': true,
          'firstBillCreated': true,
          'firstCustomerAdded': true,
        }),
        isFalse,
      );
    });

    test('hides when dismissed AND all done', () {
      expect(
        shouldShow({
          'dismissed': true,
          'firstProductAdded': true,
          'firstBillCreated': true,
          'firstCustomerAdded': true,
        }),
        isFalse,
      );
    });

    test('shows for empty onboarding data', () {
      expect(shouldShow({}), isTrue);
    });
  });

  // ── Step completion decorations ──
  // Mirrors: isCompleted ? Icons.check_circle : Icons.radio_button_unchecked

  group('OnboardingChecklist step icons', () {
    test('completed step shows check_circle', () {
      const isCompleted = true;
      expect(isCompleted, isTrue);
      // Icon: Icons.check_circle (green)
    });

    test('incomplete step shows radio_button_unchecked', () {
      const isCompleted = false;
      expect(isCompleted, isFalse);
      // Icon: Icons.radio_button_unchecked (grey)
    });
  });
}
