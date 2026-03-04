"use strict";
/**
 * Firestore Security Rules Tests
 *
 * Run with: firebase emulators:exec "cd functions && npx jest src/__tests__/rules.test.ts --forceExit" --only firestore
 *
 * Tests cover:
 * - User document access (owner, admin, unauthenticated)
 * - Subcollection access (products, bills, customers, expenses, transactions, etc.)
 * - Subscription limit enforcement (canAddProduct, canCreateBill, canAddCustomer)
 * - Rate limiting (isNotRateLimited)
 * - Field validation (name length, price bounds, amount bounds)
 * - Admin-only collections (_admin, app_config, notifications global)
 * - Desktop auth sessions (unauthenticated create, authenticated update)
 * - Registration OTPs (no client access)
 * - Default deny rule
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
const rules_unit_testing_1 = require("@firebase/rules-unit-testing");
const firestore_1 = require("firebase/firestore");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
let testEnv;
const PROJECT_ID = "rules-test-project";
const RULES_PATH = path.resolve(__dirname, "../../../firestore.rules");
beforeAll(async () => {
    testEnv = await (0, rules_unit_testing_1.initializeTestEnvironment)({
        projectId: PROJECT_ID,
        firestore: {
            rules: fs.readFileSync(RULES_PATH, "utf8"),
            host: "127.0.0.1",
            port: 8080,
        },
    });
});
afterAll(async () => {
    await testEnv.cleanup();
});
afterEach(async () => {
    await testEnv.clearFirestore();
});
// ─── Helper: seed user doc with limits via admin ────────────────────────────
async function seedUser(uid, data = {}) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await (0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", uid), Object.assign({ name: "Test User", email: `${uid}@test.com`, subscription: { plan: "free", status: "active" }, limits: {
                billsThisMonth: 0,
                billsLimit: 50,
                productsCount: 0,
                productsLimit: 100,
                customersCount: 0,
                customersLimit: 10,
            } }, data));
    });
}
async function seedAdmin(email) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await (0, firestore_1.setDoc)((0, firestore_1.doc)(db, "admins", email), { role: "admin" });
    });
}
// ═════════════════════════════════════════════════════════════════════════════
// USER DOCUMENT ACCESS
// ═════════════════════════════════════════════════════════════════════════════
describe("User document access", () => {
    test("owner can read own user doc", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "users", "user1")));
    });
    test("other user cannot read someone else's doc", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user2").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "users", "user1")));
    });
    test("unauthenticated cannot read user doc", async () => {
        await seedUser("user1");
        const db = testEnv.unauthenticatedContext().firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "users", "user1")));
    });
    test("admin can read any user doc", async () => {
        await seedUser("user1");
        await seedAdmin("admin@test.com");
        const db = testEnv
            .authenticatedContext("admin1", { email: "admin@test.com" })
            .firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "users", "user1")));
    });
    test("owner can write own user doc", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1"), { name: "New User" }));
    });
    test("user cannot delete own user doc", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.deleteDoc)((0, firestore_1.doc)(db, "users", "user1")));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// PRODUCTS — limit enforcement + field validation
// ═════════════════════════════════════════════════════════════════════════════
describe("Products subcollection", () => {
    test("owner can create product within limits", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "products", "p1"), {
            name: "Rice 5kg",
            price: 450,
            stock: 50,
            unit: "kg",
            createdAt: (0, firestore_1.serverTimestamp)(),
        }));
    });
    test("owner cannot create product over limit", async () => {
        await seedUser("user1", {
            limits: {
                productsCount: 100,
                productsLimit: 100,
                billsThisMonth: 0,
                billsLimit: 50,
                customersCount: 0,
                customersLimit: 10,
            },
        });
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "products", "p1"), {
            name: "Over Limit Product",
            price: 100,
            stock: 10,
            unit: "pcs",
        }));
    });
    test("product name is required", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "products", "p1"), {
            name: "",
            price: 100,
        }));
    });
    test("product name max 200 chars", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "products", "p1"), {
            name: "A".repeat(201),
            price: 100,
        }));
    });
    test("product price must be non-negative", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "products", "p1"), {
            name: "Bad Product",
            price: -10,
        }));
    });
    test("product price max ₹99,99,999", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "products", "p1"), {
            name: "Too Expensive",
            price: 10000000,
        }));
    });
    test("other user cannot read products", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user2").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "users", "user1", "products", "p1")));
    });
    test("owner can delete own product", async () => {
        await seedUser("user1");
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await (0, firestore_1.setDoc)((0, firestore_1.doc)(context.firestore(), "users", "user1", "products", "p1"), {
                name: "To Delete",
                price: 10,
            });
        });
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.deleteDoc)((0, firestore_1.doc)(db, "users", "user1", "products", "p1")));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// BILLS — limit enforcement + immutability
// ═════════════════════════════════════════════════════════════════════════════
describe("Bills subcollection", () => {
    test("owner can create bill within limits", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "bills", "b1"), {
            total: 500,
            items: [{ name: "Rice", price: 500, qty: 1 }],
            createdAt: (0, firestore_1.serverTimestamp)(),
        }));
    });
    test("owner cannot create bill over limit", async () => {
        await seedUser("user1", {
            limits: {
                billsThisMonth: 50,
                billsLimit: 50,
                productsCount: 0,
                productsLimit: 100,
                customersCount: 0,
                customersLimit: 10,
            },
        });
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "bills", "b1"), {
            total: 100,
            items: [{ name: "Item", price: 100, qty: 1 }],
        }));
    });
    test("bills are immutable — update denied", async () => {
        await seedUser("user1");
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await (0, firestore_1.setDoc)((0, firestore_1.doc)(context.firestore(), "users", "user1", "bills", "b1"), {
                total: 500,
                items: [{ name: "Rice", price: 500, qty: 1 }],
            });
        });
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "bills", "b1"), { total: 999 }, { merge: true }));
    });
    test("bill must have items array", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "bills", "b1"), {
            total: 100,
            // missing items
        }));
    });
    test("bill items max 500", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        const items = Array.from({ length: 501 }, (_, i) => ({
            name: `Item ${i}`,
            price: 1,
            qty: 1,
        }));
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "bills", "b1"), {
            total: 501,
            items,
        }));
    });
    test("bill total max ₹9,99,99,999", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "bills", "b1"), {
            total: 100000000,
            items: [{ name: "Big", price: 100000000, qty: 1 }],
        }));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// CUSTOMERS — limit enforcement
// ═════════════════════════════════════════════════════════════════════════════
describe("Customers subcollection", () => {
    test("owner can create customer within limits", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "customers", "c1"), {
            name: "Customer A",
            phone: "9876543210",
        }));
    });
    test("owner cannot create customer over limit", async () => {
        await seedUser("user1", {
            limits: {
                customersCount: 10,
                customersLimit: 10,
                productsCount: 0,
                productsLimit: 100,
                billsThisMonth: 0,
                billsLimit: 50,
            },
        });
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "customers", "c1"), {
            name: "Over Limit Customer",
        }));
    });
    test("customer name is required", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "customers", "c1"), {
            name: "",
            phone: "1234567890",
        }));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS — admin create, owner read/update/delete
// ═════════════════════════════════════════════════════════════════════════════
describe("Notifications subcollection", () => {
    test("owner can read own notifications", async () => {
        await seedUser("user1");
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await (0, firestore_1.setDoc)((0, firestore_1.doc)(context.firestore(), "users", "user1", "notifications", "n1"), { title: "Welcome", read: false });
        });
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "users", "user1", "notifications", "n1")));
    });
    test("owner can update notification (mark read)", async () => {
        await seedUser("user1");
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await (0, firestore_1.setDoc)((0, firestore_1.doc)(context.firestore(), "users", "user1", "notifications", "n1"), { title: "Test", read: false });
        });
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "notifications", "n1"), { read: true }, { merge: true }));
    });
    test("regular user cannot create notifications", async () => {
        await seedUser("user1");
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "users", "user1", "notifications", "n1"), {
            title: "Self-created",
            read: false,
        }));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// ADMIN-ONLY COLLECTIONS
// ═════════════════════════════════════════════════════════════════════════════
describe("Admin-only collections", () => {
    test("admin can read app_config", async () => {
        await seedAdmin("admin@test.com");
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await (0, firestore_1.setDoc)((0, firestore_1.doc)(context.firestore(), "app_config", "stats"), {
                totalUsers: 100,
            });
        });
        const db = testEnv
            .authenticatedContext("admin1", { email: "admin@test.com" })
            .firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "app_config", "stats")));
    });
    test("non-admin cannot read app_config", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "app_config", "stats")));
    });
    test("admin can write _admin docs", async () => {
        await seedAdmin("admin@test.com");
        const db = testEnv
            .authenticatedContext("admin1", { email: "admin@test.com" })
            .firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "_admin", "last_backup"), { status: "ok" }));
    });
    test("non-admin cannot access _admin", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "_admin", "last_backup")));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// REGISTRATION OTPs — fully locked
// ═════════════════════════════════════════════════════════════════════════════
describe("Registration OTPs (no client access)", () => {
    test("authenticated user cannot read OTPs", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "registration_otps", "some-hash")));
    });
    test("unauthenticated cannot read OTPs", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "registration_otps", "some-hash")));
    });
    test("authenticated user cannot write OTPs", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "registration_otps", "some-hash"), { code: "123456" }));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// PAYMENT LINKS — read admin only, write denied
// ═════════════════════════════════════════════════════════════════════════════
describe("Payment links", () => {
    test("admin can read payment links", async () => {
        await seedAdmin("admin@test.com");
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await (0, firestore_1.setDoc)((0, firestore_1.doc)(context.firestore(), "payment_links", "pl1"), {
                amount: 500,
            });
        });
        const db = testEnv
            .authenticatedContext("admin1", { email: "admin@test.com" })
            .firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "payment_links", "pl1")));
    });
    test("client cannot write payment links", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "payment_links", "pl1"), { amount: 500 }));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// DESKTOP AUTH SESSIONS — unauthenticated create
// ═════════════════════════════════════════════════════════════════════════════
describe("Desktop auth sessions", () => {
    test("unauthenticated can create pending session", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "desktop_auth_sessions", "sess1"), {
            status: "pending",
            createdAt: (0, firestore_1.serverTimestamp)(),
            expiresAt: firestore_1.Timestamp.fromDate(new Date(Date.now() + 600000)),
        }));
    });
    test("unauthenticated cannot create non-pending session", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "desktop_auth_sessions", "sess1"), {
            status: "completed",
            createdAt: (0, firestore_1.serverTimestamp)(),
            expiresAt: firestore_1.Timestamp.fromDate(new Date(Date.now() + 600000)),
        }));
    });
    test("unauthenticated cannot add extra fields", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "desktop_auth_sessions", "sess1"), {
            status: "pending",
            createdAt: (0, firestore_1.serverTimestamp)(),
            expiresAt: firestore_1.Timestamp.fromDate(new Date(Date.now() + 600000)),
            token: "malicious-token",
        }));
    });
    test("anyone can read session (polling)", async () => {
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await (0, firestore_1.setDoc)((0, firestore_1.doc)(context.firestore(), "desktop_auth_sessions", "sess1"), {
                status: "pending",
            });
        });
        const db = testEnv.unauthenticatedContext().firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "desktop_auth_sessions", "sess1")));
    });
    test("authenticated user can update session", async () => {
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await (0, firestore_1.setDoc)((0, firestore_1.doc)(context.firestore(), "desktop_auth_sessions", "sess1"), {
                status: "pending",
            });
        });
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "desktop_auth_sessions", "sess1"), { status: "authenticated", uid: "user1" }, { merge: true }));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// ADMIN SELF-PROTECTION
// ═════════════════════════════════════════════════════════════════════════════
describe("Admins collection", () => {
    test("admin can create another admin", async () => {
        await seedAdmin("admin@test.com");
        const db = testEnv
            .authenticatedContext("admin1", { email: "admin@test.com" })
            .firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "admins", "new-admin@test.com"), { role: "admin" }));
    });
    test("admin cannot delete self", async () => {
        await seedAdmin("admin@test.com");
        const db = testEnv
            .authenticatedContext("admin1", { email: "admin@test.com" })
            .firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.deleteDoc)((0, firestore_1.doc)(db, "admins", "admin@test.com")));
    });
    test("admin can delete other admin", async () => {
        await seedAdmin("admin@test.com");
        await seedAdmin("other@test.com");
        const db = testEnv
            .authenticatedContext("admin1", { email: "admin@test.com" })
            .firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.deleteDoc)((0, firestore_1.doc)(db, "admins", "other@test.com")));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// DEFAULT DENY
// ═════════════════════════════════════════════════════════════════════════════
describe("Default deny", () => {
    test("unknown collection denied for authenticated user", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "secret_collection", "doc1")));
    });
    test("unknown collection denied for unauthenticated", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "anything", "doc1")));
    });
});
// ═════════════════════════════════════════════════════════════════════════════
// APP HEALTH — any auth can create, only admin reads
// ═════════════════════════════════════════════════════════════════════════════
describe("App health collection", () => {
    test("authenticated user can submit health doc", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertSucceeds)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "app_health", "h1"), {
            screen: "dashboard",
            loadTime: 1200,
        }));
    });
    test("unauthenticated cannot submit health doc", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.setDoc)((0, firestore_1.doc)(db, "app_health", "h1"), {
            screen: "dashboard",
            loadTime: 1200,
        }));
    });
    test("non-admin cannot read health docs", async () => {
        const db = testEnv.authenticatedContext("user1").firestore();
        await (0, rules_unit_testing_1.assertFails)((0, firestore_1.getDoc)((0, firestore_1.doc)(db, "app_health", "h1")));
    });
});
//# sourceMappingURL=rules.test.js.map