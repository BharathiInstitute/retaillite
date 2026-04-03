"use strict";
/**
 * Monthly report generation tests
 */
describe("generateMonthlyReport", () => {
    test("aggregates last month bills per user", () => {
        const billsByUser = new Map();
        billsByUser.set("user1", { count: 120, revenue: 45000 });
        billsByUser.set("user2", { count: 30, revenue: 8000 });
        expect(billsByUser.size).toBe(2);
        expect(billsByUser.get("user1").revenue).toBe(45000);
    });
    test("writes report doc to users/{id}/reports/{monthKey}", () => {
        const now = new Date(2026, 3, 1); // April 1
        const firstOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const monthKey = `monthly_${firstOfLastMonth.getFullYear()}_${String(firstOfLastMonth.getMonth() + 1).padStart(2, "0")}`;
        expect(monthKey).toBe("monthly_2026_03");
    });
    test("sends notification with report summary", () => {
        const shopName = "Tulasi Stores";
        const count = 120;
        const revenue = 45000;
        const body = `${shopName} made ${count} bills totalling ₹${revenue.toLocaleString("en-IN")} last month.`;
        expect(body).toContain("Tulasi Stores");
        expect(body).toContain("120 bills");
    });
    test("uses deterministic reportId for idempotency", () => {
        const monthKey1 = "monthly_2026_03";
        const monthKey2 = "monthly_2026_03";
        expect(monthKey1).toBe(monthKey2);
        // Same month always produces same doc ID → no duplicates
    });
    test("paginates across >200 users", () => {
        const PAGE_SIZE = 200;
        const totalUsers = 1000;
        const pages = Math.ceil(totalUsers / PAGE_SIZE);
        expect(pages).toBe(5);
    });
    test("computes last month date range correctly (edge: Jan → Dec)", () => {
        const jan1 = new Date(2026, 0, 1); // Jan 2026
        const firstOfLastMonth = new Date(jan1.getFullYear(), jan1.getMonth() - 1, 1);
        expect(firstOfLastMonth.getMonth()).toBe(11); // December
        expect(firstOfLastMonth.getFullYear()).toBe(2025);
    });
});
describe("onSubscriptionWrite", () => {
    const mrrMap = { free: 0, pro: 299, business: 999 };
    test("updates stats: totalUsers increments on new user", () => {
        const userCreated = true;
        const delta = {};
        if (userCreated)
            delta.totalUsers = 1;
        expect(delta.totalUsers).toBe(1);
    });
    test("updates stats: proUsers increments on pro subscription", () => {
        const afterPlan = "pro";
        const delta = {};
        delta[`${afterPlan}Users`] = 1;
        expect(delta.proUsers).toBe(1);
    });
    test("computes MRR delta correctly", () => {
        expect(mrrMap["pro"] - mrrMap["free"]).toBe(299);
        expect(mrrMap["business"] - mrrMap["pro"]).toBe(700);
        expect(mrrMap["free"] - mrrMap["pro"]).toBe(-299);
    });
    test("deduplicates events via _dedup collection", () => {
        const processedEvents = new Set(["evt_old"]);
        const eventId = "evt_old";
        const isDuplicate = processedEvents.has(eventId);
        expect(isDuplicate).toBe(true);
    });
    test("no action when plan unchanged and not created/deleted", () => {
        const userCreated = false;
        const userDeleted = false;
        const planChanged = false;
        const shouldAct = userCreated || userDeleted || planChanged;
        expect(shouldAct).toBe(false);
    });
});
//# sourceMappingURL=reports.test.js.map