# RetailLite — Comprehensive Feature Inventory for Manual Test Cases

*Generated from full codebase exploration of `d:\retaillite\lib`*

---

## Table of Contents

1. [Authentication & Onboarding](#1-authentication--onboarding)
2. [Billing / POS](#2-billing--pos)
3. [Products Management](#3-products-management)
4. [Khata (Credit Book)](#4-khata-credit-book)
5. [Reports & Dashboard](#5-reports--dashboard)
6. [Settings](#6-settings)
7. [Subscription & Payments](#7-subscription--payments)
8. [Notifications](#8-notifications)
9. [Referral System](#9-referral-system)
10. [Super Admin](#10-super-admin)
11. [App Shell & Navigation](#11-app-shell--navigation)
12. [Router & Auth Guards](#12-router--auth-guards)
13. [Core Services](#13-core-services)
14. [Data Models](#14-data-models)
15. [Shared Widgets](#15-shared-widgets)
16. [Platform-Specific Behavior](#16-platform-specific-behavior)

---

## 1. Authentication & Onboarding

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| LoginScreen | `features/auth/screens/login_screen.dart` | Primary login (Google + Email/Password) |
| RegisterScreen | `features/auth/screens/register_screen.dart` | New user registration with email OTP |
| ShopSetupScreen | `features/auth/screens/shop_setup_screen.dart` | First-time shop profile setup |
| ForgotPasswordScreen | `features/auth/screens/forgot_password_screen.dart` | Password reset via email |
| EmailVerificationScreen | `features/auth/screens/email_verification_screen.dart` | OTP-based email verification |
| DesktopLoginScreen | `features/auth/screens/desktop_login_screen.dart` | Windows desktop: shows link code |
| DesktopLoginBridgeScreen | `features/auth/screens/desktop_login_bridge_screen.dart` | Web page for desktop auth bridge |

### Providers
| Provider | File | Purpose |
|----------|------|---------|
| FirebaseAuthNotifier / authProvider | `features/auth/providers/auth_provider.dart` | Full auth state management (~600 lines) |
| PhoneAuthNotifier / phoneAuthProvider | `features/auth/providers/phone_auth_provider.dart` | Phone OTP verification |

### Key Workflows

#### W1.1: Google Sign-In
- **Web**: 3-layer fallback: `signInWithPopup` → `GoogleSignIn` package → `signInWithRedirect`
- **Mobile (Android)**: `GoogleSignIn` package → Firebase credential
- **Windows Desktop**: Opens browser to `/desktop-login?code=XXX`, polls for custom token via Firestore `desktop_auth_sessions`
- **Edge cases**: Account linking when Google email matches existing email/password account → shows linking dialog

#### W1.2: Email/Password Registration
- User enters email → app sends 6-digit OTP via Cloud Function `sendRegistrationOTP`
- User verifies OTP inline → creates Firebase Auth account
- Password field has strength indicator
- 60-second cooldown between OTP sends

#### W1.3: Email/Password Login
- Standard Firebase email/password sign-in
- Windows: auto-expands email form (Google Sign-In less accessible)

#### W1.4: Phone OTP Verification
- E.164 format required
- Android: auto-verification reads SMS automatically
- 60-second resend countdown
- Error handling: invalid-verification-code, session-expired, too-many-requests, credential-already-in-use, provider-already-linked
- **Not available on Windows** (skipped in shop setup)

#### W1.5: Desktop Browser Bridge Auth
- Generates 8-char alphanumeric link code
- Stores in Firestore `desktop_auth_sessions` with 10-minute TTL
- Opens system browser to web app `/desktop-login?code=XXX`
- Desktop app polls Firestore for custom token
- Web bridge page: user logs in, calls `generateDesktopToken` Cloud Function → stores token in session doc→ desktop app receives it

#### W1.6: Account Linking
- When Google sign-in email conflicts with existing email/password account
- Sets `pendingAccountLink` state
- Shows dialog asking user to enter password to link accounts
- Uses `linkWithCredential` on success

#### W1.7: Shop Setup
- Fields: Shop name (required), Owner name (required), Phone (with OTP verification, skipped on Windows), Address (optional), GST number (optional)
- Pre-fills from Firebase Auth profile (displayName, phoneNumber)
- On completion: saves to Firestore, marks `isShopSetupComplete`

#### W1.8: Forgot Password
- Email input → `sendPasswordResetEmail`
- 60-second cooldown between sends
- Success/error feedback

#### W1.9: Demo Mode
- Entry point: button on login screen
- Sets `isDemoMode = true` in AuthState
- `DemoDataService` loads hardcoded in-memory data (products, customers, bills, transactions, expenses)
- Data persists only during session — lost on restart or exit
- All CRUD operations work against in-memory lists

### Business Rules & Validation
- New user Firestore doc gets default free plan limits: 100 products, 50 bills/month, 10 customers
- `_loadUserProfile()` backfills missing limit fields for existing users
- Auth state includes 5s/10s safety timeouts to prevent indefinite loading
- `authStateChanges` listener auto-refreshes on Firebase Auth state changes
- Web: `getRedirectResult()` called on init for redirect sign-in flow

### Integration Points
- Firebase Auth (email/password, Google, Phone)
- Firebase Cloud Functions: `generateDesktopToken`, `sendRegistrationOTP`, `verifyRegistrationOTP`
- Firestore: `users` collection, `desktop_auth_sessions`
- Google Sign-In package
- SharedPreferences (route persistence)
- FCM token initialization on login
- Notification service initialization on login

---

## 2. Billing / POS

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| BillingScreen | `features/billing/screens/billing_screen.dart` | Main POS screen (~500 lines) |
| PaymentModal | `features/billing/widgets/payment_modal.dart` | Payment method selection & checkout (~400 lines) |
| PosWebScreen | (referenced) | Desktop/web POS layout |

### Providers
| Provider | File | Purpose |
|----------|------|---------|
| CartNotifier / cartProvider | `features/billing/providers/cart_provider.dart` | Cart state (items, customer, totals) |
| BillingProvider | `features/billing/providers/billing_provider.dart` | Bills list with filters, search, sync status |
| BillingService | `features/billing/services/billing_service.dart` | Bill creation, bill numbering, Firestore persistence |

### Key Workflows

#### W2.1: Add Products to Cart
- Tap product → adds to cart (increments quantity if already present)
- Max quantity per item: 9999
- Cart tracks: items, customerId, customerName
- Computed: total, itemCount
- Actions: increment, decrement, updateQuantity, removeItem, clearCart

#### W2.2: Barcode Scanning in POS
- Tap barcode icon → opens `BarcodeScannerService` (camera-based modal using `mobile_scanner`)
- Scanned code → search products by barcode
- If found: add to cart immediately
- If not found: offer to create new product with barcode pre-filled
- **Android only** (camera required)

#### W2.3: Payment Flow
- Cart → tap Checkout → PaymentModal opens
- **Cash**: Simple completion
- **UPI**: Simple completion (no in-app verification)
- **Udhar (Credit)**: Select customer → enter credit amount (≤ cart total) → `saveBillWithUdharAtomic` (updates customer balance + saves transaction atomically)

#### W2.4: Bill Creation
- `BillingService.createAndSaveBill()`:
  - Generates unique bill ID
  - Gets next sequential bill number
  - Saves to Firestore (local first for offline)
  - For Udhar: atomic update of customer balance + transaction record
- Tracks bill via `UserMetricsService.trackBillCreated()`
- Bill limit check: if monthly limit reached → shows `UpgradePromptModal`
- Permission-denied Firestore errors interpreted as subscription limit → upgrade prompt

#### W2.5: Post-Bill Actions
- Post-bill dialog offers: Print Receipt, Share (WhatsApp/SMS/PDF), New Bill
- Auto-print: if enabled in settings, automatically prints to connected printer
- In-app review: prompted after 3rd bill (via `in_app_review` package)

#### W2.6: Bills List & Filtering
- `BillsFilter`: searchQuery, dateRange, paymentMethod, recordType (all/bills/expenses), pagination
- Real-time streams from Firestore with filtering
- Per-document sync status tracking (pending writes indicator)

### Responsive Layouts
- **Mobile** (<768px): Product grid + bottom cart bar → swipe-up cart sheet
- **Tablet** (≥768px): Side-by-side products + cart panel
- **Desktop**: `PosWebScreen` (dedicated desktop layout)

### Business Rules
- Bill number is sequential per user
- Cart quantity capped at 9999
- Udhar amount must be ≤ cart total
- Monthly bill limit enforced per subscription plan (Free: 50, Pro: 500, Business: unlimited)
- `receivedAmount` tracked for cash payments (change calculation)
- Date stored as "YYYY-MM-DD" string for efficient querying

### Edge Cases
- Offline bill creation: saves locally, syncs when online (sync status badge)
- Cart survives navigation within app
- Empty cart → checkout button disabled
- Barcode scan on unknown code → create product flow
- NPS survey check on billing screen init (shows after 7+ day old account, not surveyed in 90 days)
- Onboarding checklist overlay on desktop/tablet for new users

### Integration Points
- Firestore: `users/{uid}/bills`, `users/{uid}/expenses`
- BarcodeScannerService (mobile_scanner)
- BarcodeLookupService (external API)
- ThermalPrinterService / ReceiptService (printing)
- BillShareService (WhatsApp, SMS, PDF)
- UserMetricsService (bill count tracking)
- in_app_review (Android)

---

## 3. Products Management

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| ProductsScreen | (in products features) | Product list with search |
| ProductDetailScreen | `features/products/screens/product_detail_screen.dart` | Full product view (~500 lines) |
| AddProductModal | `features/products/widgets/add_product_modal.dart` | Create/edit product (~300 lines) |
| CatalogBrowserModal | `features/products/widgets/catalog_browser_modal.dart` | Pre-built catalog browser (~300 lines) |

### Providers
| Provider | File | Purpose |
|----------|------|---------|
| productsProvider | `features/products/providers/products_provider.dart` | Real-time products stream (~500 lines) |
| productByIdProvider | same | Single product stream (avoids full collection watch) |
| lowStockProductsProvider | same | Filtered: isLowStock or isOutOfStock |
| ProductsService | same | CRUD operations |

### Key Workflows

#### W3.1: Add Product
- Fields: name (required), selling price (required), purchase/cost price (optional), stock, low stock alert threshold, unit (ProductUnit enum), barcode, category, image URL
- Barcode scan button → camera scan → `BarcodeLookupService` auto-fills product name from external API
- Image upload via `ImageService` → Firebase Storage
- Product limit check before add (`UserMetricsService.trackProductAdded`) → `UpgradePromptModal` if limit reached
- Saves to Firestore

#### W3.2: Edit Product
- Opens `AddProductModal` in edit mode
- Pre-fills all fields
- Shows delete button
- Updates Firestore document

#### W3.3: Delete Product
- Confirmation dialog with warning: "This product may appear in existing bills"
- Deletes from Firestore

#### W3.4: Stock Adjustment
- From product detail: Adjust Stock button
- Dialog: add or remove stock
- Atomic operation: `FieldValue.increment` for safe concurrent updates

#### W3.5: Bulk Add from Catalog
- `CatalogBrowserModal`: Pre-built product catalog
- Categories: kirana, grocery, dairy, snacks, personal care, cleaning supplies
- Multi-select products → `addProductsBatch` (WriteBatch, 490 items per batch)
- Product limit check with remaining count validation before batch add

#### W3.6: CSV Import
- Via `ProductCsvService` (listed in core services)
- Batch import flow

### Data Model: ProductModel
- Fields: id, name, price, purchasePrice?, stock, lowStockAlert?, barcode?, imageUrl?, category?, unit (ProductUnit enum), createdAt, updatedAt?
- ProductUnit: piece, kg, gram, liter, ml, pack, box, dozen, unknown
- Computed: `isLowStock` (stock ≤ lowStockAlert), `isOutOfStock` (stock ≤ 0), `profit` (price - purchasePrice), `profitPercentage`

### Business Rules
- Product limit per plan: Free=100, Pro=1000, Business=unlimited
- Products stream ordered by name, limit 2000 documents
- Stock decrement uses `FieldValue.increment(-qty)` for atomic updates
- Batch write limit: 490 per batch (Firestore limit is 500, leaves margin)
- Barcode lookup: scans physical barcode, queries external API, auto-fills name

### Edge Cases
- Duplicate barcode handling
- Product with 0 stock still visible but marked "Out of Stock"
- Low stock alert threshold respected in dashboard notifications
- Image upload failure → product saves without image
- Catalog browser: search across all categories

### Integration Points
- Firestore: `users/{uid}/products`
- Firebase Storage (product images)
- mobile_scanner (barcode scanning)
- BarcodeLookupService (external API)
- UserMetricsService (product count tracking)
- ImageService (image upload/compression)

---

## 4. Khata (Credit Book)

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| KhataScreen | (in khata features) | Customer list with stats |
| CustomerDetailScreen | `features/khata/screens/customer_detail_screen.dart` | Customer view + transactions (~400 lines) |
| AddCustomerModal | `features/khata/widgets/add_customer_modal.dart` | Create/edit customer |
| GiveUdhaarModal | `features/khata/widgets/give_udhaar_modal.dart` | Give credit to customer |
| RecordPaymentModal | `features/khata/widgets/record_payment_modal.dart` | Record payment from customer |

### Providers
| Provider | File | Purpose |
|----------|------|---------|
| customersProvider | `features/khata/providers/khata_provider.dart` | Real-time customers stream |
| customerProvider | same | Per-customer stream |
| customerTransactionsProvider | same | Per-customer transactions stream |
| KhataService | same | CRUD + payment/credit operations |
| KhataStats | `features/khata/providers/khata_stats_provider.dart` | Aggregate stats |
| sortedCustomersProvider | same | Sorted list with 4 sort options |

### Key Workflows

#### W4.1: Add Customer
- Fields: name (required), phone (required), address (optional), opening balance
- "Customer owes me (Udhar)" checkbox for opening balance direction
- Duplicate phone number check (skipped in edit mode if phone unchanged)
- Customer limit check per subscription plan

#### W4.2: Edit Customer
- All fields editable except balance (forced through transactions for audit trail)
- Duplicate phone check skipped if phone unchanged

#### W4.3: Record Payment
- Payment modes: Cash, Online (Razorpay)
- Amount validation: must be > 0 and ≤ customer's current balance
- Quick amount chips: ₹100, ₹500, ₹1000, ₹2000
- Note/reason field
- **Cash**: Atomic Firestore write (`recordPaymentAtomic`) — updates balance + creates transaction
- **Online (Razorpay)**: `RazorpayService.checkout()` → 3 retries for Firestore sync → handles "payment taken but not synced" edge case with user guidance

#### W4.4: Give Udhaar (Credit)
- Amount input with quick chips
- Note/reason field
- New balance preview shown
- **Large credit confirmation**: amounts ≥ ₹10,000 trigger confirmation dialog
- Atomic write: `addCreditAtomic` (balance + transaction)

#### W4.5: Delete Customer
- Confirmation dialog
- Deletes customer document from Firestore

### Data Model: CustomerModel
- Fields: id, name, phone, address?, balance (positive = customer owes), createdAt, updatedAt?, lastTransactionAt?
- Computed: `hasDue` (balance > 0), `daysSinceLastTransaction`, `isOverdue` (> 30 days default), `isOverdueAfter(days)`

### Stats Dashboard
- `KhataStats`: totalOutstanding, collectedToday, activeCustomers, customersWithDue
- Sort options: highestDebt, recentlyActive, alphabetical, oldestDue
- `selectedCustomerIdProvider` for master-detail view

### Business Rules
- Customer limit per plan: Free=10, Pro=100, Business=unlimited
- Balance is always positive (represents amount owed TO the shop)
- Payment cannot exceed current balance
- Opening balance can be set on creation (bypasses transaction flow)
- Edit mode: balance field read-only to enforce transaction trail
- Overdue threshold: 30 days since last transaction

### Edge Cases
- Razorpay payment succeeds but Firestore sync fails → 3 retries → shows critical error with guidance if all fail
- Customer with 0 balance → Record Payment disabled
- Large credit (≥₹10K) requires explicit confirmation
- Duplicate phone check on add (not edit if unchanged)
- Transaction history capped at 50 visible items in UI
- Customer detail header: gradient red if due, green if fully paid

### Responsive Layout
- Mobile: fixed header + scrollable transaction list
- Desktop: scrollable full page

### Integration Points
- Firestore: `users/{uid}/customers`, `users/{uid}/customers/{cid}/transactions`
- RazorpayService (online payments)
- Atomic Firestore writes (batch/transaction)

---

## 5. Reports & Dashboard

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| DashboardWebScreen | `features/reports/screens/dashboard_web_screen.dart` | Reports dashboard (~500 lines) |

### Providers
| Provider | File | Purpose |
|----------|------|---------|
| ReportPeriod providers | `features/reports/providers/reports_provider.dart` | Period management (~400 lines) |
| salesSummaryProvider | same | Aggregated sales data |
| topProductsProvider | same | Top 10 products by quantity |
| dashboardBillsProvider | same | Last 7 days bills |

### Key Workflows

#### W5.1: View Sales Summary
- Period options: Today, This Week, This Month, Custom date range
- Previous/Next period navigation with date range label
- Metrics: totalSales, billCount, cash/upi/udhar amounts, avgBillValue, totalExpenses, COGS-based grossProfit
- Performance monitoring: warns in debug if aggregation takes > 100ms

#### W5.2: Top Products
- Aggregates product sales from bills across selected period
- Returns top 10 by quantity sold

#### W5.3: Export Report as PDF
- Uses `pdf` + `printing` packages
- Generates PDF with sales summary for selected period

#### W5.4: Share Report
- `Share.share()` with formatted text summary
- Includes period, total sales, bill count, payment breakdown

#### W5.5: Custom Date Range
- Date range picker for custom period selection
- Period offset navigation (prev/next) works for all period types

### Business Rules
- Gross profit = totalSales - COGS (cost of goods sold from purchasePrice)
- Average bill value = totalSales / billCount
- Expenses tracked separately from sales
- Period navigation wraps correctly (e.g., prev month from January → December)

### Responsive Layout
- Mobile: stacked cards
- Desktop: single row of metric cards

### Integration Points
- Firestore: `users/{uid}/bills`, `users/{uid}/expenses` (stream-based)
- pdf package (PDF generation)
- printing package (print dialog)
- share_plus (native share)

---

## 6. Settings

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| GeneralSettingsScreen | `features/settings/screens/general_settings_screen.dart` | Shop profile, business, theme, language |
| BillingSettingsScreen | `features/settings/screens/billing_settings_screen.dart` | Invoice, tax, UPI |
| HardwareSettingsScreen | `features/settings/screens/hardware_settings_screen.dart` | Printer, barcode, sync, offline |
| AccountSettingsScreen | `features/settings/screens/account_settings_screen.dart` | Profile, linked accounts, subscription, referral |
| ThemeSettingsScreen | `features/settings/screens/theme_settings_screen.dart` | Dedicated theme customization |

### Providers
| Provider | File | Purpose |
|----------|------|---------|
| SettingsNotifier / settingsProvider | `features/settings/providers/settings_provider.dart` | App settings (~500 lines) |
| PrinterNotifier / printerProvider | same | Printer state & connection |

### Sub-Feature: General Settings
- **Shop Profile**: Shop name, owner name, contact number, address
- **Business Details**: GST number, currency (INR/USD/EUR), timezone
- **Theme Customization**: Accent color presets, font family, text size slider, system theme/dark mode
- **Language**: English, Hindi (हिंदी), Telugu (తెలుగు)

### Sub-Feature: Billing Settings
- **Invoice Header**: Logo upload (Firebase Storage), invoice title
- **Tax Settings**: GST enabled toggle, tax rate, inclusive/exclusive toggle
- **UPI Settings**: UPI ID input with validation, QR code display, test payment button
- **Business UPI Guide**: Setup instructions for PhonePe, GPay, BharatPe

### Sub-Feature: Hardware Settings
- **Printer Type**: System (OS dialog), Bluetooth (ESC/POS), WiFi (IP:Port), USB (Windows)
- **Bluetooth**: Scan for devices → connect → test print
- **WiFi**: Enter IP address and port (default 9100)
- **USB**: Windows printer list → select → test
- **Paper Size**: 58mm (32 chars/line) or 80mm (48 chars/line)
- **Font Size**: Small, Normal, Large
- **Custom Width**: Override chars per line
- **Auto-Print**: Toggle for automatic printing after bill creation
- **Receipt Footer**: Custom footer text (default: "Thank you for shopping!")
- **Test Print**: Prints test receipt on connected printer
- **Barcode Settings**: Prefix/suffix configuration
- **Sync Settings**: Sync interval, offline mode toggle
- **Voice Input**: Toggle
- **App Version**: Display

### Sub-Feature: Account Settings
- **Profile Image**: Upload to Firebase Storage
- **Email**: Read-only display
- **Phone**: Display with verified badge
- **Linked Accounts**: Show linked auth providers
- **Subscription**: Current plan status + upgrade button
- **Referral**: Referral code display + share button
- **Data Export**: Export business data
- **Delete Account**: Account deletion flow

### Sub-Feature: Theme Settings
- Theme mode: System, Dark
- Primary color presets (palette selection)
- Font family selection
- Font size scale: 0.85 to 1.15 (slider)
- Live preview of changes

### Settings State Management
- `AppSettings`: isDarkMode, locale, languageCode, retentionDays, autoCleanupEnabled
- Loads sync from SharedPreferences first (immediate, no flash), then async from Firestore cloud settings
- Settings synced bidirectionally: local ↔ cloud

### Business Rules
- Tax rate default: 5% GST
- UPI ID validation regex
- Receipt footer default: "Thank you for shopping!"
- Language default: Hindi (`hi`)
- Currency default: INR
- Font scale range: 0.85-1.15

### Integration Points
- Firestore: `users/{uid}` (settings field), Firebase Storage (logo, profile image)
- SharedPreferences (local settings cache)
- print_bluetooth_thermal (Bluetooth printer)
- printing package (system printer)
- ThermalPrinterService (all printer types)
- ImageService (image upload)

---

## 7. Subscription & Payments

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| SubscriptionScreen | `features/subscription/screens/subscription_screen.dart` | Plan comparison & upgrade (~300 lines) |

### Providers & Services
| Component | File | Purpose |
|-----------|------|---------|
| subscriptionPlanProvider | `features/subscription/providers/subscription_provider.dart` | Real-time plan stream |
| SubscriptionService | `features/subscription/services/subscription_service.dart` | Razorpay subscription flow (~300 lines) |

### Plans
| Plan | Monthly | Annual | Bills/Month | Products | Customers |
|------|---------|--------|-------------|----------|-----------|
| Free | ₹0 | ₹0 | 50 | 100 | 10 |
| Pro | ₹10 | ₹20/year | 500 | 1,000 | 100 |
| Business | ₹20 | ₹30/year | Unlimited | Unlimited | Unlimited |

### Key Workflows

#### W7.1: View Plans
- Plan cards with feature comparison
- Monthly/Annual toggle with "Save ~17%" badge
- Current plan highlighted with expiry date
- Upgrade button per plan

#### W7.2: Upgrade Subscription (Razorpay)
1. User selects plan + billing cycle
2. Cloud Function `createSubscription` creates Razorpay subscription
3. App opens Razorpay checkout
4. On success: Cloud Function `activateSubscription` verifies payment server-side
5. Firestore user doc updated with new plan + limits + expiry

#### W7.3: Upgrade Prompt
- Triggered automatically when user hits: product limit, bill limit, customer limit, or feature gate
- `UpgradePromptModal.show(context, trigger: UpgradeTrigger.xxx)`
- "Later" dismisses, "View Plans" navigates to `/subscription`

### Business Rules
- Plan stored in Firestore user doc as string: "free"/"pro"/"business"
- Real-time stream updates UI immediately on plan change
- Non-web platforms (Android/Windows): message says "redirected to web app to complete payment"
- Google Play compliance: Android should use IAP; web uses Razorpay
- Subscription expires → limits revert to free plan

### Edge Cases
- Payment succeeds in Razorpay but `activateSubscription` Cloud Function fails → critical state with explicit user guidance
- `SubscriptionResult`: success/failure/cancelled states with plan, cycle, expiresAt, error details
- Firestore permission-denied errors during bill/product/customer creation → interpreted as subscription limit → upgrade prompt

### Integration Points
- Razorpay payment gateway
- Firebase Cloud Functions: `createSubscription`, `activateSubscription`
- Firestore: `users/{uid}` (plan, limits, expiry)

---

## 8. Notifications

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| NotificationsScreen | `features/notifications/screens/notifications_screen.dart` | Notification inbox |

### Providers & Services
| Component | File | Purpose |
|-----------|------|---------|
| notificationsStreamProvider | `features/notifications/providers/notification_provider.dart` | Real-time notification stream |
| unreadNotificationCountProvider | same | Unread count for badge |
| NotificationService | `features/notifications/services/notification_service.dart` | FCM handling |
| FcmTokenService | `features/notifications/services/fcm_token_service.dart` | FCM token management |
| NotificationFirestoreService | `features/notifications/services/notification_firestore_service.dart` | Firestore CRUD |
| WindowsNotificationService | `features/notifications/services/windows_notification_service.dart` | Windows polling fallback |
| NotificationBell | `features/notifications/widgets/notification_bell.dart` | App bar bell icon with badge |

### Key Workflows

#### W8.1: Receive Push Notification
- **Android**: FCM foreground handler shows in-app notification; background handler via `@pragma('vm:entry-point')` top-level function
- **Web**: FCM with foreground display (alert, badge, sound)
- **Windows**: No FCM support → custom polling-based `WindowsNotificationService`

#### W8.2: Notification Inbox
- List with read/unread styling (blue dot for unread)
- Types: announcement (campaign icon), alert (warning), reminder (alarm), system (info)
- Tap: marks as read + navigates to deep-link route if notification data contains one
- Swipe to delete (Dismissible widget)
- "Mark all read" button in header
- Time ago formatting for timestamps

#### W8.3: FCM Token Management
- Token stored in Firestore for targeting
- Auto-refresh on token change

### Business Rules
- Notification types map to different icons
- Deep-link routing: notification can carry route data → tapping navigates to that screen
- Windows uses polling instead of push (no FCM support)

### Integration Points
- Firebase Cloud Messaging (Android, Web)
- Firestore: `users/{uid}/notifications`
- go_router (deep-link navigation)

---

## 9. Referral System

### Service
| Component | File | Purpose |
|-----------|------|---------|
| ReferralService | `features/referral/services/referral_service.dart` | Code generation, sharing, tracking |

### Key Workflows

#### W9.1: Get/Create Referral Code
- Format: `XXXX0000` (4 chars from UID + 4 random digits)
- Created once, cached in Firestore

#### W9.2: Share Referral Code
- Mobile: Native share dialog (`Share.share()`)
- Web: Copy to clipboard

#### W9.3: Track Referrals
- Counts entries in `referral_rewards` collection
- Displayed in Account Settings

### Integration Points
- Firestore: `users/{uid}` (referral code), `referral_rewards` collection
- share_plus (native share)
- Clipboard (web)

---

## 10. Super Admin

### Screens
| Screen | File | Purpose |
|--------|------|---------|
| SuperAdminDashboardScreen | `features/super_admin/screens/super_admin_dashboard_screen.dart` | Admin overview |
| AdminShellScreen | (referenced) | Admin navigation shell |
| UsersListScreen | (referenced) | All users with search & filter |
| UserDetailScreen | (referenced) | Individual user details |
| AnalyticsScreen | (referenced) | Usage analytics |
| ErrorsScreen | (referenced) | Error log viewer |
| PerformanceScreen | (referenced) | Performance metrics |
| SubscriptionsScreen | (referenced) | Subscription management |
| ManageAdminsScreen | (referenced) | Admin email management |
| NotificationsAdminScreen | (referenced) | Send notifications to users |
| CostsScreen | (referenced) | Business costs tracking |
| UserCostsScreen | (referenced) | Per-user cost analysis |
| SuperAdminLoginScreen | (referenced) | Admin-specific login |

### Providers
| Provider | File | Purpose |
|----------|------|---------|
| isSuperAdminProvider | `features/super_admin/providers/super_admin_provider.dart` | Access control |
| adminStatsProvider | same | Dashboard metrics |
| allUsersProvider | same | Paginated user list with filters |
| recentUsersProvider | same | Recent signups |
| expiringSubscriptionsProvider | same | Subscriptions near expiry |
| platformStatsProvider | same | Per-platform stats |
| featureUsageProvider | same | Feature usage analytics |

### Key Features

#### Access Control
- 7 hardcoded super admin emails (primary check)
- Firestore `admin_list` document (secondary check)
- `isPrimaryOwnerProvider` for highest-level access
- Non-admins see "Access Denied" screen

#### Dashboard Stats Grid
- Total Users, Active Today, MRR (Monthly Recurring Revenue), Paid Users, New This Week, Conversion Rate %
- Responsive grid: 2/3/6 columns based on screen width
- Recent users list with plan badges
- Subscription breakdown card
- Notifications card

#### User Management
- Paginated user list with search
- Filter by subscription plan
- User detail view

#### Actions
- Recalculate stats
- Refresh data
- Send broadcast notifications

### Routes (13 admin routes)
- `/super-admin`, `/super-admin/analytics`, `/super-admin/users`, `/super-admin/user/:id`, `/super-admin/subscriptions`, `/super-admin/errors`, `/super-admin/performance`, `/super-admin/manage-admins`, `/super-admin/notifications`, `/super-admin/costs`, `/super-admin/user-costs`, `/super-admin/login`

### Integration Points
- Firestore: all user documents, admin config
- Firebase Cloud Functions (notification broadcasting)

---

## 11. App Shell & Navigation

### Components
| Component | File | Purpose |
|-----------|------|---------|
| AppShell | `features/shell/app_shell.dart` | Main app container with responsive nav |
| WebShell | `features/shell/web_shell.dart` | Desktop/web sidebar layout |

### Mobile Layout (AppShell)
- AppBar: shop logo, shop name, PlanBadge, GlobalSyncIndicator, NotificationBell, profile avatar
- Bottom navigation: Billing, Khata, Products, Dashboard, Bills (5 tabs)
- Profile sheet: user info, settings link, help link, logout
- Demo mode banner + offline banner at top

### Tablet Layout (AppShell)
- Side navigation rail (no bottom nav)
- Main content area with child
- Same banners at top

### Desktop/Web Layout (WebShell)
- Collapsible sidebar with: shop logo/name, navigation items, settings, profile
- Auto-collapse at <800px width, user toggle available
- Sidebar items: same 5 tabs + Settings + Profile
- Main content area with optional header (hidden for screens with own headers)
- Demo mode banner + offline banner at top

### Navigation Items
| Index | Route | Label |
|-------|-------|-------|
| 0 | /billing | Billing |
| 1 | /khata | Khata |
| 2 | /products | Products |
| 3 | /dashboard | Dashboard |
| 4 | /bills | Bills |
| 5 | /settings | Settings |

### Integration Points
- go_router (GoRouterState for current location)
- Riverpod (auth state, user data)
- SharedPreferences (sidebar collapse state is in-memory StateProvider)

---

## 12. Router & Auth Guards

### File
`router/app_router.dart` (~400+ lines)

### Routes
| Route | Screen | Auth Required | Notes |
|-------|--------|---------------|-------|
| `/loading` | Loading Screen | No | Shown during auth init |
| `/login` | LoginScreen | No | |
| `/register` | RegisterScreen | No | |
| `/forgot-password` | ForgotPasswordScreen | No | |
| `/shop-setup` | ShopSetupScreen | Yes | Pre-setup only |
| `/billing` | BillingScreen | Yes | Default route, ShellRoute |
| `/khata` | KhataScreen | Yes | ShellRoute |
| `/products` | ProductsScreen | Yes | ShellRoute |
| `/dashboard` | DashboardScreen | Yes | ShellRoute |
| `/bills` | BillsScreen | Yes | ShellRoute |
| `/settings/:tab` | SettingsScreen | Yes | Tab parameter |
| `/customer/:id` | CustomerDetailScreen | Yes | |
| `/product/:id` | ProductDetailScreen | Yes | |
| `/subscription` | SubscriptionScreen | Yes | |
| `/notifications` | NotificationsScreen | Yes | |
| `/desktop-login` | DesktopLoginBridgeScreen | No | Web only |
| `/super-admin/*` | Admin screens | Yes + Admin | 11+ sub-routes |

### Auth Redirect Logic
1. `isLoading` → redirect to `/loading`
2. `!isLoggedIn` → redirect to `/login`
3. `isLoggedIn && !isShopSetupComplete` → redirect to `/shop-setup`
4. Super admin routes: restricted by email list check

### Route Persistence
- Saves last visited route to SharedPreferences
- Restores on app reload/restart
- ShellRoute wraps main app tabs

---

## 13. Core Services

### Service Inventory (33 files in `core/services/`)

| Service | File | Purpose |
|---------|------|---------|
| ConnectivityService | `connectivity_service.dart` | Network status monitoring (connectivity_plus) |
| OfflineStorageService | `offline_storage_service.dart` | Local data persistence |
| SyncStatusService | `sync_status_service.dart` | Per-document pending writes tracking |
| SyncSettingsService | `sync_settings_service.dart` | Sync interval configuration |
| ErrorLoggingService | `error_logging_service.dart` | Error capture with severity levels |
| ThermalPrinterService | `thermal_printer_service.dart` | ESC/POS printing (Bluetooth, WiFi, USB) |
| PrintHelper | `print_helper.dart` | Print utility functions |
| ReceiptService | `receipt_service.dart` | Receipt formatting + system printer (pdf/printing) |
| BarcodeScannerService | `barcode_scanner_service.dart` | Camera-based barcode scanning (mobile_scanner) |
| BarcodeLookupService | `barcode_lookup_service.dart` | External barcode → product info API |
| RazorpayService | `razorpay_service.dart` | Razorpay checkout flow |
| PaymentLinkService | `payment_link_service.dart` | UPI payment link generation |
| ImageService | `image_service.dart` | Image upload/compression (Firebase Storage) |
| ProductCatalogService | `product_catalog_service.dart` | Pre-built product catalog data |
| ProductCsvService | `product_csv_service.dart` | CSV import/export for products |
| DataExportService | `data_export_service.dart` | Export bills to CSV/JSON with date ranges |
| DemoDataService | `demo_data_service.dart` | In-memory demo data (products, customers, bills, expenses) |
| AnalyticsService | `analytics_service.dart` | Firebase Analytics events |
| AndroidUpdateService | `android_update_service.dart` | In-app update (Play Store) |
| WindowsUpdateService | `windows_update_service.dart` | Windows update mechanism |
| PrivacyConsentService | `privacy_consent_service.dart` | Privacy/consent management |
| UserMetricsService | `user_metrics_service.dart` | Track product/bill/customer counts vs limits |
| UserUsageService | `user_usage_service.dart` | Usage tracking |
| UsageTrackingService | `usage_tracking_service.dart` | Feature usage analytics |
| SchemaMigrationService | `schema_migration_service.dart` | Firestore schema versioning/migration |
| ConflictResolutionService | `conflict_resolution_service.dart` | Multi-device conflict handling |
| WriteRetryQueue | `write_retry_queue.dart` | Failed write retry queue |
| PerformanceService | `performance_service.dart` | Firebase Performance monitoring |
| AppHealthService | `app_health_service.dart` | App health checks |
| DataRetentionService | `data_retention_service.dart` | Auto-cleanup of old data |
| WebPersistence | `web_persistence.dart` | Web-specific storage |
| WebPersistenceStub | `web_persistence_stub.dart` | Stub for non-web platforms |
| ThrottleService | `throttle_service.dart` | Rate limiting for operations |

### Key Service Details

#### ThermalPrinterService
- **Bluetooth**: `print_bluetooth_thermal` plugin → ESC/POS commands
- **WiFi**: TCP Socket to port 9100 → ESC/POS commands
- **USB**: Windows RAW printing / Process command
- **System**: `printing` package via ReceiptService (OS print dialog)
- ESC/POS builder: init, center, left, bold, doubleHeight, fontSize, text (UTF-8), cut
- Receipt format: Shop header → items table → totals → payment method → footer → cut
- Test page: printer info + app branding

#### DemoDataService
- Loads hardcoded data: kirana products (rice, dal, sugar, milk, etc.), sample customers, bills, transactions, expenses
- All operations (CRUD) work against in-memory lists
- `clearDemoData()` resets everything
- Session-only persistence

#### DataExportService
- Export formats: CSV, JSON
- Date range options: Today, Last 7/30/90 days, This month, Last month, All time
- Uses `csv` package for CSV generation
- Uses `file_picker` for save location (desktop)
- Uses `share_plus` for sharing (mobile)
- Uses `path_provider` for temp file storage

#### ConnectivityService
- `connectivity_plus` package
- `isOnlineProvider` → consumed by OfflineBanner and sync logic
- Assumes online during loading state

---

## 14. Data Models

### Model Inventory (`lib/models/`)

| Model | File | Key Fields |
|-------|------|------------|
| BillModel | `bill_model.dart` | id, billNumber, items (List<CartItem>), total, paymentMethod, customerId?, customerName?, receivedAmount?, createdAt, date |
| CartItem | `bill_model.dart` | productId, name, price, quantity, unit |
| ProductModel | `product_model.dart` | id, name, price, purchasePrice?, stock, lowStockAlert?, barcode?, imageUrl?, category?, unit (ProductUnit), createdAt, updatedAt? |
| CustomerModel | `customer_model.dart` | id, name, phone, address?, balance, createdAt, updatedAt?, lastTransactionAt? |
| ExpenseModel | `expense_model.dart` | id, amount, category (ExpenseCategory), description?, paymentMethod, createdAt, date |
| TransactionModel | `transaction_model.dart` | (credit/payment records for khata) |
| UserModel | `user_model.dart` | id, shopName, ownerName, phone, email?, address?, gstNumber?, shopLogoPath?, profileImagePath?, photoUrl?, upiId?, currency, timezone, settings (UserSettings), isPaid, phoneVerified, emailVerified, createdAt |
| UserSettings | `user_model.dart` | language, darkMode, autoPrint, printPreview, soundEnabled, notificationsEnabled, lowStockAlerts, subscriptionAlerts, dailySummary, printerAddress?, billSize, gstEnabled, taxRate, receiptFooter |
| SalesSummaryModel | `sales_summary_model.dart` | (aggregated sales data) |
| ThemeSettingsModel | `theme_settings_model.dart` | (theme preferences) |

### Enums
| Enum | Values |
|------|--------|
| PaymentMethod | cash, upi, udhar, unknown |
| ProductUnit | piece, kg, gram, liter, ml, pack, box, dozen, unknown |
| ExpenseCategory | rent, salary, utilities, supplies, transport, maintenance, other |

### Defaults (UserSettings)
- language: `hi` (Hindi)
- darkMode: false
- autoPrint: false
- billSize: `58mm`
- gstEnabled: true
- taxRate: 5.0
- receiptFooter: "Thank you for shopping!"

---

## 15. Shared Widgets

### Widget Inventory (`lib/shared/widgets/`)

| Widget | File | Purpose |
|--------|------|---------|
| AnnouncementBanner | `announcement_banner.dart` | Remote Config-driven banner |
| AppButton | `app_button.dart` | Styled button component |
| AppTextField | `app_text_field.dart` | Styled text input component |
| GlobalSyncIndicator | `global_sync_indicator.dart` | Sync status icon in header |
| LoadingStates | `loading_states.dart` | Loading/shimmer placeholders |
| LogoutDialog | `logout_dialog.dart` | Logout confirmation |
| NpsSurveyDialog | `nps_survey_dialog.dart` | NPS score (0-10) survey; eligible: account ≥7 days old, not surveyed in 90 days |
| OfflineBanner | `offline_banner.dart` | Orange banner when offline; shows pending change count |
| OnboardingChecklist | `onboarding_checklist.dart` | 3-step checklist (add product, create bill, add customer); dismissible; persisted in Firestore |
| PlanBadge | `plan_badge.dart` | Current subscription plan badge |
| ShopLogoWidget | `shop_logo_widget.dart` | Shop logo with fallback icon |
| SyncBadge | `sync_badge.dart` | Per-item sync status indicator |
| SyncDetailsSheet | `sync_details_sheet.dart` | Detailed sync status info |
| UpdateBanner | `update_banner.dart` | App update available banner |
| UpdateDialog | `update_dialog.dart` | Force/optional update dialog |
| UpgradePromptModal | `upgrade_prompt_modal.dart` | Triggers: productLimit, billLimit, customerLimit, featureGated |

---

## 16. Platform-Specific Behavior

### Android
| Feature | Behavior |
|---------|----------|
| Google Sign-In | GoogleSignIn package → Firebase credential |
| Phone Auth | Full OTP with auto-verification (reads SMS) |
| Barcode Scanning | Camera-based via mobile_scanner |
| Printing | Bluetooth thermal (print_bluetooth_thermal) + System |
| Push Notifications | FCM (foreground + background handler) |
| In-App Update | `in_app_update` package (Play Store) |
| In-App Review | `in_app_review` package (after 3rd bill) |
| File Sharing | `share_plus` native share sheet |
| Subscription | Should use Google Play IAP (compliance note in code) |

### Web
| Feature | Behavior |
|---------|----------|
| Google Sign-In | 3-layer: signInWithPopup → GoogleSignIn → signInWithRedirect |
| Phone Auth | Full OTP (no auto-verification) |
| Barcode Scanning | Not available (no camera access in typical web) |
| Printing | System print dialog via `printing` package |
| Push Notifications | FCM Web (foreground only — no service worker background) |
| File Sharing | Clipboard / download |
| Subscription | Razorpay checkout (primary flow) |
| Desktop Login Bridge | `/desktop-login?code=XXX` page |

### Windows Desktop
| Feature | Behavior |
|---------|----------|
| Google Sign-In | Browser bridge: generates link code → opens browser → polls for token |
| Phone Auth | **NOT AVAILABLE** (skipped in shop setup) |
| Barcode Scanning | Not available |
| Printing | USB printer (Windows RAW printing) + System print dialog |
| Push Notifications | **NO FCM** → `WindowsNotificationService` with polling |
| In-App Update | `WindowsUpdateService` (custom mechanism) |
| File Operations | `file_picker` for save dialogs, `path_provider` for temp |
| Auth | Email/password auto-expanded on login screen |

### Responsive Breakpoints
| Type | Width | Layout |
|------|-------|--------|
| Mobile | <768px | Bottom nav, single column, full-screen modals |
| Tablet | ≥768px | Side rail nav, side-by-side panels (e.g., POS) |
| Desktop | (computed) | WebShell sidebar (collapsible at <800px), multi-column |
| Desktop Large | (computed) | Wider sidebar (280px vs 240px), 6-column admin grid |

---

## Cross-Cutting Concerns

### Offline Support
- Firestore offline persistence enabled
- `ConnectivityService` monitors network status
- `OfflineBanner` shows with pending change count
- `SyncStatusService` tracks per-document pending writes
- `WriteRetryQueue` retries failed writes
- `GlobalSyncIndicator` in app bar
- Bills/products/customers created offline sync automatically when online

### Demo Mode
- Full in-memory simulation via `DemoDataService`
- Pre-loaded: kirana products, sample customers, bills, transactions, expenses
- All CRUD works against in-memory lists
- `DemoModeBanner` displayed at top of app
- Session-only — data lost on restart

### Localization
- 3 languages: English (`en`), Hindi (`hi`), Telugu (`te`)
- Default: Hindi
- `AppLocalizations` via Flutter's l10n system
- Mixed Hindi/English labels in code (e.g. "कुल बाकी (Total Due)")

### Error Handling
- `ErrorLoggingService` with severity levels (warning, error, critical)
- Firebase Crashlytics integration
- Firestore permission-denied → subscription limit check → upgrade prompt
- Razorpay payment failures → partial payment handling
- Network errors → offline fallback

### Security
- Firebase Auth for all authentication
- Firestore Security Rules (`firestore.rules`)
- Firebase Storage Rules (`storage.rules`)
- Firebase App Check
- Super admin email whitelist (hardcoded + Firestore)
- Desktop auth sessions with 10-minute TTL

### Performance
- `PerformanceService` (Firebase Performance)
- Products stream limited to 2000 documents
- Transaction history capped at 50 visible items
- Report aggregation warns if >100ms
- `ThrottleService` for rate limiting
- Batch writes capped at 490 per batch

### Data Management
- `DataRetentionService` for auto-cleanup
- `SchemaMigrationService` for versioning
- `DataExportService` for CSV/JSON export
- `ConflictResolutionService` for multi-device conflicts
