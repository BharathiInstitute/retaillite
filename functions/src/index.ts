/**
 * Firebase Cloud Functions for LITE Retail App
 * 
 * Includes:
 * - createPaymentLink: Creates Razorpay payment links for sharing
 * - razorpayWebhook: Handles Razorpay payment status updates (signature-verified)
 * - sendRegistrationOTP: Sends email OTP for registration verification
 * - verifyRegistrationOTP: Verifies email OTP during registration
 * - onUserDeleted: Cleans up Firestore user document when Auth user is deleted
 * - generateDesktopToken: Custom auth token for Windows desktop sign-in
 * - onNewUserSignup: Welcome notification + admin alert on shop setup
 * - sendPushNotification: FCM push when notification doc is created
 * - cleanupOldNotifications: Scheduled daily cleanup of old read notifications
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
    .runWith({ timeoutSeconds: 30, memory: "256MB", maxInstances: 10 })
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
    .runWith({ timeoutSeconds: 30, memory: "256MB", maxInstances: 10 })
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
    .runWith({ timeoutSeconds: 30, memory: "256MB", maxInstances: 10 })
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
    .runWith({ timeoutSeconds: 15, memory: "256MB", maxInstances: 10 })
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

// ─── Desktop Auth Token ───

/**
 * Generate a custom auth token for desktop sign-in.
 * 
 * Called by the web auth page after user completes login + shop setup.
 * The desktop app polls Firestore for the token, then uses
 * signInWithCustomToken() to authenticate.
 * 
 * Flow:
 * 1. Desktop generates a linkCode, stores {status:"pending"} in Firestore
 * 2. Desktop opens web app /desktop-login?code=LINK_CODE
 * 3. User completes auth on web
 * 4. Web calls this function with the linkCode
 * 5. Function generates customToken and stores in Firestore
 * 6. Desktop polls Firestore, finds token, signs in
 */
export const generateDesktopToken = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 15, memory: "256MB", maxInstances: 10 })
    .https.onCall(async (data: { linkCode: string }, context) => {
        // Must be authenticated (web user just signed in)
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const { linkCode } = data;
        if (!linkCode || linkCode.length !== 6) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Invalid link code"
            );
        }

        const uid = context.auth.uid;
        const db = admin.firestore();

        try {
            // Verify the session exists and is pending
            const sessionRef = db.collection("desktop_auth_sessions").doc(linkCode);
            const session = await sessionRef.get();

            if (!session.exists) {
                throw new functions.https.HttpsError(
                    "not-found",
                    "Session not found. Please try again from the desktop app."
                );
            }

            const sessionData = session.data()!;
            if (sessionData.status !== "pending") {
                throw new functions.https.HttpsError(
                    "already-exists",
                    "This session has already been used."
                );
            }

            // Check session age (max 10 minutes)
            const createdAt = sessionData.createdAt?.toDate();
            if (createdAt && Date.now() - createdAt.getTime() > 10 * 60 * 1000) {
                await sessionRef.delete();
                throw new functions.https.HttpsError(
                    "deadline-exceeded",
                    "Session expired. Please try again from the desktop app."
                );
            }

            // Generate custom auth token
            const customToken = await admin.auth().createCustomToken(uid);

            // Store token in Firestore for desktop to pick up
            await sessionRef.update({
                status: "ready",
                customToken: customToken,
                uid: uid,
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`🖥️ Desktop auth token generated for user ${uid}, code: ${linkCode}`);

            return { success: true };
        } catch (error) {
            if (error instanceof functions.https.HttpsError) throw error;
            console.error("Error generating desktop token:", error);
            throw new functions.https.HttpsError(
                "internal",
                "Failed to generate auth token"
            );
        }
    });

// ─── Notification Cloud Functions ───

/**
 * Welcome notification when a new user completes shop setup.
 * Triggers on Firestore write when isShopSetupComplete changes to true.
 */
export const onNewUserSignup = functions
    .region("asia-south1")
    .firestore.document("users/{userId}")
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const userId = context.params.userId;

        // Only trigger when shop setup transitions from false → true
        if (before.isShopSetupComplete || !after.isShopSetupComplete) {
            return;
        }

        const db = admin.firestore();
        const shopName = after.shopName || "your shop";
        const ownerName = after.ownerName || "there";

        console.log(`🎉 New user completed setup: ${ownerName} (${shopName})`);

        // 1. Send welcome notification to the new user
        await db
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .add({
                title: "Welcome to Tulasi Shop Lite! 🎉",
                body: `Hi ${ownerName}, your shop "${shopName}" is all set up. Start adding products and making sales!`,
                type: "system",
                targetType: "user",
                targetUserId: userId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                sentBy: "system",
                read: false,
            });

        // 2. Notify all admins about the new signup
        const adminsSnapshot = await db
            .collection("admins")
            .get();

        const batch = db.batch();
        for (const adminDoc of adminsSnapshot.docs) {
            const adminNotifRef = db
                .collection("users")
                .doc(adminDoc.id)
                .collection("notifications")
                .doc();

            batch.set(adminNotifRef, {
                title: "New User Signup 🆕",
                body: `${ownerName} just created shop "${shopName}"`,
                type: "alert",
                targetType: "user",
                targetUserId: adminDoc.id,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                sentBy: "system",
                read: false,
            });
        }
        await batch.commit();

        // 3. Also log to global notifications collection
        await db.collection("notifications").add({
            title: "New User Signup",
            body: `${ownerName} created shop "${shopName}"`,
            type: "alert",
            targetType: "all",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            sentBy: "system",
        });

        console.log(`✅ Welcome + admin notifications sent for ${userId}`);
    });

/**
 * Send FCM push notification when a notification document is created.
 * Listens on the user's notifications subcollection.
 */
export const sendPushNotification = functions
    .region("asia-south1")
    .firestore.document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snapshot, context) => {
        const userId = context.params.userId;
        const data = snapshot.data();

        if (!data) return;

        const title = data.title || "New Notification";
        const body = data.body || "";

        // Get user's FCM tokens
        const userDoc = await admin.firestore()
            .collection("users")
            .doc(userId)
            .get();

        const fcmTokens = userDoc.data()?.fcmTokens as string[] | undefined;

        if (!fcmTokens || fcmTokens.length === 0) {
            console.log(`📱 No FCM tokens for user ${userId}, skipping push`);
            return;
        }

        console.log(`📱 Sending push to ${fcmTokens.length} device(s) for user ${userId}`);

        // Send to all user's devices
        const message: admin.messaging.MulticastMessage = {
            tokens: fcmTokens,
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: data.type || "system",
                notificationId: context.params.notificationId,
            },
            webpush: {
                fcmOptions: {
                    link: "/notifications",
                },
            },
        };

        try {
            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`📱 Push sent: ${response.successCount} success, ${response.failureCount} failures`);

            // Remove invalid tokens
            if (response.failureCount > 0) {
                const tokensToRemove: string[] = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success && resp.error?.code === "messaging/registration-token-not-registered") {
                        tokensToRemove.push(fcmTokens[idx]);
                    }
                });

                if (tokensToRemove.length > 0) {
                    await admin.firestore().collection("users").doc(userId).update({
                        fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
                    });
                    console.log(`🗑️ Removed ${tokensToRemove.length} stale FCM token(s)`);
                }
            }
        } catch (error) {
            console.error("❌ FCM send error:", error);
        }
    });

/**
 * Scheduled cleanup: delete read notifications older than 30 days.
 * Runs daily at midnight IST (18:30 UTC).
 */
export const cleanupOldNotifications = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 300, memory: "512MB", maxInstances: 3 })
    .pubsub.schedule("30 18 * * *") // 18:30 UTC = midnight IST
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
        const db = admin.firestore();
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

        console.log("🧹 Cleaning up old notifications...");

        // Get all users
        const usersSnapshot = await db.collection("users").get();
        let totalDeleted = 0;

        for (const userDoc of usersSnapshot.docs) {
            const oldNotifs = await db
                .collection("users")
                .doc(userDoc.id)
                .collection("notifications")
                .where("read", "==", true)
                .where("createdAt", "<", thirtyDaysAgo)
                .limit(100)
                .get();

            if (!oldNotifs.empty) {
                const batch = db.batch();
                oldNotifs.docs.forEach((doc) => batch.delete(doc.ref));
                await batch.commit();
                totalDeleted += oldNotifs.size;
            }
        }

        console.log(`🧹 Cleaned up ${totalDeleted} old notifications`);
    });

// ─── Automated Notification Triggers ───

/**
 * Low Stock Alert — triggers when a product's stock is updated.
 * Sends notification if stock falls at or below lowStockAlert threshold.
 * Respects user's settings.lowStockAlerts preference.
 */
export const checkLowStock = functions
    .region("asia-south1")
    .firestore.document("users/{userId}/products/{productId}")
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const userId = context.params.userId;

        const newStock = after.stock as number;
        const oldStock = before.stock as number;
        const threshold = (after.lowStockAlert as number | null) ?? 5;
        const productName = after.name || "Product";

        // Only trigger if stock dropped and is now at/below threshold
        if (newStock >= oldStock || newStock > threshold) {
            return;
        }

        // Check user preference
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        const settings = userDoc.data()?.settings || {};
        if (settings.lowStockAlerts === false) {
            console.log(`🔕 Low stock alerts disabled for user ${userId}`);
            return;
        }

        const isOutOfStock = newStock <= 0;
        const title = isOutOfStock
            ? `Out of Stock! ❌`
            : `Low Stock Alert ⚠️`;
        const body = isOutOfStock
            ? `${productName} is now out of stock. Reorder immediately!`
            : `${productName} has only ${newStock} left (threshold: ${threshold}). Consider reordering.`;

        console.log(`📦 ${title}: ${productName} (${newStock} remaining) for user ${userId}`);

        await admin.firestore()
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .add({
                title,
                body,
                type: "alert",
                targetType: "user",
                targetUserId: userId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                sentBy: "system",
                read: false,
                data: {
                    trigger: "low_stock",
                    productId: context.params.productId,
                    productName,
                    stock: newStock,
                    threshold,
                },
            });
    });

/**
 * Subscription Expiry Reminder — runs daily at 10 AM IST (4:30 UTC).
 * Sends reminder to users whose subscription expires within 7 days.
 * Respects user's settings.subscriptionAlerts preference.
 */
export const checkSubscriptionExpiry = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 300, memory: "256MB" })
    .pubsub.schedule("30 4 * * *") // 4:30 UTC = 10 AM IST
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
        const db = admin.firestore();
        const now = new Date();

        console.log("📋 Checking subscription expiry...");

        // Get users with active subscriptions expiring in next 7 days
        const usersSnapshot = await db
            .collection("users")
            .where("subscription.status", "==", "active")
            .get();

        let sentCount = 0;

        for (const userDoc of usersSnapshot.docs) {
            const data = userDoc.data();
            const settings = data.settings || {};

            // Check user preference
            if (settings.subscriptionAlerts === false) continue;

            const expiresAt = data.subscription?.expiresAt?.toDate();
            if (!expiresAt) continue;

            // Check if expiring within 7 days
            const daysUntilExpiry = Math.ceil((expiresAt.getTime() - now.getTime()) / (24 * 60 * 60 * 1000));
            if (daysUntilExpiry > 7 || daysUntilExpiry < 0) continue;

            const planName = data.subscription?.plan || "Free";

            const title = daysUntilExpiry <= 1
                ? "Subscription Expires Today! ⏰"
                : `Subscription Expiring in ${daysUntilExpiry} Days ⚠️`;
            const body = daysUntilExpiry <= 1
                ? `Your ${planName} plan expires today. Renew now to keep your premium features!`
                : `Your ${planName} plan expires in ${daysUntilExpiry} days. Renew to avoid losing access.`;

            // Avoid duplicate alerts — check if already sent today
            const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            const existing = await db
                .collection("users")
                .doc(userDoc.id)
                .collection("notifications")
                .where("data.trigger", "==", "subscription_expiry")
                .where("createdAt", ">=", todayStart)
                .limit(1)
                .get();

            if (!existing.empty) continue;

            await db
                .collection("users")
                .doc(userDoc.id)
                .collection("notifications")
                .add({
                    title,
                    body,
                    type: "reminder",
                    targetType: "user",
                    targetUserId: userDoc.id,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    sentBy: "system",
                    read: false,
                    data: {
                        trigger: "subscription_expiry",
                        daysUntilExpiry,
                        plan: planName,
                    },
                });

            sentCount++;
        }

        console.log(`📋 Sent ${sentCount} subscription expiry reminder(s)`);
    });

/**
 * Daily Sales Summary — runs daily at 9 PM IST (15:30 UTC).
 * Sends summary of today's sales to each user.
 * Respects user's settings.dailySummary preference.
 */
export const sendDailySalesSummary = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 300, memory: "512MB" })
    .pubsub.schedule("30 15 * * *") // 15:30 UTC = 9 PM IST
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
        const db = admin.firestore();
        const now = new Date();
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

        console.log("📊 Generating daily sales summaries...");

        const usersSnapshot = await db.collection("users").get();
        let sentCount = 0;

        for (const userDoc of usersSnapshot.docs) {
            const settings = userDoc.data().settings || {};

            // Check user preference
            if (settings.dailySummary === false) continue;

            // Get today's bills for this user
            const billsSnapshot = await db
                .collection("users")
                .doc(userDoc.id)
                .collection("bills")
                .where("createdAt", ">=", todayStart)
                .where("createdAt", "<", todayEnd)
                .get();

            const totalBills = billsSnapshot.size;
            if (totalBills === 0) continue; // Skip if no sales today

            let totalRevenue = 0;
            for (const bill of billsSnapshot.docs) {
                totalRevenue += (bill.data().total as number) || 0;
            }

            const title = "Daily Sales Summary 📊";
            const body = `Today: ${totalBills} bill(s) totaling ₹${totalRevenue.toFixed(2)}. Keep up the great work!`;

            await db
                .collection("users")
                .doc(userDoc.id)
                .collection("notifications")
                .add({
                    title,
                    body,
                    type: "system",
                    targetType: "user",
                    targetUserId: userDoc.id,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    sentBy: "system",
                    read: false,
                    data: {
                        trigger: "daily_summary",
                        totalBills,
                        totalRevenue,
                        date: todayStart.toISOString().split("T")[0],
                    },
                });

            sentCount++;
        }

        console.log(`📊 Sent ${sentCount} daily sales summary(ies)`);
    });

// ─── Scheduled Firestore Backup ───

/**
 * Daily automated Firestore export at 2 AM IST (20:30 UTC).
 * Exports all collections to Google Cloud Storage for disaster recovery.
 *
 * Prerequisites:
 *   1. Create a GCS bucket: gsutil mb gs://YOUR_PROJECT_ID-backups
 *   2. Grant the default service account the "Cloud Datastore Import Export Admin" role
 *      and "Storage Admin" on the backup bucket:
 *        gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
 *          --member=serviceAccount:YOUR_PROJECT_ID@appspot.gserviceaccount.com \
 *          --role=roles/datastore.importExportAdmin
 *        gsutil iam ch serviceAccount:YOUR_PROJECT_ID@appspot.gserviceaccount.com:admin \
 *          gs://YOUR_PROJECT_ID-backups
 */
export const scheduledFirestoreBackup = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 300, memory: "256MB", maxInstances: 1 })
    .pubsub.schedule("30 20 * * *") // 20:30 UTC = 2:00 AM IST
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
        const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
        if (!projectId) {
            console.error("❌ Firestore backup: Could not determine project ID");
            return;
        }

        const bucket = `gs://${projectId}-backups`;
        const today = new Date().toISOString().split("T")[0]; // e.g. 2026-02-24
        const outputUri = `${bucket}/firestore-daily/${today}`;

        console.log(`💾 Starting Firestore backup to ${outputUri}...`);

        try {
            // Use the Firestore Admin REST API to trigger an export
            const accessToken = await admin.credential.applicationDefault()
                .getAccessToken();

            const response = await fetch(
                `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default):exportDocuments`,
                {
                    method: "POST",
                    headers: {
                        "Authorization": `Bearer ${accessToken.access_token}`,
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        outputUriPrefix: outputUri,
                        // Empty collectionIds = export ALL collections
                        collectionIds: [],
                    }),
                }
            );

            if (!response.ok) {
                const errorBody = await response.text();
                console.error(`❌ Firestore backup failed (${response.status}):`, errorBody);
                return;
            }

            const result = await response.json() as Record<string, unknown>;
            console.log(`✅ Firestore backup started successfully:`, result.name);
        } catch (error) {
            console.error("❌ Firestore backup error:", error);
        }
    });

// ─── Windows Desktop Email/Password Auth ───

/**
 * Exchange a Firebase Auth REST API idToken for a custom token.
 * 
 * On Windows desktop, signInWithEmailAndPassword fails with unknown-error
 * due to a buggy platform channel. The workaround:
 * 1. Desktop calls Firebase Auth REST API to verify email/password
 * 2. REST API returns an idToken
 * 3. Desktop calls this function to exchange idToken for customToken
 * 4. Desktop calls signInWithCustomToken(customToken) to establish session
 * 
 * No auth required since the user isn't signed in yet on desktop.
 */
export const exchangeIdToken = functions
    .region("asia-south1")
    .runWith({ timeoutSeconds: 15, memory: "256MB", maxInstances: 10 })
    .https.onCall(async (data: { idToken: string }) => {
        const { idToken } = data;

        if (!idToken) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "idToken is required"
            );
        }

        try {
            // Verify the idToken to get the user's UID
            const decodedToken = await admin.auth().verifyIdToken(idToken);
            const uid = decodedToken.uid;

            console.log(`🖥️ Exchanging idToken for customToken, uid: ${uid}`);

            // Generate a custom token for this user
            const customToken = await admin.auth().createCustomToken(uid);

            return { customToken };
        } catch (error) {
            console.error("❌ exchangeIdToken error:", error);
            throw new functions.https.HttpsError(
                "internal",
                "Failed to exchange token. Please try again."
            );
        }
    });
