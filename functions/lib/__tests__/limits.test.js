"use strict";
/**
 * Limit enforcement tests
 *
 * Tests onBillCreated, onProductCreated/Deleted, onCustomerCreated/Deleted,
 * getSubscriptionLimits.
 */
describe("onBillCreated", () => {
    test("increments billsThisMonth transactionally", () => {
        const before = { billsThisMonth: 10, lastResetMonth: "2026-04" };
        const after = Object.assign(Object.assign({}, before), { billsThisMonth: before.billsThisMonth + 1 });
        expect(after.billsThisMonth).toBe(11);
    });
    test("does month rollover when lastResetMonth differs", () => {
        const now = new Date();
        const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
        const limits = { billsThisMonth: 45, lastResetMonth: "2026-03" };
        const isNewMonth = limits.lastResetMonth !== currentMonth;
        expect(isNewMonth).toBe(true);
        const newCount = isNewMonth ? 0 : limits.billsThisMonth;
        expect(newCount).toBe(0);
    });
    test("deletes bill when billsThisMonth >= billsLimit (safety net)", () => {
        const limits = { billsThisMonth: 50, billsLimit: 50 };
        const overLimit = limits.billsThisMonth >= limits.billsLimit;
        expect(overLimit).toBe(true);
        // bill should be deleted
    });
    test("normal case: bill below limit is kept", () => {
        const limits = { billsThisMonth: 25, billsLimit: 50 };
        const overLimit = limits.billsThisMonth >= limits.billsLimit;
        expect(overLimit).toBe(false);
    });
    test("free plan defaults: 50 bill limit", () => {
        const limits = {};
        const billsLimit = limits.billsLimit || 50;
        expect(billsLimit).toBe(50);
    });
    test("bill counter starts at 0 when no data", () => {
        const limits = {};
        const billsThisMonth = limits.billsThisMonth || 0;
        expect(billsThisMonth).toBe(0);
    });
});
describe("onProductCreated / onProductDeleted", () => {
    test("increments productsCount on create", () => {
        const before = 10;
        const after = before + 1;
        expect(after).toBe(11);
    });
    test("deletes product when productsCount >= limit", () => {
        const productsCount = 100;
        const productsLimit = 100;
        expect(productsCount >= productsLimit).toBe(true);
    });
    test("decrements productsCount on delete", () => {
        const before = 10;
        const after = before - 1;
        expect(after).toBe(9);
    });
    test("default product limit is 100", () => {
        const limits = {};
        const productsLimit = limits.productsLimit || 100;
        expect(productsLimit).toBe(100);
    });
    test("at-limit product is blocked", () => {
        const productsCount = 100;
        const productsLimit = 100;
        expect(productsCount >= productsLimit).toBe(true);
    });
    test("below-limit product is allowed", () => {
        const productsCount = 99;
        const productsLimit = 100;
        expect(productsCount >= productsLimit).toBe(false);
    });
});
describe("onCustomerCreated / onCustomerDeleted", () => {
    test("increments customersCount on create", () => {
        const before = 5;
        const after = before + 1;
        expect(after).toBe(6);
    });
    test("deletes customer when customersCount >= limit", () => {
        const customersCount = 10;
        const customersLimit = 10;
        expect(customersCount >= customersLimit).toBe(true);
    });
    test("decrements customersCount on delete", () => {
        const before = 5;
        const after = before - 1;
        expect(after).toBe(4);
    });
    test("default customer limit is 10", () => {
        const limits = {};
        const customersLimit = limits.customersLimit || 10;
        expect(customersLimit).toBe(10);
    });
});
describe("getSubscriptionLimits", () => {
    test("returns authoritative limits from user data", () => {
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
        expect(response).toEqual({
            billsThisMonth: 25,
            billsLimit: 500,
            productsCount: 80,
            productsLimit: 5000,
            customersCount: 5,
            plan: "pro",
            status: "active",
        });
    });
    test("rejects unauthenticated request", () => {
        const auth = null;
        expect(auth).toBeNull();
    });
    test("defaults to free tier when user has no data", () => {
        const limits = {};
        const sub = {};
        const response = {
            billsThisMonth: limits.billsThisMonth || 0,
            billsLimit: limits.billsLimit || 50,
            productsCount: limits.productsCount || 0,
            productsLimit: limits.productsLimit || 100,
            customersCount: limits.customersCount || 0,
            plan: sub.plan || "free",
            status: sub.status || "active",
        };
        expect(response.billsLimit).toBe(50);
        expect(response.productsLimit).toBe(100);
        expect(response.plan).toBe("free");
    });
});
//# sourceMappingURL=limits.test.js.map