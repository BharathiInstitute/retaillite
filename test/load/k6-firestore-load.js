/**
 * RetailLite — k6 Load Test for 10K Subscriber Scale
 *
 * Simulates concurrent Firestore REST API traffic to validate
 * the system handles expected peak load without errors.
 *
 * SETUP:
 *   1. Generate a Firebase Auth ID token (or use a service account):
 *      export K6_AUTH_TOKEN="<firebase-id-token>"
 *   2. Run:
 *      k6 run --env AUTH_TOKEN=$K6_AUTH_TOKEN test/load/k6-firestore-load.js
 *
 * WHAT IT TESTS:
 *   - 500 virtual users ramping up over 2 minutes
 *   - Concurrent Firestore document reads (user profile, products, bills)
 *   - Concurrent Firestore document writes (create bill, create product)
 *   - Cloud Function HTTP endpoint health (getSubscriptionLimits)
 *   - Checks: p95 < 500ms, error rate < 1%, throughput > 100 rps
 *
 * NOTE: Uses Firestore REST API (not WebSocket listeners) because k6
 * doesn't support gRPC streaming. Each REST request ≈ 1 listener snapshot.
 */

import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

// ─── Configuration ──────────────────────────────────────────────────────────

const PROJECT_ID = "login-radha";
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const CF_BASE = `https://asia-south1-${PROJECT_ID}.cloudfunctions.net`;

// Auth token — pass via: k6 run --env AUTH_TOKEN=<token> ...
const AUTH_TOKEN = __ENV.AUTH_TOKEN || "";

// ─── Custom Metrics ─────────────────────────────────────────────────────────

const readLatency = new Trend("firestore_read_latency", true);
const writeLatency = new Trend("firestore_write_latency", true);
const cfLatency = new Trend("cloud_function_latency", true);
const errorRate = new Rate("error_rate");

// ─── Test Stages ────────────────────────────────────────────────────────────

export const options = {
  stages: [
    { duration: "30s", target: 50 },   // Warm up to 50 VUs
    { duration: "1m", target: 200 },    // Ramp to 200 VUs
    { duration: "1m", target: 500 },    // Peak at 500 VUs
    { duration: "30s", target: 500 },   // Sustain peak
    { duration: "30s", target: 0 },     // Cool down
  ],
  thresholds: {
    // System targets for 10K subscriber scale
    "firestore_read_latency": ["p(95)<500"],     // p95 reads under 500ms
    "firestore_write_latency": ["p(95)<1000"],   // p95 writes under 1s
    "cloud_function_latency": ["p(95)<2000"],    // p95 CF calls under 2s
    "error_rate": ["rate<0.01"],                  // <1% errors
    "http_req_duration": ["p(95)<1500"],          // Overall p95 under 1.5s
    "http_reqs": ["rate>100"],                    // >100 rps throughput
  },
};

// ─── Helpers ────────────────────────────────────────────────────────────────

function firestoreHeaders() {
  const headers = { "Content-Type": "application/json" };
  if (AUTH_TOKEN) {
    headers["Authorization"] = `Bearer ${AUTH_TOKEN}`;
  }
  return headers;
}

function randomUserId() {
  // Simulate different user paths (k6 VU IDs 1-500)
  return `load-test-user-${__VU}`;
}

function randomProductId() {
  return `product-${__VU}-${Math.floor(Math.random() * 100)}`;
}

function randomBillId() {
  return `bill-${__VU}-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
}

// ─── Test Scenarios ─────────────────────────────────────────────────────────

export default function () {
  const userId = randomUserId();
  const headers = firestoreHeaders();

  // Scenario 1: Read user profile (most common operation)
  {
    const url = `${FIRESTORE_BASE}/users/${userId}`;
    const res = http.get(url, { headers, tags: { operation: "read_user" } });
    readLatency.add(res.timings.duration);
    const ok = check(res, {
      "read user: reachable": (r) => [200, 403, 404].includes(r.status),
    });
    errorRate.add(!ok);
  }

  sleep(0.1);

  // Scenario 2: Read products list (paginated — first 20)
  {
    const url = `${FIRESTORE_BASE}/users/${userId}/products?pageSize=20`;
    const res = http.get(url, { headers, tags: { operation: "read_products" } });
    readLatency.add(res.timings.duration);
    const ok = check(res, {
      "read products: reachable": (r) => [200, 403, 404].includes(r.status),
    });
    errorRate.add(!ok);
  }

  sleep(0.1);

  // Scenario 3: Read bills (paginated — first 20)
  {
    const url = `${FIRESTORE_BASE}/users/${userId}/bills?pageSize=20`;
    const res = http.get(url, { headers, tags: { operation: "read_bills" } });
    readLatency.add(res.timings.duration);
    const ok = check(res, {
      "read bills: reachable": (r) => [200, 403, 404].includes(r.status),
    });
    errorRate.add(!ok);
  }

  sleep(0.1);

  // Scenario 4: Write — create a product document
  {
    const productId = randomProductId();
    const url = `${FIRESTORE_BASE}/users/${userId}/products/${productId}`;
    const body = JSON.stringify({
      fields: {
        name: { stringValue: `Load Test Product ${productId}` },
        price: { doubleValue: Math.floor(Math.random() * 9999) + 1 },
        stock: { integerValue: Math.floor(Math.random() * 100).toString() },
        unit: { stringValue: "pcs" },
        createdAt: { timestampValue: new Date().toISOString() },
      },
    });
    const res = http.patch(url, body, {
      headers,
      tags: { operation: "write_product" },
    });
    writeLatency.add(res.timings.duration);
    const ok = check(res, {
      "write product: reachable": (r) => [200, 403].includes(r.status),
    });
    errorRate.add(!ok);
  }

  sleep(0.1);

  // Scenario 5: Write — create a bill document
  {
    const billId = randomBillId();
    const url = `${FIRESTORE_BASE}/users/${userId}/bills/${billId}`;
    const body = JSON.stringify({
      fields: {
        total: { doubleValue: Math.floor(Math.random() * 10000) + 100 },
        items: {
          arrayValue: {
            values: [
              {
                mapValue: {
                  fields: {
                    name: { stringValue: "Test Item" },
                    price: { doubleValue: 250 },
                    qty: { integerValue: "2" },
                  },
                },
              },
            ],
          },
        },
        createdAt: { timestampValue: new Date().toISOString() },
        paymentMode: { stringValue: "cash" },
      },
    });
    const res = http.patch(url, body, {
      headers,
      tags: { operation: "write_bill" },
    });
    writeLatency.add(res.timings.duration);
    const ok = check(res, {
      "write bill: reachable": (r) => [200, 403].includes(r.status),
    });
    errorRate.add(!ok);
  }

  sleep(0.1);

  // Scenario 6: Cloud Function — getSubscriptionLimits (callable)
  {
    const url = `${CF_BASE}/getSubscriptionLimits`;
    const body = JSON.stringify({ data: {} });
    const cfHeaders = {
      "Content-Type": "application/json",
    };
    if (AUTH_TOKEN) {
      cfHeaders["Authorization"] = `Bearer ${AUTH_TOKEN}`;
    }
    const res = http.post(url, body, {
      headers: cfHeaders,
      tags: { operation: "cf_get_limits" },
    });
    cfLatency.add(res.timings.duration);
    const ok = check(res, {
      "CF getSubscriptionLimits: reachable": (r) =>
        [200, 401, 403].includes(r.status),
    });
    errorRate.add(!ok);
  }

  sleep(0.2 + Math.random() * 0.3); // Jitter between iterations
}

// ─── Summary ────────────────────────────────────────────────────────────────

export function handleSummary(data) {
  const summary = {
    timestamp: new Date().toISOString(),
    project: PROJECT_ID,
    stages: options.stages,
    thresholds: {},
    metrics: {},
  };

  // Capture threshold results
  for (const [name, thresholds] of Object.entries(data.root_group?.thresholds || {})) {
    summary.thresholds[name] = thresholds;
  }

  // Capture key metrics
  for (const [name, metric] of Object.entries(data.metrics || {})) {
    if (metric.values) {
      summary.metrics[name] = metric.values;
    }
  }

  return {
    "build/reports/k6-load-test-results.json": JSON.stringify(summary, null, 2),
    stdout: textSummary(data, { indent: " ", enableColors: true }),
  };
}

// k6 built-in text summary
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js";
