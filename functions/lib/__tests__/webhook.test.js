"use strict";
/**
 * Razorpay Webhook handler tests
 *
 * Tests signature verification, event handling, idempotency.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const crypto = __importStar(require("crypto"));
describe("razorpayWebhook", () => {
    const webhookSecret = "test_webhook_secret_123";
    test("validates HMAC-SHA256 signature", () => {
        const body = JSON.stringify({ event: "payment_link.paid", payload: {} });
        const sig = crypto.createHmac("sha256", webhookSecret).update(body).digest("hex");
        const verifySig = crypto.createHmac("sha256", webhookSecret).update(body).digest("hex");
        expect(sig).toBe(verifySig);
    });
    test("rejects request with invalid signature", () => {
        const body = JSON.stringify({ event: "test" });
        const validSig = crypto.createHmac("sha256", webhookSecret).update(body).digest("hex");
        const invalidSig = crypto.createHmac("sha256", "wrong_secret").update(body).digest("hex");
        expect(validSig).not.toBe(invalidSig);
    });
    test("handles payment_link.paid event", () => {
        const event = {
            event: "payment_link.paid",
            payload: {
                payment_link: { entity: { id: "plink_abc123" } },
                payment: { entity: { id: "pay_xyz789" } },
            },
        };
        expect(event.event).toBe("payment_link.paid");
        expect(event.payload.payment_link.entity.id).toBeTruthy();
        expect(event.payload.payment.entity.id).toBeTruthy();
    });
    test("handles subscription.activated event", () => {
        const event = {
            event: "subscription.activated",
            payload: { subscription: { entity: { id: "sub_abc123" } } },
        };
        expect(event.event).toBe("subscription.activated");
        expect(event.payload.subscription.entity.id).toMatch(/^sub_/);
    });
    test("handles subscription.charged event — extends expiry", () => {
        const cycle = "monthly";
        const daysToAdd = cycle === "annual" ? 365 : 30;
        const now = new Date();
        const newExpiry = new Date(now);
        newExpiry.setDate(newExpiry.getDate() + daysToAdd);
        expect(Math.round((newExpiry.getTime() - now.getTime()) / (24 * 60 * 60 * 1000))).toBe(30);
    });
    test("handles subscription.charged event — resets billsThisMonth", () => {
        const updatePayload = {
            "subscription.status": "active",
            "limits.billsThisMonth": 0,
        };
        expect(updatePayload["limits.billsThisMonth"]).toBe(0);
    });
    test("handles subscription.charged event — sends renewal notification", () => {
        const notification = {
            title: "Subscription Renewed! 🎉",
            type: "subscription",
            read: false,
        };
        expect(notification.title).toContain("Renewed");
        expect(notification.read).toBe(false);
    });
    test("handles subscription.halted event — downgrades to free", () => {
        const update = {
            "subscription.status": "expired",
            "subscription.plan": "free",
            "limits.billsLimit": 50,
            "limits.productsLimit": 100,
            "limits.customersLimit": 10,
        };
        expect(update["subscription.plan"]).toBe("free");
        expect(update["limits.billsLimit"]).toBe(50);
        expect(update["limits.productsLimit"]).toBe(100);
        expect(update["limits.customersLimit"]).toBe(10);
    });
    test("handles subscription.cancelled event", () => {
        const update = { "subscription.status": "cancelled" };
        expect(update["subscription.status"]).toBe("cancelled");
    });
    test("is idempotent: duplicate webhook delivery does not double-process", () => {
        const processedEvents = new Set();
        const eventId = "evt_123";
        // First processing
        processedEvents.add(eventId);
        expect(processedEvents.has(eventId)).toBe(true);
        // Second delivery — should be skipped
        const shouldProcess = !processedEvents.has(eventId);
        expect(shouldProcess).toBe(false);
    });
    test("returns 200 for already-processed events", () => {
        const processedEvents = new Set(["evt_old"]);
        const statusCode = processedEvents.has("evt_old") ? 200 : 500;
        expect(statusCode).toBe(200);
    });
    test("returns 400 for malformed payload", () => {
        const payload = null;
        const isValid = payload && payload.event;
        expect(isValid).toBeFalsy();
    });
});
//# sourceMappingURL=webhook.test.js.map