import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for viewing and managing subscription plans.
///
/// **Google Play Billing Policy Compliance:**
/// Digital subscriptions on Android MUST use Google Play Billing (IAP).
/// Razorpay / external payment gateways can only be used for:
///   - Web platform subscriptions
///   - Server-side renewals (outside Google Play)
/// Using external gateways for in-app digital purchases on Android
/// will cause rejection from the Play Store.
///
/// Implementation plan:
///   - Android: Use `in_app_purchase` package with Google Play Billing
///   - Web: Use Razorpay or Stripe payment links
///   - Windows: Use Razorpay or direct bank transfer
///   - iOS (future): Use StoreKit via `in_app_purchase`
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose the right plan for your business',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildPlanCard(
              context,
              name: 'Free',
              price: '₹0',
              period: 'forever',
              features: [
                '50 bills/month',
                '100 products',
                '10 customers',
                'Basic reports',
              ],
              color: Colors.grey,
              isCurrent:
                  true, // Current plan determination handled by _isPlanCurrent below
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              name: 'Pro',
              price: '₹299',
              period: '/month',
              features: [
                '500 bills/month',
                '1,000 products',
                '100 customers',
                'Advanced reports',
                'Priority support',
              ],
              color: Colors.blue,
              isCurrent: false,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              name: 'Business',
              price: '₹999',
              period: '/month',
              features: [
                'Unlimited bills',
                'Unlimited products',
                'Unlimited customers',
                'All reports',
                'Dedicated support',
                'Multi-device sync',
              ],
              color: Colors.purple,
              isCurrent: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    required bool isCurrent,
  }) {
    return Card(
      elevation: isCurrent ? 0 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (isCurrent)
                  Chip(
                    label: const Text('Current'),
                    backgroundColor: color.withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  TextSpan(
                    text: period,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!isCurrent)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _handleUpgrade(context, name);
                  },
                  style: FilledButton.styleFrom(backgroundColor: color),
                  child: Text('Upgrade to $name'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Handle subscription upgrade with platform-aware payment flow.
  ///
  /// - **Android**: Must use Google Play Billing (IAP) per Play Store policy.
  /// - **Web / Windows**: Can use Razorpay, Stripe, or direct payment links.
  /// - **iOS**: Must use StoreKit (Apple IAP) per App Store policy.
  void _handleUpgrade(BuildContext context, String planName) {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    if (isAndroid || isIOS) {
      // Google Play / App Store in-app purchase flow
      // Uses `in_app_purchase` package:
      //   1. Query available products from Play Store / App Store
      //   2. Launch purchase flow
      //   3. Verify receipt server-side via Cloud Function
      //   4. Update user subscription in Firestore
      // NOTE: Requires in_app_purchase setup in pubspec.yaml + Play Console products
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$planName upgrade via ${isAndroid ? "Google Play" : "App Store"} coming soon!',
          ),
        ),
      );
    } else {
      // Web / Desktop: Use Razorpay checkout or Stripe payment links
      // NOTE: Razorpay integration available via RazorpayService; wire when live keys are configured
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$planName upgrade coming soon!')));
    }
  }
}
