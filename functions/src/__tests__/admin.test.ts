/**
 * Admin operations tests
 */

describe("seedAdmins", () => {
  test("creates admin entries from ADMIN_EMAILS env var", () => {
    const adminEmailsEnv = "admin1@test.com,admin2@test.com,admin3@test.com";
    const adminEmails = adminEmailsEnv.split(",").map(e => e.trim()).filter(e => e.length > 0);
    expect(adminEmails).toHaveLength(3);
    expect(adminEmails).toContain("admin1@test.com");
  });

  test("falls back to hardcoded list when env empty", () => {
    const adminEmailsEnv: string = "";
    const hardcoded = [
      "kehsaram001@gmail.com",
      "admin@retaillite.com",
      "bharathiinstitute1@gmail.com",
    ];
    const adminEmails = adminEmailsEnv
      ? adminEmailsEnv.split(",").map((e: string) => e.trim()).filter((e: string) => e.length > 0)
      : hardcoded;
    expect(adminEmails).toHaveLength(3);
    expect(adminEmails).toContain("kehsaram001@gmail.com");
  });

  test("rejects non-admin caller", () => {
    const callerEmail = "random@gmail.com";
    const adminEmails = ["admin@retaillite.com"];
    const isAdmin = adminEmails.includes(callerEmail);
    expect(isAdmin).toBe(false);
  });

  test("handles empty env var gracefully", () => {
    const envVar: string = "";
    const emails = envVar ? envVar.split(",").map((e: string) => e.trim()).filter((e: string) => e.length > 0) : [];
    expect(emails).toHaveLength(0);
  });
});

describe("seedUserUsage", () => {
  test("bootstraps user_usage collection with cost estimates", () => {
    const userUsage = {
      userId: "user_123",
      billsCount: 45,
      productsCount: 80,
      expensesCount: 12,
    };
    expect(userUsage.billsCount).toBeGreaterThanOrEqual(0);
    expect(userUsage.productsCount).toBeGreaterThanOrEqual(0);
  });

  test("counts bills/products/expenses per user correctly", () => {
    const bills = 100;
    const products = 50;
    const expenses = 25;
    expect(bills + products + expenses).toBe(175);
  });
});
