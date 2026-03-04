# RetailLite — Test Readiness Plan for 10K Subscribers

**Created:** March 2, 2026  
**Goal:** Sufficient automated + manual test coverage to safely serve 10,000+ subscribers

---

## CURRENT STATE — NOT READY

| Metric | Current | Target (10K) | Gap |
|--------|---------|-------------|-----|
| Automated test cases | 837 | 1,200+ | ~400 missing |
| Test-to-code ratio | 0.13 | 0.40+ | 3x improvement needed |
| Feature modules with tests | 6/11 (55%) | 11/11 (100%) | 5 modules have ZERO tests |
| Integration tests | 0 | 15+ | Critical gap |
| Widget tests | 57 (~7%) | 150+ (~12%) | Need more UI tests |
| CI coverage threshold | None | 60%+ enforced | Not enforced |
| Manual test cases | 42 | 60+ | Missing 5+ feature areas |
| Pre-existing test failures | 11 | 0 | Need to fix |

### Feature Test Coverage Map

| Feature | Dart Files | Tests? | Priority |
|---------|-----------|--------|----------|
| **auth/** | 14 | 1 file (95 lines) | P1 — Critical |
| **billing/** | 10 | 4 files (~556 lines) | P2 — Has basics |
| **khata/** | 7 | 1 file (231 lines) | P1 — Money |
| **products/** | 5 | 0 | P1 — Core CRUD |
| **reports/** | 2 | 0 | P2 — Data integrity |
| **settings/** | 9 | 0 | P3 — Low risk |
| **notifications/** | 8 | 1 file (428 lines) | P3 — Has coverage |
| **shell/** | 2 | 0 | P4 — UI only |
| **referral/** | 1 | 0 | P4 — Simple |
| **subscription/** | 1 | 0 | P1 — Paywall |
| **super_admin/** | 16 | 0 | P2 — Admin tools |
| **models/** | 12 | 12 files | ✅ Good |
| **core/services/** | 27 | ~10 files | P2 — Partial |
| **core/utils/** | 7 | 6 files | ✅ Good |

---

## PHASE A — Foundation (Immediate)

### A.1 Fix Pre-existing Failures
- Fix 10 connectivity_service test API mismatches
- Fix 1 theme_settings assertion

### A.2 Add Test Infrastructure
- Add `fake_cloud_firestore` for Firestore mocking
- Create shared test helpers (mock providers, fake user, fake bill)
- Create `test/fixtures/` for JSON test data

### A.3 Enforce CI Coverage
- Add coverage threshold (60% initially, raise to 75%)
- Add coverage reporting to PR comments

---

## PHASE B — Critical Business Flow Tests

### B.1 Subscription Enforcement Tests (~15 tests)
- Free tier bill limit enforcement
- Free tier product limit enforcement
- Free tier customer limit enforcement
- Pro/Business tier unlimited access
- Expired subscription handling
- Trial period logic
- Plan upgrade/downgrade

### B.2 Product CRUD Tests (~20 tests)
- Create product (valid/invalid)
- Update product fields
- Delete product (with bill references)
- Stock adjustment (+/-)
- Low stock alert trigger
- Barcode duplicate detection
- Category filtering
- CSV bulk import/export
- Price validation (0, negative, very large)

### B.3 Khata Transaction Tests (~20 tests)
- Give udhaar (credit) — normal flow
- Give udhaar — large amount (≥₹10K confirmation)
- Record payment — partial
- Record payment — full settlement
- Customer balance calculation
- Overdue detection (30-day default, custom days)
- WhatsApp message generation (UPI link, masked UPI ID)
- Transaction history ordering

### B.4 Auth Flow Tests (~15 tests)
- Email/password login — success/failure
- Google Sign-In — success/failure
- Sign out — cleanup (FCM token, cache)
- Session persistence
- Phone OTP verification (mock)
- Shop setup flow
- Email verification banner logic
- Admin role detection
- Account deletion cleanup

### B.5 Report Logic Tests (~15 tests)
- Daily sales summary calculation
- Weekly/monthly aggregation
- Top products ranking
- Revenue vs profit calculation
- Date range filtering
- Empty data handling
- Export data formatting

---

## PHASE C — Integration & Edge Cases

### C.1 Billing Integration Tests (~10 tests)
- Full checkout flow (cart → bill → save)
- Payment method switching (cash, UPI, mixed)
- Bill number generation (uniqueness)
- Bill share (WhatsApp, print)
- Customer bill linking

### C.2 Offline & Sync Tests (~5 tests)
- Offline bill creation
- Sync queue processing
- Conflict resolution
- Network recovery handling

### C.3 Settings & Config Tests (~10 tests)
- Theme persistence
- Printer configuration
- GST settings
- Shop info update
- Setting save feedback
- No-op toggle states

---

## PHASE D — Manual Test Coverage Expansion

### Missing Manual Test Areas

| Area | Tests Needed |
|------|-------------|
| Products CRUD | Add/edit/delete product, CSV import, barcode scan |
| Reports | View daily/weekly/monthly, export PDF/share |
| Settings | Change theme, configure printer, update shop info |
| Subscription | Subscribe, upgrade, downgrade, expired state |
| Referral | Generate code, apply code, reward distribution |
| Expenses | Add/edit/delete expense, categorize |

---

## PRIORITY ORDER

| # | Category | Tests | Impact | Effort |
|---|----------|-------|--------|--------|
| 1 | Fix pre-existing failures | 11 fixes | Baseline | 1 hour |
| 2 | Test infrastructure | Helpers + mocks | Unblocks all | 2 hours |
| 3 | Subscription enforcement | ~15 tests | Revenue protection | 3 hours |
| 4 | Product CRUD | ~20 tests | Core feature | 3 hours |
| 5 | Khata transactions | ~20 tests | Money accuracy | 3 hours |
| 6 | Auth flows | ~15 tests | Security | 3 hours |
| 7 | Report logic | ~15 tests | Data integrity | 2 hours |
| 8 | CI coverage gate | Config | Prevention | 1 hour |
| 9 | Settings tests | ~10 tests | UX quality | 2 hours |
| **Total** | | **~120 new tests** | | **~20 hours** |
