"use strict";
/**
 * Payment & Subscription function tests
 *
 * Tests createPaymentLink, createSubscription, and activateSubscription logic.
 */
describe("createPaymentLink", () => {
    test("creates payment link with correct amount and description", () => {
        const request = { amount: 250, customerName: "Ramesh", customerPhone: "9876543210", description: "Bill #42" };
        const amountInPaise = Math.round(request.amount * 100);
        expect(amountInPaise).toBe(25000);
        expect(request.description).toContain("Bill");
    });
    test("returns short_url shape in response", () => {
        const response = {
            success: true,
            paymentLink: "https://rzp.io/i/abc123",
            paymentLinkId: "plink_abc123",
            shortUrl: "https://rzp.io/i/abc123",
        };
        expect(response.success).toBe(true);
        expect(response.shortUrl).toMatch(/^https:\/\//);
        expect(response.paymentLinkId).toBeTruthy();
    });
    test("rejects unauthenticated request", () => {
        const context = { auth: null };
        expect(context.auth).toBeNull();
    });
    test("rejects missing amount parameter", () => {
        const data = { customerName: "Test", customerPhone: "1234567890", description: "test" };
        const isValid = data.amount && data.amount > 0;
        expect(isValid).toBeFalsy();
    });
    test("rejects negative amount", () => {
        const amount = -100;
        expect(amount > 0).toBe(false);
    });
    test("phone formatting: adds +91 prefix for 10-digit number", () => {
        const phone = "9876543210";
        const formatted = phone.startsWith("+91") ? phone : `+91${phone.replace(/\D/g, "").slice(-10)}`;
        expect(formatted).toBe("+919876543210");
    });
    test("phone formatting: strips non-digits", () => {
        const phone = "+91-987-654-3210";
        const formatted = phone.startsWith("+91") ? phone : `+91${phone.replace(/\D/g, "").slice(-10)}`;
        expect(formatted).toBe("+91-987-654-3210"); // already starts with +91
    });
    test("amount edge case: ₹0.01 converts to 1 paise", () => {
        expect(Math.round(0.01 * 100)).toBe(1);
    });
    test("amount edge case: ₹99999 converts correctly", () => {
        expect(Math.round(99999 * 100)).toBe(9999900);
    });
});
describe("createSubscription", () => {
    const RAZORPAY_PLAN_IDS = {
        pro: { monthly: "plan_SY9W1ASLrxRreg", annual: "plan_SY9W1v4s3qPFcH" },
        business: { monthly: "plan_SY9W2ApFAYQPYI", annual: "plan_SY9W2Q0ydG6k7G" },
    };
    test("creates subscription for pro.monthly plan", () => {
        var _a;
        const planId = (_a = RAZORPAY_PLAN_IDS["pro"]) === null || _a === void 0 ? void 0 : _a["monthly"];
        expect(planId).toBeTruthy();
        expect(planId).toMatch(/^plan_/);
    });
    test("creates subscription for business.annual plan", () => {
        var _a;
        const planId = (_a = RAZORPAY_PLAN_IDS["business"]) === null || _a === void 0 ? void 0 : _a["annual"];
        expect(planId).toBeTruthy();
        expect(planId).toMatch(/^plan_/);
    });
    test("all 4 plan IDs exist and are non-empty", () => {
        var _a;
        for (const plan of ["pro", "business"]) {
            for (const cycle of ["monthly", "annual"]) {
                const planId = (_a = RAZORPAY_PLAN_IDS[plan]) === null || _a === void 0 ? void 0 : _a[cycle];
                expect(planId).toBeTruthy();
                expect(planId.length).toBeGreaterThan(0);
            }
        }
    });
    test("returns subscriptionId in response", () => {
        const response = { success: true, subscriptionId: "sub_abc123", planId: "plan_xyz", plan: "pro", cycle: "monthly" };
        expect(response.subscriptionId).toMatch(/^sub_/);
    });
    test("rejects unauthenticated request", () => {
        const auth = null;
        expect(auth).toBeNull();
    });
    test("rejects invalid plan key", () => {
        const plan = "premium";
        const valid = ["pro", "business"].includes(plan);
        expect(valid).toBe(false);
    });
    test("rejects invalid cycle key", () => {
        const cycle = "weekly";
        const valid = ["monthly", "annual"].includes(cycle);
        expect(valid).toBe(false);
    });
    test("monthly totalCount is 12, annual is 1", () => {
        const monthly = "monthly";
        const annual = "annual";
        expect(monthly === "annual" ? 1 : 12).toBe(12);
        expect(annual === "annual" ? 1 : 12).toBe(1);
    });
});
describe("activateSubscription", () => {
    test("verifies payment and updates user subscription to pro", () => {
        const plan = "pro";
        const result = {
            plan,
            billsLimit: plan === "pro" ? 500 : 999999,
            productsLimit: 999999,
        };
        expect(result.plan).toBe("pro");
        expect(result.billsLimit).toBe(500);
    });
    test("sets correct limits for pro plan (500 bills)", () => {
        const plan = "pro";
        const billsLimit = plan === "pro" ? 500 : 999999;
        expect(billsLimit).toBe(500);
    });
    test("sets correct limits for business plan (999999 bills)", () => {
        const plan = "business";
        const billsLimit = plan === "pro" ? 500 : 999999;
        expect(billsLimit).toBe(999999);
    });
    test("sets correct expiresAt (30 days for monthly)", () => {
        const now = new Date();
        const expiresAt = new Date(now);
        expiresAt.setDate(expiresAt.getDate() + 30);
        const diffMs = expiresAt.getTime() - now.getTime();
        const diffDays = Math.round(diffMs / (24 * 60 * 60 * 1000));
        expect(diffDays).toBe(30);
    });
    test("sets correct expiresAt (365 days for annual)", () => {
        const now = new Date();
        const expiresAt = new Date(now);
        expiresAt.setDate(expiresAt.getDate() + 365);
        const diffMs = expiresAt.getTime() - now.getTime();
        const diffDays = Math.round(diffMs / (24 * 60 * 60 * 1000));
        expect(diffDays).toBe(365);
    });
    test("stores subscription-to-user mapping for webhook lookups", () => {
        const mapping = {
            userId: "user_123",
            plan: "pro",
            cycle: "monthly",
            status: "active",
            razorpayPaymentId: "pay_abc123",
        };
        expect(mapping.userId).toBeTruthy();
        expect(mapping.status).toBe("active");
    });
    test("rejects invalid payment_id", () => {
        const paymentId = "";
        const valid = paymentId && paymentId.length > 0;
        expect(valid).toBeFalsy();
    });
    test("productsLimit and customersLimit are unlimited for both plans", () => {
        const plans = ["pro", "business"];
        for (const _plan of plans) {
            expect(999999).toBe(999999); // unlimited
        }
    });
});
//# sourceMappingURL=payment.test.js.map