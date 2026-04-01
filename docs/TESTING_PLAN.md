# RetailLite — Final Testing Plan

> **Version:** 1.0-final | **Date:** April 2026 | **Project:** RetailLite v9.7.0  
> **Scope:** 173 Dart source files, 25+ Cloud Functions, Firestore security rules, Storage rules  
> **Current state:** 134 test files (~1,200 tests), ~55% line coverage  
> **Target:** 100% file coverage, 95%+ line coverage, 0 untested public APIs  

---

## Table of Contents

1. [Inventory & Gap Analysis](#1-inventory--gap-analysis)
2. [Test Infrastructure](#2-test-infrastructure)
3. [Layer 1 — Models & Data](#3-layer-1--models--data)
4. [Layer 2 — Utilities & Config](#4-layer-2--utilities--config)
5. [Layer 3 — Services](#5-layer-3--services)
6. [Layer 4 — Providers & State Management](#6-layer-4--providers--state-management)
7. [Layer 5 — Widgets & Components](#7-layer-5--widgets--components)
8. [Layer 6 — Screens](#8-layer-6--screens)
9. [Layer 7 — Navigation & Routing](#9-layer-7--navigation--routing)
10. [Layer 8 — Integration Tests](#10-layer-8--integration-tests)
11. [Layer 9 — Security Tests](#11-layer-9--security-tests)
12. [Layer 10 — Cloud Functions Tests](#12-layer-10--cloud-functions-tests)
13. [Layer 11 — Firestore & Storage Rules Tests](#13-layer-11--firestore--storage-rules-tests)
14. [Layer 12 — Performance & Load Tests](#14-layer-12--performance--load-tests)
15. [Layer 13 — E2E & Manual-Only Tests](#15-layer-13--e2e--manual-only-tests)
16. [Coverage Enforcement & CI](#16-coverage-enforcement--ci)
17. [Execution Schedule](#17-execution-schedule)
18. [Final Inventory](#18-final-inventory)

---

## 1. Inventory & Gap Analysis

### Current Coverage by Layer

| Layer | Source Files | Test Files | Line Coverage | Verdict |
|-------|-------------|------------|---------------|---------|
| Models (lib/models/) | 8 | 18 | ~95% | Good — add boundary tests |
| Utils (lib/core/utils/) | 9 | 8 | ~90% | Good — 1 file missing |
| Config (lib/core/config/) | 3 | 3 | ~85% | Good — add plan ID tests |
| Constants (lib/core/constants/) | 2 | 1 | ~80% | Good |
| Design (lib/core/design/) | 5 | 6 | ~95% | Done |
| L10n | 1 | 1 | ~90% | Done |
| Core Services (lib/core/services/) | 34 | 41 | ~70% | 3 files missing |
| Feature Services | 8 | 0 | 0% | **Critical gap** |
| Providers | 20 | 15 | ~60% | 5 missing, 1 at 9% |
| Shared Widgets | 16 | 11 | ~40% | 9 missing |
| Feature Widgets | 12 | 5 | ~25% | 7 missing |
| Screens | 35 | 0 | 0% | **Critical gap** |
| Routing | 1 | 1 | ~10% | Only constants tested |
| Shell (app_shell, web_shell) | 2 | 0 | 0% | **Critical gap** |
| Security | — | 2 | N/A | Needs 5 more |
| Integration | — | 8 | N/A | Needs 10 more |
| Cloud Functions (functions/src/) | 25+ | 0 | 0% | **Critical gap** |
| Firestore Rules | 1 | 0 | 0% | **Critical gap** |
| Performance/Load | — | 1 | N/A | 1 k6 script exists |

### High-Risk Untested Areas (Ordered by Business Impact)

1. **Subscription purchase flow** — Revenue-generating path, 0% tested
2. **Cloud Functions** — 25+ functions running in production, 0% tested  
3. **Firestore security rules** — All data protection logic, 0% tested
4. **Billing provider** — Core feature powering POS, 9% coverage
5. **Notification system** — 4 services + 1 provider + 1 widget, all 0%
6. **Navigation shells** — app_shell + web_shell, user-facing navigation
7. **All 35 screens** — No render tests, no interaction tests
8. **Month rollover logic** — Billing limits reset, race condition risk
9. **Referral idempotency** — Duplicate rewards if webhook re-delivered
10. **Desktop auth flow** — 10-min session expiry, token management

---

## 2. Test Infrastructure

### 2.1 Existing Helpers (Keep As-Is)

| File | Purpose |
|------|---------|
| `test/helpers/test_app.dart` | `testApp(widget)` — MaterialApp wrapper for widget tests |
| `test/helpers/test_factories.dart` | `makeProduct()`, `makeBill()`, `makeCustomer()`, `makeUser()`, `makeExpense()`, `makeTransaction()`, `makeSubscription()`, `makeLimits()`, `makeNotification()`, `makeAdminUser()` |

### 2.2 New Helpers to Create

#### `test/helpers/mock_services.dart`
Centralized mock classes using `mocktail`. One mock per injectable dependency.

```dart
import 'package:mocktail/mocktail.dart';

// Firebase
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockHttpCallableResult extends Mock implements HttpsCallableResult {}

// Core Services
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockOfflineStorageService extends Mock implements OfflineStorageService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockErrorLoggingService extends Mock implements ErrorLoggingService {}
class MockSyncStatusService extends Mock implements SyncStatusService {}
class MockWriteRetryQueue extends Mock implements WriteRetryQueue {}

// Feature Services
class MockSubscriptionService extends Mock implements SubscriptionService {}
class MockRazorpay extends Mock implements Razorpay {}
class MockNotificationFirestoreService extends Mock implements NotificationFirestoreService {}
class MockReferralService extends Mock implements ReferralService {}
class MockAdminFirestoreService extends Mock implements AdminFirestoreService {}
class MockBillingService extends Mock implements BillingService {}
class MockBillShareService extends Mock implements BillShareService {}
class MockKhataWriteService extends Mock implements KhataWriteService {}

// Platform
class MockGoRouter extends Mock implements GoRouter {}
class MockBuildContext extends Mock implements BuildContext {}
```

**Why this matters:** Every widget test, screen test, and provider test needs mock services. Without this file, each test file re-creates mocks — inconsistent and brittle.

#### `test/helpers/mock_providers.dart`
Pre-configured Riverpod overrides for isolated testing. Groups overrides by scenario.

```dart
/// Base overrides — enough to render any widget without Firebase
List<Override> baseOverrides({
  String userId = 'test-user-1',
  String plan = 'free',
  bool isOnline = true,
  bool isDemoMode = false,
}) => [
  currentUserIdProvider.overrideWithValue(userId),
  subscriptionPlanProvider.overrideWith((_) => Stream.value(plan)),
  isOnlineProvider.overrideWithValue(AsyncData(isOnline)),
  // Auth state as logged in with test user
  authNotifierProvider.overrideWith(() => MockAuthNotifier(userId, isDemoMode)),
];

/// For billing screens
List<Override> billingOverrides({...}) => [
  ...baseOverrides(),
  filteredBillsProvider.overrideWith((_) => Stream.value(testBills)),
  billsFilterProvider.overrideWithValue(const BillsFilter()),
  cartProvider.overrideWith(() => CartNotifier()),
];

/// For admin screens
List<Override> adminOverrides({...}) => [
  ...baseOverrides(userId: 'admin-1'),
  superAdminProvider.overrideWith(() => MockSuperAdminNotifier()),
];
```

**Why this matters:** Screen and widget tests fail without provider overrides. This avoids 50+ test files each manually wiring providers.

#### `test/helpers/pump_helpers.dart`
High-level pump functions that wrap ProviderScope + MaterialApp + optional GoRouter.

```dart
/// Pump a screen widget with all required wrappers
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override>? overrides,
  Size screenSize = const Size(1920, 1080),  // Desktop default
}) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? baseOverrides(),
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.view.resetPhysicalSize());
}

/// Pump with GoRouter (for navigation testing)
Future<void> pumpWithRouter(
  WidgetTester tester, {
  required GoRouter router,
  List<Override>? overrides,
}) async { ... }

/// Pump for mobile viewport
Future<void> pumpMobile(WidgetTester tester, Widget screen, {...}) async {
  await pumpScreen(tester, screen, screenSize: const Size(390, 844), ...);
}

/// Pump for tablet viewport
Future<void> pumpTablet(WidgetTester tester, Widget screen, {...}) async {
  await pumpScreen(tester, screen, screenSize: const Size(820, 1180), ...);
}
```

**Why this matters:** Tests break when screen size affects layout (responsive shell switches between mobile/tablet/desktop). Standardized pumping prevents flaky tests.

#### `test/helpers/fake_firestore_setup.dart`
Pre-populated FakeFirebaseFirestore with realistic test data.

```dart
/// Returns a FakeFirebaseFirestore with test data pre-loaded
FakeFirebaseFirestore setupFakeFirestore({
  String userId = 'test-user-1',
  int products = 5,
  int bills = 10,
  int customers = 3,
  String plan = 'free',
}) {
  final fs = FakeFirebaseFirestore();
  // Seed user doc with subscription
  fs.collection('users').doc(userId).set({
    'shopName': 'Test Shop',
    'ownerName': 'Test Owner',
    'subscription': {'plan': plan, 'status': 'active'},
    'limits': {'billsThisMonth': 0, 'billsLimit': 50, 'productsCount': products},
  });
  // Seed products, bills, customers from test_factories
  for (var i = 0; i < products; i++) { ... }
  return fs;
}
```

---

## 3. Layer 1 — Models & Data

### 3.1 Existing Tests (18 files — keep, extend)

All 8 models have tests. These tests use pure Dart assertions on immutable objects — no mocking.

**Extension tests to add** (append to existing files, not new files):

| Existing Test File | New Test Cases |
|-------------------|----------------|
| `bill_model_test.dart` | CartItem with qty=0, qty=MAX, negative price, empty items list, `toMap()`/`fromMap()` roundtrip with all PaymentMethod values |
| `product_model_test.dart` | All 6 `ProductUnit` values (piece/kg/gram/liter/ml/pack), `profit` when purchasePrice=null, barcode=null vs barcode="", stock underflow (0→-1 via model only) |
| `customer_model_test.dart` | `balance` at MAX_DOUBLE, phone format edge cases (empty, 9 digits, 11 digits), `lastTransactionAt` null handling |
| `user_model_test.dart` | All `SubscriptionPlan` enum values, `UserLimits.usagePercentage` at 0/50/100/101%, `isNearLimit` boundary (79% vs 80% vs 81%), `isAtLimit` boundary (49/50/51 of 50), `UserSubscription.isExpired` with DateTime.now edge |
| `expense_model_test.dart` | All `ExpenseCategory` enum values, amount=0, `toMap()`/`fromMap()` roundtrip |
| `sales_summary_model.dart` | Empty bill list, single bill, 1000 bills, all-cash vs all-UPI vs all-credit |
| `notification_model_test.dart` | All `NotificationType` values, all `NotificationTargetType` values, `isForUser()` filtering logic (all/plan/specific), `data` map serialization |
| `transaction_model_test.dart` | `TransactionType.purchase` vs `.payment`, amount boundary (0.01, 99999999), billId null for payments |

**New test file:**

| File | Tests |
|------|-------|
| `test/models/model_serialization_test.dart` | Round-trip `toMap()` → `fromMap()` for ALL 8 models with all field combinations: null optionals, empty strings, DateTime boundaries, nested objects (CartItem in Bill), enum serialization. **32 tests.** |

### 3.2 Mock Data Validation

| File | Tests |
|------|-------|
| `test/unit/mock_data_test.dart` | ✅ EXISTS — verify all counts, no duplicates |

**Extension:** Add tests for mock data determinism (seed=42 produces same data every time) and that all products have valid prices/stock.

**Total new tests in Layer 1: ~60 tests across 9 extended files + 1 new file**

---

## 4. Layer 2 — Utilities & Config

### 4.1 Utilities (8 existing + 1 missing)

| File | Test | Status | Extension Needed |
|------|------|--------|-----------------|
| `validators.dart` | `validators_test.dart` | ✅ | GST: 15-char format NNAA*NNNNX*NZ* ; UPI: handle@bank ; phone: exactly 10 digits, no letters; email: RFC-safe subset; barcode: EAN-13 checksum |
| `formatters.dart` | `formatters_test.dart` | ✅ | ₹0.00, ₹99,99,999 (Indian grouping), negative currency, date across IST/UTC, `timeAgo()` at 0s/59s/1m/59m/1h/23h/1d/30d/365d boundaries |
| `extensions.dart` | `extensions_test.dart` | ✅ | Null-safe extensions on empty strings, empty lists, null DateTime, `capitalize()` on single char, Unicode (Hindi/Telugu names) |
| `id_generator.dart` | `id_generator_test.dart` | ✅ | Generate 10,000 IDs → all unique (Set size check), format regex match, length consistency |
| `error_handler.dart` | `error_handler_test.dart` | ✅ | — |
| `color_utils.dart` | `color_utils_test.dart` | ✅ | — |
| `a11y.dart` | `a11y_test.dart` | ✅ | — |
| `website_url.dart` | `website_url_test.dart` | ✅ | — |
| **`platform_utils.dart`** | **MISSING** | ❌ | **NEW:** Platform detection booleans (isWeb, isWindows, isAndroid, isIOS, isDesktop, isMobile), conditional imports behavior |

**New test file:**

```
test/utils/platform_utils_test.dart
  group('PlatformUtils')
    test('isMobile returns true when isAndroid or isIOS')
    test('isDesktop returns true when isWindows or isMacOS or isLinux')
    test('isWeb detection')
    test('platform name string')
    — 8 tests
```

### 4.2 Config (3 existing)

| File | Test | Extension Needed |
|------|------|-----------------|
| `app_check_config.dart` | ✅ | — |
| `razorpay_config.dart` | ✅ | Plan ID map: all 4 keys exist (pro.monthly, pro.annual, business.monthly, business.annual), no empty values, key format starts with `rzp_` |
| `remote_config_state.dart` | ✅ | All config keys have defaults, type safety (bool fields can't be string), `minimumVersion` semver parsing |

### 4.3 Constants & Design (7 files — all covered)

Extension: Add `app_constants_test.dart` to verify all plan limits match (free=50/100/10, pro=500/unlimited, business=unlimited).

**Total new tests in Layer 2: ~30 tests across extensions + 1 new file**

---

## 5. Layer 3 — Services

This is the most critical layer — services contain all business logic. 37+ services total.

### 5.1 Core Services — Existing & Well-Tested (31 services)

These have test files and good coverage. **No action needed** unless coverage report exposes specific methods below 90%.

| Service | Test | Status |
|---------|------|--------|
| analytics_service | analytics_platform_test | ✅ |
| app_health_service | app_health_test | ✅ |
| barcode_lookup_service | barcode_lookup_test | ✅ |
| conflict_resolution_service | conflict_resolution_test | ✅ |
| connectivity_service | connectivity_test | ✅ |
| data_export_service | data_export_service_test | ✅ |
| data_retention_service | data_retention_test | ✅ |
| demo_data_service | demo_data_service_test | ✅ |
| error_logging_service | error_logging_test | ✅ |
| image_service | image_service_test | ✅ |
| offline_storage_service | offline_storage_settings_test | ✅ |
| payment_link_service | payment_link_test | ✅ |
| performance_service | performance_test | ✅ |
| privacy_consent_service | privacy_consent_test | ✅ |
| product_catalog_service | product_catalog_test | ✅ |
| product_csv_service | product_csv_service_test | ✅ |
| razorpay_service | razorpay_result_test | ✅ |
| receipt_service | receipt_service_test | ✅ |
| schema_migration_service | schema_migration_service_test | ✅ |
| sync_settings_service | sync_settings_test | ✅ |
| sync_status_service | sync_status_test | ✅ |
| thermal_printer_service | thermal_printer_test | ✅ |
| throttle_service | throttle_test | ✅ |
| usage_tracking_service | usage_tracking_test | ✅ |
| user_metrics_service | user_metrics_test | ✅ |
| user_usage_service | user_usage_test | ✅ |
| windows_update_service | windows_update_test | ✅ |
| write_retry_queue | retry_behavior_test | ✅ |
| billing_service | billing_service_test | ✅ |
| bill_share_service | bill_share_test | ✅ |
| khata_write_service | khata_write_logic_test | ✅ |

### 5.2 Core Services — Missing Tests (3 services)

#### `test/services/barcode_scanner_service_test.dart` — NEW

```
group('BarcodeScannerService')
  test('parseScanResult returns product ID for valid barcode')
  test('parseScanResult returns null for empty scan')
  test('parseScanResult handles malformed barcode gracefully')
  test('torch toggle state switches correctly')
  test('scan timeout returns null after duration')
  test('consecutive scans debounced (no double-add)')
  — 6 tests, mock: camera controller
```

#### `test/services/print_helper_test.dart` — NEW

```
group('PrintHelper')
  test('formatReceipt generates valid receipt string for bill')
  test('formatReceipt includes shop name, items, totals, footer')
  test('formatReceipt handles 0 items gracefully')
  test('formatReceipt handles long product names (truncation)')
  test('formatReceipt respects paper width 58mm vs 80mm')
  test('formatReceipt includes GST number when present')
  test('formatReceipt includes UPI ID when present')
  test('formatReceipt in Hindi/Telugu locale')
  test('calculatePaperWidth returns correct px for paper size index')
  test('PDF generation does not throw for valid bill')
  — 10 tests, no mocks (pure formatting)
```

#### `test/services/web_persistence_test.dart` — NEW

```
group('WebPersistence')
  test('enablePersistence completes without error')
  test('stub implementation is no-op on non-web platforms')
  — 2 tests
```

### 5.3 Feature Services — ALL MISSING (7 services, 0% tested)

#### `test/features/subscription/subscription_service_test.dart` — NEW (CRITICAL)

```
group('SubscriptionResult')
  test('success factory sets correct status, plan, cycle')
  test('failure factory sets error message')
  test('cancelled factory sets cancelled status')
  test('isSuccess returns true only for success status')
  test('isCancelled returns true only for cancelled status')

group('SubscriptionService.purchaseSubscription')
  // Mock: FirebaseFunctions.httpsCallable, Razorpay
  test('calls createSubscription Cloud Function with plan=pro, cycle=monthly')
  test('calls createSubscription Cloud Function with plan=business, cycle=annual')
  test('passes customerEmail, customerPhone, customerName to CF')
  test('extracts subscriptionId from CF response')
  test('opens Razorpay checkout with correct subscription_id')
  test('opens Razorpay checkout with correct amount for pro.monthly')
  test('opens Razorpay checkout with correct amount for business.annual')
  test('on payment success: calls activateSubscription CF')
  test('on payment success: passes razorpay_payment_id and subscription_id')
  test('on payment success: invokes onResult with SubscriptionResult.success')
  test('on payment failure: invokes onResult with SubscriptionResult.failure')
  test('on payment failure: includes error description')
  test('on external wallet: invokes onResult with failure + wallet name')
  test('CF createSubscription error: invokes onResult with failure')
  test('CF activateSubscription error: invokes onResult with failure')
  test('CF network timeout: invokes onResult with failure (not crash)')
  test('non-web platform: returns redirect result (no checkout opened)')
  test('dispose clears Razorpay event handlers')

group('SubscriptionService singleton')
  test('instance returns same object')
  — 20 tests total
```

#### `test/features/referral/referral_service_test.dart` — NEW

```
group('ReferralService')
  // Mock: FirebaseFirestore (fake_cloud_firestore), FirebaseAuth
  test('getOrCreateCode creates new 8-char code if none exists')
  test('getOrCreateCode returns existing code on second call')
  test('getOrCreateCode code is alphanumeric uppercase')
  test('getReferralCount returns 0 for new user')
  test('getReferralCount returns correct count after referrals')
  test('share copies code to clipboard')
  test('share returns true on success')
  test('share returns false when clipboard unavailable')
  test('getOrCreateCode handles Firestore error gracefully')
  — 9 tests
```

#### `test/features/notifications/fcm_token_service_test.dart` — NEW

```
group('FCMTokenService')
  // Mock: FirebaseMessaging, FirebaseFirestore
  test('initAndSaveToken requests permission')
  test('initAndSaveToken gets FCM token')
  test('initAndSaveToken saves token to Firestore at users/{uid}/fcmTokens')
  test('initAndSaveToken handles permission denied (no crash)')
  test('initAndSaveToken handles getToken failure gracefully')
  test('removeToken deletes FCM token(s) from Firestore')
  test('removeToken handles missing document gracefully')
  test('initAndSaveToken on web platform uses vapid key')
  — 8 tests
```

#### `test/features/notifications/notification_firestore_service_test.dart` — NEW

```
group('NotificationFirestoreService')
  // Uses: FakeFirebaseFirestore (package:fake_cloud_firestore)
  test('getUserNotificationsStream returns notifications ordered by createdAt desc')
  test('getUserNotificationsStream returns empty list for new user')
  test('getUserNotificationsStream updates in real-time on new notification')
  test('getUnreadCountStream returns correct count')
  test('getUnreadCountStream updates when notification marked as read')
  test('markAsRead sets read=true on notification doc')
  test('markAsRead does not affect other notifications')
  test('markAllAsRead sets read=true on ALL user notifications')
  test('deleteNotification removes notification doc')
  test('deleteNotification on non-existent doc does not throw')
  test('sendToUser creates notification in user subcollection')
  test('sendToUser sets correct fields (title, body, type, createdAt)')
  test('sendToAllUsers creates notification for every user')
  test('sendToAllUsers returns correct recipientCount')
  test('sendToAllUsers paginates correctly (>200 users)')
  test('sendToPlanUsers only targets users with matching plan')
  test('sendToPlanUsers skips free users when targeting pro')
  test('sendToSelectedUsers targets only specified userIds')
  test('searchUsers finds by shopName substring')
  test('searchUsers finds by email')
  test('searchUsers returns empty list for no match')
  test('getAllUsers returns all user summaries')
  test('getNotificationHistory returns last N notifications ordered by date')
  test('getNotificationHistory respects limit parameter')
  — 24 tests
```

#### `test/features/notifications/notification_service_test.dart` — NEW

```
group('NotificationService')
  // Mock: FirebaseMessaging
  test('initMessageListeners registers onMessage callback')
  test('initMessageListeners registers onMessageOpenedApp callback')
  test('setForegroundOptions sets alert+badge+sound')
  test('dispose cancels message subscription')
  test('backgroundHandler processes remote message without crash')
  — 5 tests
```

#### `test/features/notifications/windows_notification_service_test.dart` — NEW

```
group('WindowsNotificationService')
  // Mock: FlutterLocalNotificationsPlugin, FirebaseFirestore
  test('init initializes local notification plugin')
  test('startListening subscribes to user notification stream')
  test('startListening shows toast for each new notification')
  test('stopListening cancels Firestore subscription')
  test('init on non-Windows platform is safe no-op')
  — 5 tests
```

#### `test/features/super_admin/admin_firestore_service_test.dart` — NEW

```
group('AdminFirestoreService')
  // Uses: FakeFirebaseFirestore
  test('ensureAdminSeeded creates admins collection if empty')
  test('ensureAdminSeeded does not overwrite existing admins')
  test('getAllUsers returns paginated user list')
  test('getAllUsers respects limit parameter')
  test('getAllUsers filters by searchQuery (shopName)')
  test('getAllUsers filters by planFilter')
  test('getAllUsers supports startAfter cursor')
  test('getUser returns AdminUser for valid userId')
  test('getUser returns null for non-existent userId')
  test('getAdminStats returns totalUsers, freeUsers, proUsers, businessUsers, mrr')
  test('getAdminStats computes paidUsers = pro + business')
  test('getAdminStats computes conversionRate correctly')
  test('recalculateStats re-aggregates from Firestore')
  test('getUserBillsCount returns correct bill count')
  test('getUserProductsCount returns correct product count')
  test('getUserCustomersCount returns correct customer count')
  test('updateUserSubscription writes correct fields')
  test('updateUserSubscription updates limits based on plan')
  test('resetUserLimits sets billsThisMonth to 0')
  test('getRecentUsers returns users sorted by createdAt desc')
  test('getExpiringSubscriptions finds subs expiring within N days')
  test('getExpiringSubscriptions excludes already expired')
  test('getPlatformStats returns platform distribution')
  test('getFeatureUsageStats returns feature adoption percentages')
  test('getAggregatedAnalytics returns composite analytics object')
  test('getAdminEmails returns admin email list')
  test('addAdminEmail adds email to admins collection')
  test('addAdminEmail rejects duplicate email')
  test('removeAdminEmail removes email from admins')
  test('removeAdminEmail cannot remove primaryOwnerEmail')
  test('removeAdminEmail returns false for non-existent email')
  — 31 tests
```

**Total new tests in Layer 3: ~85 tests across 10 new test files**

---

## 6. Layer 4 — Providers & State Management

### 6.1 Existing Providers — Well-Tested (12 of 20)

| Provider | Test | Coverage |
|----------|------|----------|
| core_providers | core_providers_test | ✅ |
| paginated_provider | paginated_provider_test | ✅ |
| auth_provider | auth_state_test | ✅ |
| phone_auth_provider | phone_auth_state_test | ✅ |
| cart_provider | cart_provider_test | ✅ 96.5% |
| khata_provider | khata_logic_test | ✅ |
| khata_stats_provider | khata_stats_test | ✅ |
| products_provider | products_provider_test | ✅ |
| reports_provider | reports_provider_test | ✅ |
| settings_provider | settings_provider_test | ✅ |
| theme_settings_provider | theme_settings_provider_test | ✅ |
| super_admin_provider | super_admin_provider_test | ✅ |

### 6.2 Existing Provider — Needs Major Expansion

#### `test/providers/billing_provider_expanded_test.dart` — NEW

The existing `billing_provider_test.dart` is at 9% coverage. The provider exposes 5 providers with complex filtering logic.

```
group('BillsFilter model')
  test('default filter has no search, no date range, no payment method, recordType=all')
  test('copyWith creates new instance with overridden fields')
  test('copyWith preserves non-overridden fields')
  test('page and perPage defaults')

group('filteredBillsProvider')
  // Mock: OfflineStorageService.billsStream, authNotifierProvider.isDemoMode
  test('returns all bills when no filter applied')
  test('filters by searchQuery on billNumber')
  test('filters by searchQuery on customerName (case insensitive)')
  test('filters by searchQuery on customerName (partial match)')
  test('filters by dateRange start date')
  test('filters by dateRange end date')
  test('filters by dateRange both start and end')
  test('filters by paymentMethod cash')
  test('filters by paymentMethod upi')
  test('filters by paymentMethod credit')
  test('combined filter: searchQuery + dateRange + paymentMethod')
  test('sorts by createdAt descending')
  test('returns demo data when isDemoMode=true')
  test('re-emits when filter changes')
  test('empty search returns all bills')
  test('no matching filter returns empty list')

group('filteredExpensesProvider')
  test('returns all expenses when no filter applied')
  test('filters by searchQuery on description')
  test('filters by searchQuery on category name')
  test('filters by dateRange')
  test('filters by paymentMethod')
  test('sorts by createdAt descending')

group('billsSyncStatusProvider')
  test('returns map of billId to hasPendingWrites')
  test('returns empty map in demo mode')
  test('updates when pending writes change')

group('expensesSyncStatusProvider')
  test('returns map of expenseId to hasPendingWrites')
  test('returns empty map in demo mode')

— 28 tests
```

### 6.3 Missing Providers (5 providers)

#### `test/features/subscription/subscription_provider_test.dart` — NEW

```
group('subscriptionPlanProvider')
  // Uses: FakeFirebaseFirestore, mock auth state
  test('emits "free" when user doc has no subscription field')
  test('emits "free" when subscription.plan is null')
  test('emits "pro" when subscription.plan is "pro"')
  test('emits "business" when subscription.plan is "business"')
  test('re-emits when subscription field changes in Firestore')
  test('emits "free" when user is not authenticated')
  test('does not crash when user doc does not exist')
  test('handles Firestore stream error gracefully')
  — 8 tests
```

#### `test/features/notifications/notification_provider_test.dart` — NEW

```
group('notificationsStreamProvider')
  // Mock: NotificationFirestoreService.getUserNotificationsStream
  test('emits loading state initially')
  test('emits notification list from Firestore stream')
  test('emits empty list for user with no notifications')
  test('updates when new notification arrives')
  test('re-subscribes when auth state changes')

group('unreadNotificationCountProvider')
  test('emits 0 when no unread notifications')
  test('emits correct count for unread notifications')
  test('updates count when notification is marked as read')
  test('re-subscribes when auth state changes')
  — 9 tests
```

#### `test/providers/paginated_collections_provider_test.dart` — NEW

```
group('PaginatedCollectionsProvider')
  test('initial state has empty list and no cursor')
  test('fetchNext loads first page')
  test('fetchNext with existing cursor loads next page')
  test('fetchNext at end of data sets hasMore=false')
  test('refresh clears cursor and reloads from start')
  test('respects per-page limit')
  — 6 tests
```

#### Settings Provider Extension

The existing `settings_provider_test.dart` covers AppSettings but NOT PrinterState/PrinterNotifier.

```
// Append to existing settings_provider_test.dart or new file:
test/providers/printer_provider_test.dart — NEW

group('PrinterState model')
  test('default state: disconnected, no printer name, system type')
  test('paperSizeLabel returns 58mm for index 0')
  test('paperSizeLabel returns 80mm for index 1')
  test('fontSize returns correct PrinterFontSize for index')
  test('effectiveWidth calculates from paperSize when customWidth=0')
  test('effectiveWidth returns customWidth when > 0')
  test('widthLabel returns "Auto" when customWidth=0')
  test('isThermalPrinter returns false for system type')
  test('isThermalPrinter returns true for bluetooth/usb/wifi')

group('PrinterNotifier')
  // Mock: PrinterStorage
  test('init loads saved printer from PrinterStorage')
  test('connectPrinter saves name+address and sets connected=true')
  test('disconnectPrinter clears name+address and sets connected=false')
  test('setPaperSize updates paperSizeIndex and persists')
  test('setFontSize updates fontSizeIndex and persists')
  test('setCustomWidth updates customWidth and persists')
  test('setPrinterType updates type and persists')
  test('setAutoPrint toggles autoPrint flag')
  test('setReceiptFooter updates footer text')
  test('setError sets error message')
  test('clearError clears error message')
  test('checkConnection verifies Bluetooth status')
  — 21 tests
```

**Total new tests in Layer 4: ~72 tests across 5 new files + 1 expanded file**

---

## 7. Layer 5 — Widgets & Components

### 7.1 Existing Widget Tests (16 test files — keep)

These test shared widgets (AppButton, AppTextField, LoadingStates, etc.), auth widgets, and a few feature widgets. All use `testWidgets()` + `testApp()` pattern.

### 7.2 Missing Shared Widget Tests (9 widgets)

#### `test/widgets/plan_badge_test.dart` — NEW

```
group('PlanBadge')
  // Mock: subscriptionPlanProvider, GoRouter
  testWidgets('renders "FREE" with grey color for free plan')
  testWidgets('renders "PRO" with blue color and star icon for pro plan')
  testWidgets('renders "BUSINESS" with purple color and diamond icon for business plan')
  testWidgets('tap navigates to subscription screen')
  testWidgets('compact=true renders icon-only badge')
  testWidgets('compact=false renders full label')
  testWidgets('handles loading state gracefully (shows shimmer or placeholder)')
  testWidgets('handles error state gracefully (shows FREE as fallback)')
  — 8 tests
```

#### `test/widgets/announcement_banner_test.dart` — NEW

```
group('AnnouncementBanner')
  // Mock: RemoteConfigState, OfflineStorageService
  testWidgets('shows banner when announcement text is non-empty')
  testWidgets('hides banner when announcement text is empty')
  testWidgets('shows correct announcement message')
  testWidgets('dismiss button hides banner')
  testWidgets('dismissed banner does not reappear on rebuild')
  testWidgets('wraps child widget correctly')
  — 6 tests
```

#### `test/widgets/global_sync_indicator_test.dart` — NEW

```
group('GlobalSyncIndicator')
  // Mock: isOnlineProvider, globalSyncStatusProvider
  testWidgets('shows spinning icon during active sync')
  testWidgets('shows idle icon when sync complete')
  testWidgets('shows error icon on sync failure')
  testWidgets('shows offline icon when offline')
  testWidgets('tap opens SyncDetailsSheet')
  — 5 tests
```

#### `test/widgets/logout_dialog_test.dart` — NEW

```
group('showLogoutDialog')
  // Mock: authNotifierProvider, WriteRetryQueue
  testWidgets('dialog shows "Are you sure?" message')
  testWidgets('Cancel button closes dialog without logout')
  testWidgets('Logout button calls auth signOut')
  testWidgets('Logout button flushes write retry queue before sign out')
  — 4 tests
```

#### `test/widgets/nps_survey_dialog_test.dart` — NEW

```
group('NpsSurveyDialog')
  // Mock: FirebaseFirestore
  testWidgets('showIfEligible does NOT show for accounts < 7 days old')
  testWidgets('showIfEligible shows for accounts ≥ 7 days old')
  testWidgets('showIfEligible does NOT show if already submitted (Firestore check)')
  testWidgets('star rating 1-5 taps update visual state')
  testWidgets('submit sends rating + optional feedback to Firestore')
  testWidgets('skip button closes dialog without submitting')
  testWidgets('rating of 0 (no stars) disables submit button')
  — 7 tests
```

#### `test/widgets/onboarding_checklist_test.dart` — NEW

```
group('OnboardingChecklist')
  // Mock: FirebaseFirestore, FirebaseAuth
  testWidgets('renders all checklist steps')
  testWidgets('completed steps show checkmark')
  testWidgets('incomplete steps are clickable')
  testWidgets('progress indicator shows correct fraction')
  testWidgets('dismiss hides checklist')
  test('markOnboardingBillDone writes to Firestore')
  test('dismissOnboarding writes dismissed=true to Firestore')
  test('reopenOnboarding sets dismissed=false in Firestore')
  — 8 tests
```

#### `test/widgets/sync_details_sheet_test.dart` — NEW

```
group('SyncDetailsSheet')
  // Mock: globalSyncStatusProvider, isOnlineProvider
  testWidgets('shows last sync timestamp')
  testWidgets('shows pending write count')
  testWidgets('shows "Online" when connected')
  testWidgets('shows "Offline" when disconnected')
  testWidgets('retry button is visible when there are pending writes')
  — 5 tests
```

#### `test/widgets/update_banner_test.dart` — NEW

```
group('UpdateBanner')
  // Mock: WindowsUpdateService
  testWidgets('shows banner when new version is available')
  testWidgets('hides banner when on latest version')
  testWidgets('shows correct version number')
  testWidgets('Download button fires update callback')
  testWidgets('dismiss button hides banner')
  testWidgets('wraps child widget correctly')
  — 6 tests
```

#### `test/widgets/update_dialog_test.dart` — NEW

```
group('UpdateDialog')
  // Mock: WindowsUpdateService
  testWidgets('shows changelog text')
  testWidgets('shows Update Now and Later buttons')
  testWidgets('force mode hides Later button')
  testWidgets('Update Now triggers download')
  testWidgets('Later button closes dialog')
  testWidgets('shows download progress indicator during update')
  test('checkAndShow opens dialog when update available')
  test('checkAndShow does nothing when on latest')
  — 8 tests
```

### 7.3 Missing Feature Widget Tests (7 widgets)

#### `test/features/notifications/notification_bell_test.dart` — NEW

```
group('NotificationBell')
  // Mock: unreadNotificationCountProvider, GoRouter
  testWidgets('renders bell icon')
  testWidgets('shows badge with count when unread > 0')
  testWidgets('hides badge when unread = 0')
  testWidgets('badge shows 9+ when count > 9')
  testWidgets('tap navigates to notifications screen')
  — 5 tests
```

#### `test/widgets/payment_modal_test.dart` — NEW

```
group('PaymentModal')
  testWidgets('renders all payment method options (cash, UPI, card, credit)')
  testWidgets('cash selected by default')
  testWidgets('amount field shows bill total')
  testWidgets('change due calculates correctly for cash payment')
  testWidgets('credit option shows customer selection')
  testWidgets('pay button is enabled when valid amount entered')
  testWidgets('pay button is disabled when amount is 0')
  testWidgets('submit calls billing service with correct payment method')
  testWidgets('submit calls billing service with correct amount')
  testWidgets('UPI option shows UPI ID field')
  — 10 tests
```

#### `test/widgets/add_product_modal_test.dart` — NEW

```
group('AddProductModal')
  testWidgets('renders name, price, stock, category fields')
  testWidgets('name validation: empty name shows error')
  testWidgets('price validation: 0 or negative shows error')
  testWidgets('stock validation: negative shows error')
  testWidgets('barcode field accepts pre-fill value')
  testWidgets('category dropdown shows all categories')
  testWidgets('unit dropdown shows all ProductUnit values')
  testWidgets('save button calls onSave with ProductModel')
  testWidgets('cancel button closes modal')
  testWidgets('image picker button opens image source selector')
  — 10 tests
```

#### `test/widgets/add_customer_modal_test.dart` — NEW

```
group('AddCustomerModal')
  testWidgets('renders name and phone fields')
  testWidgets('name validation: empty shows error')
  testWidgets('phone validation: non-10-digit shows error')
  testWidgets('save creates CustomerModel with correct fields')
  testWidgets('cancel closes modal')
  — 5 tests
```

#### `test/widgets/khata_modals_test.dart` — NEW

```
group('GiveUdhaarModal')
  testWidgets('amount validation: 0 or negative shows error')
  testWidgets('amount validation: exceeds 99,999,999 shows error')
  testWidgets('note field is optional')
  testWidgets('submit creates credit transaction')

group('RecordPaymentModal')
  testWidgets('amount validation: 0 or negative shows error')
  testWidgets('amount validation: exceeds balance shows warning')
  testWidgets('payment mode dropdown (cash/UPI)')
  testWidgets('submit creates payment transaction')
  — 8 tests
```

#### `test/widgets/catalog_browser_modal_test.dart` — NEW

```
group('CatalogBrowserModal')
  testWidgets('renders search field')
  testWidgets('shows products matching search query')
  testWidgets('category filter tabs work')
  testWidgets('tap on product calls onSelect callback')
  testWidgets('empty search shows all products')
  testWidgets('no matches shows empty state')
  — 6 tests
```

#### `test/widgets/edit_shop_modal_test.dart` — NEW

```
group('EditShopModal')
  testWidgets('pre-fills current shop name')
  testWidgets('pre-fills current owner name')
  testWidgets('pre-fills current phone')
  testWidgets('pre-fills UPI ID if set')
  testWidgets('validation: empty shop name shows error')
  testWidgets('save updates user profile in Firestore')
  — 6 tests
```

**Total new tests in Layer 5: ~107 tests across 16 new files**

---

## 8. Layer 6 — Screens

Every screen needs at minimum: (a) renders without crash, (b) key elements visible, (c) primary interaction works. All screen tests use `pumpScreen()` helper with provider overrides.

### 8.1 Auth Screens (7 screens)

#### `test/screens/auth/login_screen_test.dart`
```
testWidgets('renders email and password fields')
testWidgets('renders Google Sign-In button')
testWidgets('renders Register link')
testWidgets('renders Forgot Password link')
testWidgets('empty email shows validation error on submit')
testWidgets('empty password shows validation error on submit')
testWidgets('valid credentials call auth provider signIn')
testWidgets('loading state disables submit button')
testWidgets('error state shows error message')
testWidgets('renders Demo Mode button')
— 10 tests
```

#### `test/screens/auth/register_screen_test.dart`
```
testWidgets('renders all registration fields')
testWidgets('password strength indicator updates on input')
testWidgets('mismatched passwords show error')
testWidgets('submit with valid data calls register')
testWidgets('renders Login link')
— 5 tests
```

#### `test/screens/auth/forgot_password_screen_test.dart`
```
testWidgets('renders email field')
testWidgets('send reset shows success message')
testWidgets('invalid email shows error')
testWidgets('back button returns to login')
— 4 tests
```

#### `test/screens/auth/email_verification_screen_test.dart`
```
testWidgets('renders verification message')
testWidgets('resend button has cooldown timer')
testWidgets('verify button checks verification status')
testWidgets('skip button navigates to shop setup')
— 4 tests
```

#### `test/screens/auth/shop_setup_screen_test.dart`
```
testWidgets('renders shop name, owner name, phone fields')
testWidgets('renders UPI ID field (optional)')
testWidgets('validation: empty shop name blocked')
testWidgets('submit creates user profile in Firestore')
testWidgets('submit navigates to billing screen')
— 5 tests
```

#### `test/screens/auth/desktop_login_screen_test.dart`
```
testWidgets('renders link code display')
testWidgets('renders "Open browser to sign in" instructions')
testWidgets('code refreshes when expired')
— 3 tests
```

#### `test/screens/auth/desktop_login_bridge_test.dart`
```
testWidgets('extracts auth code from URL parameters')
testWidgets('shows success message on valid code')
testWidgets('shows error for expired/invalid code')
— 3 tests
```

### 8.2 Billing/POS Screens (3 screens)

#### `test/screens/billing/billing_screen_test.dart`
```
testWidgets('renders product grid')
testWidgets('renders cart section')
testWidgets('renders search bar')
testWidgets('add product to cart updates cart count')
testWidgets('checkout button opens payment modal')
testWidgets('empty cart disables checkout')
testWidgets('barcode scanner button visible on mobile')
testWidgets('voice search button visible')
— 8 tests
```

#### `test/screens/billing/bills_history_screen_test.dart`
```
testWidgets('renders bill list')
testWidgets('search filters bills by number')
testWidgets('date range filter works')
testWidgets('payment method filter works')
testWidgets('tap on bill shows detail')
testWidgets('empty state shows "No bills found"')
testWidgets('sync indicator shows for pending bills')
— 7 tests
```

#### `test/screens/billing/pos_web_screen_test.dart`
```
testWidgets('renders split layout: products left, cart right')
testWidgets('product grid adapts to screen width')
testWidgets('keyboard shortcut for search focuses search bar')
testWidgets('renders correctly at 1920x1080')
— 4 tests
```

### 8.3 Khata/Products Screens (4 screens)

#### `test/screens/khata/khata_web_screen_test.dart`
```
testWidgets('renders customer list')
testWidgets('search filters customers')
testWidgets('shows total outstanding balance')
testWidgets('tap customer navigates to detail')
testWidgets('add customer button opens modal')
— 5 tests
```

#### `test/screens/khata/customer_detail_screen_test.dart`
```
testWidgets('renders customer name and phone')
testWidgets('renders transaction history list')
testWidgets('Give Credit button opens modal')
testWidgets('Record Payment button opens modal')
testWidgets('balance shows correct amount')
— 5 tests
```

#### `test/screens/products/products_web_screen_test.dart`
```
testWidgets('renders product list/grid')
testWidgets('search filters products')
testWidgets('category filter tabs')
testWidgets('add product button opens modal')
testWidgets('low stock products highlighted')
testWidgets('out of stock products tagged')
— 6 tests
```

#### `test/screens/products/product_detail_screen_test.dart`
```
testWidgets('renders product info (name, price, stock, category)')
testWidgets('edit button toggles edit mode')
testWidgets('stock adjustment +/- buttons work')
testWidgets('save updates product in Firestore')
testWidgets('delete shows confirmation dialog')
— 5 tests
```

### 8.4 Settings Screens (6 screens)

#### `test/screens/settings/settings_web_screen_test.dart`
```
testWidgets('renders settings tabs (General, Billing, Account, Hardware, Theme)')
testWidgets('tab switching works')
testWidgets('renders correct content for each tab')
— 3 tests
```

#### `test/screens/settings/general_settings_screen_test.dart`
```
testWidgets('language selector shows English/Hindi/Telugu')
testWidgets('dark mode toggle works')
testWidgets('data retention period selector')
testWidgets('auto-cleanup toggle')
— 4 tests
```

#### `test/screens/settings/billing_settings_screen_test.dart`
```
testWidgets('receipt footer text field')
testWidgets('tax configuration fields')
testWidgets('default payment method selector')
testWidgets('bill number format settings')
— 4 tests
```

#### `test/screens/settings/account_settings_screen_test.dart`
```
testWidgets('shows shop name and owner name')
testWidgets('edit shop button opens EditShopModal')
testWidgets('change password option visible for email users')
testWidgets('delete account button shows confirmation')
testWidgets('logout button works')
— 5 tests
```

#### `test/screens/settings/hardware_settings_screen_test.dart`
```
testWidgets('renders printer type selector (System/Bluetooth/USB/WiFi)')
testWidgets('paper size selector (58mm/80mm)')
testWidgets('font size selector')
testWidgets('auto-print toggle')
testWidgets('test print button')
testWidgets('Bluetooth scan button visible on Android')
— 6 tests
```

#### `test/screens/settings/theme_settings_screen_test.dart`
```
testWidgets('color picker grid renders')
testWidgets('selecting color updates theme preview')
testWidgets('font scale slider adjusts text size')
testWidgets('dark mode toggle')
testWidgets('reset to defaults button')
— 5 tests
```

### 8.5 Other Screens (4 screens)

#### `test/screens/reports/dashboard_web_screen_test.dart`
```
testWidgets('renders sales chart')
testWidgets('renders today stats cards (total sales, bill count, average)')
testWidgets('date range selector works')
testWidgets('payment method breakdown pie chart')
testWidgets('export button visible')
— 5 tests
```

#### `test/screens/notifications/notifications_screen_test.dart`
```
testWidgets('renders notification list')
testWidgets('unread notifications styled differently')
testWidgets('tap marks as read')
testWidgets('swipe to delete')
testWidgets('Mark All Read button')
testWidgets('empty state shows "No notifications"')
— 6 tests
```

#### `test/screens/subscription/subscription_screen_test.dart`
```
testWidgets('renders plan cards (Free, Pro, Business)')
testWidgets('monthly/annual toggle switches prices')
testWidgets('current plan card shows "Current Plan" badge')
testWidgets('upgrade button enabled for higher plans')
testWidgets('upgrade button disabled for current/lower plans')
testWidgets('shows correct prices for monthly plans')
testWidgets('shows correct prices for annual plans')
testWidgets('on non-web: shows browser redirect icon and note')
testWidgets('on web: upgrade button calls SubscriptionService')
testWidgets('loading state during purchase shows spinner')
testWidgets('error state shows error message')
— 11 tests
```

#### `test/screens/shell/app_shell_test.dart`
```
testWidgets('mobile: renders bottom navigation with 5 items')
testWidgets('mobile: bottom nav items are POS, Khata, Products, Dashboard, Bills')
testWidgets('mobile: tapping nav item navigates to correct route')
testWidgets('mobile: AppBar shows shop name')
testWidgets('mobile: AppBar shows PlanBadge')
testWidgets('mobile: AppBar shows NotificationBell')
testWidgets('mobile: AppBar shows GlobalSyncIndicator')
testWidgets('mobile: profile button opens bottom sheet')
testWidgets('tablet: renders side navigation instead of bottom nav')
testWidgets('tablet: side nav collapses based on screen width')
testWidgets('desktop: delegates to WebShell')
— 11 tests
```

#### `test/screens/shell/web_shell_test.dart`
```
testWidgets('renders sidebar with 5 navigation items')
testWidgets('sidebar items: POS, Khata, Inventory, Dashboard, Bills')
testWidgets('sidebar shows user profile card at bottom')
testWidgets('sidebar shows PlanBadge')
testWidgets('collapse button toggles sidebar width (240px vs 72px)')
testWidgets('collapsed sidebar shows icon-only items with tooltips')
testWidgets('expanded sidebar shows icon + label')
testWidgets('auto-collapse when screen width < 800px')
testWidgets('user override persists collapse state')
testWidgets('notification bell shows unread count')
testWidgets('settings icon in profile card navigates to settings')
— 11 tests
```

### 8.6 Super Admin Screens (12 screens)

#### `test/screens/super_admin/super_admin_login_test.dart`
```
testWidgets('renders email/password fields')
testWidgets('non-admin email shows access denied')
testWidgets('admin email proceeds to dashboard')
— 3 tests
```

#### `test/screens/super_admin/super_admin_dashboard_test.dart`
```
testWidgets('renders stats cards (total users, paid, MRR)')
testWidgets('renders navigation links to sub-pages')
testWidgets('recent users list shows last 5 signups')
— 3 tests
```

#### `test/screens/super_admin/users_list_screen_test.dart`
```
testWidgets('renders user table with columns')
testWidgets('search filters users')
testWidgets('plan filter dropdown works')
testWidgets('pagination loads more users')
testWidgets('tap user navigates to detail')
— 5 tests
```

#### `test/screens/super_admin/user_detail_screen_test.dart`
```
testWidgets('renders user info (shop, email, plan, limits)')
testWidgets('shows subscription details')
testWidgets('shows usage stats (bills, products, customers)')
testWidgets('manage subscription button works')
— 4 tests
```

(Remaining 8 admin screens: 3 tests each = 24 tests)

```
subscriptions_screen_test.dart    — 3 tests: list, filter, stats
analytics_screen_test.dart        — 3 tests: charts render, date range, export
errors_screen_test.dart           — 3 tests: error list, expandable stack trace, group by type
performance_screen_test.dart      — 3 tests: metrics display, thresholds, time range
user_costs_screen_test.dart       — 3 tests: cost table, per-user breakdown, sort
manage_admins_screen_test.dart    — 3 tests: admin list, add email, remove email (not primary)
notifications_admin_test.dart     — 3 tests: compose form, target selector (all/plan/users), send
admin_shell_screen_test.dart      — 3 tests: sidebar nav renders, route switching, active highlight
```

**Total new tests in Layer 6: ~188 tests across 31 new test files**

---

## 9. Layer 7 — Navigation & Routing

#### `test/routing/router_navigation_test.dart` — NEW

```
group('Route paths')
  // Already in routing_test.dart ✅ — keep
  
group('Auth redirect logic')
  test('unauthenticated user on /billing redirects to /login')
  test('authenticated user on /login redirects to /billing')
  test('user without shop setup redirects to /shop-setup')
  test('user with shop setup skips /shop-setup')
  test('super-admin route: admin email can access /super-admin')
  test('super-admin route: non-admin email redirects to /billing')
  test('deep link preserved through auth: /products → login → /products')
  test('pendingRedirect restored on cold start from SharedPrefs')

group('Shell routes')
  test('billing, khata, products, dashboard, bills use AppShell')
  test('customer detail is outside shell (no bottom nav)')
  test('product detail is outside shell')
  test('settings is outside shell')
  test('super-admin routes use AdminShellScreen shell')

group('Route observer')
  test('navigating to /products sets screen context for error handler')
  test('navigating tracks screen view in Firebase Analytics')

group('Error handling')
  test('unknown route shows 404 or redirects to /billing')
  test('route with invalid customer :id handles gracefully')
  test('route with invalid product :id handles gracefully')

— 18 tests
```

---

## 10. Layer 8 — Integration Tests

Cross-module flows testing data integrity across layers. These use real model classes + FakeFirebaseFirestore where applicable.

### 10.1 Existing Integration Tests (8 files — keep)

| Test | Covers |
|------|--------|
| billing_flow_test | Product → Cart → Bill → Summary |
| concurrent_test | Race conditions |
| csv_import_flow_test | CSV file → Products |
| desktop_auth_flow_test | Desktop login bridge |
| khata_flow_test | Credit → Payment → Balance |
| offline_resilience_test | Offline queue → sync |
| product_lifecycle_test | CRUD → stock → delete |
| subscription_enforcement_test | Plan limits enforcement |

### 10.2 New Integration Tests (10 files)

#### `test/integration/subscription_purchase_flow_test.dart`
```
test('free → select pro.monthly → create subscription → mock payment → activate → plan=pro')
test('free → select business.annual → create → pay → activate → plan=business')
test('upgrade: pro → business → limits updated')
test('expired subscription → features locked to free limits')
test('monthly reset: new month resets billsThisMonth to 0')
test('month rollover: Dec→Jan transition on limit reset')
test('leap year Feb 29 → Mar 1 rollover')
test('cancel payment → plan remains unchanged')
test('non-web platform → redirect to web URL (not checkout)')
— 9 tests
```

#### `test/integration/notification_lifecycle_test.dart`
```
test('create notification in Firestore → appears in provider stream')
test('mark as read → unread count decrements')
test('mark all as read → count goes to 0')
test('delete notification → removed from stream')
test('admin sends to all → each user gets notification')
test('admin sends to plan=pro → only pro users receive')
test('admin sends to selected users → only those users receive')
— 7 tests
```

#### `test/integration/referral_flow_test.dart`
```
test('user A generates code → user B enters code → referrerId stored')
test('referral code is unique per user')
test('entering own referral code is rejected')
test('entering invalid code returns error')
test('referral count increments after successful referral')
— 5 tests
```

#### `test/integration/settings_sync_test.dart`
```
test('change theme color → saved to Firestore → reload returns same')
test('change language → saved → reload returns same')
test('change billing settings → receipt reflects changes')
test('printer config survives sign-out + sign-in')
test('clearUserLocalSettings removes user data but keeps printer config')
— 5 tests
```

#### `test/integration/data_export_import_test.dart`
```
test('export products to CSV → import CSV → all products match')
test('export bills to CSV → columns and values correct')
test('export customers → phone numbers properly formatted')
test('import CSV with missing columns → error message')
test('import CSV with duplicate barcodes → handles gracefully')
— 5 tests
```

#### `test/integration/auth_flow_complete_test.dart`
```
test('register → email verification → shop setup → dashboard')
test('login verified user → direct to dashboard')
test('login unverified user → email verification screen')
test('forgot password → reset email dispatched')
test('demo mode login → mock data loaded → billing screen')
— 5 tests
```

#### `test/integration/billing_edge_cases_test.dart`
```
test('bill with 0 items: rejected at model level')
test('bill with negative total: rejected')
test('bill with credit → customer balance updated in khata')
test('bill exceeds free plan limit → blocked with upgrade prompt')
test('partial payment: correct change calculation (₹500 on ₹480 bill = ₹20)')
test('max cart quantity: 9999 per item capped')
test('bill with all payment methods tested (cash, upi, card, credit)')
test('bill number auto-increments correctly')
— 8 tests
```

#### `test/integration/search_across_modules_test.dart`
```
test('search product by name (partial, case-insensitive)')
test('search product by barcode (exact match)')
test('search product by category')
test('search customer by name (Hindi characters)')
test('search customer by phone (partial)')
test('search bill by number')
test('search bill by customer name')
test('search across date ranges')
— 8 tests
```

#### `test/integration/admin_operations_test.dart`
```
test('admin views user list → correct count and data')
test('admin views user detail → subscription and usage shown')
test('admin updates subscription → user limits change')
test('admin resets user limits → billsThisMonth goes to 0')
test('admin adds admin email → appears in admin list')
test('admin removes admin email → removed from list')
test('admin cannot remove primary owner email')
— 7 tests
```

#### `test/integration/demo_mode_test.dart`
```
test('demo mode: 100 products pre-loaded')
test('demo mode: 100 customers pre-loaded')
test('demo mode: 100 bills pre-loaded')
test('demo mode: billing works with mock data')
test('demo mode: no writes to Firestore')
test('exit demo mode: mock data cleared')
— 6 tests
```

**Total new tests in Layer 8: ~65 tests across 10 new files**

---

## 11. Layer 9 — Security Tests

### 11.1 Existing (2 files — keep)

| Test | Covers |
|------|--------|
| admin_protection_test | Admin email protection, stats computation, limits |
| data_isolation_test | UID path isolation, no cross-tenant access |

### 11.2 New Security Tests (5 files)

#### `test/security/input_sanitization_test.dart`
```
test('product name with <script> tag is escaped/rejected')
test('customer name with HTML entities handled safely')
test('bill note with SQL injection pattern treated as plain text')
test('search query with regex special chars does not crash')
test('receipt content with script injection rendered as text')
test('notification body with HTML tags escaped')
test('shop name with emoji characters accepted')
test('shop name with null bytes rejected')
— 8 tests
```

#### `test/security/auth_security_test.dart`
```
test('null userId returns empty data from all providers')
test('empty string userId returns empty data')
test('provider with expired auth state returns loading/error')
test('route guard blocks unauthenticated access to /billing')
test('route guard blocks unauthenticated access to /settings')
test('route guard blocks non-admin from /super-admin')
test('demo mode: no Firestore writes occur (write paths are no-ops)')
— 7 tests
```

#### `test/security/subscription_bypass_test.dart`
```
test('cannot create 51st bill on free plan (model validation)')
test('cannot create product beyond limit (model validation)')
test('expired subscription: plan field = free, limits = free defaults')
test('tampered billsThisMonth < 0: treated as 0')
test('tampered billsLimit = 999999 on free plan: overridden by server limits')
test('plan "admin" or "superuser": treated as free (unrecognized plans)')
— 6 tests
```

#### `test/security/payment_security_test.dart`
```
test('Razorpay checkout amount matches plan price (not client-editable)')
test('SubscriptionResult cannot be forged (immutable constructor)')
test('activateSubscription requires valid payment_id format')
test('webhook signature verification fails for wrong secret')
test('webhook with tampered amount detected by server-side check')
— 5 tests
```

#### `test/security/data_privacy_test.dart`
```
test('data export contains only requesting user data')
test('data export does not include other user IDs')
test('error logs do not contain full phone numbers')
test('error logs do not contain passwords or tokens')
test('CSV export sanitizes PII in customer phone field')
test('receipt service does not leak other customer data')
— 6 tests
```

**Total new tests in Layer 9: ~32 tests across 5 new files**

---

## 12. Layer 10 — Cloud Functions Tests

The 25+ Cloud Functions in `functions/src/index.ts` are currently untested. These need their own test suite in the `functions/` directory using the Firebase Emulator Suite or Jest mocks.

### 12.1 Test Setup

Create `functions/test/` directory with Jest + firebase-functions-test.

```
functions/
├── test/
│   ├── setup.ts                     — Firebase emulator connection, test user seeding
│   ├── payment.test.ts              — Payment & subscription functions
│   ├── auth.test.ts                 — Auth & registration functions
│   ├── limits.test.ts               — Bill/product/customer limit enforcement
│   ├── notifications.test.ts        — Push notification & scheduled functions
│   ├── admin.test.ts                — Admin operations
│   ├── webhook.test.ts              — Razorpay webhook handling
│   ├── referral.test.ts             — Referral code & reward functions
│   ├── cleanup.test.ts              — Scheduled cleanup & backup functions
│   └── reports.test.ts              — Monthly report generation
```

### 12.2 Test Cases by File

#### `functions/test/payment.test.ts`

```
describe('createPaymentLink')
  it('creates payment link with correct amount and description')
  it('returns short_url in response')
  it('rejects unauthenticated request')
  it('rejects missing amount parameter')
  it('rejects negative amount')

describe('createSubscription')
  it('creates Razorpay subscription for pro.monthly plan')
  it('creates Razorpay subscription for business.annual plan')
  it('returns subscriptionId in response')
  it('rejects unauthenticated request')
  it('rejects invalid plan key')

describe('activateSubscription')
  it('verifies payment and updates user subscription to pro')
  it('sets correct limits for pro plan (500 bills)')
  it('sets correct limits for business plan (999999 bills)')
  it('sets correct expiresAt (30 days for monthly, 365 for annual)')
  it('stores subscription-to-user mapping for webhook lookups')
  it('rejects invalid payment_id')
  it('rejects when subscription not found')
— 17 tests
```

#### `functions/test/webhook.test.ts`

```
describe('razorpayWebhook')
  it('validates HMAC-SHA256 signature')
  it('rejects request with invalid signature')
  it('handles payment_link.paid event')
  it('handles subscription.activated event')
  it('handles subscription.charged event — extends expiry')
  it('handles subscription.charged event — resets billsThisMonth')
  it('handles subscription.charged event — sends renewal notification')
  it('handles subscription.halted event — downgrades to free')
  it('handles subscription.cancelled event')
  it('is idempotent: duplicate webhook delivery does not double-process')
  it('returns 200 for already-processed events')
  it('returns 400 for malformed payload')
— 12 tests
```

#### `functions/test/auth.test.ts`

```
describe('sendRegistrationOTP')
  it('sends 6-digit OTP to valid email')
  it('rate limits: rejects second request within 1 minute')
  it('stores hashed email as Firestore key')
  it('sets 10-minute expiry on OTP')
  it('rejects empty email')

describe('verifyRegistrationOTP')
  it('returns success for correct OTP')
  it('returns failure for wrong OTP')
  it('tracks attempt count (max 5)')
  it('rejects after 5 failed attempts')
  it('rejects expired OTP (>10 min)')

describe('generateDesktopToken')
  it('creates custom auth token for valid session')
  it('rejects expired session (>10 min)')
  it('rejects invalid link code')
  it('rejects non-pending session')

describe('exchangeIdToken')
  it('returns custom token for valid ID token')
  it('rejects invalid ID token')

describe('onUserDeleted')
  it('deletes user doc and all 9 subcollections')
  it('handles already-deleted user gracefully')

describe('deleteUserAccount')
  it('deletes all user data, storage files, and auth account')
  it('DPDP: no user data remains after deletion')
— 20 tests
```

#### `functions/test/limits.test.ts`

```
describe('onBillCreated')
  it('increments billsThisMonth transactionally')
  it('does month rollover when lastResetMonth differs')
  it('deletes bill when billsThisMonth >= billsLimit (safety net)')
  it('normal case: bill below limit is kept')

describe('onProductCreated / onProductDeleted')
  it('increments productsCount on create')
  it('deletes product when productsCount >= limit')
  it('decrements productsCount on delete')

describe('onCustomerCreated / onCustomerDeleted')
  it('increments customersCount on create')
  it('deletes customer when customersCount >= limit')
  it('decrements customersCount on delete')

describe('getSubscriptionLimits')
  it('returns authoritative limits from Firestore')
  it('rejects unauthenticated request')
— 12 tests
```

#### `functions/test/notifications.test.ts`

```
describe('sendPushNotification')
  it('sends FCM multicast to user tokens')
  it('removes stale tokens on send failure')
  it('handles user with no tokens gracefully')

describe('onNewUserSignup')
  it('sends welcome notification to new user')
  it('sends admin alert for new signup')

describe('cleanupOldNotifications')
  it('deletes read notifications older than 30 days')
  it('preserves unread notifications')
  it('paginates across >200 users')

describe('sendDailySalesSummary')
  it('aggregates today bills per user')
  it('formats message: "N bill(s) totalling ₹X"')
  it('respects user dailySummary setting')
  it('skips users with 0 bills today')

describe('checkSubscriptionExpiry')
  it('sends -7d warning notification')
  it('sends -3d warning notification')
  it('sends -1d warning notification')
  it('sends 0d expiry notification')
  it('uses deterministic notifId for dedup')
  it('sends bilingual message (Hindi + English)')

describe('checkChurnedUsers')
  it('detects 7-day inactive user')
  it('detects 14-day inactive user')
  it('detects 30-day inactive user')
  it('tracks lastChurnMessageDays to avoid duplicates')

describe('checkLowStock')
  it('sends alert when stock <= lowStockAlert')
  it('distinguishes "Out of Stock" vs "Low Stock"')
  it('respects user lowStockAlerts setting')

describe('sendNotificationToAll / sendNotificationToPlan')
  it('broadcasts to all users, returns recipientCount')
  it('paginates across >200 users with 500 writes/batch')
  it('targets only plan=pro users')
— 27 tests
```

#### `functions/test/referral.test.ts`

```
describe('redeemReferralCode')
  it('stores referrerId on user doc for valid code')
  it('rejects invalid code')
  it('rejects own referral code')
  it('rejects already-referred user')

describe('processReferralReward')
  it('extends referrer subscription by 30 days')
  it('extends referee subscription by 30 days')
  it('sends notification to both users')
  it('is idempotent per referee (no duplicate rewards)')
— 8 tests
```

#### `functions/test/admin.test.ts`

```
describe('seedAdmins')
  it('creates admin entries from ADMIN_EMAILS env var')
  it('skips if admins already exist')
  it('rejects non-admin caller')

describe('seedUserUsage')
  it('bootstraps user_usage collection with cost estimates')
  it('counts bills/products/expenses per user correctly')
— 5 tests
```

#### `functions/test/reports.test.ts`

```
describe('generateMonthlyReport')
  it('aggregates last month bills per user')
  it('writes report doc to users/{id}/reports/{monthKey}')
  it('sends notification with report summary')
  it('uses deterministic reportId for idempotency')
  it('paginates across >200 users')

describe('onSubscriptionWrite')
  it('updates stats: totalUsers increments on new user')
  it('updates stats: proUsers increments on pro subscription')
  it('computes MRR delta correctly')
  it('deduplicates events via _dedup collection')
— 9 tests
```

#### `functions/test/cleanup.test.ts`

```
describe('scheduledFirestoreBackup')
  it('triggers Firestore export to GCS bucket')
  it('logs backup status to _admin/last_backup')
  it('handles export timeout (8 min) gracefully')
— 3 tests
```

**Total new tests in Layer 10: ~113 tests across 10 new test files**

### 12.3 Package.json Update

```json
// Add to functions/package.json:
"devDependencies": {
  "firebase-functions-test": "^3.0.0",
  "jest": "^29.0.0",
  "ts-jest": "^29.0.0",
  "@types/jest": "^29.0.0"
},
"scripts": {
  "test": "jest --detectOpenHandles",
  "test:watch": "jest --watch"
}
```

---

## 13. Layer 11 — Firestore & Storage Rules Tests

Firestore rules are the last line of defense. Currently untested.

### 13.1 Setup

Uses `@firebase/rules-unit-testing` package with Firebase Emulator.

```
test/rules/
├── firestore_rules_test.ts     — All Firestore security rules
└── storage_rules_test.ts       — All Storage security rules
```

### 13.2 Firestore Rules Tests

#### `test/rules/firestore_rules_test.ts`

```
describe('User document /users/{userId}')
  it('authenticated user can read own document')
  it('authenticated user CANNOT read other user document')
  it('admin can read any user document')
  it('authenticated user can write own document')
  it('authenticated user CANNOT write other user document')
  it('document > 500KB is rejected')
  it('unauthenticated user cannot read any user document')

describe('Products /users/{userId}/products/{productId}')
  it('owner can read own products')
  it('owner can create product within limit')
  it('owner CANNOT create product beyond limit (canAddProduct)')
  it('admin can read any user products')
  it('other user CANNOT read products')
  it('name > 200 chars is rejected')
  it('price <= 0 is rejected')
  it('rate limiting: 2 writes within 1s rejected')

describe('Bills /users/{userId}/bills/{billId}')
  it('owner can read own bills')
  it('owner can create bill within limit (canCreateBill)')
  it('owner CANNOT create bill beyond monthly limit')
  it('bill with 0 items is rejected')
  it('bill with > 500 items is rejected')
  it('bill with total <= 0 is rejected')
  it('bill is immutable after creation (no update)')
  it('admin can read any user bills')
  it('other user CANNOT read bills')
  it('monthly limit resets on new month (lastResetMonth)')

describe('Customers /users/{userId}/customers/{customerId}')
  it('owner can read and write own customers')
  it('owner CANNOT create beyond limit (canAddCustomer)')
  it('name > 200 chars is rejected')
  it('other user CANNOT access')

describe('Transactions')
  it('amount > 0 and <= 99,999,999 accepted')
  it('amount <= 0 rejected')
  it('amount > 99,999,999 rejected')
  it('rate limited: 2 writes within 1s rejected')

describe('Expenses')
  it('owner can CRUD own expenses')
  it('amount range validation')
  it('rate limited')

describe('Notifications /users/{userId}/notifications/{notifId}')
  it('owner can read own notifications')
  it('admin can write notifications (from admin panel)')
  it('other user CANNOT access')

describe('Admin collections /_admin, /admin, /admins, /app_config')
  it('admin can read and write')
  it('non-admin CANNOT read or write')
  it('hardcoded primary owner email has admin access even if /admins empty')
  it('removing primary owner from /admins is rejected')

describe('Desktop auth sessions')
  it('unauthenticated user can CREATE session (link code)')
  it('authenticated user can UPDATE session (set token)')
  it('public can READ session (polling)')

describe('App health & errors')
  it('any authenticated user can create app_health doc')
  it('any authenticated user can create error_logs doc')
  it('doc > 10KB is rejected')

describe('Payment links')
  it('admin can read payment_links')
  it('no direct write access (Cloud Functions only)')

describe('Referral rewards')
  it('referrer can read own rewards')
  it('no direct write access (Cloud Functions only)')

describe('User usage')
  it('owner can read own usage')
  it('admin can read any user usage')
— 52 tests
```

### 13.3 Storage Rules Tests

#### `test/rules/storage_rules_test.ts`

```
describe('User storage /users/{userId}/')
  it('owner can upload image < 2MB')
  it('owner CANNOT upload file > 2MB')
  it('owner CANNOT upload non-image (pdf, exe, etc.)')
  it('owner can read own files')
  it('owner CANNOT read other user files')
  it('owner can delete own files')

describe('Downloads /downloads/')
  it('public can read download files (no auth required)')
  it('non-admin CANNOT write to downloads')

describe('Default deny')
  it('unauthenticated user cannot access root')
  it('any other path is denied')
— 10 tests
```

**Total new tests in Layer 11: ~62 tests across 2 new files**

---

## 14. Layer 12 — Performance & Load Tests

### 14.1 Existing

- `test/load/k6-firestore-load.js` — k6 load test (500 VUs, Firestore REST + Cloud Functions)

### 14.2 New Dart Performance Tests

#### `test/load/large_dataset_test.dart`

```
test('10,000 products: search completes < 100ms')
test('50,000 bills: provider builds state < 500ms')
test('5,000 customers: list renders without timeout')
test('MockData.products (100) generates in < 50ms')
test('MockData.bills (100) generates in < 50ms')
— 5 tests
```

#### `test/load/memory_management_test.dart`

```
test('creating 1,000 bills does not leak CartItem objects')
test('filter changes 100 times: provider disposes old listeners')
test('mock data generation is deterministic (seed=42)')
— 3 tests
```

#### `test/load/pagination_test.dart`

```
test('paginated provider: first page loads N items')
test('paginated provider: second page appends without duplicates')
test('paginated provider: rapid page requests do not cause duplication')
test('pagination with concurrent filter change: no stale data')
— 4 tests
```

#### `test/load/startup_test.dart`

```
test('App widget builds without error')
test('ProviderScope init time < 200ms (mock Firebase)')
test('settings provider loads from SharedPrefs < 50ms')
— 3 tests
```

### 14.3 k6 Load Test Extension

```
test/load/k6-subscription-load.js — NEW
  // Test subscription creation under load
  // 50 concurrent subscription creates → all succeed
  // 200 concurrent limit checks → p95 < 500ms
```

**Total new tests in Layer 12: ~16 tests across 5 new files**

---

## 15. Layer 13 — E2E & Manual-Only Tests

### 15.1 Flutter Integration Tests (Real Device / Emulator)

```
integration_test/
├── app_smoke_test.dart
│   test('cold start → splash → login screen renders')
│   test('demo mode login → billing screen with 100 products')
│   test('navigate all 5 bottom tabs')
│   — 3 tests
│
├── billing_e2e_test.dart
│   test('search product → add to cart → checkout → cash → bill created')
│   test('voice search opens speech recognition')
│   — 2 tests
│
├── subscription_e2e_test.dart
│   test('open subscription screen → plan cards visible')
│   test('toggle monthly/annual → prices update')
│   — 2 tests
│
└── offline_e2e_test.dart
    test('airplane mode → create bill → works from offline cache')
    test('reconnect → bill syncs to Firestore')
    — 2 tests
```

### 15.2 Manual-Only Tests (from manual_tests.csv — unchanged)

These cannot be automated. They require real hardware or external services.

| Category | Count | Reason |
|----------|-------|--------|
| Bluetooth/USB printing | 9 tests | Physical printer |
| Barcode scanning | 3 tests | Physical camera + barcode |
| UPI payment flow | 5 tests | Real Android UPI app |
| Multi-device sync | 3 tests | 2 physical devices |
| TalkBack/VoiceOver | 1 test | Real screen reader |
| Firebase Console actions | 5 tests | Manual Remote Config |
| Play Store / Windows Store | 4 tests | Real store submission |
| Performance (30-min soak) | 1 test | Manual observation |

**Total: 31 manual tests documented in manual_tests.csv**

**Total new E2E tests: 9 tests across 4 integration_test files**

---

## 16. Coverage Enforcement & CI

### 16.1 Coverage Thresholds

| Layer | Minimum | Target | Enforcement |
|-------|---------|--------|-------------|
| Models | 98% | 100% | Deploy blocked |
| Utils | 95% | 100% | Deploy blocked |
| Config | 95% | 100% | Deploy blocked |
| Services | 85% | 95% | Deploy warned at 85, blocked at 80 |
| Providers | 85% | 95% | Deploy warned at 85, blocked at 80 |
| Widgets | 75% | 85% | Deploy warned at 75 |
| Screens | 60% | 75% | Deploy warned at 60 |
| Overall | 85% | 95% | Deploy blocked at 85% |

### 16.2 Coverage Script (add to smart-deploy.ps1 after test step)

```powershell
# --- Coverage Check ---
if (-not $skipBuild -and -not $failed -and -not (Is-StepDone "coverage")) {
    Write-Step "Checking test coverage..."
    flutter test --coverage
    if (Test-Path "coverage/lcov.info") {
        $lcov = Get-Content "coverage/lcov.info" -Raw
        $lf = ([regex]::Matches($lcov, "LF:(\d+)") | 
               ForEach-Object { [int]$_.Groups[1].Value } | 
               Measure-Object -Sum).Sum
        $lh = ([regex]::Matches($lcov, "LH:(\d+)") | 
               ForEach-Object { [int]$_.Groups[1].Value } | 
               Measure-Object -Sum).Sum
        $pct = if ($lf -gt 0) { [math]::Round(($lh / $lf) * 100, 1) } else { 0 }
        
        Write-Info "Coverage: $pct% ($lh / $lf lines)"
        Write-DeployLog "COVERAGE | $pct% ($lh/$lf)"
        
        if ($pct -lt 85) {
            Write-Fail "Coverage $pct% is below 85% minimum! Fix before deploying."
            $failed = $true
        } elseif ($pct -lt 90) {
            Write-Warn "Coverage $pct% is below 90% target. Consider adding tests."
        } else {
            Write-Ok "Coverage $pct% meets target"
        }
    } else {
        Write-Warn "No coverage data (lcov.info not found)"
    }
    Complete-Step "coverage"
}
```

### 16.3 Cloud Functions Coverage

```json
// In functions/package.json:
"scripts": {
  "test": "jest --coverage --detectOpenHandles",
  "test:ci": "jest --coverage --ci --coverageReporters=lcov"
}
```

### 16.4 Running All Tests

```bash
# Flutter (Dart) tests — all layers
flutter test --coverage

# Flutter tests by layer
flutter test test/models/
flutter test test/services/
flutter test test/providers/
flutter test test/widgets/
flutter test test/screens/
flutter test test/integration/
flutter test test/security/
flutter test test/routing/
flutter test test/load/

# Cloud Functions tests
cd functions && npm test

# Firestore rules tests (requires emulator)
firebase emulators:exec "npx jest test/rules/"

# k6 load tests
k6 run test/load/k6-firestore-load.js

# Flutter integration tests (real device)
flutter test integration_test/

# Coverage report
genhtml coverage/lcov.info -o coverage/html && start coverage/html/index.html
```

---

## 17. Execution Schedule

### Wave 1 — Foundation & Critical Revenue Path (Days 1-4)

| Day | Task | New Files | Tests |
|-----|------|-----------|-------|
| 1 | Create 4 helper files (mock_services, mock_providers, pump_helpers, fake_firestore_setup) | 4 | 0 |
| 1 | subscription_service_test.dart | 1 | 20 |
| 2 | subscription_provider_test.dart | 1 | 8 |
| 2 | subscription_screen_test.dart | 1 | 11 |
| 2 | subscription_purchase_flow_test.dart (integration) | 1 | 9 |
| 3 | billing_provider_expanded_test.dart | 1 | 28 |
| 3 | printer_provider_test.dart | 1 | 21 |
| 4 | payment_modal_test.dart | 1 | 10 |
| 4 | subscription_bypass_test.dart + payment_security_test.dart | 2 | 11 |
| **Subtotal** | | **13 files** | **118 tests** |

### Wave 2 — Notification System & Admin (Days 5-8)

| Day | Task | New Files | Tests |
|-----|------|-----------|-------|
| 5 | notification_firestore_service_test.dart | 1 | 24 |
| 5 | fcm_token_service_test.dart | 1 | 8 |
| 6 | notification_service_test.dart | 1 | 5 |
| 6 | windows_notification_service_test.dart | 1 | 5 |
| 6 | notification_provider_test.dart | 1 | 9 |
| 6 | notification_bell_test.dart | 1 | 5 |
| 7 | admin_firestore_service_test.dart | 1 | 31 |
| 7 | referral_service_test.dart | 1 | 9 |
| 8 | notification_lifecycle_test.dart + referral_flow_test.dart (integration) | 2 | 12 |
| **Subtotal** | | **10 files** | **108 tests** |

### Wave 3 — Shared Widget Coverage (Days 9-11)

| Day | Task | New Files | Tests |
|-----|------|-----------|-------|
| 9 | plan_badge, announcement_banner, global_sync_indicator | 3 | 19 |
| 9 | logout_dialog, sync_details_sheet | 2 | 9 |
| 10 | nps_survey_dialog, onboarding_checklist | 2 | 15 |
| 10 | update_banner, update_dialog | 2 | 14 |
| 11 | add_product_modal, add_customer_modal, edit_shop_modal | 3 | 21 |
| 11 | khata_modals_test, catalog_browser_modal | 2 | 14 |
| **Subtotal** | | **14 files** | **92 tests** |

### Wave 4 — All Screens (Days 12-18)

| Day | Task | New Files | Tests |
|-----|------|-----------|-------|
| 12 | Auth screens (7 files) | 7 | 34 |
| 13 | Billing/POS screens (3 files) | 3 | 19 |
| 14 | Khata + Products screens (4 files) | 4 | 21 |
| 15 | Settings screens (6 files) | 6 | 27 |
| 16 | Reports + Notifications + Subscription screens (3 files) | 3 | 22 |
| 17 | Shell tests (app_shell, web_shell) | 2 | 22 |
| 18 | Super Admin screens (12 files) | 12 | 39 |
| **Subtotal** | | **37 files** | **184 tests** |

### Wave 5 — Navigation, Integration, Security (Days 19-22)

| Day | Task | New Files | Tests |
|-----|------|-----------|-------|
| 19 | router_navigation_test.dart | 1 | 18 |
| 19 | auth_flow_complete_test.dart | 1 | 5 |
| 20 | billing_edge_cases_test.dart, search_across_modules_test.dart | 2 | 16 |
| 20 | admin_operations_test.dart, demo_mode_test.dart, settings_sync_test.dart | 3 | 18 |
| 21 | data_export_import_test.dart | 1 | 5 |
| 21 | input_sanitization_test.dart, auth_security_test.dart, data_privacy_test.dart | 3 | 21 |
| 22 | Model boundary extensions + platform_utils_test + razorpay config | 3 | 38 |
| **Subtotal** | | **14 files** | **121 tests** |

### Wave 6 — Cloud Functions & Rules (Days 23-28)

| Day | Task | New Files | Tests |
|-----|------|-----------|-------|
| 23 | CF test setup + payment.test.ts + webhook.test.ts | 3 | 29 |
| 24 | auth.test.ts + limits.test.ts | 2 | 32 |
| 25 | notifications.test.ts | 1 | 27 |
| 26 | referral.test.ts + admin.test.ts + reports.test.ts + cleanup.test.ts | 4 | 25 |
| 27 | firestore_rules_test.ts | 1 | 52 |
| 28 | storage_rules_test.ts | 1 | 10 |
| **Subtotal** | | **12 files** | **175 tests** |

### Wave 7 — Performance, E2E, Polish (Days 29-30)

| Day | Task | New Files | Tests |
|-----|------|-----------|-------|
| 29 | large_dataset_test, memory_test, pagination_test, startup_test | 4 | 15 |
| 29 | k6-subscription-load.js | 1 | N/A |
| 30 | integration_test/ E2E (4 files) | 4 | 9 |
| 30 | Coverage enforcement script in smart-deploy.ps1 | 0 | N/A |
| 30 | paginated_collections_provider_test | 1 | 6 |
| **Subtotal** | | **10 files** | **30 tests** |

---

## 18. Final Inventory

### Test Files

| Category | Existing | New | Total |
|----------|----------|-----|-------|
| Helpers | 2 | 4 | 6 |
| Models | 18 | 1 (+8 extended) | 19 |
| Utils | 8 | 1 (+2 extended) | 9 |
| Config | 3 | 1 (+1 extended) | 4 |
| Constants + Design + L10n | 8 | 0 | 8 |
| Core Services | 41 | 3 | 44 |
| Feature Services | 0 | 7 | 7 |
| Providers | 15 | 5 | 20 |
| Shared Widgets | 11 | 9 | 20 |
| Feature Widgets | 5 | 7 | 12 |
| Screens | 0 | 31 | 31 |
| Shell | 0 | 2 | 2 |
| Routing | 1 | 1 | 2 |
| Security | 2 | 5 | 7 |
| Integration | 8 | 10 | 18 |
| Load/Performance | 1 | 5 | 6 |
| E2E (integration_test) | 0 | 4 | 4 |
| **Dart subtotal** | **123** | **95** | **218** |
| Cloud Functions (TS) | 0 | 10 | 10 |
| Firestore/Storage rules | 0 | 2 | 2 |
| **Grand total** | **123** | **107** | **230** |

### Test Count

| Category | Existing | New | Total |
|----------|----------|-----|-------|
| Dart tests (unit + widget + integration) | ~1,200 | ~828 | ~2,028 |
| Cloud Functions tests (Jest) | 0 | ~113 | ~113 |
| Firestore/Storage rules tests | 0 | ~62 | ~62 |
| Flutter E2E (integration_test) | 0 | ~9 | ~9 |
| k6 load scenarios | 6 | ~4 | ~10 |
| Manual tests (manual_tests.csv) | 31 | 0 | 31 |
| **Grand total** | **~1,237** | **~1,016** | **~2,253** |

### Coverage Projection

| Layer | Before | After (projected) |
|-------|--------|--------------------|
| Models | 95% | 100% |
| Utils | 90% | 100% |
| Config | 85% | 100% |
| Services | 70% | 95% |
| Providers | 60% | 95% |
| Widgets | 40% | 85% |
| Screens | 0% | 75% |
| Cloud Functions | 0% | 90% |
| Firestore Rules | 0% | 95% |
| **Overall Dart** | **~55%** | **~93%** |
| **Overall (all layers)** | **~45%** | **~91%** |

---

*This is the final testing plan. 107 new test files. ~1,016 new tests. 30 days of execution. 91%+ projected coverage across Flutter, Cloud Functions, and Firestore rules. Every public method, every screen, every security rule, every scheduled function.*
