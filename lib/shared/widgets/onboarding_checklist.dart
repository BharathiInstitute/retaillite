import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retaillite/core/services/error_logging_service.dart';

/// Marks the onboarding "first bill" step as completed.
Future<void> markOnboardingBillDone() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
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

/// A checklist widget shown during onboarding to guide new users.
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

        final hasProducts = onboarding['firstProductAdded'] == true;
        final hasBill = onboarding['firstBillCreated'] == true;
        final hasCustomer = onboarding['firstCustomerAdded'] == true;

        // Don't show if all steps are done
        if (hasProducts && hasBill && hasCustomer) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Getting Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ChecklistItem(
                  title: 'Add your first product',
                  isCompleted: hasProducts,
                ),
                _ChecklistItem(
                  title: 'Create your first bill',
                  isCompleted: hasBill,
                ),
                _ChecklistItem(
                  title: 'Add your first customer',
                  isCompleted: hasCustomer,
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

  const _ChecklistItem({required this.title, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
        ],
      ),
    );
  }
}
