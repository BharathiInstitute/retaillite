/**
 * Firebase Cloud Functions for LITE Retail App
 * 
 * Includes:
 * - createPaymentLink: Creates Razorpay payment links for sharing
 * - razorpayWebhook: Handles Razorpay payment status updates (signature-verified)
 * - sendRegistrationOTP: Sends email OTP for registration verification
 * - verifyRegistrationOTP: Verifies email OTP during registration
 * - onUserDeleted: Cleans up Firestore user document when Auth user is deleted
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as nodemailer from "nodemailer";

admin.initializeApp();

// ─── Email Config (Brevo) ───
const getEmailTransporter = () => {
    return nodemailer.createTransport({
        host: "smtp-relay.brevo.com",
        port: 587,
        secure: false,
        auth: {
            user: "a26d60001@smtp-brevo.com",
            pass: process.env.BREVO_API_KEY || "",
        },
    });
};


// ─── Razorpay Config ───
// Set in functions/.env file (auto-loaded by Firebase)
const getRazorpayConfig = () => {
    return {
        keyId: process.env.RAZORPAY_KEY_ID || "",
        keySecret: process.env.RAZORPAY_KEY_SECRET || "",
        webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET || "",
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

// ─── Pre-Registration Email OTP ───

/**
 * Send a 6-digit OTP to an email BEFORE account creation
 * No authentication required — used during registration
 */
export const sendRegistrationOTP = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 30, memory: "256MB" })
    .https.onCall(async (data: { email: string }) => {
        const email = data.email?.trim()?.toLowerCase();

        if (!email || !/^[^@]+@[^@]+\.[^@]+$/.test(email)) {
            return { success: false, error: "Please enter a valid email address" };
        }

        const db = admin.firestore();
        // Use email hash as document ID (safe for Firestore)
        const emailKey = crypto.createHash("sha256").update(email).digest("hex").substring(0, 20);
        const otpRef = db.collection("registration_otps").doc(emailKey);

        // Rate limit: 1 OTP per minute
        const existing = await otpRef.get();
        if (existing.exists) {
            const lastSent = existing.data()?.sentAt?.toDate();
            if (lastSent && Date.now() - lastSent.getTime() < 60000) {
                const waitSecs = Math.ceil((60000 - (Date.now() - lastSent.getTime())) / 1000);
                return {
                    success: false,
                    error: `Please wait ${waitSecs} seconds before requesting a new code`,
                };
            }
        }

        // Generate 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Store OTP with 10-minute expiry
        await otpRef.set({
            code: otp,
            email: email,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 10 * 60 * 1000),
            attempts: 0,
        });

        // Send email via Brevo
        try {
            const transporter = getEmailTransporter();
            await transporter.sendMail({
                from: `"Tulasi Stores" <${process.env.BREVO_EMAIL}>`,
                to: email,
                subject: "Your Verification Code - Tulasi Stores",
                html: `
                    <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f8faf8; border-radius: 12px;">
                        <div style="text-align: center; margin-bottom: 24px;">
                            <h2 style="color: #059669; margin: 0;">Tulasi Stores</h2>
                            <p style="color: #6b7280; font-size: 14px; margin-top: 4px;">Email Verification</p>
                        </div>
                        <div style="background: white; border-radius: 8px; padding: 24px; text-align: center; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                            <p style="color: #374151; font-size: 15px; margin-bottom: 16px;">Your verification code is:</p>
                            <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #059669; background: #ecfdf5; padding: 16px; border-radius: 8px; margin: 16px 0;">
                                ${otp}
                            </div>
                            <p style="color: #9ca3af; font-size: 13px; margin-top: 16px;">This code expires in <strong>10 minutes</strong></p>
                        </div>
                        <p style="color: #9ca3af; font-size: 12px; text-align: center; margin-top: 16px;">If you didn't request this, please ignore this email.</p>
                    </div>
                `,
            });

            console.log(`📧 Registration OTP sent to ${email}`);
            return { success: true };
        } catch (emailError: any) {
            console.error("Failed to send OTP email:", emailError);
            await otpRef.delete();
            const detail = emailError?.response || emailError?.message || "Unknown error";
            return {
                success: false,
                error: `Email sending failed: ${detail}`,
            };
        }
    });

/**
 * Verify pre-registration OTP
 * No authentication required — used during registration
 */
export const verifyRegistrationOTP = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 15, memory: "256MB" })
    .https.onCall(async (data: { email: string; otp: string }) => {
        const email = data.email?.trim()?.toLowerCase();
        const { otp } = data;

        if (!email || !otp || otp.length !== 6) {
            return { success: false, error: "Please enter a valid 6-digit code" };
        }

        const db = admin.firestore();
        const emailKey = crypto.createHash("sha256").update(email).digest("hex").substring(0, 20);
        const otpRef = db.collection("registration_otps").doc(emailKey);
        const otpDoc = await otpRef.get();

        if (!otpDoc.exists) {
            return { success: false, error: "No code found. Please request a new one." };
        }

        const otpData = otpDoc.data()!;

        // Check max attempts (5 tries)
        if (otpData.attempts >= 5) {
            await otpRef.delete();
            return { success: false, error: "Too many attempts. Please request a new code." };
        }

        // Check expiry
        const expiresAt = otpData.expiresAt?.toDate?.() || new Date(0);
        if (Date.now() > expiresAt.getTime()) {
            await otpRef.delete();
            return { success: false, error: "Code has expired. Please request a new one." };
        }

        // Increment attempts
        await otpRef.update({ attempts: admin.firestore.FieldValue.increment(1) });

        // Verify code
        if (otpData.code !== otp) {
            const remaining = 5 - (otpData.attempts + 1);
            return {
                success: false,
                error: `Incorrect code. ${remaining} attempt${remaining !== 1 ? "s" : ""} remaining.`,
            };
        }

        // OTP verified! Clean up
        await otpRef.delete();
        console.log(`✅ Registration OTP verified for ${email}`);
        return { success: true };
    });

// ─── Auth User Cleanup ───

/**
 * Automatically clean up Firestore user document when a user is deleted from Firebase Auth.
 * This frees up the phone number and prevents orphaned data.
 */
export const onUserDeleted = functions
    .region("asia-south1")
    .auth.user().onDelete(async (user) => {
        const uid = user.uid;
        const email = user.email || "unknown";
        console.log(`🗑️ Auth user deleted: ${email} (${uid}). Cleaning up Firestore...`);

        const db = admin.firestore();

        try {
            // Delete the user document from Firestore
            const userDoc = db.collection("users").doc(uid);
            const doc = await userDoc.get();

            if (doc.exists) {
                const data = doc.data();
                console.log(`🗑️ Deleting Firestore user doc: phone=${data?.phone}, shop=${data?.shopName}`);
                await userDoc.delete();
                console.log(`✅ Firestore user doc deleted for ${email}`);
            } else {
                console.log(`ℹ️ No Firestore user doc found for ${uid}`);
            }
        } catch (error) {
            console.error(`❌ Error cleaning up Firestore for ${uid}:`, error);
        }
    });
