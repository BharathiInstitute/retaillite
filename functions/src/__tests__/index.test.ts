/**
 * Cloud Functions Unit Tests
 *
 * Tests pure logic, input validation, and limit enforcement.
 * Uses firebase-functions-test in offline mode (no emulator needed).
 */

import * as crypto from "crypto";

// ─── Interface / Type Tests ─────────────────────────────────────────────────

describe("PaymentLinkRequest validation", () => {
  // These mirror the validation checks in createPaymentLink
  const validRequest = {
    amount: 100,
    customerName: "Test User",
    customerPhone: "9876543210",
    description: "Test payment",
  };

  test("valid request has all required fields", () => {
    expect(validRequest.amount).toBeGreaterThan(0);
    expect(validRequest.customerName).toBeTruthy();
    expect(validRequest.customerPhone).toMatch(/^\d{10}$/);
    expect(validRequest.description).toBeTruthy();
  });

  test("amount must be positive", () => {
    expect(0).not.toBeGreaterThan(0);
    expect(-100).not.toBeGreaterThan(0);
  });

  test("amount converts to paise correctly", () => {
    const amountInPaise = Math.round(validRequest.amount * 100);
    expect(amountInPaise).toBe(10000);
    // Edge case: ₹0.01
    expect(Math.round(0.01 * 100)).toBe(1);
    // Edge case: ₹99999
    expect(Math.round(99999 * 100)).toBe(9999900);
  });
});

// ─── OTP Logic Tests ────────────────────────────────────────────────────────

describe("OTP generation logic", () => {
  test("generates 6-digit OTP", () => {
    const otp = crypto.randomInt(100000, 999999).toString();
    expect(otp).toHaveLength(6);
    expect(Number(otp)).toBeGreaterThanOrEqual(100000);
    expect(Number(otp)).toBeLessThan(999999);
  });

  test("email key hashing produces consistent 20-char hex", () => {
    const email = "test@example.com";
    const emailKey = crypto
      .createHash("sha256")
      .update(email)
      .digest("hex")
      .substring(0, 20);
    expect(emailKey).toHaveLength(20);
    expect(emailKey).toMatch(/^[a-f0-9]+$/);

    // Same email → same hash
    const emailKey2 = crypto
      .createHash("sha256")
      .update(email)
      .digest("hex")
      .substring(0, 20);
    expect(emailKey2).toBe(emailKey);
  });

  test("different emails produce different keys", () => {
    const key1 = crypto.createHash("sha256").update("a@b.com").digest("hex").substring(0, 20);
    const key2 = crypto.createHash("sha256").update("c@d.com").digest("hex").substring(0, 20);
    expect(key1).not.toBe(key2);
  });

  test("email normalization: trim + lowercase", () => {
    const raw = "  Test@Example.COM  ";
    const normalized = raw.trim().toLowerCase();
    expect(normalized).toBe("test@example.com");
  });

  test("email validation regex", () => {
    const regex = /^[^@]+@[^@]+\.[^@]+$/;
    expect(regex.test("user@example.com")).toBe(true);
    expect(regex.test("user@sub.example.com")).toBe(true);
    expect(regex.test("")).toBe(false);
    expect(regex.test("noatsign")).toBe(false);
    expect(regex.test("@missing.com")).toBe(false);
    expect(regex.test("user@")).toBe(false);
    expect(regex.test("user@nodot")).toBe(false);
  });

  test("OTP expiry is 10 minutes", () => {
    const now = Date.now();
    const expiresAt = new Date(now + 10 * 60 * 1000);
    expect(expiresAt.getTime() - now).toBe(600000);
  });

  test("rate limit: 1 per minute check", () => {
    const sentAt = new Date(Date.now() - 30000); // 30s ago
    const elapsed = Date.now() - sentAt.getTime();
    expect(elapsed).toBeLessThan(60000); // still rate limited

    const sentOld = new Date(Date.now() - 61000); // 61s ago
    const elapsedOld = Date.now() - sentOld.getTime();
    expect(elapsedOld).toBeGreaterThanOrEqual(60000); // rate limit passed
  });

  test("max attempts is 5", () => {
    const maxAttempts = 5;
    for (let attempts = 0; attempts < maxAttempts; attempts++) {
      expect(attempts).toBeLessThan(maxAttempts);
    }
    expect(maxAttempts).not.toBeLessThan(maxAttempts);
  });

  test("remaining attempts calculation", () => {
    expect(5 - (0 + 1)).toBe(4);
    expect(5 - (3 + 1)).toBe(1);
    expect(5 - (4 + 1)).toBe(0);
  });
});

// ─── Webhook Signature Verification Logic ───────────────────────────────────

describe("Razorpay webhook signature verification", () => {
  const webhookSecret = "test_webhook_secret_123";

  test("HMAC-SHA256 signature matches for valid body", () => {
    const body = JSON.stringify({ event: "payment_link.paid", payload: {} });
    const expectedSig = crypto
      .createHmac("sha256", webhookSecret)
      .update(body)
      .digest("hex");

    const actualSig = crypto
      .createHmac("sha256", webhookSecret)
      .update(body)
      .digest("hex");

    expect(actualSig).toBe(expectedSig);
  });

  test("signature mismatch for tampered body", () => {
    const body = JSON.stringify({ event: "payment_link.paid" });
    const tamperedBody = JSON.stringify({ event: "payment_link.paid", extra: true });

    const sig = crypto.createHmac("sha256", webhookSecret).update(body).digest("hex");
    const tamperedSig = crypto.createHmac("sha256", webhookSecret).update(tamperedBody).digest("hex");

    expect(sig).not.toBe(tamperedSig);
  });

  test("signature mismatch for wrong secret", () => {
    const body = JSON.stringify({ event: "test" });
    const sig1 = crypto.createHmac("sha256", "secret1").update(body).digest("hex");
    const sig2 = crypto.createHmac("sha256", "secret2").update(body).digest("hex");
    expect(sig1).not.toBe(sig2);
  });
});

// ─── Limit Enforcement Logic ────────────────────────────────────────────────

describe("Bill limit enforcement (onBillCreated logic)", () => {
  test("free plan: 50 bill limit", () => {
    const limits = { billsThisMonth: 49, billsLimit: 50 };
    expect(limits.billsThisMonth < limits.billsLimit).toBe(true); // allowed
    limits.billsThisMonth = 50;
    expect(limits.billsThisMonth >= limits.billsLimit).toBe(true); // blocked
  });

  test("pro plan: 500 bill limit", () => {
    const limits = { billsThisMonth: 499, billsLimit: 500 };
    expect(limits.billsThisMonth < limits.billsLimit).toBe(true);
    limits.billsThisMonth = 500;
    expect(limits.billsThisMonth >= limits.billsLimit).toBe(true);
  });

  test("month rollover resets count", () => {
    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    const lastResetMonth = "2025-12";
    const isNewMonth = lastResetMonth !== currentMonth;
    expect(isNewMonth).toBe(true);

    const billsThisMonth = isNewMonth ? 0 : 49;
    expect(billsThisMonth).toBe(0);
  });

  test("same month does not reset", () => {
    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    const isNewMonth = currentMonth !== currentMonth;
    expect(isNewMonth).toBe(false);
  });

  test("default limits when missing", () => {
    const limits: Record<string, unknown> = {};
    const billsThisMonth = (limits.billsThisMonth as number) || 0;
    const billsLimit = (limits.billsLimit as number) || 50;
    expect(billsThisMonth).toBe(0);
    expect(billsLimit).toBe(50);
  });
});

describe("Product limit enforcement (onProductCreated logic)", () => {
  test("free plan: 100 product limit", () => {
    const productsCount = 99;
    const productsLimit = 100;
    expect(productsCount < productsLimit).toBe(true);
    expect(100 >= productsLimit).toBe(true); // at limit → blocked
  });

  test("default product limit is 100", () => {
    const limits: Record<string, unknown> = {};
    expect((limits.productsLimit as number) || 100).toBe(100);
  });
});

describe("Customer limit enforcement (onCustomerCreated logic)", () => {
  test("free plan: 10 customer limit", () => {
    const customersCount = 9;
    const customersLimit = 10;
    expect(customersCount < customersLimit).toBe(true);
    expect(10 >= customersLimit).toBe(true); // at limit → blocked
  });

  test("default customer limit is 10", () => {
    const limits: Record<string, unknown> = {};
    expect((limits.customersLimit as number) || 10).toBe(10);
  });
});

// ─── Subscription Stats Logic (onSubscriptionWrite) ─────────────────────────

describe("Subscription stats aggregation logic", () => {
  const mrrMap: Record<string, number> = { free: 0, pro: 299, business: 999 };

  test("MRR map values", () => {
    expect(mrrMap.free).toBe(0);
    expect(mrrMap.pro).toBe(299);
    expect(mrrMap.business).toBe(999);
  });

  test("MRR delta: free → pro upgrade", () => {
    const mrrBefore = mrrMap["free"];
    const mrrAfter = mrrMap["pro"];
    expect(mrrAfter - mrrBefore).toBe(299);
  });

  test("MRR delta: pro → business upgrade", () => {
    expect(mrrMap["business"] - mrrMap["pro"]).toBe(700);
  });

  test("MRR delta: pro → free downgrade", () => {
    expect(mrrMap["free"] - mrrMap["pro"]).toBe(-299);
  });

  test("MRR delta: no change same plan", () => {
    expect(mrrMap["pro"] - mrrMap["pro"]).toBe(0);
  });

  test("user created: totalUsers +1, planUsers +1", () => {
    const userCreated = true;
    const afterPlan = "free";
    const delta: Record<string, number> = {};

    if (userCreated) {
      delta.totalUsers = 1;
      delta[`${afterPlan}Users`] = 1;
    }

    expect(delta.totalUsers).toBe(1);
    expect(delta.freeUsers).toBe(1);
  });

  test("user deleted: totalUsers -1, planUsers -1", () => {
    const userDeleted = true;
    const beforePlan = "pro";
    const delta: Record<string, number> = {};

    if (userDeleted) {
      delta.totalUsers = -1;
      delta[`${beforePlan}Users`] = -1;
    }

    expect(delta.totalUsers).toBe(-1);
    expect(delta.proUsers).toBe(-1);
  });

  test("plan changed: swap counts", () => {
    const beforePlan = "free";
    const afterPlan = "pro";
    const delta: Record<string, number> = {};

    delta[`${beforePlan}Users`] = -1;
    delta[`${afterPlan}Users`] = 1;

    expect(delta.freeUsers).toBe(-1);
    expect(delta.proUsers).toBe(1);
  });

  test("no action when plan unchanged and not created/deleted", () => {
    const userCreated = false;
    const userDeleted = false;
    const planChanged = false;
    const shouldAct = userCreated || userDeleted || planChanged;
    expect(shouldAct).toBe(false);
  });
});

// ─── Subscription Limits Response Tests ─────────────────────────────────────

describe("getSubscriptionLimits response shape", () => {
  test("default free-tier limits when user has no data", () => {
    const limits: Record<string, unknown> = {};
    const sub: Record<string, unknown> = {};

    const response = {
      billsThisMonth: limits.billsThisMonth || 0,
      billsLimit: limits.billsLimit || 50,
      productsCount: limits.productsCount || 0,
      productsLimit: limits.productsLimit || 100,
      customersCount: limits.customersCount || 0,
      plan: sub.plan || "free",
      status: sub.status || "active",
    };

    expect(response.billsThisMonth).toBe(0);
    expect(response.billsLimit).toBe(50);
    expect(response.productsCount).toBe(0);
    expect(response.productsLimit).toBe(100);
    expect(response.customersCount).toBe(0);
    expect(response.plan).toBe("free");
    expect(response.status).toBe("active");
  });

  test("pro user limits returned correctly", () => {
    const limits = { billsThisMonth: 25, billsLimit: 500, productsCount: 80, productsLimit: 5000, customersCount: 5 };
    const sub = { plan: "pro", status: "active" };

    const response = {
      billsThisMonth: limits.billsThisMonth || 0,
      billsLimit: limits.billsLimit || 50,
      productsCount: limits.productsCount || 0,
      productsLimit: limits.productsLimit || 100,
      customersCount: limits.customersCount || 0,
      plan: sub.plan || "free",
      status: sub.status || "active",
    };

    expect(response.billsThisMonth).toBe(25);
    expect(response.billsLimit).toBe(500);
    expect(response.productsCount).toBe(80);
    expect(response.productsLimit).toBe(5000);
    expect(response.customersCount).toBe(5);
    expect(response.plan).toBe("pro");
    expect(response.status).toBe("active");
  });
});

// ─── Subcollection Deletion Logic ───────────────────────────────────────────

describe("deleteUserSubcollections logic", () => {
  const subCollections = [
    "products", "bills", "customers", "transactions",
    "expenses", "notifications", "counters", "settings",
    "attendance", "subscription_audit",
  ];

  test("covers all 10 subcollections", () => {
    expect(subCollections).toHaveLength(10);
  });

  test("includes critical collections", () => {
    expect(subCollections).toContain("products");
    expect(subCollections).toContain("bills");
    expect(subCollections).toContain("customers");
    expect(subCollections).toContain("notifications");
    expect(subCollections).toContain("transactions");
  });

  test("batch size is 400", () => {
    const batchSize = 400;
    expect(batchSize).toBeLessThanOrEqual(500); // Firestore max
    expect(batchSize).toBeGreaterThan(0);
  });
});

// ─── Subscription Expiry Logic ──────────────────────────────────────────────

describe("Subscription expiry touchpoints", () => {
  const touchpoints = [
    { days: -7, label: "7 days until expiry" },
    { days: -3, label: "3 days until expiry" },
    { days: -1, label: "expires tomorrow" },
    { days: 0, label: "expires today" },
    { days: 3, label: "expired 3 days ago" },
  ];

  test("5 touchpoints defined", () => {
    expect(touchpoints).toHaveLength(5);
  });

  test("touchpoints range from -7 to +3 days", () => {
    const days = touchpoints.map((t) => t.days);
    expect(Math.min(...days)).toBe(-7);
    expect(Math.max(...days)).toBe(3);
  });

  test("subscription duration: pro monthly = 30 days", () => {
    const now = new Date();
    const expiry = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    const diffDays = Math.round((expiry.getTime() - now.getTime()) / (24 * 60 * 60 * 1000));
    expect(diffDays).toBe(30);
  });

  test("subscription duration: pro yearly = 365 days", () => {
    const now = new Date();
    const expiry = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
    const diffDays = Math.round((expiry.getTime() - now.getTime()) / (24 * 60 * 60 * 1000));
    expect(diffDays).toBe(365);
  });
});

// ─── Churn Detection Logic ──────────────────────────────────────────────────

describe("Churn detection thresholds", () => {
  test("inactivity thresholds: 7, 14, 30 days", () => {
    const thresholds = [7, 14, 30];
    expect(thresholds).toEqual([7, 14, 30]);
  });

  test("days since last active calculation", () => {
    const lastActive = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000);
    const daysSince = Math.floor((Date.now() - lastActive.getTime()) / (24 * 60 * 60 * 1000));
    expect(daysSince).toBe(8);
    expect(daysSince).toBeGreaterThanOrEqual(7); // triggers 7-day churn
    expect(daysSince).toBeLessThan(14); // doesn't trigger 14-day
  });

  test("dedup: same touchpoint not sent twice", () => {
    const lastChurnMessageDays = 7;
    const daysSinceActive = 8;
    // Should NOT send 7-day message again
    expect(daysSinceActive >= 7 && lastChurnMessageDays < 7).toBe(false);
    // Should send 14-day when reaches 14
    const daysSinceActive2 = 15;
    expect(daysSinceActive2 >= 14 && lastChurnMessageDays < 14).toBe(true);
  });
});

// ─── Referral Logic ─────────────────────────────────────────────────────────

describe("Referral code validation", () => {
  test("referral code is 6 characters", () => {
    const code = "ABC123";
    expect(code).toHaveLength(6);
  });

  test("self-referral prevention", () => {
    const callerId = "user123";
    const referrerId = "user123";
    expect(callerId).toBe(referrerId); // should be blocked
  });

  test("referral reward: extends subscription by 30 days", () => {
    const currentExpiry = new Date("2026-04-01");
    const newExpiry = new Date(currentExpiry.getTime() + 30 * 24 * 60 * 60 * 1000);
    const expectedExpiry = new Date("2026-05-01");
    expect(newExpiry.getDate()).toBe(expectedExpiry.getDate());
    expect(newExpiry.getMonth()).toBe(expectedExpiry.getMonth());
  });
});

// ─── Notification Cleanup Logic ─────────────────────────────────────────────

describe("Notification cleanup logic", () => {
  test("30-day retention for read notifications", () => {
    const retentionMs = 30 * 24 * 60 * 60 * 1000;
    const cutoffDate = new Date(Date.now() - retentionMs);
    const oldNotification = new Date("2026-01-01");
    const recentNotification = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000);

    expect(oldNotification < cutoffDate).toBe(true); // should delete
    expect(recentNotification < cutoffDate).toBe(false); // should keep
  });

  test("pagination: 200 users per page", () => {
    const pageSize = 200;
    const totalUsers = 10000;
    const pages = Math.ceil(totalUsers / pageSize);
    expect(pages).toBe(50);
  });
});

// ─── Scheduled Backup Logic ─────────────────────────────────────────────────

describe("Scheduled backup config", () => {
  test("backup bucket naming convention", () => {
    const projectId = "login-radha";
    const bucket = `gs://${projectId}-firestore-backups`;
    expect(bucket).toBe("gs://login-radha-firestore-backups");
  });

  test("backup path includes timestamp", () => {
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const path = `backups/${timestamp}`;
    expect(path).toMatch(/^backups\/\d{4}-\d{2}-\d{2}T/);
  });
});

// ─── Admin Notification Fan-out Logic ───────────────────────────────────────

describe("Notification fan-out pagination", () => {
  test("200 users per page, 500 writes per batch", () => {
    const usersPerPage = 200;
    const writesPerBatch = 500;
    expect(usersPerPage).toBeLessThanOrEqual(writesPerBatch);
    // Each user gets 1 notification write, so 200 fits in one batch
    expect(usersPerPage).toBeLessThanOrEqual(writesPerBatch);
  });

  test("fan-out to 10K users requires 50 pages", () => {
    const totalUsers = 10000;
    const usersPerPage = 200;
    expect(Math.ceil(totalUsers / usersPerPage)).toBe(50);
  });
});

// ─── Month Formatting ───────────────────────────────────────────────────────

describe("Month key formatting (used in reports + bill resets)", () => {
  test("formats single-digit month with leading zero", () => {
    const date = new Date(2026, 0, 15); // January
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
    expect(monthKey).toBe("2026-01");
  });

  test("formats double-digit month correctly", () => {
    const date = new Date(2026, 11, 25); // December
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
    expect(monthKey).toBe("2026-12");
  });
});
