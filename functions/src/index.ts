/**
 * Firebase Cloud Functions for LITE Retail App
 * 
 * Includes:
 * - createPaymentLink: Creates Razorpay payment links for sharing
 * - razorpayWebhook: Handles Razorpay payment status updates (signature-verified)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

admin.initializeApp();

// Razorpay API credentials (set via Firebase config)
// Run: firebase functions:config:set razorpay.key_id="rzp_xxx" razorpay.key_secret="xxx" razorpay.webhook_secret="xxx"
const getRazorpayConfig = () => {
    const config = functions.config();
    return {
        keyId: config.razorpay?.key_id || process.env.RAZORPAY_KEY_ID || "",
        keySecret: config.razorpay?.key_secret || process.env.RAZORPAY_KEY_SECRET || "",
        webhookSecret: config.razorpay?.webhook_secret || process.env.RAZORPAY_WEBHOOK_SECRET || "",
    };
};

interface PaymentLinkRequest {
    amount: number; // Amount in rupees
    customerName: string;
    customerPhone: string;
    customerEmail?: string;
    description: string;
    billId?: string;
    shopName?: string;
}

interface PaymentLinkResponse {
    success: boolean;
    paymentLink?: string;
    paymentLinkId?: string;
    shortUrl?: string;
    error?: string;
}

/**
 * Create a Razorpay Payment Link
 * 
 * This function creates a shareable payment link that customers can use
 * to pay via UPI, cards, or netbanking.
 */
export const createPaymentLink = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 30, memory: "256MB" })
    .https.onCall(
    async (data: PaymentLinkRequest, context): Promise<PaymentLinkResponse> => {
        // Verify authentication (optional but recommended)
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated to create payment links"
            );
        }

        // Validate input
        if (!data.amount || data.amount <= 0) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Amount must be greater than 0"
            );
        }

        if (!data.customerName || !data.customerPhone) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Customer name and phone are required"
            );
        }

        const razorpayConfig = getRazorpayConfig();

        // Check if Razorpay is configured
        if (!razorpayConfig.keyId || !razorpayConfig.keySecret) {
            console.error("Razorpay not configured:", {
                hasKeyId: !!razorpayConfig.keyId,
                hasKeySecret: !!razorpayConfig.keySecret
            });
            throw new functions.https.HttpsError(
                "failed-precondition",
                "Razorpay is not configured. Set razorpay.key_id and razorpay.key_secret"
            );
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

            const result = await response.json() as Record<string, unknown>;

            if (!response.ok) {
                console.error("Razorpay API error:", result);
                const errorDesc = (result.error as Record<string, unknown>)?.description as string || "Failed to create payment link";
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
            } catch (dbError) {
                console.warn("Failed to log payment link:", dbError);
            }

            return {
                success: true,
                paymentLink: result.short_url as string,
                paymentLinkId: result.id as string,
                shortUrl: result.short_url as string,
            };
        } catch (error) {
            console.error("Error creating payment link:", error);
            return {
                success: false,
                error: error instanceof Error ? error.message : "Unknown error",
            };
        }
    }
);

/**
 * Webhook handler for Razorpay payment status updates
 * 
 * Configure this URL in Razorpay Dashboard -> Settings -> Webhooks
 * IMPORTANT: Set the webhook secret via:
 *   firebase functions:config:set razorpay.webhook_secret="your_webhook_secret"
 */
export const razorpayWebhook = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 30, memory: "256MB" })
    .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
        res.status(405).send("Method not allowed");
        return;
    }

    try {
        // ─── Verify Razorpay webhook signature ───
        const razorpayConfig = getRazorpayConfig();
        const webhookSecret = razorpayConfig.webhookSecret;

        if (!webhookSecret) {
            console.error("Razorpay webhook secret not configured");
            res.status(500).send("Webhook secret not configured");
            return;
        }

        const signature = req.headers["x-razorpay-signature"] as string;
        if (!signature) {
            console.warn("Missing x-razorpay-signature header — rejecting request");
            res.status(401).send("Unauthorized: missing signature");
            return;
        }

        // Compute expected signature: HMAC-SHA256 of raw body with webhook secret
        const rawBody = typeof req.body === "string" ? req.body : JSON.stringify(req.body);
        const expectedSignature = crypto
            .createHmac("sha256", webhookSecret)
            .update(rawBody)
            .digest("hex");

        if (signature !== expectedSignature) {
            console.warn("Invalid webhook signature — possible spoofing attempt");
            res.status(401).send("Unauthorized: invalid signature");
            return;
        }
        // ─── Signature verified ───

        const event = req.body;

        console.log("Received webhook event:", event.event);

        // Handle payment events
        switch (event.event) {
            case "payment_link.paid":
                const paymentLinkId = event.payload.payment_link?.entity?.id;
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
                            paymentId: event.payload.payment?.entity?.id,
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
    } catch (error) {
        console.error("Webhook error:", error);
        res.status(500).send("Internal error");
    }
});
