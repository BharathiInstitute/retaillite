/**
 * Emulator Verification Script
 *
 * Verifies Cloud Functions triggers work correctly in the Firebase emulator.
 * Run with: firebase emulators:exec "cd functions && npx ts-node src/__tests__/emulator-verify.ts" --only firestore,functions
 *
 * Tests:
 * 1. onSubscriptionWrite — creates a user doc, checks stats aggregation
 * 2. Rate limit / customer limit (already verified in rules tests)
 */

import * as admin from "firebase-admin";

// Point to emulator
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

const app = admin.initializeApp({ projectId: "login-radha" });
const db = admin.firestore();

async function sleep(ms: number) {
  return new Promise((res) => setTimeout(res, ms));
}

async function verifyOnSubscriptionWrite(): Promise<boolean> {
  console.log("\n═══ Test 1: onSubscriptionWrite aggregation ═══");

  // Clear any existing stats
  try {
    await db.collection("app_config").doc("stats").delete();
  } catch {
    // ok if doesn't exist
  }

  // Create a new user (should trigger onSubscriptionWrite)
  const userId = "emulator-test-user-" + Date.now();
  console.log(`  Creating user ${userId} with plan=pro, status=active...`);

  await db.collection("users").doc(userId).set({
    name: "Emulator Test User",
    email: "emulator@test.com",
    subscription: { plan: "pro", status: "active" },
    limits: {
      billsThisMonth: 0,
      billsLimit: 500,
      productsCount: 5,
      productsLimit: 5000,
      customersCount: 2,
      customersLimit: 1000,
    },
    activity: { platform: "android" },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Wait for the trigger to fire
  console.log("  Waiting 5s for trigger to fire...");
  await sleep(5000);

  // Check stats doc
  const statsDoc = await db.collection("app_config").doc("stats").get();
  if (!statsDoc.exists) {
    console.log("  ❌ FAIL: stats doc does not exist after user creation");
    return false;
  }

  const stats = statsDoc.data()!;
  console.log("  Stats doc:", JSON.stringify(stats, null, 2));

  const checks = [
    { field: "totalUsers", expected: 1, actual: stats.totalUsers },
    { field: "proUsers", expected: 1, actual: stats.proUsers },
    { field: "mrr", expected: 299, actual: stats.mrr },
  ];

  let allPassed = true;
  for (const c of checks) {
    if (c.actual === c.expected) {
      console.log(`  ✅ ${c.field} = ${c.actual}`);
    } else {
      console.log(`  ❌ ${c.field} = ${c.actual} (expected ${c.expected})`);
      allPassed = false;
    }
  }

  // Now update the plan: pro → business
  console.log("\n  Upgrading user to business plan...");
  await db.collection("users").doc(userId).update({
    "subscription.plan": "business",
  });
  await sleep(5000);

  const statsAfter = (await db.collection("app_config").doc("stats").get()).data()!;
  console.log("  Stats after upgrade:", JSON.stringify(statsAfter, null, 2));

  const upgradeChecks = [
    { field: "proUsers", expected: 0, actual: statsAfter.proUsers },
    { field: "businessUsers", expected: 1, actual: statsAfter.businessUsers },
    { field: "mrr", expected: 999, actual: statsAfter.mrr },
  ];

  for (const c of upgradeChecks) {
    if (c.actual === c.expected) {
      console.log(`  ✅ ${c.field} = ${c.actual}`);
    } else {
      console.log(`  ❌ ${c.field} = ${c.actual} (expected ${c.expected})`);
      allPassed = false;
    }
  }

  // Cleanup
  await db.collection("users").doc(userId).delete();
  await sleep(3000);

  return allPassed;
}

async function main() {
  console.log("🔥 Firebase Emulator Verification");
  console.log("=".repeat(50));

  let exitCode = 0;

  try {
    const result1 = await verifyOnSubscriptionWrite();
    console.log(result1 ? "\n✅ onSubscriptionWrite: PASSED" : "\n❌ onSubscriptionWrite: FAILED");
    if (!result1) exitCode = 1;
  } catch (err) {
    console.error("Error:", err);
    exitCode = 1;
  }

  // Cleanup
  await app.delete();
  process.exit(exitCode);
}

main();
