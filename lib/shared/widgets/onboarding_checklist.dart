import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/core/services/error_logging_service.dart';

/// Helper to get the user's Firestore ref.
DocumentReference? _userRef() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

/// Marks the onboarding "first bill" step as completed.
Future<void> markOnboardingBillDone() async {
  final ref = _userRef();
  if (ref == null) return;

  try {
    await ref.set({
      'onboarding': {
        'firstBillCreated': true,
        'firstBillAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  } catch (e, st) {
    debugPrint('⚠️ Onboarding: markFirstBillCreated failed: $e');
    ErrorLoggingService.logError(
      error: e,
      stackTrace: st,
      severity: ErrorSeverity.warning,
      metadata: {'context': 'markOnboardingBillDone'},
    ).ignore();
  }
}

/// Dismisses the onboarding checklist permanently.
Future<void> dismissOnboarding() async {
  final ref = _userRef();
  if (ref == null) return;

  try {
    await ref.set({
      'onboarding': {'dismissed': true},
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('⚠️ Onboarding: dismiss failed: $e');
  }
}

/// Resets the dismissed flag so the checklist shows again (for Settings).
Future<void> reopenOnboarding() async {
  final ref = _userRef();
  if (ref == null) return;

  try {
    await ref.set({
      'onboarding': {'dismissed': false},
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('⚠️ Onboarding: reopen failed: $e');
  }
}

/// Returns true if all onboarding steps are completed.
bool _allStepsDone(Map<String, dynamic> onboarding) {
  return onboarding['firstProductAdded'] == true &&
      onboarding['firstBillCreated'] == true &&
      onboarding['firstCustomerAdded'] == true;
}

/// A checklist widget shown during onboarding to guide new users.
/// Hidden once all steps are done or user dismisses it.
class OnboardingChecklist extends StatelessWidget {
  const OnboardingChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final onboarding = data['onboarding'] as Map<String, dynamic>? ?? {};

        // Don't show if dismissed or all steps done
        if (onboarding['dismissed'] == true || _allStepsDone(onboarding)) {
          return const SizedBox.shrink();
        }

        final hasProducts = onboarding['firstProductAdded'] == true;
        final hasBill = onboarding['firstBillCreated'] == true;
        final hasCustomer = onboarding['firstCustomerAdded'] == true;
        final doneCount =
            (hasProducts ? 1 : 0) + (hasBill ? 1 : 0) + (hasCustomer ? 1 : 0);

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.checklist, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Getting Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$doneCount/3',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => dismissOnboarding(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ChecklistItem(
                  title: 'Add your first product',
                  isCompleted: hasProducts,
                  onTap: hasProducts ? null : () => context.push('/products'),
                ),
                _ChecklistItem(
                  title: 'Create your first bill',
                  isCompleted: hasBill,
                  onTap: hasBill ? null : () => context.push('/billing'),
                ),
                _ChecklistItem(
                  title: 'Add your first customer',
                  isCompleted: hasCustomer,
                  onTap: hasCustomer ? null : () => context.push('/khata'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _ChecklistItem({
    required this.title,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : null,
              ),
            ),
            if (!isCompleted)
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
