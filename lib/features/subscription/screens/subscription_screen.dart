import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:retaillite/features/auth/providers/auth_provider.dart';
import 'package:retaillite/features/subscription/services/subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isAnnual = false;
  bool _isLoading = false;

  String _currentPlan = 'free';
  String _subscriptionStatus = 'active';
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .get();
    final sub = doc.data()?['subscription'] as Map<String, dynamic>?;
    if (sub != null && mounted) {
      setState(() {
        _currentPlan = (sub['plan'] as String?) ?? 'free';
        _subscriptionStatus = (sub['status'] as String?) ?? 'active';
        _expiresAt = (sub['expiresAt'] as Timestamp?)?.toDate();
      });
    }
  }

  @override
  void dispose() {
    SubscriptionService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              GoRouter.of(context).go('/billing');
            }
          },
        ),
        title: const Text('Subscription Plans'),
      ),
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
            const SizedBox(height: 8),
            if (_currentPlan != 'free' && _expiresAt != null)
              Text(
                  'Current: ${_currentPlan[0].toUpperCase()}${_currentPlan.substring(1)} '
                  '($_subscriptionStatus) — expires ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            const SizedBox(height: 16),
            // Monthly / Annual toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Monthly'),
                Switch(
                  value: _isAnnual,
                  onChanged: (v) => setState(() => _isAnnual = v),
                ),
                const Text('Annual'),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Save ~17%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 8),
              Text(
                'You\'ll be redirected to the web app to complete payment',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              planKey: 'free',
              name: 'Free',
              monthlyPrice: 0,
              annualPrice: 0,
              features: [
                '50 bills/month',
                '100 products',
                '10 customers',
                'Basic reports',
              ],
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              planKey: 'pro',
              name: 'Pro',
              monthlyPrice: 10,
              annualPrice: 20,
              features: [
                '500 bills/month',
                '1,000 products',
                '100 customers',
                'Advanced reports',
                'Priority support',
              ],
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              planKey: 'business',
              name: 'Business',
              monthlyPrice: 20,
              annualPrice: 30,
              features: [
                'Unlimited bills',
                'Unlimited products',
                'Unlimited customers',
                'All reports',
                'Dedicated support',
                'Multi-device sync',
              ],
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String planKey,
    required String name,
    required int monthlyPrice,
    required int annualPrice,
    required List<String> features,
    required Color color,
  }) {
    final isCurrent = _currentPlan == planKey;
    final price = _isAnnual ? annualPrice : monthlyPrice;
    final period = planKey == 'free'
        ? 'forever'
        : _isAnnual
        ? '/year'
        : '/month';

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
                    text: '₹$price',
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
            if (!isCurrent && planKey != 'free')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : () => _handleUpgrade(planKey),
                  style: FilledButton.styleFrom(backgroundColor: color),
                  icon: !kIsWeb
                      ? const Icon(Icons.open_in_browser, size: 18)
                      : null,
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Upgrade to $name'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Handle subscription upgrade with platform-aware payment flow.
  ///
  /// On **web**: Opens Razorpay checkout directly.
  /// On **Android / Windows / iOS**: Opens the web app subscription page
  /// in the browser — avoids 15-30% platform store commissions.
  void _handleUpgrade(String planKey) {
    if (kIsWeb) {
      // Web: direct Razorpay checkout
      _startRazorpayPurchase(planKey);
    } else {
      // Android / Windows / iOS: open web app for payment
      _openWebSubscriptionPage();
    }
  }

  Future<void> _openWebSubscriptionPage() async {
    const webSubscriptionUrl = 'https://app.retaillite.com/app/subscription';
    final uri = Uri.parse(webSubscriptionUrl);

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open browser. Please visit app.retaillite.com to upgrade.',
          ),
        ),
      );
    }
  }

  Future<void> _startRazorpayPurchase(String planKey) async {
    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    final cycle = _isAnnual ? 'annual' : 'monthly';

    await SubscriptionService.instance.purchaseSubscription(
      plan: planKey,
      cycle: cycle,
      customerEmail: user?.email,
      customerPhone: user?.phone,
      customerName: user?.ownerName,
      onResult: (result) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${planKey == 'pro' ? 'Pro' : 'Business'} plan activated! 🎉',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Reload subscription state
          _loadCurrentSubscription();
        } else if (result.isCancelled) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Payment failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}
