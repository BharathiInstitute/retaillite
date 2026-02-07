"use strict";
/**
 * Firebase Cloud Functions for LITE Retail App
 *
 * Includes:
 * - createPaymentLink: Creates Razorpay payment links for sharing
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
exports.razorpayWebhook = exports.createPaymentLink = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// Razorpay API credentials (set via Firebase config)
// Run: firebase functions:config:set razorpay.key_id="rzp_xxx" razorpay.key_secret="xxx"
const getRazorpayConfig = () => {
    var _a, _b;
    const config = functions.config();
    return {
        keyId: ((_a = config.razorpay) === null || _a === void 0 ? void 0 : _a.key_id) || process.env.RAZORPAY_KEY_ID || "",
        keySecret: ((_b = config.razorpay) === null || _b === void 0 ? void 0 : _b.key_secret) || process.env.RAZORPAY_KEY_SECRET || "",
    };
};
/**
 * Create a Razorpay Payment Link
 *
 * This function creates a shareable payment link that customers can use
 * to pay via UPI, cards, or netbanking.
 */
exports.createPaymentLink = functions.https.onCall(async (data, context) => {
    var _a;
    // Verify authentication (optional but recommended)
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated to create payment links");
    }
    // Validate input
    if (!data.amount || data.amount <= 0) {
        throw new functions.https.HttpsError("invalid-argument", "Amount must be greater than 0");
    }
    if (!data.customerName || !data.customerPhone) {
        throw new functions.https.HttpsError("invalid-argument", "Customer name and phone are required");
    }
    const razorpayConfig = getRazorpayConfig();
    // Check if Razorpay is configured
    if (!razorpayConfig.keyId || !razorpayConfig.keySecret) {
        console.error("Razorpay not configured:", {
            hasKeyId: !!razorpayConfig.keyId,
            hasKeySecret: !!razorpayConfig.keySecret
        });
        throw new functions.https.HttpsError("failed-precondition", "Razorpay is not configured. Set razorpay.key_id and razorpay.key_secret");
    }
    try {
        // Convert amount to paise
        const amountInPaise = Math.round(data.amount * 100);
        // Create payment link via Razorpay API
        const auth = Buffer.from(`${razorpayConfig.keyId}:${razorpayConfig.keySecret}`).toString("base64");
        console.log("Creating Razorpay payment link for amount:", data.amount);
        const response = await fetch("https://api.razorpay.com/v1/payment_links", {
            method: "POST",
            headers: {
                "Authorization": `Basic ${auth}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                amount: amountInPaise,
                currency: "INR",
                description: data.description || `Payment to ${data.shopName || "Store"}`,
                customer: {
                    name: data.customerName,
                    contact: data.customerPhone.startsWith("+91")
                        ? data.customerPhone
                        : `+91${data.customerPhone.replace(/\D/g, "").slice(-10)}`,
                },
                notify: {
                    sms: true,
                    email: false,
                },
                reminder_enable: true,
                notes: {
                    bill_id: data.billId || "",
                    shop_name: data.shopName || "",
                },
            }),
        });
        const result = await response.json();
        if (!response.ok) {
            console.error("Razorpay API error:", result);
            const errorDesc = ((_a = result.error) === null || _a === void 0 ? void 0 : _a.description) || "Failed to create payment link";
            return {
                success: false,
                error: errorDesc,
            };
        }
        console.log("Razorpay payment link created:", result.short_url);
        // Log the transaction (optional)
        try {
            await admin.firestore().collection("payment_links").add({
                paymentLinkId: result.id,
                amount: data.amount,
                customerName: data.customerName,
                customerPhone: data.customerPhone,
                billId: data.billId || null,
                createdBy: context.auth.uid,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                status: "created",
                shortUrl: result.short_url,
            });
        }
        catch (dbError) {
            console.warn("Failed to log payment link:", dbError);
        }
        return {
            success: true,
            paymentLink: result.short_url,
            paymentLinkId: result.id,
            shortUrl: result.short_url,
        };
    }
    catch (error) {
        console.error("Error creating payment link:", error);
        return {
            success: false,
            error: error instanceof Error ? error.message : "Unknown error",
        };
    }
});
/**
 * Webhook handler for Razorpay payment status updates
 *
 * Configure this URL in Razorpay Dashboard -> Settings -> Webhooks
 */
exports.razorpayWebhook = functions.https.onRequest(async (req, res) => {
    var _a, _b, _c, _d;
    if (req.method !== "POST") {
        res.status(405).send("Method not allowed");
        return;
    }
    try {
        const event = req.body;
        console.log("Received webhook event:", event.event);
        // Handle payment events
        switch (event.event) {
            case "payment_link.paid":
                const paymentLinkId = (_b = (_a = event.payload.payment_link) === null || _a === void 0 ? void 0 : _a.entity) === null || _b === void 0 ? void 0 : _b.id;
                if (paymentLinkId) {
                    // Update payment link status in Firestore
                    const snapshot = await admin.firestore()
                        .collection("payment_links")
                        .where("paymentLinkId", "==", paymentLinkId)
                        .get();
                    if (!snapshot.empty) {
                        const doc = snapshot.docs[0];
                        await doc.ref.update({
                            status: "paid",
                            paidAt: admin.firestore.FieldValue.serverTimestamp(),
                            paymentId: (_d = (_c = event.payload.payment) === null || _c === void 0 ? void 0 : _c.entity) === null || _d === void 0 ? void 0 : _d.id,
                        });
                        console.log("Payment link marked as paid:", paymentLinkId);
                    }
                }
                break;
            case "payment_link.expired":
                console.log("Payment link expired");
                break;
            default:
                console.log("Unhandled webhook event:", event.event);
        }
        res.status(200).send("OK");
    }
    catch (error) {
        console.error("Webhook error:", error);
        res.status(500).send("Internal error");
    }
});
//# sourceMappingURL=index.js.map