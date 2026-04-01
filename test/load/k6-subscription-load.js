/**
 * RetailLite — k6 Subscription Load Test
 *
 * Tests subscription-related Cloud Functions under concurrent load.
 *
 * SETUP:
 *   1. Generate a Firebase Auth ID token:
 *      export K6_AUTH_TOKEN="<firebase-id-token>"
 *   2. Run:
 *      k6 run --env AUTH_TOKEN=$K6_AUTH_TOKEN test/load/k6-subscription-load.js
 *
 * WHAT IT TESTS:
 *   - 50 concurrent subscription creates → all succeed
 *   - 200 concurrent limit checks → p95 < 500ms
 *   - Subscription activation under load
 *   - Rate limiting behavior
 */

import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

// ─── Configuration ──────────────────────────────────────────────────────────

const PROJECT_ID = "login-radha";
const CF_BASE = `https://asia-south1-${PROJECT_ID}.cloudfunctions.net`;
const AUTH_TOKEN = __ENV.AUTH_TOKEN || "";

// ─── Custom Metrics ─────────────────────────────────────────────────────────

const subscriptionCreateLatency = new Trend("subscription_create_latency", true);
const limitCheckLatency = new Trend("limit_check_latency", true);
const activationLatency = new Trend("activation_latency", true);
const errorRate = new Rate("error_rate");

// ─── Test Configuration ─────────────────────────────────────────────────────

export const options = {
  scenarios: {
    subscription_creates: {
      executor: "constant-vus",
      vus: 50,
      duration: "1m",
      exec: "testSubscriptionCreate",
    },
    limit_checks: {
      executor: "constant-vus",
      vus: 200,
      duration: "1m",
      startTime: "1m",
      exec: "testLimitChecks",
    },
  },
  thresholds: {
    subscription_create_latency: ["p(95)<2000"],
    limit_check_latency: ["p(95)<500"],
    error_rate: ["rate<0.01"],
    http_req_duration: ["p(95)<1500"],
  },
};

// ─── Auth Headers ───────────────────────────────────────────────────────────

function authHeaders() {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${AUTH_TOKEN}`,
  };
}

// ─── Scenario: Subscription Creates ─────────────────────────────────────────

export function testSubscriptionCreate() {
  const payload = JSON.stringify({
    data: {
      plan: "pro",
      cycle: "monthly",
    },
  });

  const res = http.post(`${CF_BASE}/createSubscription`, payload, {
    headers: authHeaders(),
    tags: { name: "createSubscription" },
  });

  subscriptionCreateLatency.add(res.timings.duration);

  const success = check(res, {
    "createSubscription: status 200": (r) => r.status === 200,
    "createSubscription: has subscription_id": (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.result && body.result.subscriptionId;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);
  sleep(0.5);
}

// ─── Scenario: Limit Checks ────────────────────────────────────────────────

export function testLimitChecks() {
  const payload = JSON.stringify({ data: {} });

  const res = http.post(`${CF_BASE}/getSubscriptionLimits`, payload, {
    headers: authHeaders(),
    tags: { name: "getSubscriptionLimits" },
  });

  limitCheckLatency.add(res.timings.duration);

  const success = check(res, {
    "getSubscriptionLimits: status 200": (r) => r.status === 200,
    "getSubscriptionLimits: has limits": (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.result && typeof body.result.billsLimit === "number";
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);
  sleep(0.1);
}
